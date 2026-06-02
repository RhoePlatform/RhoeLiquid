//
//  StringFilters.swift
//  LiquidFilters
//
//  Built-in string manipulation filters
//

import Foundation
import LiquidCore

// MARK: - String Filters

/// Truncates a string to a specified length
public struct TruncateFilter: CustomFilter {
    public let name = "truncate"
    
    public init() {}
    
    public func apply(to value: Any, arguments: [Any], namedArguments: [String: Any]) async throws -> Any {
        let str = String(describing: value)
        let length = (arguments.first as? Int) ?? 50
        let ending = (arguments.dropFirst().first as? String) ?? "..."
        
        guard length > 0 else { return "" }
        
        if str.count <= length {
            return str
        }
        
        let truncateLength = max(0, length - ending.count)
        let truncated = String(str.prefix(truncateLength))
        return truncated + ending
    }
}

/// Truncates a string to a specified number of words
public struct TruncateWordsFilter: CustomFilter {
    public let name = "truncatewords"
    
    public init() {}
    
    public func apply(to value: Any, arguments: [Any], namedArguments: [String: Any]) async throws -> Any {
        let str = String(describing: value)
        let wordCount = (arguments.first as? Int) ?? 15
        let ending = (arguments.dropFirst().first as? String) ?? "..."
        
        guard wordCount > 0 else { return "" }
        
        let words = str.split(separator: " ", omittingEmptySubsequences: true)
        
        if words.count <= wordCount {
            return str
        }
        
        let truncated = words.prefix(wordCount).joined(separator: " ")
        return truncated + ending
    }
}

// Note: StripHTMLFilter is already defined in XMLFilters.swift

/// Removes newlines from a string
public struct StripNewlinesFilter: CustomFilter {
    public let name = "strip_newlines"
    
    public init() {}
    
    public func apply(to value: Any, arguments: [Any], namedArguments: [String: Any]) async throws -> Any {
        let str = String(describing: value)
        return str.replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
    }
}

/// Converts newlines to HTML <br> tags
public struct NewlineToBrFilter: CustomFilter {
    public let name = "newline_to_br"
    
    public init() {}
    
    public func apply(to value: Any, arguments: [Any], namedArguments: [String: Any]) async throws -> Any {
        let str = String(describing: value)
        return str.replacingOccurrences(of: "\n", with: "<br>\n")
    }
}

/// Creates a URL-safe slug from a string
public struct SlugifyFilter: CustomFilter {
    public let name = "slugify"
    
    public init() {}
    
    public func apply(to value: Any, arguments: [Any], namedArguments: [String: Any]) async throws -> Any {
        let str = String(describing: value)
        
        // Convert to lowercase
        var slug = str.lowercased()
        
        // Replace spaces with hyphens
        slug = slug.replacingOccurrences(of: " ", with: "-")
        
        // Remove non-alphanumeric characters (except hyphens)
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
        slug = slug.unicodeScalars
            .filter { allowed.contains($0) }
            .map { String($0) }
            .joined()
        
        // Remove multiple consecutive hyphens
        while slug.contains("--") {
            slug = slug.replacingOccurrences(of: "--", with: "-")
        }
        
        // Trim hyphens from start and end
        slug = slug.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        
        return slug
    }
}

/// Escapes a string for use in URLs
public struct URLEncodeFilter: CustomFilter {
    public let name = "url_encode"
    
    public init() {}
    
    public func apply(to value: Any, arguments: [Any], namedArguments: [String: Any]) async throws -> Any {
        let str = String(describing: value)
        return str.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? str
    }
}

/// Decodes a URL-encoded string
public struct URLDecodeFilter: CustomFilter {
    public let name = "url_decode"
    
    public init() {}
    
    public func apply(to value: Any, arguments: [Any], namedArguments: [String: Any]) async throws -> Any {
        let str = String(describing: value)
        return str.removingPercentEncoding ?? str
    }
}

/// Base64 encodes a string
public struct Base64EncodeFilter: CustomFilter {
    public let name = "base64_encode"
    
    public init() {}
    
    public func apply(to value: Any, arguments: [Any], namedArguments: [String: Any]) async throws -> Any {
        let str = String(describing: value)
        guard let data = str.data(using: .utf8) else { return str }
        return data.base64EncodedString()
    }
}

/// Base64 decodes a string
public struct Base64DecodeFilter: CustomFilter {
    public let name = "base64_decode"

    public init() {}

    public func apply(to value: Any, arguments: [Any], namedArguments: [String: Any]) async throws -> Any {
        if value is NSNull { return "" }
        guard let str = value as? String else {
            throw NSError(domain: "LiquidFilter", code: 1, userInfo: [NSLocalizedDescriptionKey: "\(name): expected string, got \(type(of: value))"])
        }
        guard let data = Data(base64Encoded: str),
              let decoded = String(data: data, encoding: .utf8) else { return str }
        return decoded
    }
}

/// Left strip - removes leading whitespace
public struct LStripFilter: CustomFilter {
    public let name = "lstrip"
    
    public init() {}
    
    public func apply(to value: Any, arguments: [Any], namedArguments: [String: Any]) async throws -> Any {
        let str = String(describing: value)
        return str.replacingOccurrences(of: "^\\s+", with: "", options: .regularExpression)
    }
}

/// Right strip - removes trailing whitespace
public struct RStripFilter: CustomFilter {
    public let name = "rstrip"
    
    public init() {}
    
