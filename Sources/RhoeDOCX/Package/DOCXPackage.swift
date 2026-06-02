//
//  DOCXPackage.swift
//  RhoeDOCX
//
//  High-level DOCX package access built on the active ZIP layer.
//

import Foundation

/// A complete DOCX package with the active set of package parts and relationships.
public actor DOCXPackage: Sendable {
    
    /// The underlying ZIP package
    private let zipPackage: ZIPPackage
    
    /// Content types configuration
    public let contentTypes: ContentTypes
    
    /// Package relationships
    public let relationships: PackageRelationships
    
    /// All package parts indexed by path
    private var parts: [String: PackagePart] = [:]
    
    /// Main document part
    public var mainDocument: MainDocumentPart? {
        get async {
            await getPart(MainDocumentPart.self, path: "word/document.xml")
        }
    }
    
    /// Styles part
    public var styles: StylesPart? {
        get async {
            await getPart(StylesPart.self, path: "word/styles.xml")
        }
    }
    
    /// Document settings
    public var settings: SettingsPart? {
        get async {
            await getPart(SettingsPart.self, path: "word/settings.xml")
        }
    }
    
    /// Numbering definitions
    public var numbering: NumberingPart? {
        get async {
            await getPart(NumberingPart.self, path: "word/numbering.xml")
        }
    }
    
    // MARK: - Initialization
    
    /// Creates a package from an already opened ZIP package.
    init(zipPackage: ZIPPackage) async throws {
        self.zipPackage = zipPackage
        
        // Parse content types
        let contentTypesData = try await zipPackage.extractData(for: "[Content_Types].xml")
        self.contentTypes = try ContentTypes(data: contentTypesData)
        
        // Parse package relationships
        let relsData = try await zipPackage.extractData(for: "_rels/.rels")
        self.relationships = try PackageRelationships(data: relsData)
        
        // Load all parts
        try await loadParts()
    }
    
    // MARK: - Public API
    
    /// Opens a DOCX package from in-memory data.
    public static func open(data: Data) async throws -> DOCXPackage {
        let archive = ZIPArchive(data: data)
        let zipPackage = try await archive.open()
        return try await DOCXPackage(zipPackage: zipPackage)
    }
    
    /// Opens a DOCX package from a file URL.
    public static func open(url: URL) async throws -> DOCXPackage {
        let archive = ZIPArchive(url: url)
        let zipPackage = try await archive.open()
        return try await DOCXPackage(zipPackage: zipPackage)
    }
    
    /// Returns every loaded header part in the package.
    public func headers() async -> [HeaderPart] {
        parts.values.compactMap { $0 as? HeaderPart }
    }
    
    /// Returns every loaded footer part in the package.
    public func footers() async -> [FooterPart] {
        parts.values.compactMap { $0 as? FooterPart }
    }
    
    /// Looks up a part by its package path.
    public func part(at path: String) async -> PackagePart? {
        parts[path]
    }
    
    /// Looks up a part by path and casts it to a specific part type.
    public func getPart<T: PackagePart>(_ type: T.Type, path: String) async -> T? {
        parts[path] as? T
    }
    
    /// Adds or replaces a part at the supplied package path.
    public func setPart(_ part: PackagePart, at path: String) {
        parts[path] = part
    }
    
    /// Removes a part from the package.
    public func removePart(at path: String) {
        parts.removeValue(forKey: path)
    }
    
    /// Serializes the current package back into DOCX data.
    public func save() async throws -> Data {
        let builder = ZIPBuilder()
        
        // Add content types
        let contentTypesData = try contentTypes.toXML()
        await builder.addFile(path: "[Content_Types].xml", data: contentTypesData)
        
        // Add package relationships
        let relsData = try relationships.toXML()
        await builder.addFile(path: "_rels/.rels", data: relsData)
        
        // Add all parts
        for (path, part) in parts {
            let partData = try await part.toXML()
            await builder.addFile(path: path, data: partData)
            
            // Add part relationships if any
            if let partRels = await part.relationships {
                let relsPath = relationshipPath(for: path)
                let partRelsData = try partRels.toXML()
                await builder.addFile(path: relsPath, data: partRelsData)
            }
        }
        
        // Add any other files from original package (media, etc.)
        for (path, _) in zipPackage.files {
            if !isSystemPath(path) && parts[path] == nil {
                let data = try await zipPackage.extractData(for: path)
                await builder.addFile(path: path, data: data)
            }
        }
        
        return try await builder.build()
    }
    
    // MARK: - Private Implementation
    
    private func loadParts() async throws {
        // Load main document
        if let mainRel = relationships.relationships.first(where: { $0.type == RelationshipTypes.mainDocument }) {
            let path = resolvePath(mainRel.target, from: "")
            if zipPackage.exists(path: path) {
                let data = try await zipPackage.extractData(for: path)
                let mainDoc = try MainDocumentPart(data: data, path: path, package: self)
                parts[path] = mainDoc
                
                // Load document relationships
                try await loadPartRelationships(for: path)
            }
        }
        
        // Load styles
        if zipPackage.exists(path: "word/styles.xml") {
            let data = try await zipPackage.extractData(for: "word/styles.xml")
            parts["word/styles.xml"] = try StylesPart(data: data)
        }
        
        // Load settings
        if zipPackage.exists(path: "word/settings.xml") {
            let data = try await zipPackage.extractData(for: "word/settings.xml")
            parts["word/settings.xml"] = try SettingsPart(data: data)
        }
        
        // Load numbering
        if zipPackage.exists(path: "word/numbering.xml") {
            let data = try await zipPackage.extractData(for: "word/numbering.xml")
            parts["word/numbering.xml"] = try NumberingPart(data: data)
        }
        
        // Load headers and footers from document relationships
        if let mainDoc = await mainDocument {
            for rel in await mainDoc.relationships?.relationships ?? [] {
                let path = resolvePath(rel.target, from: "word/")
                
                switch rel.type {
                case RelationshipTypes.header:
                    if zipPackage.exists(path: path) {
                        let data = try await zipPackage.extractData(for: path)
                        parts[path] = try HeaderPart(data: data, path: path)
                    }
                    
                case RelationshipTypes.footer:
                    if zipPackage.exists(path: path) {
                        let data = try await zipPackage.extractData(for: path)
                        parts[path] = try FooterPart(data: data, path: path)
                    }
                    
                default:
                    break
                }
            }
        }
    }
    
    private func loadPartRelationships(for partPath: String) async throws {
        let relsPath = relationshipPath(for: partPath)
        
        if zipPackage.exists(path: relsPath) {
            let relsData = try await zipPackage.extractData(for: relsPath)
            let relationships = try PartRelationships(data: relsData)
            
            if let part = parts[partPath] {
                await part.setRelationships(relationships)
            }
        }
    }
    
    private func relationshipPath(for partPath: String) -> String {
        let directory = (partPath as NSString).deletingLastPathComponent
        let filename = (partPath as NSString).lastPathComponent
        
        if directory.isEmpty || directory == "/" {
            return "_rels/\(filename).rels"
        } else {
            return "\(directory)/_rels/\(filename).rels"
        }
    }
    
    private func resolvePath(_ target: String, from base: String) -> String {
        if target.hasPrefix("/") {
            return String(target.dropFirst())
        }
        
        if base.isEmpty {
            return target
        }
        
        let basePath = base.hasSuffix("/") ? base : base + "/"
        return basePath + target
    }
    
    private func isSystemPath(_ path: String) -> Bool {
        return path == "[Content_Types].xml" || 
               path.contains("_rels/") ||
               path.hasPrefix("docProps/")
    }
}

