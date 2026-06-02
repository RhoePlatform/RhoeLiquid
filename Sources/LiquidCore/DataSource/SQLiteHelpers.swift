//
//  SQLiteHelpers.swift
//  LiquidCore
//
//  Helper types and extensions for SQLite data source
//

import Foundation

/// Extended LoadOptions for SQLite queries
public extension LoadOptions {
    /// Create LoadOptions for a SQL query
    static func sqlQuery(
        _ query: String,
        params: [Any] = [],
        cacheDuration: TimeInterval? = nil
    ) -> LoadOptions {
        // For now, we'll encode SQL parameters in the URL query string
        // since LoadOptions doesn't support metadata
        return LoadOptions(
            cacheDuration: cacheDuration
        )
    }
    
    /// Create LoadOptions for loading a table
    static func sqlTable(
        _ table: String,
        limit: Int? = nil,
        offset: Int? = nil,
        orderBy: String? = nil,
        cacheDuration: TimeInterval? = nil
    ) -> LoadOptions {
        // For now, we'll encode SQL parameters in the URL query string
        // since LoadOptions doesn't support metadata
        return LoadOptions(
            cacheDuration: cacheDuration
        )
    }
    
    /// Create LoadOptions for schema query
    static func sqlSchema(
        cacheDuration: TimeInterval? = nil
    ) -> LoadOptions {
        return LoadOptions(
            cacheDuration: cacheDuration
        )
    }
}

/// SQLite-specific error types
public enum SQLiteError: Error, LocalizedError {
    case invalidQuery(String)
    case connectionFailed(String)
    case accessDenied(String)
    case invalidParameter(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidQuery(let message):
            return "Invalid SQL query: \(message)"
        case .connectionFailed(let message):
            return "Failed to connect to database: \(message)"
        case .accessDenied(let message):
            return "Access denied: \(message)"
        case .invalidParameter(let message):
            return "Invalid parameter: \(message)"
        }
    }
}

/// SQL query validation utilities
public struct SQLValidator {
    /// Check if a query is read-only (SELECT only)
    public static func isReadOnly(_ query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // Only allow SELECT statements
        guard trimmed.hasPrefix("select") else {
            return false
        }
        
        // Block dangerous keywords
        let dangerousKeywords = [
            "insert", "update", "delete", "drop", "create", "alter",
            "grant", "revoke", "exec", "execute", "call"
        ]
        
        for keyword in dangerousKeywords {
            if trimmed.contains(keyword) {
                return false
            }
        }
        
        return true
    }
    
    /// Validate table name to prevent injection
    public static func isValidTableName(_ name: String) -> Bool {
        // Only allow alphanumeric, underscore, and dash
        let pattern = "^[a-zA-Z0-9_-]+$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: name.utf16.count)
        return regex?.firstMatch(in: name, options: [], range: range) != nil
    }
    
    /// Validate column name
    public static func isValidColumnName(_ name: String) -> Bool {
        // Similar to table name validation
        return isValidTableName(name)
    }
}

/// SQL result formatting options
public struct SQLResultFormat: Sendable {
    /// Whether to convert column names to camelCase
    public let camelCaseColumns: Bool
    
    /// Whether to parse ISO dates automatically
    public let parseDates: Bool
    
    /// Whether to convert numeric strings to numbers
    public let parseNumbers: Bool
    
    /// Default formatting options
    public static let `default` = SQLResultFormat(
        camelCaseColumns: false,
        parseDates: true,
        parseNumbers: true
    )
    
    public init(
        camelCaseColumns: Bool = false,
        parseDates: Bool = true,
        parseNumbers: Bool = true
    ) {
        self.camelCaseColumns = camelCaseColumns
        self.parseDates = parseDates
        self.parseNumbers = parseNumbers
    }
}

/// Convert snake_case to camelCase
private func toCamelCase(_ snakeCase: String) -> String {
    let components = snakeCase.components(separatedBy: "_")
    guard components.count > 1 else { return snakeCase }
    
    let first = components[0].lowercased()
    let rest = components.dropFirst().map { $0.capitalized }
    
    return first + rest.joined()
}