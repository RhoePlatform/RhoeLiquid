//
//  MathFilters.swift
//  LiquidFilters
//
//  Built-in mathematical filters
//

import Foundation
import LiquidCore

// MARK: - Math Filters

/// Returns the absolute value of a number
public struct AbsFilter: CustomFilter {
    public let name = "abs"
    
    public init() {}
    
    public func apply(to value: Any, arguments: [Any], namedArguments: [String: Any]) async throws -> Any {
        if let int = value as? Int {
            return abs(int)
        } else if let double = value as? Double {
            return abs(double)
        } else if let str = value as? String, let double = Double(str) {
            return abs(double)
        }
        return 0
    }
}

/// Ensures a number is at least a minimum value
public struct AtLeastFilter: CustomFilter {
    public let name = "at_least"
    
    public init() {}
    
    public func apply(to value: Any, arguments: [Any], namedArguments: [String: Any]) async throws -> Any {
        guard let minimum = arguments.first else { return value }
        
        let num = toDouble(value) ?? 0
        let min = toDouble(minimum) ?? 0
        
        return max(num, min)
    }
    
    private func toDouble(_ value: Any) -> Double? {
        if let double = value as? Double { return double }
        if let int = value as? Int { return Double(int) }
        if let str = value as? String { return Double(str) }
        return nil
    }
}

/// Ensures a number is at most a maximum value
public struct AtMostFilter: CustomFilter {
    public let name = "at_most"
    
    public init() {}
    
    public func apply(to value: Any, arguments: [Any], namedArguments: [String: Any]) async throws -> Any {
        guard let maximum = arguments.first else { return value }
        
        let num = toDouble(value) ?? 0
        let max = toDouble(maximum) ?? 0
        
        return min(num, max)
    }
    
    private func toDouble(_ value: Any) -> Double? {
        if let double = value as? Double { return double }
        if let int = value as? Int { return Double(int) }
        if let str = value as? String { return Double(str) }
        return nil
    }
}

/// Clamps a number between minimum and maximum values
public struct ClampFilter: CustomFilter {
    public let name = "clamp"
    
    public init() {}
    
    public func apply(to value: Any, arguments: [Any], namedArguments: [String: Any]) async throws -> Any {
        guard arguments.count >= 2 else { return value }
        
        let num = toDouble(value) ?? 0
        let minimum = toDouble(arguments[0]) ?? 0
        let maximum = toDouble(arguments[1]) ?? 0
        
        return max(minimum, min(num, maximum))
    }
    
    private func toDouble(_ value: Any) -> Double? {
        if let double = value as? Double { return double }
        if let int = value as? Int { return Double(int) }
        if let str = value as? String { return Double(str) }
        return nil
    }
}

// MARK: - Date Filters

/// Formats a date according to a format string
public struct DateFilter: CustomFilter {
    public let name = "date"
    
    public init() {}
    
    public func apply(to value: Any, arguments: [Any], namedArguments: [String: Any]) async throws -> Any {
        let format = (arguments.first as? String) ?? "%Y-%m-%d %H:%M:%S"
        
        let date: Date
        if let d = value as? Date {
            date = d
        } else if value is String && (value as! String).lowercased() == "now" {
            date = Date()
        } else if let timestamp = toDouble(value) {
            date = Date(timeIntervalSince1970: timestamp)
        } else {
            return value
        }
        
        // Convert strftime format to DateFormatter format
        let dateFormat = convertStrftimeToDateFormat(format)
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        return formatter.string(from: date)
    }
    
    private func toDouble(_ value: Any) -> Double? {
        if let double = value as? Double { return double }
        if let int = value as? Int { return Double(int) }
        if let str = value as? String { return Double(str) }
        return nil
    }
    
    private func convertStrftimeToDateFormat(_ format: String) -> String {
        var result = format
        
        // Common strftime to DateFormatter conversions
        let conversions = [
            ("%Y", "yyyy"),    // 4-digit year
            ("%y", "yy"),      // 2-digit year
            ("%m", "MM"),      // Month (01-12)
            ("%B", "MMMM"),    // Full month name
            ("%b", "MMM"),     // Abbreviated month name
            ("%d", "dd"),      // Day of month (01-31)
            ("%e", "d"),       // Day of month (1-31)
            ("%H", "HH"),      // Hour (00-23)
            ("%I", "hh"),      // Hour (01-12)
            ("%M", "mm"),      // Minute (00-59)
            ("%S", "ss"),      // Second (00-59)
            ("%p", "a"),       // AM/PM
            ("%A", "EEEE"),    // Full weekday name
            ("%a", "EEE"),     // Abbreviated weekday name
            ("%Z", "zzz"),     // Time zone
            ("%%", "%")        // Literal %
        ]
        
        for (strftime, dateFormat) in conversions {
            result = result.replacingOccurrences(of: strftime, with: dateFormat)
        }
        
        return result
    }
}

/// Converts a date to a string
public struct DateToStringFilter: CustomFilter {
    public let name = "date_to_string"
    
    public init() {}
    
    public func apply(to value: Any, arguments: [Any], namedArguments: [String: Any]) async throws -> Any {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "en_US")
        
        if let date = value as? Date {
            return formatter.string(from: date)
        } else if let timestamp = toDouble(value) {
            let date = Date(timeIntervalSince1970: timestamp)
            return formatter.string(from: date)
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

/// Converts a date to RFC822 format
public struct DateToRFC822Filter: CustomFilter {
    public let name = "date_to_rfc822"
    
    public init() {}
    
    public func apply(to value: Any, arguments: [Any], namedArguments: [String: Any]) async throws -> Any {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        if let date = value as? Date {
            return formatter.string(from: date)
        } else if let timestamp = toDouble(value) {
            let date = Date(timeIntervalSince1970: timestamp)
            return formatter.string(from: date)
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

/// Converts a date to ISO8601 format
public struct DateToISO8601Filter: CustomFilter {
    public let name = "date_to_iso8601"
    
    public init() {}
    
    public func apply(to value: Any, arguments: [Any], namedArguments: [String: Any]) async throws -> Any {
        if #available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *) {
            let formatter = ISO8601DateFormatter()
            
            if let date = value as? Date {
                return formatter.string(from: date)
            } else if let timestamp = toDouble(value) {
                let date = Date(timeIntervalSince1970: timestamp)
                return formatter.string(from: date)
            }
        } else {
            // Fallback for older OS versions
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            
            if let date = value as? Date {
                return formatter.string(from: date)
            } else if let timestamp = toDouble(value) {
                let date = Date(timeIntervalSince1970: timestamp)
                return formatter.string(from: date)
            }
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

/// Returns the current date/time
public struct NowFilter: CustomFilter {
    public let name = "now"
    
    public init() {}
    
    public func apply(to value: Any, arguments: [Any], namedArguments: [String: Any]) async throws -> Any {
        return Date()
    }
}