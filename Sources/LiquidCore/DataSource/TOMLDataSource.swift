//
//  TOMLDataSource.swift
//  LiquidCore
//
//  TOML data source loader for RhoeLiquid
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Data source for loading TOML files
///
/// `TOMLDataSource` provides support for TOML (Tom's Obvious, Minimal Language),
/// a configuration file format that's designed to be easy to read and write.
/// It's particularly popular in the Rust ecosystem and modern development tools.
///
/// ## Features
///
/// - **Human-Friendly**: Minimal syntax, maximum readability
/// - **Strongly Typed**: Clear distinction between strings, integers, floats, booleans
/// - **DateTime Support**: First-class support for dates and times
/// - **Table Organization**: Hierarchical data with clear structure
/// - **Comments**: Single-line comments with #
///
/// ## TOML Syntax Examples
///
/// ### Basic Values
/// ```toml
/// # This is a comment
/// title = "TOML Example"
/// 
/// # Strings
/// name = "Tom Preston-Werner"
/// description = """
/// Multi-line
/// string"""
/// 
/// # Numbers
/// integer = 42
/// float = 3.14
/// 
/// # Booleans
/// enabled = true
/// 
/// # Dates and Times
/// date = 2024-01-15
/// time = 2024-01-15T10:30:00Z
/// ```
///
/// ### Tables (Objects)
/// ```toml
/// [server]
/// host = "localhost"
/// port = 8080
/// 
/// [database]
/// server = "192.168.1.1"
/// ports = [8001, 8002, 8003]
/// connection_max = 5000
/// enabled = true
/// ```
///
/// ### Arrays
/// ```toml
/// # Inline arrays
/// colors = ["red", "yellow", "green"]
/// numbers = [1, 2, 3]
/// 
/// # Array of tables
/// [[products]]
/// name = "Hammer"
/// sku = 738594937
/// 
/// [[products]]
/// name = "Nail"
/// sku = 284758393
/// ```
///
/// ## Usage Examples
///
/// ### Configuration File
/// ```liquid
/// {% data config = load("./Cargo.toml") %}
/// 
/// Package: {{ config.package.name }} v{{ config.package.version }}
/// Author: {{ config.package.authors[0] }}
/// 
/// Dependencies:
/// {% for dep in config.dependencies %}
///   - {{ dep[0] }}: {{ dep[1] }}
/// {% endfor %}
/// ```
///
/// ### Site Configuration
/// ```liquid
/// {% data site = load("./config.toml") %}
/// 
/// <title>{{ site.title }}</title>
/// <meta name="description" content="{{ site.description }}">
/// 
/// {% if site.features.comments %}
///   <!-- Comments enabled -->
/// {% endif %}
/// ```
///
/// ### Project Settings
/// ```liquid
/// {% data project = load("./pyproject.toml") %}
/// 
/// Project: {{ project.tool.poetry.name }}
/// Version: {{ project.tool.poetry.version }}
/// Python: {{ project.tool.poetry.dependencies.python }}
/// ```
///
/// ## Advantages over Other Formats
///
/// - **Clearer than YAML**: No ambiguity, no gotchas
/// - **More readable than JSON**: Comments, no quotes for keys
/// - **More structured than INI**: Proper hierarchy, arrays
/// - **Type-safe**: Clear distinction between types
///
/// ## See Also
/// - ``DataSource``: Protocol this implements
/// - ``LoadOptions``: Configuration options
/// - ``DataValue``: The data representation format
public struct TOMLDataSource: DataSource {
    public init() {}
    
    public var supportedExtensions: [String] {
        ["toml"]
    }
    
    public func load(from url: URL, options: LoadOptions) async throws -> DataValue {
        // Load file data
        let data: Data
        if url.isFileURL {
            do {
                data = try Data(contentsOf: url)
            } catch {
                throw DataSourceError.fileNotFound(url)
            }
        } else {
            #if os(WASI)
            throw DataSourceError.unsupportedFormat("Network loading not available in WebAssembly")
            #else
            var request = URLRequest(url: url)
            request.timeoutInterval = options.timeout

            for (key, value) in options.headers {
                request.setValue(value, forHTTPHeaderField: key)
            }

            do {
                let (responseData, response) = try await URLSession.shared.data(for: request)

                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode >= 400 {
                    throw DataSourceError.networkError(
                        NSError(
                            domain: "HTTP",
                            code: httpResponse.statusCode,
                            userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"]
                        )
                    )
                }

                data = responseData
            } catch {
                throw DataSourceError.networkError(error)
            }
            #endif
        }
        
        // Check file size
        if data.count > options.maxSize {
            throw DataSourceError.fileTooLarge(data.count, options.maxSize)
        }
        
        // Convert to string
        guard let tomlString = String(data: data, encoding: options.encoding) else {
            throw DataSourceError.parseError("Unable to decode TOML as \(options.encoding)")
        }
        
        // Parse TOML
        return try parseTOML(tomlString)
    }
    
