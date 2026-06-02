//
//  XMLBuffer.swift
//  RhoeDOCX
//
//  High-performance XML output buffer for DOM serialization
//  Optimized for memory efficiency and speed
//

import Foundation

/// High-performance XML output buffer
public struct XMLBuffer: Sendable {
    
    private var buffer: String
    private var indentLevel: Int
    private let options: XMLSerializer.SerializationOptions
    private var elementStack: [String]
    
    public init(options: XMLSerializer.SerializationOptions) {
        self.buffer = ""
        self.indentLevel = 0
        self.options = options
        self.elementStack = []
        
        // Pre-allocate buffer for better performance
        self.buffer.reserveCapacity(8192)
    }
    
    /// Reset buffer for reuse
    public mutating func reset() {
        buffer.removeAll(keepingCapacity: true)
        indentLevel = 0
        elementStack.removeAll(keepingCapacity: true)
    }
    
    /// Get the final XML string
    public func getXML() -> String {
        return buffer
    }
    
    // MARK: - XML Declaration and Structure
    
    /// Write XML declaration
    public mutating func writeXMLDeclaration(version: String = "1.0", encoding: String = "UTF-8", standalone: String? = "yes") {
        buffer.append("<?xml version=\"\(version)\" encoding=\"\(encoding)\"")
        if let standalone = standalone {
            buffer.append(" standalone=\"\(standalone)\"")
        }
        buffer.append("?>")
        
        if options.prettyPrint {
            buffer.append("\n")
        }
    }
    
    // MARK: - Element Writing
    
    /// Start an element with optional attributes
    public mutating func startElement(_ name: String, attributes: [String: String] = [:]) {
        writeIndent()
        buffer.append("<\(name)")
        
        // Write attributes
        let sortedAttributes = options.sortAttributes ? 
            attributes.sorted(by: { $0.key < $1.key }) : 
            Array(attributes)
            
        for (key, value) in sortedAttributes {
            buffer.append(" \(key)=\"")
            buffer.append(escapeAttributeValue(value))
            buffer.append("\"")
        }
        
        buffer.append(">")
        
        if options.prettyPrint {
            buffer.append("\n")
        }
        
        elementStack.append(name)
        indentLevel += 1
    }
    
    /// End an element
    public mutating func endElement(_ name: String) {
        indentLevel -= 1
        
        // Validate element nesting
        if let lastElement = elementStack.popLast() {
            if lastElement != name {
                // This is a programming error, but we'll continue for robustness
                print("Warning: Element nesting mismatch. Expected '\(lastElement)', got '\(name)'")
            }
        }
        
        writeIndent()
        buffer.append("</\(name)>")
        
        if options.prettyPrint {
            buffer.append("\n")
        }
    }
    
    /// Write a complete element with content
    public mutating func writeElement(_ name: String, content: String = "", attributes: [String: String] = [:]) {
        writeIndent()
        buffer.append("<\(name)")
        
        // Write attributes
        let sortedAttributes = options.sortAttributes ? 
            attributes.sorted(by: { $0.key < $1.key }) : 
            Array(attributes)
            
        for (key, value) in sortedAttributes {
            buffer.append(" \(key)=\"")
            buffer.append(escapeAttributeValue(value))
            buffer.append("\"")
        }
        
        if content.isEmpty {
            buffer.append("/>")
        } else {
            buffer.append(">")
            buffer.append(escapeTextContent(content))
            buffer.append("</\(name)>")
        }
        
        if options.prettyPrint {
            buffer.append("\n")
        }
    }
    
    /// Write text content (escapes special characters)
    public mutating func writeTextContent(_ content: String) {
        if options.prettyPrint && !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            writeIndent()
        }
        
        buffer.append(escapeTextContent(content))
        
