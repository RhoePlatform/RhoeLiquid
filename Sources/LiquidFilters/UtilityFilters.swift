//
//  UtilityFilters.swift
//  LiquidFilters
//
//  Built-in utility filters
//

import Foundation
import LiquidCore

// MARK: - Utility Filters

/// Returns a default value if the input is nil or empty
public struct DefaultFilter: CustomFilter {
    public let name = "default"
    
    public init() {}
    
    public func apply(to value: Any, arguments: [Any], namedArguments: [String: Any]) async throws -> Any {
        // Check if value is nil, NSNull, or empty
        if value is NSNull {
            return arguments.first ?? ""
        }
        
        if let str = value as? String, str.isEmpty {
            return arguments.first ?? ""
        }
        
        if let array = value as? [Any], array.isEmpty {
            return arguments.first ?? ""
        }
        
        return value
    }
}

/// Converts a value to JSON
public struct JSONFilter: CustomFilter {
    public let name = "json"
    
    public init() {}
    
    public func apply(to value: Any, arguments: [Any], namedArguments: [String: Any]) async throws -> Any {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: convertToJSONCompatible(value), options: [])
            return String(data: jsonData, encoding: .utf8) ?? ""
        } catch {
            return String(describing: value)
        }
    }
    
    private func convertToJSONCompatible(_ value: Any) -> Any {
        if let array = value as? [Any] {
            return array.map { convertToJSONCompatible($0) }
        } else if let dict = value as? [String: Any] {
            return dict.mapValues { convertToJSONCompatible($0) }
        } else if value is NSNull {
            return NSNull()
        } else if let date = value as? Date {
            return ISO8601DateFormatter().string(from: date)
        } else if let data = value as? Data {
            return data.base64EncodedString()
        } else {
            return value
        }
    }
}

/// Parses a JSON string
public struct ParseJSONFilter: CustomFilter {
    public let name = "parse_json"
    
    public init() {}
    
    public func apply(to value: Any, arguments: [Any], namedArguments: [String: Any]) async throws -> Any {
        guard let jsonString = value as? String,
              let data = jsonString.data(using: .utf8) else { return value }
        
        do {
            return try JSONSerialization.jsonObject(with: data, options: [])
        } catch {
            return value
        }
    }
}

/// Extracts a URL parameter
public struct URLParamFilter: CustomFilter {
    public let name = "url_param"
    
    public init() {}
    
    public func apply(to value: Any, arguments: [Any], namedArguments: [String: Any]) async throws -> Any {
        guard let urlString = value as? String,
              let paramName = arguments.first as? String,
              let url = URL(string: urlString),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return "" }
        
        return components.queryItems?.first(where: { $0.name == paramName })?.value ?? ""
    }
}

/// Inspects a value (for debugging)
public struct InspectFilter: CustomFilter {
    public let name = "inspect"
    
    public init() {}
    
    public func apply(to value: Any, arguments: [Any], namedArguments: [String: Any]) async throws -> Any {
        return String(reflecting: value)
    }
}

/// Returns the type of a value
public struct TypeFilter: CustomFilter {
    public let name = "type"
    
    public init() {}
    
    public func apply(to value: Any, arguments: [Any], namedArguments: [String: Any]) async throws -> Any {
        switch value {
        case is String: return "string"
        case is Int: return "integer"
        case is Double: return "float"
        case is Bool: return "boolean"
        case is [Any]: return "array"
        case is [String: Any]: return "object"
        case is NSNull: return "null"
        case is Date: return "date"
        case is Data: return "data"
        default: return "unknown"
        }
    }
}

/// Generates a random number
public struct RandomFilter: CustomFilter {
    public let name = "random"
    
    public init() {}
    
    public func apply(to value: Any, arguments: [Any], namedArguments: [String: Any]) async throws -> Any {
        if let max = toInt(value), max > 0 {
            return Int.random(in: 0..<max)
        } else if arguments.count >= 2,
                  let min = toInt(arguments[0]),
                  let max = toInt(arguments[1]),
                  min < max {
            return Int.random(in: min..<max)
        }
        
        // Default: random float between 0 and 1
        return Double.random(in: 0..<1)
    }
    
    private func toInt(_ value: Any) -> Int? {
        if let int = value as? Int { return int }
        if let double = value as? Double { return Int(double) }
        if let str = value as? String { return Int(str) }
        return nil
    }
}

/// Creates a range of numbers
public struct RangeFilter: CustomFilter {
    public let name = "range"
    
    public init() {}
    
    public func apply(to value: Any, arguments: [Any], namedArguments: [String: Any]) async throws -> Any {
        if let end = toInt(value) {
            return Array(0..<end)
        } else if let start = toInt(value),
                  let end = toInt(arguments.first) {
            return Array(start..<end)
        }
        
        return []
    }
    
    private func toInt(_ value: Any?) -> Int? {
        guard let value = value else { return nil }
        if let int = value as? Int { return int }
        if let double = value as? Double { return Int(double) }
        if let str = value as? String { return Int(str) }
        return nil
    }
}

/// Formats a number with thousands separators
public struct NumberFormatFilter: CustomFilter {
    public let name = "number_format"
    
    public init() {}
    
    public func apply(to value: Any, arguments: [Any], namedArguments: [String: Any]) async throws -> Any {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_US")
        
        // Get decimal places from arguments
        if let decimalPlaces = arguments.first as? Int {
            formatter.minimumFractionDigits = decimalPlaces
            formatter.maximumFractionDigits = decimalPlaces
        }
        
        if let number = toDouble(value) {
            return formatter.string(from: NSNumber(value: number)) ?? String(number)
        }
        
        return value
    }
    
    private func toDouble(_ value: Any) -> Double? {
        if let double = value as? Double { return double }
        if let int = value as? Int { return Double(int) }
        if let str = value as? String { return Double(str) }
        return nil
    }
}

/// Formats currency
public struct CurrencyFilter: CustomFilter {
    public let name = "currency"
    
    public init() {}
    
    public func apply(to value: Any, arguments: [Any], namedArguments: [String: Any]) async throws -> Any {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        
        // Get currency code from arguments
        if let currencyCode = arguments.first as? String {
            formatter.currencyCode = currencyCode
        } else {
            formatter.locale = Locale(identifier: "en_US")
        }
        
        if let number = toDouble(value) {
            return formatter.string(from: NSNumber(value: number)) ?? "$\(number)"
        }
        
        return value
    }
    
    private func toDouble(_ value: Any) -> Double? {
        if let double = value as? Double { return double }
        if let int = value as? Int { return Double(int) }
        if let str = value as? String { return Double(str) }
        return nil
    }
}