    private func parseTOML(_ string: String) throws -> DataValue {
        // For a full implementation, we would use a TOML parsing library
        // For now, we'll create a simple parser for basic TOML
        
        var parser = SimpleTOMLParser(string: string)
        return try parser.parse()
    }
}

// MARK: - Simple TOML Parser

/// A basic TOML parser for common use cases
/// Note: This is a simplified implementation. For production use,
/// consider integrating a full TOML parsing library.
private struct SimpleTOMLParser {
    let lines: [String]
    var currentLine = 0
    var currentTable: [String] = []
    var result: [String: DataValue] = [:]
    
    init(string: String) {
        self.lines = string.components(separatedBy: .newlines)
    }
    
    mutating func parse() throws -> DataValue {
        while currentLine < lines.count {
            let line = lines[currentLine].trimmingCharacters(in: .whitespaces)
            currentLine += 1
            
            // Skip empty lines and comments
            if line.isEmpty || line.hasPrefix("#") {
                continue
            }
            
            // Table header
            if line.hasPrefix("[") && line.hasSuffix("]") {
                let tableName = String(line.dropFirst().dropLast())
                currentTable = tableName.split(separator: ".").map(String.init)
                continue
            }
            
            // Key-value pair
            if let equalIndex = line.firstIndex(of: "=") {
                let key = line[..<equalIndex].trimmingCharacters(in: .whitespaces)
                let value = line[line.index(after: equalIndex)...].trimmingCharacters(in: .whitespaces)
                
                let parsedValue = try parseValue(String(value))
                setValue(parsedValue, forKeyPath: currentTable + [key])
            }
        }
        
        return .object(result)
    }
    
    private func parseValue(_ value: String) throws -> DataValue {
        // String
        if value.hasPrefix("\"") && value.hasSuffix("\"") {
            let content = value.dropFirst().dropLast()
            return .string(String(content))
        }
        
        // Boolean
        if value == "true" {
            return .bool(true)
        }
        if value == "false" {
            return .bool(false)
        }
        
        // Integer
        if let int = Int(value) {
            return .int(int)
        }
        
        // Float
        if let double = Double(value) {
            return .double(double)
        }
        
        // Array
        if value.hasPrefix("[") && value.hasSuffix("]") {
            let content = value.dropFirst().dropLast()
            let elements = content.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            let parsedElements = try elements.map { try parseValue(String($0)) }
            return .array(parsedElements)
        }
        
        // Date (simplified - only handle basic date format)
        if value.count == 10 && value.contains("-") {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            if let date = formatter.date(from: value) {
                return .date(date)
            }
        }
        
        // Default to string without quotes
        return .string(value)
    }
    
    private mutating func setValue(_ value: DataValue, forKeyPath keyPath: [String]) {
        guard !keyPath.isEmpty else { return }
        
        if keyPath.count == 1 {
            result[keyPath[0]] = value
        } else {
            // Create nested structure
            var current = result
            
            for i in 0..<keyPath.count - 1 {
                let key = keyPath[i]
                if case .object(let dict) = current[key] {
                    current = dict
                } else {
                    current[key] = .object([:])
                    if case .object(let dict) = current[key] {
                        current = dict
                    }
                }
            }
            
            current[keyPath.last!] = value
        }
    }
}

// MARK: - TOML-specific Filters

/// Convert data to TOML string
///
/// Usage:
/// {{ data | to_toml }}
public struct ToTOMLFilter: CustomFilter {
    public let name = "to_toml"
    
    public init() {}
    
    public func apply(
        to value: Any,
        arguments: [Any],
        namedArguments: [String: Any]
    ) async throws -> Any {
        // Simple TOML serialization
        let dataValue = DataValue(from: value)
        return tomlString(from: dataValue)
    }
    
    private func tomlString(from value: DataValue, prefix: String = "") -> String {
        switch value {
        case .null:
            return "null"
        case .bool(let b):
            return b ? "true" : "false"
        case .int(let i):
            return String(i)
        case .double(let d):
            return String(d)
        case .string(let s):
            return "\"\(s.replacingOccurrences(of: "\"", with: "\\\""))\""
        case .date(let date):
            let formatter = ISO8601DateFormatter()
            return formatter.string(from: date)
        case .data:
            return "# Binary data"
        case .array(let array):
            let elements = array.map { tomlString(from: $0) }.joined(separator: ", ")
            return "[\(elements)]"
        case .object(let dict):
            var result = ""
            for (key, val) in dict.sorted(by: { $0.key < $1.key }) {
                if prefix.isEmpty {
                    result += "\(key) = \(tomlString(from: val))\n"
                } else {
                    result += "\(prefix).\(key) = \(tomlString(from: val))\n"
                }
            }
            return result
        }
    }
}
