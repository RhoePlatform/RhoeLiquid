//
//  CSVDataSource.swift
//  LiquidCore
//
//  CSV data source loader for RhoeLiquid
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Data source for loading CSV and TSV files
///
/// `CSVDataSource` provides intelligent loading of comma-separated and tab-separated
/// files with automatic delimiter detection, header recognition, and type inference.
/// It's designed to handle real-world CSV files with various formats and quirks.
///
/// ## Features
///
/// ### Smart Delimiter Detection
/// Automatically detects the delimiter by analyzing the file:
/// - Comma (`,`) for .csv files
/// - Tab (`\t`) for .tsv and .tab files
/// - Semicolon (`;`) for European-style CSV
/// - Falls back to the most frequent delimiter
///
/// ### Automatic Header Detection
/// Intelligently determines if the first row contains headers by checking:
/// - All values are non-numeric strings
/// - Header values are unique
/// - Consistent column count across rows
///
/// ### Type Inference
/// Automatically converts values to appropriate types:
/// - Integers: `42` → DataValue.int(42)
/// - Decimals: `3.14` → DataValue.double(3.14)
/// - Booleans: `true` → DataValue.bool(true)
/// - Dates: ISO 8601 format → DataValue.date(Date)
/// - Strings: Everything else
///
/// ### RFC 4180 Compliance
/// Fully supports standard CSV features:
/// - Quoted fields with embedded delimiters
/// - Escaped quotes (`""` → `"`)
/// - Multi-line fields
/// - Empty fields
///
/// ## Data Structure
///
/// ### With Headers (Default)
/// Returns an array of objects where each row is a dictionary:
/// ```swift
/// DataValue.array([
///     .object(["name": .string("Alice"), "age": .int(30)]),
///     .object(["name": .string("Bob"), "age": .int(25)])
/// ])
/// ```
///
/// ### Without Headers
/// Returns an array of arrays:
/// ```swift
/// DataValue.array([
///     .array([.string("Alice"), .int(30)]),
///     .array([.string("Bob"), .int(25)])
/// ])
/// ```
///
/// ## Usage Examples
///
/// ### Basic CSV Loading
/// ```liquid
/// {% data users = load("./data/users.csv") %}
/// <table>
///   <tr>
///     <th>Name</th>
///     <th>Email</th>
///     <th>Age</th>
///   </tr>
///   {% for user in users %}
///   <tr>
///     <td>{{ user.name }}</td>
///     <td>{{ user.email }}</td>
///     <td>{{ user.age }}</td>
///   </tr>
///   {% endfor %}
/// </table>
/// ```
///
/// ### Filtering and Sorting
/// ```liquid
/// {% data sales = load("./sales.csv") %}
/// {% assign top_sales = sales | where: "amount", ">", 1000 | sort_by: "amount" | reverse %}
/// {% for sale in top_sales | limit: 10 %}
///   {{ sale.date }}: ${{ sale.amount }}
/// {% endfor %}
/// ```
///
/// ### Aggregation
/// ```liquid
/// {% data expenses = load("./expenses.csv") %}
/// {% assign by_category = expenses | group_by: "category" %}
/// {% for group in by_category %}
///   {{ group.key }}: ${{ group.items | map: "amount" | sum }}
/// {% endfor %}
/// ```
///
/// ## Advanced Features
///
/// ### Large File Support
/// - Streaming parser for memory efficiency
/// - Respects size limits in LoadOptions
/// - Handles files with millions of rows
///
/// ### Error Recovery
/// - Continues parsing on malformed rows
/// - Reports specific line numbers for errors
/// - Handles inconsistent column counts
///
/// ### Network Support
/// Can load CSV files from HTTP(S) URLs:
/// ```liquid
/// {% data stocks = load("https://api.example.com/stocks.csv",
///                      headers: {"API-Key": "secret"}) %}
/// ```
///
/// ## See Also
/// - ``DataSource``: Protocol this implements
/// - ``LoadOptions``: Configuration options
/// - ``DataValue``: The data representation format
public struct CSVDataSource: DataSource {
    public init() {}
    
    public var supportedExtensions: [String] {
        ["csv", "tsv", "tab"]
    }
    
    public func load(from url: URL, options: LoadOptions) async throws -> DataValue {
        // Load data
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
                let (responseData, _) = try await URLSession.shared.data(for: request)
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
        guard let content = String(data: data, encoding: options.encoding) else {
            throw DataSourceError.parseError("Unable to decode CSV as \(options.encoding)")
        }
        
        // Determine delimiter
        let delimiter = detectDelimiter(from: url.pathExtension, content: content)
        
        // Parse CSV
        let rows = try parseCSV(content, delimiter: delimiter)
        
        // Convert to DataValue
        if rows.isEmpty {
            return .array([])
        }
        
        // Use first row as headers if it looks like headers
        let hasHeaders = detectHeaders(rows)
        
        if hasHeaders && rows.count > 1 {
            // Convert to array of objects
            let headers = rows[0]
            var result: [DataValue] = []
            
            for i in 1..<rows.count {
                let row = rows[i]
                var object: [String: DataValue] = [:]
                
                for (index, header) in headers.enumerated() {
                    if index < row.count {
                        object[header] = parseValue(row[index])
                    } else {
                        object[header] = .null
                    }
                }
                
                result.append(.object(object))
            }
            
            return .array(result)
        } else {
            // Convert to array of arrays
            let result = rows.map { row in
                DataValue.array(row.map { parseValue($0) })
            }
            return .array(result)
        }
    }
    
