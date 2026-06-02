//
//  SimpleXMLParser.swift
//  RhoeDOCX
//
//  Simplified XML parser for WordprocessingML documents
//  Uses synchronous processing to avoid concurrency complexity
//

import Foundation

/// Simple XML parser for WordprocessingML documents
public class SimpleXMLParser: NSObject {
    
    /// Parsing events
    public enum Event {
        case startDocument
        case endDocument
        case startElement(name: String, namespace: String?, attributes: [String: String])
        case endElement(name: String, namespace: String?)
        case characters(String)
        case processingInstruction(target: String, data: String?)
        case comment(String)
        case error(XMLParsingError)
    }
    
    /// XML parsing errors
    public enum XMLParsingError: Error {
        case invalidXML(String)
        case namespaceError(String)
        case encodingError(String)
        case structureError(String)
        case unexpectedEOF
    }
    
    /// Collected events
    public private(set) var events: [Event] = []
    
    /// Namespace stack
    private var namespaceStack: [[String: String]] = [[:]]
    
    public override init() {
        super.init()
    }
    
    /// Parse XML data and collect events
    public func parse(data: Data) throws -> [Event] {
        events.removeAll()
        namespaceStack = [[:]]
        
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.shouldProcessNamespaces = true
        parser.shouldReportNamespacePrefixes = true
        
        events.append(.startDocument)
        
        let success = parser.parse()
        
        if !success {
            if let error = parser.parserError {
                let xmlError = XMLParsingError.invalidXML(error.localizedDescription)
                events.append(.error(xmlError))
                throw xmlError
            } else {
                let xmlError = XMLParsingError.invalidXML("Unknown parsing error")
                events.append(.error(xmlError))
                throw xmlError
            }
        }
        
        events.append(.endDocument)
        return events
    }
    
    /// Parse XML from file
    public func parse(url: URL) throws -> [Event] {
        let data = try Data(contentsOf: url)
        return try parse(data: data)
    }
    
    /// Parse XML from string
    public func parse(string: String) throws -> [Event] {
        guard let data = string.data(using: .utf8) else {
            throw XMLParsingError.encodingError("Failed to encode string as UTF-8")
        }
        return try parse(data: data)
    }
}

// MARK: - XMLParserDelegate

extension SimpleXMLParser: XMLParserDelegate {
    
    public func parser(_ parser: XMLParser, didStartElement elementName: String,
                      namespaceURI: String?, qualifiedName qName: String?,
                      attributes attributeDict: [String: String] = [:]) {
        
        // Push new namespace context
        var newNamespaces = namespaceStack.last ?? [:]
        
        // Process namespace declarations in attributes
        for (key, value) in attributeDict {
            if key == "xmlns" {
                // Default namespace
                newNamespaces[""] = value
            } else if key.hasPrefix("xmlns:") {
                // Prefixed namespace
                let prefix = String(key.dropFirst(6))
                newNamespaces[prefix] = value
            }
        }
        
        namespaceStack.append(newNamespaces)
        
        // Filter out namespace declarations from attributes
        let filteredAttributes = attributeDict.filter { key, _ in
            !key.hasPrefix("xmlns")
        }
        
        events.append(.startElement(
            name: elementName,
            namespace: namespaceURI,
            attributes: filteredAttributes
        ))
    }
    
    public func parser(_ parser: XMLParser, didEndElement elementName: String,
                      namespaceURI: String?, qualifiedName qName: String?) {
        
        events.append(.endElement(
            name: elementName,
            namespace: namespaceURI
        ))
        
        // Pop namespace context
        if namespaceStack.count > 1 {
            namespaceStack.removeLast()
        }
    }
    
    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        events.append(.characters(string))
    }
    
    public func parser(_ parser: XMLParser, foundComment comment: String) {
        events.append(.comment(comment))
    }
    
    public func parser(_ parser: XMLParser, foundProcessingInstructionWithTarget target: String,
                      data: String?) {
        events.append(.processingInstruction(target: target, data: data))
    }
    
    public func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        let xmlError = XMLParsingError.invalidXML(parseError.localizedDescription)
        events.append(.error(xmlError))
    }
    
    public func parser(_ parser: XMLParser, validationErrorOccurred validationError: Error) {
        let xmlError = XMLParsingError.structureError(validationError.localizedDescription)
        events.append(.error(xmlError))
    }
}

// MARK: - WordprocessingML Namespace Constants

/// Common namespaces used in WordprocessingML documents
public enum WordMLNamespaces {
    /// WordprocessingML main namespace
    public static let main = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    
    /// Relationships namespace
    public static let relationships = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
    
    /// DrawingML main namespace
    public static let drawingML = "http://schemas.openxmlformats.org/drawingml/2006/main"
    
    /// WordprocessingDrawing namespace
    public static let wordprocessingDrawing = "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
    
    /// Picture namespace
    public static let picture = "http://schemas.openxmlformats.org/drawingml/2006/picture"
    
    /// Content Types namespace
    public static let contentTypes = "http://schemas.openxmlformats.org/package/2006/content-types"
    
    /// Package relationships namespace
    public static let packageRelationships = "http://schemas.openxmlformats.org/package/2006/relationships"
    
    /// Check if namespace is WordprocessingML main
    public static func isMain(_ namespace: String?) -> Bool {
        return namespace == main
    }
    
    /// Check if namespace is relationships
    public static func isRelationships(_ namespace: String?) -> Bool {
        return namespace == relationships
    }
    
    /// Check if namespace is DrawingML
    public static func isDrawingML(_ namespace: String?) -> Bool {
        return namespace == drawingML
    }
}