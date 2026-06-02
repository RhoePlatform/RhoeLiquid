//
//  XMLUtilities.swift
//  RhoeDOCX
//
//  XML utility functions for DOCX processing
//

import Foundation

// MARK: - XML Escaping

public extension String {
    /// Escape string for XML
    var xmlEscaped: String {
        let entities = [
            ("&", "&amp;"),
            ("<", "&lt;"),
            (">", "&gt;"),
            ("\"", "&quot;"),
            ("'", "&apos;")
        ]
        
        var escaped = self
        for (char, entity) in entities {
            escaped = escaped.replacingOccurrences(of: char, with: entity)
        }
        
        return escaped
    }
    
    /// Unescape XML entities
    var xmlUnescaped: String {
        let entities = [
            ("&amp;", "&"),
            ("&lt;", "<"),
            ("&gt;", ">"),
            ("&quot;", "\""),
            ("&apos;", "'")
        ]
        
        var unescaped = self
        for (entity, char) in entities {
            unescaped = unescaped.replacingOccurrences(of: entity, with: char)
        }
        
        return unescaped
    }
}

// MARK: - XML Namespaces

/// Common XML namespaces used in DOCX
public enum XMLNamespaces {
    public static let wordprocessingML = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    public static let drawingML = "http://schemas.openxmlformats.org/drawingml/2006/main"
    public static let relationships = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
    public static let contentTypes = "http://schemas.openxmlformats.org/package/2006/content-types"
    
    /// Namespace prefixes
    public enum Prefix {
        public static let w = "w"    // WordprocessingML
        public static let a = "a"    // DrawingML
        public static let r = "r"    // Relationships
        public static let ct = "ct"  // Content Types
    }
}

// MARK: - XML Builder Helpers

/// Helper for building XML with proper formatting
public struct XMLBuilder {
    private var content: String = ""
    private var indentLevel: Int = 0
    private let indentString = "  "
    
    public init() {}
    
    /// Add XML declaration
    public mutating func addDeclaration() {
        content += #"<?xml version="1.0" encoding="UTF-8" standalone="yes"?>"# + "\n"
    }
    
    /// Open an element
    public mutating func openElement(_ name: String, attributes: [(String, String)] = []) {
        addIndent()
        content += "<\(name)"
        
        for (key, value) in attributes {
            content += #" \#(key)="\#(value.xmlEscaped)""#
        }
        
        content += ">"
        indentLevel += 1
    }
    
    /// Open an element with namespace
    public mutating func openElement(_ name: String, namespace: String, attributes: [(String, String)] = []) {
        var allAttributes = attributes
        allAttributes.insert(("xmlns", namespace), at: 0)
        openElement(name, attributes: allAttributes)
    }
    
    /// Close an element
    public mutating func closeElement(_ name: String) {
        indentLevel -= 1
        if content.hasSuffix(">") {
            content += "\n"
            addIndent()
        }
        content += "</\(name)>\n"
    }
    
    /// Add a self-closing element
    public mutating func addElement(_ name: String, attributes: [(String, String)] = []) {
        addIndent()
        content += "<\(name)"
        
        for (key, value) in attributes {
            content += #" \#(key)="\#(value.xmlEscaped)""#
        }
        
        content += "/>\n"
    }
    
    /// Add text content
    public mutating func addText(_ text: String) {
        content += text.xmlEscaped
    }
    
    /// Add raw content (already escaped)
    public mutating func addRawContent(_ raw: String) {
        content += raw
    }
    
    /// Build the final XML string
    public func build() -> String {
        return content
    }
    
    /// Build as Data
    public func buildData() throws -> Data {
        guard let data = content.data(using: .utf8) else {
            throw DOCXError.encodingError("Failed to encode XML as UTF-8")
        }
        return data
    }
    
    private mutating func addIndent() {
        for _ in 0..<indentLevel {
            content += indentString
        }
    }
}

// MARK: - XML Parsing Helpers

/// Base class for XML parser delegates with common functionality
open class BaseXMLParserDelegate: NSObject, XMLParserDelegate {
    
    /// Current element being parsed
    public var currentElement: String = ""
    
    /// Text content of current element
    public var currentText: String = ""
    
    /// Stack of element names for nested parsing
    public var elementStack: [String] = []
    
    /// Namespace mappings
    public var namespaces: [String: String] = [:]
    
    // MARK: - XMLParserDelegate
    
    public func parser(_ parser: XMLParser, didStartElement elementName: String,
                      namespaceURI: String?, qualifiedName qName: String?,
                      attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        currentText = ""
        elementStack.append(elementName)
        
        // Handle namespace declarations
        for (key, value) in attributeDict {
            if key.hasPrefix("xmlns") {
                let prefix = key.count > 5 ? String(key.dropFirst(6)) : ""
                namespaces[prefix] = value
            }
        }
        
        // Call subclass implementation
        didStartElement(elementName, namespaceURI: namespaceURI,
                       qualifiedName: qName, attributes: attributeDict)
    }
    
    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }
    
    public func parser(_ parser: XMLParser, didEndElement elementName: String,
                      namespaceURI: String?, qualifiedName qName: String?) {
        // Call subclass implementation
        didEndElement(elementName, text: currentText.trimmingCharacters(in: .whitespacesAndNewlines),
                     namespaceURI: namespaceURI, qualifiedName: qName)
        
        elementStack.removeLast()
        currentElement = elementStack.last ?? ""
        currentText = ""
    }
    
    // MARK: - Subclass Override Points
    
    /// Override in subclass to handle element start
    open func didStartElement(_ elementName: String, namespaceURI: String?,
                             qualifiedName: String?, attributes: [String: String]) {
        // Subclasses override this
    }
    
    /// Override in subclass to handle element end with text content
    open func didEndElement(_ elementName: String, text: String,
                           namespaceURI: String?, qualifiedName: String?) {
        // Subclasses override this
    }
    
    // MARK: - Helpers
    
    /// Check if currently parsing within a specific element
    public func isWithin(_ elementName: String) -> Bool {
        return elementStack.contains(elementName)
    }
    
    /// Get the parent element name
    public var parentElement: String? {
        guard elementStack.count > 1 else { return nil }
        return elementStack[elementStack.count - 2]
    }
}