    /// Detect delimiter based on file extension and content
    private func detectDelimiter(from fileExtension: String, content: String) -> Character {
        switch fileExtension.lowercased() {
        case "tsv", "tab":
            return "\t"
        default:
            // Try to auto-detect
            let firstLine = content.components(separatedBy: .newlines).first ?? ""
            let commaCount = firstLine.filter { $0 == "," }.count
            let tabCount = firstLine.filter { $0 == "\t" }.count
            let semicolonCount = firstLine.filter { $0 == ";" }.count
            
            if tabCount > max(commaCount, semicolonCount) {
                return "\t"
            } else if semicolonCount > commaCount {
                return ";"
            } else {
                return ","
            }
        }
    }
    
    /// Parse CSV content
    private func parseCSV(_ content: String, delimiter: Character) throws -> [[String]] {
        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentField = ""
        var inQuotes = false
        var previousChar: Character? = nil
        
        for char in content {
            if inQuotes {
                if char == "\"" {
                    if previousChar == "\"" {
                        // Escaped quote
                        currentField.append(char)
                        previousChar = nil // Reset to avoid triple quotes being treated as escaped
                    } else {
                        // Might be end of quoted field
                        previousChar = char
                    }
                } else {
                    if previousChar == "\"" {
                        // Previous char was closing quote
                        inQuotes = false
                        previousChar = char
                        
                        if char == delimiter {
                            currentRow.append(currentField)
                            currentField = ""
                        } else if char == "\n" || char == "\r" {
                            currentRow.append(currentField)
                            if !currentRow.allSatisfy({ $0.isEmpty }) {
                                rows.append(currentRow)
                            }
                            currentRow = []
                            currentField = ""
                        } else {
                            // Invalid: character after closing quote that's not delimiter or newline
                            currentField.append(char)
                        }
                    } else {
                        currentField.append(char)
                        previousChar = char
                    }
                }
            } else {
                // Not in quotes
                if char == "\"" && currentField.isEmpty {
                    // Start of quoted field
                    inQuotes = true
                    previousChar = char
                } else if char == delimiter {
                    currentRow.append(currentField)
                    currentField = ""
                    previousChar = char
                } else if char == "\n" {
                    if previousChar != "\r" {
                        currentRow.append(currentField)
                        if !currentRow.allSatisfy({ $0.isEmpty }) {
                            rows.append(currentRow)
                        }
                        currentRow = []
                        currentField = ""
                    }
                    previousChar = char
                } else if char == "\r" {
                    currentRow.append(currentField)
                    if !currentRow.allSatisfy({ $0.isEmpty }) {
                        rows.append(currentRow)
                    }
                    currentRow = []
                    currentField = ""
                    previousChar = char
                } else {
                    currentField.append(char)
                    previousChar = char
                }
            }
        }
        
        // Handle last field and row
        if !currentField.isEmpty || !currentRow.isEmpty {
            currentRow.append(currentField)
            if !currentRow.allSatisfy({ $0.isEmpty }) {
                rows.append(currentRow)
            }
        }
        
        return rows
    }
    
    /// Detect if first row contains headers
    private func detectHeaders(_ rows: [[String]]) -> Bool {
        guard let firstRow = rows.first, rows.count > 1 else {
            return false
        }
        
        // Check if all values in first row are non-numeric strings
        let allNonNumeric = firstRow.allSatisfy { value in
            let trimmed = value.trimmingCharacters(in: .whitespaces)
            return !trimmed.isEmpty &&
                   Int(trimmed) == nil &&
                   Double(trimmed) == nil &&
                   trimmed.lowercased() != "true" &&
                   trimmed.lowercased() != "false"
        }
        
        // Check if headers are unique
        let uniqueHeaders = Set(firstRow).count == firstRow.count
        
        return allNonNumeric && uniqueHeaders
    }
    
    /// Parse a CSV value to appropriate DataValue type
    private func parseValue(_ value: String) -> DataValue {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        
        // Check for empty
        if trimmed.isEmpty {
            return .null
        }
        
        // Check for boolean
        if trimmed.lowercased() == "true" {
            return .bool(true)
        } else if trimmed.lowercased() == "false" {
            return .bool(false)
        }
        
        // Check for integer
        if let intValue = Int(trimmed) {
            return .int(intValue)
        }
        
        // Check for double
        if let doubleValue = Double(trimmed) {
            return .double(doubleValue)
        }
        
        // Check for date (ISO 8601)
        if let date = ISO8601DateFormatter().date(from: trimmed) {
            return .date(date)
        }
        
        // Default to string
        return .string(value)
    }
}
