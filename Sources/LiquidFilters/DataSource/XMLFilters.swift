//
//  XMLFilters.swift
//  LiquidFilters
//
//  XML/HTML manipulation filters for RhoeLiquid
//

import Foundation
import LiquidCore

// MARK: - Select Filter

/// Select elements using CSS selectors (for HTML)
///
/// Usage:
/// {{ html | select: "div.content" }}
/// {{ html | select: "#main-content > p" }}
public struct SelectFilter: CustomFilter {
    public let name = "select"
    
    public init() {}
    
    public func apply(
        to value: Any,
        arguments: [Any],
        namedArguments: [String: Any]
    ) async throws -> Any {
        guard let selector = arguments.first as? String else {
            return NSNull()
        }
        
        guard let dataValue = convertToDataValue(value) else {
            return NSNull()
        }

        let selected = dataValue.select(selector)
        return selected == .null ? NSNull() : selected.liquidValue
    }

    func selectElements(from value: DataValue, selector: String) -> [DataValue] {
        CSSSelector(selector: selector).selectAll(in: value)
    }
}

// MARK: - Select All Filter

/// Select all elements matching CSS selector
///
/// Usage:
/// {{ html | select_all: "p" }}
/// {{ html | select_all: ".product-item" }}
public struct SelectAllFilter: CustomFilter {
    public let name = "select_all"
    
    public init() {}
    
    public func apply(
        to value: Any,
        arguments: [Any],
        namedArguments: [String: Any]
    ) async throws -> Any {
        guard let selector = arguments.first as? String else {
            return []
        }
        
        guard let dataValue = convertToDataValue(value) else {
            return []
        }

        return dataValue.selectAll(selector).liquidValue
    }
}

// MARK: - XPath Filter

/// Query XML using XPath expressions
///
/// Usage:
/// {{ xml | xpath: "//book[@category='fiction']" }}
/// {{ xml | xpath: "/catalog/book[price>10]" }}
public struct XPathFilter: CustomFilter {
    public let name = "xpath"
    
    public init() {}
    
    public func apply(
        to value: Any,
        arguments: [Any],
        namedArguments: [String: Any]
    ) async throws -> Any {
        guard let expression = arguments.first as? String else {
            return []
        }
        
        guard let dataValue = convertToDataValue(value) else {
            return []
        }

        return dataValue.xpath(expression).liquidValue
    }
}

// MARK: - Text Content Filter

/// Extract text content from elements
///
/// Usage:
/// {{ element | text }}
/// {{ html | select: "h1" | text }}
public struct TextContentFilter: CustomFilter {
    public let name = "text"
    
    public init() {}
    
    public func apply(
        to value: Any,
        arguments: [Any],
        namedArguments: [String: Any]
    ) async throws -> Any {
        guard let dataValue = convertToDataValue(value) else {
            return ""
        }
        
        return extractText(from: dataValue)
    }
    
    private func extractText(from value: DataValue) -> String {
        switch value {
        case .string(let str):
            return str
            
        case .object(let obj):
            // Check for text content
            if let text = obj["@text"] ?? obj["#text"] ?? obj["text"] ?? obj["@full_text"] {
                return text.stringValue
            }
            
            // Recursively extract from children
            var texts: [String] = []
            for (key, child) in obj {
                if !key.hasPrefix("@") && key != "@name" {
                    let childText = extractText(from: child)
                    if !childText.isEmpty {
                        texts.append(childText)
                    }
                }
            }
            return texts.joined(separator: " ")
            
        case .array(let array):
            return array.map { extractText(from: $0) }.joined(separator: " ")
            
        default:
            return value.stringValue
        }
    }
}

// MARK: - Attribute Filter

/// Get attribute value from element
///
/// Usage:
/// {{ element | attr: "href" }}
/// {{ element | attr: "class" }}
public struct AttributeFilter: CustomFilter {
    public let name = "attr"
    
    public init() {}
    
    public func apply(
        to value: Any,
        arguments: [Any],
        namedArguments: [String: Any]
    ) async throws -> Any {
        guard let attrName = arguments.first as? String else {
            return NSNull()
        }
        
        guard let dataValue = convertToDataValue(value) else {
            return NSNull()
        }
        
        return dataValue.attribute(attrName)?.liquidValue ?? NSNull()
    }
}

