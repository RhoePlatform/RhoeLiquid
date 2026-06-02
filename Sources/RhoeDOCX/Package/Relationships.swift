//
//  Relationships.swift
//  RhoeDOCX
//
//  Relationships handling for DOCX packages
//

import Foundation

/// A single relationship
public struct Relationship: Sendable, Identifiable {
    public let id: String
    public let type: String
    public let target: String
    public let targetMode: TargetMode
    
    public enum TargetMode: String, Sendable {
        case `internal` = "Internal"
        case external = "External"
    }
    
    public init(id: String, type: String, target: String, targetMode: TargetMode = .internal) {
        self.id = id
        self.type = type
        self.target = target
        self.targetMode = targetMode
    }
}

/// Package-level relationships (_rels/.rels)
public struct PackageRelationships: Sendable {
    public var relationships: [Relationship] = []
    
    /// Initialize empty relationships
    public init() {}
    
    /// Initialize from XML data
    public init(data: Data) throws {
        try parseXML(data)
    }
    
    /// Find relationship by ID
    public func relationship(withId id: String) -> Relationship? {
        relationships.first { $0.id == id }
    }
    
    /// Find relationships by type
    public func relationships(ofType type: String) -> [Relationship] {
        relationships.filter { $0.type == type }
    }
    
    /// Add a relationship
    public mutating func add(_ relationship: Relationship) {
        relationships.append(relationship)
    }
    
    /// Remove a relationship
    public mutating func remove(withId id: String) {
        relationships.removeAll { $0.id == id }
    }
    
    /// Generate next available relationship ID
    public func nextRelationshipId() -> String {
        let existingIds = relationships.compactMap { rel in
            // Extract number from rId1, rId2, etc.
            if rel.id.hasPrefix("rId") {
                return Int(rel.id.dropFirst(3))
            }
            return nil
        }
        
        let nextNumber = (existingIds.max() ?? 0) + 1
        return "rId\(nextNumber)"
    }
    
    /// Convert to XML data
    public func toXML() throws -> Data {
        var xml = #"""
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
        """#
        
        for rel in relationships {
            let targetMode = rel.targetMode == .external ? #" TargetMode="External""# : ""
            xml += #"""
            
            <Relationship Id="\#(rel.id)" Type="\#(rel.type)" Target="\#(rel.target.xmlEscaped)"\#(targetMode)/>
            """#
        }
        
        xml += "\n</Relationships>"
        
        guard let data = xml.data(using: .utf8) else {
            throw DOCXError.encodingError("Failed to encode relationships XML")
        }
        
        return data
    }
    
    // MARK: - Private Implementation
    
    private mutating func parseXML(_ data: Data) throws {
        let parser = XMLParser(data: data)
        let delegate = RelationshipsParserDelegate()
        parser.delegate = delegate
        
        guard parser.parse() else {
            throw DOCXError.xmlParseError("Failed to parse relationships", parser.parserError)
        }
        
        self.relationships = delegate.relationships
    }
}

/// Part-level relationships (e.g., word/_rels/document.xml.rels)
public typealias PartRelationships = PackageRelationships

// MARK: - XML Parser Delegate

private class RelationshipsParserDelegate: NSObject, XMLParserDelegate {
    var relationships: [Relationship] = []
    
    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String : String] = [:]) {
        
        if elementName == "Relationship" {
            guard let id = attributeDict["Id"],
                  let type = attributeDict["Type"],
                  let target = attributeDict["Target"] else {
                return
            }
            
            let targetMode: Relationship.TargetMode
            if let mode = attributeDict["TargetMode"], mode == "External" {
                targetMode = .external
            } else {
                targetMode = .internal
            }
            
            let relationship = Relationship(
                id: id,
                type: type,
                target: target,
                targetMode: targetMode
            )
            
            relationships.append(relationship)
        }
    }
}

// MARK: - Relationship Builder

/// Helper for building relationships
public struct RelationshipBuilder {
    private var relationships: [Relationship] = []
    private var idCounter = 1
    
    public init() {}
    
    /// Add a main document relationship
    @discardableResult
    public mutating func addMainDocument(target: String = "word/document.xml") -> String {
        let id = "rId\(idCounter)"
        idCounter += 1
        
        relationships.append(Relationship(
            id: id,
            type: RelationshipTypes.mainDocument,
            target: target
        ))
        
        return id
    }
    
    /// Add a styles relationship
    @discardableResult
    public mutating func addStyles(target: String = "styles.xml") -> String {
        let id = "rId\(idCounter)"
        idCounter += 1
        
        relationships.append(Relationship(
            id: id,
            type: RelationshipTypes.styles,
            target: target
        ))
        
        return id
    }
    
    /// Add a header relationship
    @discardableResult
    public mutating func addHeader(target: String) -> String {
        let id = "rId\(idCounter)"
        idCounter += 1
        
        relationships.append(Relationship(
            id: id,
            type: RelationshipTypes.header,
            target: target
        ))
        
        return id
    }
    
    /// Add a footer relationship
    @discardableResult
    public mutating func addFooter(target: String) -> String {
        let id = "rId\(idCounter)"
        idCounter += 1
        
        relationships.append(Relationship(
            id: id,
            type: RelationshipTypes.footer,
            target: target
        ))
        
        return id
    }
    
    /// Add an image relationship
    @discardableResult
    public mutating func addImage(target: String) -> String {
        let id = "rId\(idCounter)"
        idCounter += 1
        
        relationships.append(Relationship(
            id: id,
            type: RelationshipTypes.image,
            target: target
        ))
        
        return id
    }
    
    /// Add a hyperlink relationship
    @discardableResult
    public mutating func addHyperlink(target: String, external: Bool = true) -> String {
        let id = "rId\(idCounter)"
        idCounter += 1
        
        relationships.append(Relationship(
            id: id,
            type: RelationshipTypes.hyperlink,
            target: target,
            targetMode: external ? .external : .internal
        ))
        
        return id
    }
    
    /// Add a custom relationship
    @discardableResult
    public mutating func addCustom(type: String, target: String, external: Bool = false) -> String {
        let id = "rId\(idCounter)"
        idCounter += 1
        
        relationships.append(Relationship(
            id: id,
            type: type,
            target: target,
            targetMode: external ? .external : .internal
        ))
        
        return id
    }
    
    /// Build the relationships
    public func build() -> PackageRelationships {
        var rels = PackageRelationships()
        rels.relationships = relationships
        return rels
    }
}