        if options.prettyPrint && !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            buffer.append("\n")
        }
    }
    
    /// Write CDATA section
    public mutating func writeCDATA(_ content: String) {
        if options.prettyPrint {
            writeIndent()
        }
        
        buffer.append("<![CDATA[")
        buffer.append(content)
        buffer.append("]]>")
        
        if options.prettyPrint {
            buffer.append("\n")
        }
    }
    
    /// Write XML comment
    public mutating func writeComment(_ content: String) {
        if options.prettyPrint {
            writeIndent()
        }
        
        buffer.append("<!-- ")
        buffer.append(content.replacingOccurrences(of: "--", with: "- -"))  // Escape double hyphens
        buffer.append(" -->")
        
        if options.prettyPrint {
            buffer.append("\n")
        }
    }
    
    /// Write processing instruction
    public mutating func writeProcessingInstruction(target: String, data: String? = nil) {
        if options.prettyPrint {
            writeIndent()
        }
        
        buffer.append("<?")
        buffer.append(target)
        
        if let data = data, !data.isEmpty {
            buffer.append(" ")
            buffer.append(data)
        }
        
        buffer.append("?>")
        
        if options.prettyPrint {
            buffer.append("\n")
        }
    }
    
    // MARK: - Formatting Helpers
    
    /// Write indentation for pretty printing
    private mutating func writeIndent() {
        if options.prettyPrint && indentLevel > 0 {
            let indent = String(repeating: " ", count: indentLevel * options.indentSize)
            buffer.append(indent)
        }
    }
    
    // MARK: - Character Escaping
    
    /// Escape text content for XML
    private func escapeTextContent(_ text: String) -> String {
        var result = text
        result = result.replacingOccurrences(of: "&", with: "&amp;")   // Must be first
        result = result.replacingOccurrences(of: "<", with: "&lt;")
        result = result.replacingOccurrences(of: ">", with: "&gt;")
        return result
    }
    
    /// Escape attribute values for XML
    private func escapeAttributeValue(_ value: String) -> String {
        var result = value
        result = result.replacingOccurrences(of: "&", with: "&amp;")   // Must be first
        result = result.replacingOccurrences(of: "<", with: "&lt;")
        result = result.replacingOccurrences(of: ">", with: "&gt;")
        result = result.replacingOccurrences(of: "\"", with: "&quot;")
        result = result.replacingOccurrences(of: "'", with: "&#39;")
        
        // Handle control characters that are invalid in XML
        result = result.filter { char in
            let code = char.unicodeScalars.first?.value ?? 0
            // Valid XML characters: #x9 | #xA | #xD | [#x20-#xD7FF] | [#xE000-#xFFFD] | [#x10000-#x10FFFF]
            return code == 0x09 || code == 0x0A || code == 0x0D || 
                   (code >= 0x20 && code <= 0xD7FF) ||
                   (code >= 0xE000 && code <= 0xFFFD) ||
                   (code >= 0x10000 && code <= 0x10FFFF)
        }
        
        return result
    }
    
    // MARK: - Performance Monitoring
    
    /// Get buffer statistics
    public func getStatistics() -> BufferStatistics {
        return BufferStatistics(
            bufferSize: buffer.count,
            bufferCapacity: buffer.count, // String doesn't have capacity in Swift, use count
            elementDepth: indentLevel,
            elementStackSize: elementStack.count
        )
    }
}

/// Buffer performance statistics
public struct BufferStatistics: Sendable {
    public let bufferSize: Int
    public let bufferCapacity: Int
    public let elementDepth: Int
    public let elementStackSize: Int
    
    /// Buffer utilization percentage
    public var utilization: Double {
        guard bufferCapacity > 0 else { return 0 }
        return Double(bufferSize) / Double(bufferCapacity) * 100
    }
    
    /// Human-readable buffer size
    public var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bufferSize))
    }
}

// MARK: - XML Validation

/// XML validation utilities
public struct XMLValidator: Sendable {
    
    /// Validate XML element name
    public static func isValidElementName(_ name: String) -> Bool {
        guard !name.isEmpty else { return false }
        
        // XML names must start with a letter or underscore
        let firstChar = name.first!
        guard firstChar.isLetter || firstChar == "_" else { return false }
        
        // Rest of the name can be letters, digits, hyphens, periods, or underscores
        for char in name.dropFirst() {
            if !char.isLetter && !char.isNumber && char != "-" && char != "." && char != "_" {
                return false
            }
        }
        
        return true
    }
    
    /// Validate XML attribute name  
    public static func isValidAttributeName(_ name: String) -> Bool {
        return isValidElementName(name)
    }
    
    /// Check if text contains only valid XML characters
    public static func containsOnlyValidXMLCharacters(_ text: String) -> Bool {
        for char in text {
            let code = char.unicodeScalars.first?.value ?? 0
            // Valid XML characters: #x9 | #xA | #xD | [#x20-#xD7FF] | [#xE000-#xFFFD] | [#x10000-#x10FFFF]
            if !(code == 0x09 || code == 0x0A || code == 0x0D || 
                 (code >= 0x20 && code <= 0xD7FF) ||
                 (code >= 0xE000 && code <= 0xFFFD) ||
                 (code >= 0x10000 && code <= 0x10FFFF)) {
                return false
            }
        }
        return true
    }
}

// MARK: - Serialization Errors

/// Errors that can occur during XML serialization
public enum XMLSerializationError: Error, Sendable {
    case invalidElementName(String)
    case invalidAttributeName(String)
    case invalidCharacters(String)
    case elementNestingError(expected: String, got: String)
    case namespaceValidationFailed(String)
    case bufferOverflow
}

extension XMLSerializationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidElementName(let name):
            return "Invalid XML element name: \(name)"
        case .invalidAttributeName(let name):
            return "Invalid XML attribute name: \(name)"
        case .invalidCharacters(let text):
            return "Text contains invalid XML characters: \(text)"
        case .elementNestingError(let expected, let got):
            return "Element nesting error: expected \(expected), got \(got)"
        case .namespaceValidationFailed(let reason):
            return "Namespace validation failed: \(reason)"
        case .bufferOverflow:
            return "XML buffer overflow"
        }
    }
}