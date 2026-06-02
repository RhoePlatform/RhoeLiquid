//
//  HTMLEscape.swift
//  LiquidUtilities
//
//  HTML escaping utilities for security
//

import Foundation

/// HTML escaping utilities for XSS protection
public enum HTMLEscape {
    
    /// Characters that need to be escaped in HTML
    private static let escapeMap: [Character: String] = [
        "&": "&amp;",
        "<": "&lt;",
        ">": "&gt;",
        "\"": "&quot;",
        "'": "&#39;"
    ]
    
    /// Escapes a string for safe HTML output
    ///
    /// - Parameter string: The string to escape
    /// - Returns: The HTML-escaped string
    public static func escape(_ string: String) -> String {
        var escaped = ""
        escaped.reserveCapacity(string.count * 2) // Pre-allocate for performance
        
        for char in string {
            if let replacement = escapeMap[char] {
                escaped.append(replacement)
            } else {
                escaped.append(char)
            }
        }
        
        return escaped
    }
    
    /// Escapes a string only once - doesn't double-escape already escaped entities
    ///
    /// This is more complex than regular escaping as it needs to detect existing 
    /// HTML entities and only escape unescaped dangerous characters.
    ///
    /// - Parameter string: The string to escape
    /// - Returns: The HTML-escaped string with no double-escaping
    public static func escapeOnce(_ string: String) -> String {
        // Strategy: Parse the string and identify existing entities, then escape only raw characters
        var result = ""
        result.reserveCapacity(string.count * 2)
        
        var index = string.startIndex
        
        while index < string.endIndex {
            let char = string[index]
            
            // Check if this is the start of an HTML entity
            if char == "&" {
                // Look ahead to see if this is a valid entity
                if let entityEnd = findEntityEnd(in: string, from: index) {
                    // This is an existing entity - keep it as-is
                    result.append(String(string[index..<entityEnd]))
                    index = entityEnd
                    continue
                } else {
                    // This is a bare & that needs escaping
                    result.append("&amp;")
                    index = string.index(after: index)
                    continue
                }
            }
            
            // Check for characters that need escaping (excluding &)
            if let replacement = escapeMapExceptAmpersand[char] {
                result.append(replacement)
            } else {
                result.append(char)
            }
            
            index = string.index(after: index)
        }
        
        return result
    }
    
    /// Escape map without the ampersand (used by escapeOnce)
    private static let escapeMapExceptAmpersand: [Character: String] = [
        "<": "&lt;",
        ">": "&gt;",
        "\"": "&quot;",
        "'": "&#39;"
    ]
    
    /// Finds the end of an HTML entity starting at the given index
    ///
    /// - Parameters:
    ///   - string: The string to search in
    ///   - startIndex: The index of the '&' character
    /// - Returns: The index after the entity if valid, nil if not a valid entity
    private static func findEntityEnd(in string: String, from startIndex: String.Index) -> String.Index? {
        guard string[startIndex] == "&" else { return nil }
        
        var index = string.index(after: startIndex)
        var entityContent = ""
        
        // Look for the semicolon, with reasonable length limit
        while index < string.endIndex && entityContent.count < 20 {
            let char = string[index]
            
            if char == ";" {
                // Found potential entity end - validate the content
                if isValidHTMLEntity(entityContent) {
                    return string.index(after: index) // Return position after semicolon
                } else {
                    return nil // Not a valid entity
                }
            }
            
            // Only allow alphanumeric characters and # for entities
            if char.isLetter || char.isNumber || char == "#" {
                entityContent.append(char)
                index = string.index(after: index)
            } else {
                // Invalid character in entity - this isn't an entity
                return nil
            }
        }
        
        // Reached end of string or length limit without finding semicolon
        return nil
    }
    
    /// Validates if a string is a valid HTML entity name
    ///
    /// - Parameter entity: The entity content (without & and ;)
    /// - Returns: true if this is a recognized HTML entity
    private static func isValidHTMLEntity(_ entity: String) -> Bool {
        // Check numeric entities
        if entity.hasPrefix("#") {
            let numberPart = String(entity.dropFirst())
            
            if numberPart.hasPrefix("x") || numberPart.hasPrefix("X") {
                // Hexadecimal entity like &#xFF;
                let hexPart = String(numberPart.dropFirst())
                return !hexPart.isEmpty && hexPart.allSatisfy { $0.isHexDigit }
            } else {
                // Decimal entity like &#123;
                return !numberPart.isEmpty && numberPart.allSatisfy { $0.isNumber }
            }
        }
        
        // Check named entities
        return knownHTMLEntities.contains(entity.lowercased())
    }
    
