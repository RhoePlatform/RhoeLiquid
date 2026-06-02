//
//  ContentTypes.swift
//  RhoeDOCX
//
//  Content Types handling for DOCX packages ([Content_Types].xml)
//

import Foundation

/// Content Types configuration for a DOCX package
public struct ContentTypes: Sendable {
    
    /// Default content types by extension
    public var defaults: [String: String] = [:]
    
    /// Override content types by part name
    public var overrides: [String: String] = [:]
    
    /// Initialize empty content types
    public init() {
        setupDefaults()
    }
    
    /// Initialize from XML data
    public init(data: Data) throws {
        setupDefaults()
        try parseXML(data)
    }
    
    /// Get content type for a part
    public func contentType(for path: String) -> String? {
        // Check overrides first
        if let override = overrides["/\(path)"] {
            return override
        }
        
        // Check defaults by extension
        let ext = (path as NSString).pathExtension.lowercased()
        return defaults[ext]
    }
    
    /// Add or update a content type
    public mutating func setContentType(_ contentType: String, for path: String) {
        overrides["/\(path)"] = contentType
    }
    
    /// Convert to XML data
    public func toXML() throws -> Data {
        var xml = #"""
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
        """#
        
        // Write defaults
        for (ext, contentType) in defaults.sorted(by: { $0.key < $1.key }) {
            xml += #"""
            
            <Default Extension="\#(ext)" ContentType="\#(contentType.xmlEscaped)"/>
            """#
        }
        
        // Write overrides
        for (partName, contentType) in overrides.sorted(by: { $0.key < $1.key }) {
            xml += #"""
            
            <Override PartName="\#(partName)" ContentType="\#(contentType.xmlEscaped)"/>
            """#
        }
        
        xml += "\n</Types>"
        
        guard let data = xml.data(using: .utf8) else {
            throw DOCXError.encodingError("Failed to encode content types XML")
        }
        
        return data
    }
    
    // MARK: - Private Implementation
    
    private mutating func setupDefaults() {
        // Standard defaults as per ECMA-376
        defaults = [
            "rels": DOCXContentTypes.relationships,
            "xml": "application/xml",
            "png": "image/png",
            "jpeg": "image/jpeg",
            "jpg": "image/jpeg",
            "gif": "image/gif",
            "emf": "image/x-emf",
            "wmf": "image/x-wmf",
            "bin": "application/vnd.openxmlformats-officedocument.oleObject"
        ]
        
        // Standard overrides
        overrides = [
            "/word/document.xml": DOCXContentTypes.mainDocument,
            "/word/styles.xml": DOCXContentTypes.styles,
            "/word/settings.xml": DOCXContentTypes.settings,
            "/word/fontTable.xml": "application/vnd.openxmlformats-officedocument.wordprocessingml.fontTable+xml",
            "/word/webSettings.xml": "application/vnd.openxmlformats-officedocument.wordprocessingml.webSettings+xml",
            "/docProps/app.xml": "application/vnd.openxmlformats-officedocument.extended-properties+xml",
            "/docProps/core.xml": "application/vnd.openxmlformats-package.core-properties+xml"
        ]
    }
    
    private mutating func parseXML(_ data: Data) throws {
        let parser = XMLParser(data: data)
        let delegate = ContentTypesParserDelegate()
        parser.delegate = delegate
        
        guard parser.parse() else {
            throw DOCXError.xmlParseError("Failed to parse content types", parser.parserError)
        }
        
        // Merge parsed values
        for (ext, contentType) in delegate.defaults {
            defaults[ext] = contentType
        }
        
        for (partName, contentType) in delegate.overrides {
            overrides[partName] = contentType
        }
    }
}

// MARK: - XML Parser Delegate

private class ContentTypesParserDelegate: NSObject, XMLParserDelegate {
    var defaults: [String: String] = [:]
    var overrides: [String: String] = [:]
    
    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String : String] = [:]) {
        
        switch elementName {
        case "Default":
            if let ext = attributeDict["Extension"],
               let contentType = attributeDict["ContentType"] {
                defaults[ext] = contentType
            }
            
        case "Override":
            if let partName = attributeDict["PartName"],
               let contentType = attributeDict["ContentType"] {
                overrides[partName] = contentType
            }
            
        default:
            break
        }
    }
}