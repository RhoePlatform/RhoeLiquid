//
//  DocumentParts.swift
//  RhoeDOCX
//
//  Core document parts for DOCX packages
//

import Foundation

// MARK: - Main Document Part

/// The main document part (word/document.xml)
public actor MainDocumentPart: PackagePart {
    public let path: String
    public let contentType = DOCXContentTypes.mainDocument
    
    private var _relationships: PartRelationships?
    
    /// The document body
    public let body: Body
    
    /// Weak reference to parent package
    private weak var package: DOCXPackage?
    
    public var relationships: PartRelationships? {
        get async {
            return _relationships
        }
    }
    
    public func setRelationships(_ relationships: PartRelationships) async {
        _relationships = relationships
    }
    
    init(data: Data, path: String, package: DOCXPackage) throws {
        self.path = path
        self.package = package
        
        // v0.1.0 package model: structured body parsing is handled by the
        // templating pipeline; this part keeps a minimal body representation.
        self.body = Body(paragraphs: [])
    }
    
    public func toXML() async throws -> Data {
        var builder = XMLBuilder()
        builder.addDeclaration()
        
        // v0.1.0 package model: serialize the minimal body representation.
        builder.openElement("w:document", namespace: XMLNamespaces.wordprocessingML)
        builder.openElement("w:body")
        
        // Serialize body content
        for paragraph in body.paragraphs {
            builder.addRawContent(paragraph.toXML())
        }
        
        builder.closeElement("w:body")
        builder.closeElement("w:document")
        
        return try builder.buildData()
    }
}

// MARK: - Styles Part

/// The styles part (word/styles.xml)
public struct StylesPart: PackagePart {
    public let path = "word/styles.xml"
    public let contentType = DOCXContentTypes.styles
    
    init(data: Data) throws {
        _ = data
    }
    
    public func toXML() async throws -> Data {
        // Opaque style preservation is owned by the package pipeline.
        return Data()
    }
}

// MARK: - Settings Part

/// The settings part (word/settings.xml)
public struct SettingsPart: PackagePart {
    public let path = "word/settings.xml"
    public let contentType = DOCXContentTypes.settings
    
    init(data: Data) throws {
        _ = data
    }
    
    public func toXML() async throws -> Data {
        // Opaque settings preservation is owned by the package pipeline.
        return Data()
    }
}

// MARK: - Numbering Part

/// The numbering part (word/numbering.xml)
public struct NumberingPart: PackagePart {
    public let path = "word/numbering.xml"
    public let contentType = DOCXContentTypes.numbering
    
    init(data: Data) throws {
        _ = data
    }
    
    public func toXML() async throws -> Data {
        // Opaque numbering preservation is owned by the package pipeline.
        return Data()
    }
}

// MARK: - Header Part

/// A header part
public struct HeaderPart: PackagePart {
    public let path: String
    public let contentType = DOCXContentTypes.header
    
    init(data: Data, path: String) throws {
        self.path = path
        _ = data
    }
    
    public func toXML() async throws -> Data {
        // Opaque header preservation is owned by the package pipeline.
        return Data()
    }
}

// MARK: - Footer Part

/// A footer part
public struct FooterPart: PackagePart {
    public let path: String
    public let contentType = DOCXContentTypes.footer
    
    init(data: Data, path: String) throws {
        self.path = path
        _ = data
    }
    
    public func toXML() async throws -> Data {
        // Opaque footer preservation is owned by the package pipeline.
        return Data()
    }
}

// MARK: - Minimal Document Model

/// Document body
public struct Body: Sendable {
    public let paragraphs: [Paragraph]
}

/// A paragraph in the document
public struct Paragraph: Sendable {
    public let runs: [Run]
    
    init(runs: [Run] = []) {
        self.runs = runs
    }
    
    func toXML() -> String {
        // v0.1.0 package model: richer paragraph serialization is handled by
        // the dedicated WordprocessingML pipeline.
        return "<w:p></w:p>"
    }
}

/// A run of text with consistent formatting
public struct Run: Sendable {
    public let text: String
    
    init(text: String) {
        self.text = text
    }
}