    public func apply(to value: Any, arguments: [Any], namedArguments: [String: Any]) async throws -> Any {
        let str = String(describing: value)
        return str.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression)
    }
}

/// Removes a substring from a string
public struct RemoveFilter: CustomFilter {
    public let name = "remove"
    
    public init() {}
    
    public func apply(to value: Any, arguments: [Any], namedArguments: [String: Any]) async throws -> Any {
        let str = String(describing: value)
        guard let substring = arguments.first else { return str }
        let substringStr = String(describing: substring)
        return str.replacingOccurrences(of: substringStr, with: "")
    }
}

/// Removes the first occurrence of a substring
public struct RemoveFirstFilter: CustomFilter {
    public let name = "remove_first"
    
    public init() {}
    
    public func apply(to value: Any, arguments: [Any], namedArguments: [String: Any]) async throws -> Any {
        let str = String(describing: value)
        guard let substring = arguments.first else { return str }
        let substringStr = String(describing: substring)
        
        if let range = str.range(of: substringStr) {
            return str.replacingCharacters(in: range, with: "")
        }
        return str
    }
}

/// Replaces occurrences of a string with another
public struct ReplaceFilter: CustomFilter {
    public let name = "replace"
    
    public init() {}
    
    public func apply(to value: Any, arguments: [Any], namedArguments: [String: Any]) async throws -> Any {
        let str = String(describing: value)
        guard arguments.count >= 2 else { return str }
        
        let search = String(describing: arguments[0])
        let replacement = String(describing: arguments[1])
        
        return str.replacingOccurrences(of: search, with: replacement)
    }
}

/// Replaces the first occurrence of a string
public struct ReplaceFirstFilter: CustomFilter {
    public let name = "replace_first"
    
    public init() {}
    
    public func apply(to value: Any, arguments: [Any], namedArguments: [String: Any]) async throws -> Any {
        let str = String(describing: value)
        guard arguments.count >= 2 else { return str }
        
        let search = String(describing: arguments[0])
        let replacement = String(describing: arguments[1])
        
        if let range = str.range(of: search) {
            return str.replacingCharacters(in: range, with: replacement)
        }
        return str
    }
}

/// Removes the last occurrence of a substring
public struct RemoveLastFilter: CustomFilter {
    public let name = "remove_last"

    public init() {}

    public func apply(to value: Any, arguments: [Any], namedArguments: [String: Any]) async throws -> Any {
        if value is NSNull { return "" }
        let str = String(describing: value)
        guard let substring = arguments.first else { return str }
        let substringStr = String(describing: substring)

        if let range = str.range(of: substringStr, options: .backwards) {
            return str.replacingCharacters(in: range, with: "")
        }
        return str
    }
}

/// Replaces the last occurrence of a string
public struct ReplaceLastFilter: CustomFilter {
    public let name = "replace_last"

    public init() {}

    public func apply(to value: Any, arguments: [Any], namedArguments: [String: Any]) async throws -> Any {
        let str = String(describing: value)
        guard arguments.count >= 2 else { return str }

        let search = String(describing: arguments[0])
        let replacement = String(describing: arguments[1])

        if let range = str.range(of: search, options: .backwards) {
            return str.replacingCharacters(in: range, with: replacement)
        }
        return str
    }
}

/// Extracts a substring by index and optional length
public struct SliceFilter: CustomFilter {
    public let name = "slice"

    public init() {}

    public func apply(to value: Any, arguments: [Any], namedArguments: [String: Any]) async throws -> Any {
        let str = String(describing: value)
        guard let firstArg = arguments.first else { return str }
        var offset = Int(String(describing: firstArg)) ?? 0
        let length = arguments.count > 1 ? (Int(String(describing: arguments[1])) ?? 1) : 1

        // Handle negative offsets
        if offset < 0 {
            offset = str.count + offset
        }

        guard offset >= 0, offset < str.count else { return "" }

        let startIndex = str.index(str.startIndex, offsetBy: offset)
        let endOffset = min(offset + length, str.count)
        let endIndex = str.index(str.startIndex, offsetBy: endOffset)

        return String(str[startIndex ..< endIndex])
    }
}

/// Returns the remainder of dividing a number
public struct ModuloFilter: CustomFilter {
    public let name = "modulo"

    public init() {}

    public func apply(to value: Any, arguments: [Any], namedArguments: [String: Any]) async throws -> Any {
        guard let divisor = arguments.first else { return value }
        let num = Double(String(describing: value)) ?? 0
        let div = Double(String(describing: divisor)) ?? 1
        guard div != 0 else { return 0 }
        return num.truncatingRemainder(dividingBy: div)
    }
}

/// Sorts array items case-insensitively
public struct SortNaturalFilter: CustomFilter {
    public let name = "sort_natural"

    public init() {}

    public func apply(to value: Any, arguments: [Any], namedArguments: [String: Any]) async throws -> Any {
        guard let array = value as? [Any] else { return value }

        if let property = arguments.first as? String {
            // Sort by property, case-insensitive
            return array.sorted { a, b in
                let aDict = a as? [String: Any]
                let bDict = b as? [String: Any]
                let aVal = String(describing: aDict?[property] ?? "").lowercased()
                let bVal = String(describing: bDict?[property] ?? "").lowercased()
                return aVal < bVal
            }
        }

        // Sort values directly, case-insensitive
        return array.sorted { a, b in
            String(describing: a).lowercased() < String(describing: b).lowercased()
        }
    }
}