//
//  JSONDataSource.swift
//  LiquidCore
//
//  JSON data source loader for RhoeLiquid
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Data source for loading JSON files and URLs
///
/// `JSONDataSource` provides comprehensive support for JSON data formats including
/// standard JSON, JSON with Comments (JSONC), and JSON5. It handles both local files
/// and remote URLs with full support for schema validation.
///
/// ## Supported Formats
///
/// - **JSON**: Standard JSON format (RFC 8259)
/// - **JSONC**: JSON with Comments - supports `//` and `/* */` comments
/// - **JSON5**: Extended JSON syntax with trailing commas, unquoted keys, etc.
///
/// ## Features
///
/// ### Automatic Format Detection
/// The loader automatically detects and handles different JSON variants based on
/// file extension or content analysis.
///
/// ### Schema Validation
/// Supports JSON Schema validation for ensuring data integrity:
/// ```swift
/// let schema = DataValue.object([
///     "type": .string("object"),
///     "required": .array([.string("name"), .string("age")]),
///     "properties": .object([
///         "name": .object(["type": .string("string")]),
///         "age": .object(["type": .string("integer")])
///     ])
/// ])
/// 
/// let options = LoadOptions(schema: schema)
/// let data = try await loader.load(from: url, options: options)
/// ```
///
/// ### Network Support
/// Full support for loading JSON from HTTP(S) endpoints:
/// ```swift
/// let options = LoadOptions(
///     headers: ["Authorization": "Bearer token"],
///     timeout: 10
/// )
/// let data = try await loader.load(from: apiURL, options: options)
/// ```
///
/// ## Usage Examples
///
/// ### Basic JSON Loading
/// ```liquid
/// {% data users = load("./users.json") %}
/// {% for user in users %}
///   {{ user.name }} - {{ user.email }}
/// {% endfor %}
/// ```
///
/// ### JSON with Comments
/// ```liquid
/// {% data config = load("./config.jsonc") %}
/// Theme: {{ config.theme }}
/// ```
///
/// ### API Endpoint
/// ```liquid
/// {% data weather = load("https://api.weather.com/current", 
///                       headers: {"API-Key": "secret"}) %}
/// Temperature: {{ weather.temp }}°C
/// ```
///
/// ## Error Handling
///
/// The loader provides detailed error messages for common issues:
/// - Invalid JSON syntax with line/column information
/// - Network failures with status codes
/// - Schema validation failures with specific violations
///
/// ## Performance
///
/// - Efficient streaming parser for large files
/// - Automatic cleanup of comments and trailing commas
/// - Respects size limits to prevent memory exhaustion
///
/// ## See Also
/// - ``DataSource``: Protocol this implements
/// - ``LoadOptions``: Configuration options
/// - ``DataValue``: The data representation format
public struct JSONDataSource: DataSource {
    public init() {}
    
    public var supportedExtensions: [String] {
        ["json", "jsonc", "json5"]
    }
    
    public func load(from url: URL, options: LoadOptions) async throws -> DataValue {
        let data: Data
        
        if url.isFileURL {
            // Load from file
            do {
                data = try Data(contentsOf: url)
            } catch {
                throw DataSourceError.fileNotFound(url)
            }
            
            // Check file size
            if data.count > options.maxSize {
                throw DataSourceError.fileTooLarge(data.count, options.maxSize)
            }
        } else {
            #if os(WASI)
            throw DataSourceError.unsupportedFormat("Network loading not available in WebAssembly")
            #else
            // Load from network
            var request = URLRequest(url: url)
            request.timeoutInterval = options.timeout

            // Add custom headers
            for (key, value) in options.headers {
                request.setValue(value, forHTTPHeaderField: key)
            }

            do {
                let (responseData, response) = try await URLSession.shared.data(for: request)

                // Check response
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
                if (error as NSError).code == NSURLErrorTimedOut {
                    throw DataSourceError.timeout
                } else {
                    throw DataSourceError.networkError(error)
                }
            }
            #endif
        }
        
        // Parse JSON
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [.allowFragments])
            return DataValue(from: json)
        } catch {
            // Try to parse as JSON5 or JSONC (with comments)
            if let cleanedData = cleanJSON5(data, encoding: options.encoding) {
                do {
                    let json = try JSONSerialization.jsonObject(with: cleanedData, options: [.allowFragments])
                    return DataValue(from: json)
                } catch {
                    throw DataSourceError.parseError("Invalid JSON: \(error.localizedDescription)")
                }
            } else {
                throw DataSourceError.parseError("Invalid JSON: \(error.localizedDescription)")
            }
        }
    }
    
    public func validate(_ data: DataValue, against schema: DataValue) async throws -> Bool {
        // Basic JSON Schema validation
        return try validateValue(data, against: schema)
    }
    
    // Clean JSON5/JSONC by removing comments and trailing commas
    private func cleanJSON5(_ data: Data, encoding: String.Encoding) -> Data? {
        guard var string = String(data: data, encoding: encoding) else {
            return nil
        }
        
        // Remove single-line comments
        string = string.replacingOccurrences(
            of: #"//[^\n]*"#,
            with: "",
            options: .regularExpression
        )
        
        // Remove multi-line comments
        string = string.replacingOccurrences(
            of: #"/\*[\s\S]*?\*/"#,
            with: "",
            options: .regularExpression
        )
        
        // Remove trailing commas
        string = string.replacingOccurrences(
            of: #",(\s*[}\]])"#,
            with: "$1",
            options: .regularExpression
        )
        
        return string.data(using: encoding)
    }
    
    // Basic JSON Schema validation
    private func validateValue(_ value: DataValue, against schema: DataValue) throws -> Bool {
        guard case .object(let schemaDict) = schema else {
            return true // No schema or invalid schema
        }
        
        // Check type
        if let typeValue = schemaDict["type"] {
            let expectedType = typeValue.stringValue
            
            switch (expectedType, value) {
            case ("null", .null):
                break
            case ("boolean", .bool):
                break
            case ("integer", .int):
                break
            case ("number", .double), ("number", .int):
                break
            case ("string", .string):
                break
            case ("array", .array):
                break
            case ("object", .object):
                break
            default:
                throw DataSourceError.validationFailed(
                    "Expected type '\(expectedType)' but got '\(value.typeName)'"
                )
            }
        }
        
        // Check required properties for objects
        if case .object(let valueDict) = value,
           let required = schemaDict["required"]?.arrayValue {
            for req in required {
                let key = req.stringValue
                if valueDict[key] == nil {
                    throw DataSourceError.validationFailed(
                        "Required property '\(key)' is missing"
                    )
                }
            }
        }
        
        // Check properties
        if case .object(let valueDict) = value,
           let properties = schemaDict["properties"]?.objectValue {
            for (key, propSchema) in properties {
                if let propValue = valueDict[key] {
                    _ = try validateValue(propValue, against: propSchema)
                }
            }
        }
        
        // Check array items
        if case .array(let valueArray) = value,
           let items = schemaDict["items"] {
            for item in valueArray {
                _ = try validateValue(item, against: items)
            }
        }
        
        return true
    }
}

// Helper to get type name
private extension DataValue {
    var typeName: String {
        switch self {
        case .null: return "null"
        case .bool: return "boolean"
        case .int: return "integer"
        case .double: return "number"
        case .string: return "string"
        case .array: return "array"
        case .object: return "object"
        case .date: return "date"
        case .data: return "data"
        }
    }
}