/// Base protocol implemented by active package-part types.
public protocol PackagePart: Sendable {
    /// The path of this part within the package
    var path: String { get }
    
    /// Content type of this part
    var contentType: String { get }
    
    /// Relationships for this part
    var relationships: PartRelationships? { get async }
    
    /// Set relationships for this part
    func setRelationships(_ relationships: PartRelationships) async
    
    /// Convert to XML data
    func toXML() async throws -> Data
}

/// Default no-op behavior for part relationships.
public extension PackagePart {
    var relationships: PartRelationships? {
        get async { nil }
    }
    
    func setRelationships(_ relationships: PartRelationships) async {
        // Default: no-op
    }
}

/// Relationship type constants used by the active package loader.
public enum RelationshipTypes {
    public static let mainDocument = "http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument"
    public static let styles = "http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles"
    public static let settings = "http://schemas.openxmlformats.org/officeDocument/2006/relationships/settings"
    public static let numbering = "http://schemas.openxmlformats.org/officeDocument/2006/relationships/numbering"
    public static let header = "http://schemas.openxmlformats.org/officeDocument/2006/relationships/header"
    public static let footer = "http://schemas.openxmlformats.org/officeDocument/2006/relationships/footer"
    public static let image = "http://schemas.openxmlformats.org/officeDocument/2006/relationships/image"
    public static let hyperlink = "http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink"
    public static let theme = "http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme"
    public static let fontTable = "http://schemas.openxmlformats.org/officeDocument/2006/relationships/fontTable"
}

/// Content-type constants used by the active package loader.
public enum DOCXContentTypes {
    public static let mainDocument = "application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"
    public static let styles = "application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"
    public static let settings = "application/vnd.openxmlformats-officedocument.wordprocessingml.settings+xml"
    public static let numbering = "application/vnd.openxmlformats-officedocument.wordprocessingml.numbering+xml"
    public static let header = "application/vnd.openxmlformats-officedocument.wordprocessingml.header+xml"
    public static let footer = "application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml"
    public static let relationships = "application/vnd.openxmlformats-package.relationships+xml"
}