// MARK: - Inner HTML Filter

/// Get inner HTML content
///
/// Usage:
/// {{ element | inner_html }}
public struct InnerHTMLFilter: CustomFilter {
    public let name = "inner_html"
    
    public init() {}
    
    public func apply(
        to value: Any,
        arguments: [Any],
        namedArguments: [String: Any]
    ) async throws -> Any {
        guard let dataValue = convertToDataValue(value) else {
            return ""
        }
        
        // This would reconstruct HTML from the DataValue
        // For now, return a simplified version
        return reconstructHTML(from: dataValue, includeRoot: false)
    }
    
    private func reconstructHTML(from value: DataValue, includeRoot: Bool) -> String {
        switch value {
        case .string(let str):
            return str
            
        case .object(let obj):
            guard let name = obj["@name"], case .string(let tagName) = name else {
                return ""
            }
            
            var html = ""
            
            if includeRoot {
                html += "<\(tagName)"
                
                // Add attributes
                if let attrs = obj["@attributes"], case .object(let attributes) = attrs {
                    for (key, value) in attributes {
                        if case .string(let attrValue) = value {
                            html += " \(key)=\"\(attrValue.replacingOccurrences(of: "\"", with: "&quot;"))\""
                        }
                    }
                }
                
                html += ">"
            }
            
            // Add content
            for (key, child) in obj {
                if !key.hasPrefix("@") {
                    html += reconstructHTML(from: child, includeRoot: true)
                }
            }
            
            if includeRoot {
                html += "</\(tagName)>"
            }
            
            return html
            
        case .array(let array):
            return array.map { reconstructHTML(from: $0, includeRoot: true) }.joined()
            
        default:
            return value.stringValue
        }
    }
}

// MARK: - Strip HTML Filter

/// Remove HTML tags from content
///
/// Usage:
/// {{ content | strip_html }}
public struct StripHTMLFilter: CustomFilter {
    public let name = "strip_html"
    
    public init() {}
    
    public func apply(
        to value: Any,
        arguments: [Any],
        namedArguments: [String: Any]
    ) async throws -> Any {
        let text = String(describing: value)
        
        // Simple regex to remove HTML tags
        let pattern = "<[^>]+>"
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: text.utf16.count)
        let stripped = regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
        
        // Decode HTML entities
        return stripped
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ")
    }
}

// MARK: - Tag Name Filter

/// Get element tag name
///
/// Usage:
/// {{ element | tag_name }}
public struct TagNameFilter: CustomFilter {
    public let name = "tag_name"
    
    public init() {}
    
    public func apply(
        to value: Any,
        arguments: [Any],
        namedArguments: [String: Any]
    ) async throws -> Any {
        guard let dataValue = convertToDataValue(value) else {
            return ""
        }
        
        if case .object(let obj) = dataValue,
           let name = obj["@name"],
           case .string(let tagName) = name {
            return tagName
        }
        
        return ""
    }
}

// MARK: - Children Filter

/// Get child elements
///
/// Usage:
/// {{ element | children }}
/// {{ element | children: "div" }}  // Only div children
public struct ChildrenFilter: CustomFilter {
    public let name = "children"
    
    public init() {}
    
    public func apply(
        to value: Any,
        arguments: [Any],
        namedArguments: [String: Any]
    ) async throws -> Any {
        guard let dataValue = convertToDataValue(value) else {
            return []
        }
        
        let tagFilter = arguments.first as? String
        var children = dataValue.childElements
        
        // Filter by tag name if specified
        if let filter = tagFilter {
            children = children.filter { child in
                if case .object(let obj) = child,
                   let name = obj["@name"],
                   case .string(let tagName) = name {
                    return tagName.lowercased() == filter.lowercased()
                }
                return false
            }
        }
        
        return children.map { $0.liquidValue }
    }
}

// MARK: - Helper Functions

private func convertToDataValue(_ value: Any) -> DataValue? {
    if let dataValue = value as? DataValue {
        return dataValue
    }
    
    // Try to convert from Liquid value
    return DataValue(from: value)
}