    /// Set of known HTML entity names (most common ones)
    private static let knownHTMLEntities: Set<String> = [
        // Basic entities
        "amp", "lt", "gt", "quot", "apos",
        
        // Common named entities  
        "nbsp", "copy", "reg", "trade", "hellip", "mdash", "ndash",
        "lsquo", "rsquo", "ldquo", "rdquo", "bull", "middot",
        "laquo", "raquo", "iexcl", "iquest", "sect", "para",
        "micro", "plusmn", "sup2", "sup3", "frac14", "frac12", "frac34",
        "times", "divide", "cent", "pound", "yen", "euro",
        "alpha", "beta", "gamma", "delta", "epsilon", "pi", "sigma",
        "hearts", "diams", "clubs", "spades",
        "larr", "uarr", "rarr", "darr", "harr",
        
        // Additional common entities
        "acute", "cedil", "circ", "macr", "ring", "tilde", "uml",
        "ensp", "emsp", "thinsp", "zwnj", "zwj", "lrm", "rlm",
        "shy", "deg", "ordm", "ordf"
    ]
    
    /// Escapes a string for safe HTML attribute output
    ///
    /// This is more aggressive than regular HTML escaping and also escapes
    /// characters that could break out of attributes.
    ///
    /// - Parameter string: The string to escape
    /// - Returns: The attribute-escaped string
    public static func escapeAttribute(_ string: String) -> String {
        var escaped = ""
        escaped.reserveCapacity(string.count * 2)
        
        for char in string {
            switch char {
            case "&":
                escaped.append("&amp;")
            case "<":
                escaped.append("&lt;")
            case ">":
                escaped.append("&gt;")
            case "\"":
                escaped.append("&quot;")
            case "'":
                escaped.append("&#39;")
            case "/":
                escaped.append("&#47;")
            case "=":
                escaped.append("&#61;")
            case "`":
                escaped.append("&#96;")
            case "\n":
                escaped.append("&#10;")
            case "\r":
                escaped.append("&#13;")
            case "\t":
                escaped.append("&#9;")
            default:
                // Escape non-ASCII characters as well for safety
                if char.isASCII {
                    escaped.append(char)
                } else {
                    let scalar = String(char).unicodeScalars.first!
                    escaped.append("&#\(scalar.value);")
                }
            }
        }
        
        return escaped
    }
    
    /// Escapes a string for safe JavaScript string literal output
    ///
    /// - Parameter string: The string to escape
    /// - Returns: The JavaScript-escaped string
    public static func escapeJavaScript(_ string: String) -> String {
        var escaped = ""
        escaped.reserveCapacity(string.count * 2)
        
        for char in string {
            switch char {
            case "\\":
                escaped.append("\\\\")
            case "\"":
                escaped.append("\\\"")
            case "'":
                escaped.append("\\'")
            case "\n":
                escaped.append("\\n")
            case "\r":
                escaped.append("\\r")
            case "\t":
                escaped.append("\\t")
            case "\u{2028}": // Line separator
                escaped.append("\\u2028")
            case "\u{2029}": // Paragraph separator
                escaped.append("\\u2029")
            case "<":
                // Escape < to prevent </script> injection
                escaped.append("\\u003C")
            case ">":
                escaped.append("\\u003E")
            case "/":
                escaped.append("\\/")
            default:
                escaped.append(char)
            }
        }
        
        return escaped
    }
    
    /// Escapes a string for safe URL parameter output
    ///
    /// - Parameter string: The string to escape
    /// - Returns: The URL-encoded string
    public static func escapeURL(_ string: String) -> String {
        return string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? string
    }
    
    /// Checks if a string contains potentially dangerous HTML
    ///
    /// - Parameter string: The string to check
    /// - Returns: true if the string contains dangerous patterns
    public static func containsDangerousHTML(_ string: String) -> Bool {
        let dangerousPatterns = [
            "<script",
            "</script",
            "javascript:",
            "onerror=",
            "onload=",
            "onclick=",
            "onmouseover=",
            "<iframe",
            "<object",
            "<embed",
            "<link",
            "<meta",
            "vbscript:",
            "data:text/html"
        ]
        
        let lowercased = string.lowercased()
        for pattern in dangerousPatterns {
            if lowercased.contains(pattern) {
                return true
            }
        }
        
        return false
    }
}

/// Protocol for types that can be HTML-escaped
public protocol HTMLEscapable {
    /// Returns an HTML-escaped version of this value
    var htmlEscaped: String { get }
}

extension String: HTMLEscapable {
    public var htmlEscaped: String {
        return HTMLEscape.escape(self)
    }
}

extension Substring: HTMLEscapable {
    public var htmlEscaped: String {
        return HTMLEscape.escape(String(self))
    }
}

/// Marks a string as safe HTML that should not be escaped
public struct SafeHTML: Sendable {
    public let value: String
    
    public init(_ value: String) {
        self.value = value
    }
    
    public init(unsafe value: String) {
        // In production, you might want to validate or sanitize here
        self.value = value
    }
}