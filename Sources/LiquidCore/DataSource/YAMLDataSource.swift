//
//  YAMLDataSource.swift
//  LiquidCore
//
//  YAML data source loader for RhoeLiquid
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if canImport(Yams) && !os(WASI)
import Yams
#endif

/// Data source for loading YAML files
///
/// `YAMLDataSource` provides comprehensive support for YAML (YAML Ain't Markup Language),
/// a human-friendly data serialization format widely used for configuration files,
/// data exchange, and content management.
///
/// ## Features
///
/// - **Full YAML 1.2 Support**: All YAML features including anchors, aliases, and tags
/// - **Human-Friendly**: Designed for readability and ease of editing
/// - **Type Inference**: Automatic detection of strings, numbers, booleans, dates
/// - **Multi-Document**: Support for multiple YAML documents in one file
/// - **Comments**: Preserves context through comments (for documentation)
///
/// ## YAML Features Supported
///
/// ### Basic Types
/// ```yaml
/// string: Hello World
/// number: 42
/// float: 3.14
/// boolean: true
/// null_value: null
/// date: 2024-01-15
/// ```
///
/// ### Collections
/// ```yaml
/// # Arrays
/// fruits:
///   - apple
///   - banana
///   - orange
///
/// # Inline arrays
/// numbers: [1, 2, 3, 4, 5]
///
/// # Objects
/// person:
///   name: John Doe
///   age: 30
///   email: john@example.com
/// ```
///
/// ### Advanced Features
/// ```yaml
/// # Anchors and Aliases
/// defaults: &defaults
///   adapter: postgresql
///   encoding: unicode
///
/// development:
///   <<: *defaults
///   database: myapp_development
///
/// production:
///   <<: *defaults
///   database: myapp_production
///
/// # Multi-line strings
/// description: |
///   This is a multi-line
///   string that preserves
///   line breaks.
///
/// # Folded strings
/// summary: >
///   This is a folded string
///   that will be rendered
///   as a single line.
/// ```
///
/// ## Usage Examples
///
/// ### Configuration Files
/// ```liquid
/// {% data config = load("./config.yml") %}
/// 
/// Database: {{ config.database.host }}:{{ config.database.port }}
/// Environment: {{ config.environment }}
/// ```
///
/// ### Site Data
/// ```liquid
/// {% data site = load("./_data/site.yaml") %}
/// 
/// <h1>{{ site.title }}</h1>
/// <nav>
///   {% for item in site.navigation %}
///     <a href="{{ item.url }}">{{ item.name }}</a>
///   {% endfor %}
/// </nav>
/// ```
///
/// ### Content Collections
/// ```liquid
/// {% data team = load("./team.yml") %}
/// 
/// {% for member in team.members %}
///   <div class="team-member">
///     <h3>{{ member.name }}</h3>
///     <p>{{ member.role }}</p>
///     <p>{{ member.bio }}</p>
///   </div>
/// {% endfor %}
/// ```
///
/// ## Multi-Document Support
///
/// YAML files can contain multiple documents separated by `---`:
/// ```yaml
/// ---
/// title: Document 1
/// ---
/// title: Document 2
/// ```
///
/// Access as array:
/// ```liquid
/// {% data docs = load("./multi.yml") %}
/// {% for doc in docs %}
///   {{ doc.title }}
/// {% endfor %}
/// ```
///
/// ## See Also
/// - ``DataSource``: Protocol this implements
/// - ``LoadOptions``: Configuration options
/// - ``DataValue``: The data representation format
public struct YAMLDataSource: DataSource {
    public init() {}
    
    public var supportedExtensions: [String] {
        ["yml", "yaml"]
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
        guard let yamlString = String(data: data, encoding: options.encoding) else {
            throw DataSourceError.parseError("Unable to decode YAML as \(options.encoding)")
        }
        
        // Parse YAML
        return try parseYAML(yamlString)
    }
    
    private func parseYAML(_ string: String) throws -> DataValue {
        #if canImport(Yams) && !os(WASI)
        do {
            // Try to load all documents
            let documents = Array(try Yams.load_all(yaml: string))
            
            if documents.isEmpty {
                return .null
            } else if documents.count == 1 {
                // Single document - return directly
                return convertToDataValue(documents[0])
            } else {
                // Multiple documents - return as array
                return .array(documents.map { convertToDataValue($0) })
            }
        } catch {
            throw DataSourceError.parseError("Invalid YAML: \(error.localizedDescription)")
        }
        #else
        throw DataSourceError.unsupportedFormat("YAML parsing requires Yams, which is disabled for WebAssembly builds")
        #endif
    }
    
    private func convertToDataValue(_ value: Any?) -> DataValue {
        switch value {
        case nil:
            return .null
        case let bool as Bool:
            return .bool(bool)
        case let int as Int:
            return .int(int)
        case let double as Double:
            return .double(double)
        case let string as String:
            return .string(string)
        case let date as Date:
            return .date(date)
        case let data as Data:
            return .data(data)
        case let array as [Any?]:
            return .array(array.map { convertToDataValue($0) })
        case let dict as [String: Any?]:
            var result: [String: DataValue] = [:]
            for (key, val) in dict {
                result[key] = convertToDataValue(val)
            }
            return .object(result)
        default:
            // Try string representation
            return .string(String(describing: value))
        }
    }
}

// MARK: - YAML-specific Filters

/// Merge YAML documents or objects
///
/// Usage:
/// {{ defaults | yaml_merge: overrides }}
public struct YAMLMergeFilter: CustomFilter {
    public let name = "yaml_merge"
    
    public init() {}
    
    public func apply(
        to value: Any,
        arguments: [Any],
        namedArguments: [String: Any]
    ) async throws -> Any {
        guard let override = arguments.first else {
            return value
        }
        
        // Convert to DataValue for merging
        let baseData = DataValue(from: value)
        let overrideData = DataValue(from: override)
        
        return mergeDataValues(baseData, overrideData).liquidValue
    }
    
    private func mergeDataValues(_ base: DataValue, _ override: DataValue) -> DataValue {
        switch (base, override) {
        case (.object(var baseDict), .object(let overrideDict)):
            // Deep merge objects
            for (key, value) in overrideDict {
                if let existingValue = baseDict[key] {
                    baseDict[key] = mergeDataValues(existingValue, value)
                } else {
                    baseDict[key] = value
                }
            }
            return .object(baseDict)
            
        case (.array(let baseArray), .array(let overrideArray)):
            // Concatenate arrays
            return .array(baseArray + overrideArray)
            
        default:
            // Override wins for non-mergeable types
            return override
        }
    }
}

/// Convert data to YAML string
///
/// Usage:
/// {{ data | to_yaml }}
public struct ToYAMLFilter: CustomFilter {
    public let name = "to_yaml"
    
    public init() {}
    
    public func apply(
        to value: Any,
        arguments: [Any],
        namedArguments: [String: Any]
    ) async throws -> Any {
        #if canImport(Yams) && !os(WASI)
        do {
            let yamlString = try Yams.dump(object: value)
            return yamlString
        } catch {
            return "# Error converting to YAML: \(error)"
        }
        #else
        return "# YAML conversion requires Yams, which is disabled for WebAssembly builds"
        #endif
    }
}
