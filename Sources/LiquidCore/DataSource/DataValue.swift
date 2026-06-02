//
//  DataValue.swift
//  LiquidCore
//
//  A unified data representation for all data sources in RhoeLiquid
//

import Foundation
#if canImport(CoreFoundation)
import CoreFoundation
#endif

/// A universal value type that can represent any data loaded from external sources
///
/// `DataValue` provides a unified interface for accessing data from JSON, Markdown,
/// CSV, XML, and other formats. It supports both object and array access patterns
/// with automatic type coercion, making it the foundation of RhoeLiquid's data source system.
///
/// ## Overview
///
/// The `DataValue` enum supports all common data types found in structured data formats:
/// - **Primitive types**: null, boolean, integer, double, string
/// - **Complex types**: arrays, objects (key-value pairs)
/// - **Special types**: dates, binary data
///
/// ## Usage Examples
///
/// ### Creating DataValues
/// ```swift
/// // Primitive values
/// let nullValue = DataValue.null
/// let boolValue = DataValue.bool(true)
/// let intValue = DataValue.int(42)
/// let stringValue = DataValue.string("Hello, World!")
///
/// // Complex values
/// let arrayValue = DataValue.array([.int(1), .int(2), .int(3)])
/// let objectValue = DataValue.object([
///     "name": .string("John"),
///     "age": .int(30),
///     "active": .bool(true)
/// ])
/// ```
///
/// ### Accessing Data
/// ```swift
/// // Subscript access for objects
/// let name = objectValue["name"]  // Returns DataValue.string("John")
/// 
/// // Subscript access for arrays
/// let firstItem = arrayValue[0]    // Returns DataValue.int(1)
///
/// // Dot notation for nested data
/// let city = userData["address.city"]  // Supports path-based access
/// let zip = userData["address.postal.code"]  // Multi-level paths
///
/// // Type-safe value extraction
/// if let age = userData["age"].intValue {
///     print("User is \(age) years old")
/// }
/// ```
///
/// ### Type Conversions
///
/// DataValue provides safe type conversion through computed properties:
/// ```swift
/// let value = DataValue.string("42")
/// 
/// // Convert to different types
/// value.boolValue     // true (non-empty string)
/// value.intValue      // Optional(42)
/// value.doubleValue   // Optional(42.0)
/// value.stringValue   // "42"
/// ```
///
/// ## Data Path Access
///
/// DataValue supports sophisticated path-based access using dot notation:
/// ```swift
/// let data = DataValue.object([
///     "users": .array([
///         .object(["name": .string("Alice"), "age": .int(30)]),
///         .object(["name": .string("Bob"), "age": .int(25)])
///     ]),
///     "settings": .object([
///         "theme": .object([
///             "name": .string("dark"),
///             "colors": .object(["primary": .string("#007AFF")])
///         ])
///     ])
/// ])
///
/// // Access nested data
/// let themeName = data["settings.theme.name"]     // "dark"
/// let primaryColor = data["settings.theme.colors.primary"]  // "#007AFF"
/// let firstUser = data["users.0.name"]            // "Alice"
/// ```
///
/// ## Liquid Template Integration
///
/// DataValue seamlessly integrates with Liquid templates:
/// ```liquid
/// {% data users = load("./users.json") %}
/// {% for user in users %}
///   Name: {{ user.name }}
///   Age: {{ user.age }}
/// {% endfor %}
/// ```
///
/// ## Type Safety and Conversions
///
/// All type conversions are safe and return optional values:
/// - **boolValue**: Converts to Bool (0/empty = false, others = true)
/// - **intValue**: Converts numeric types to Int
/// - **doubleValue**: Converts numeric types to Double
/// - **stringValue**: Always succeeds, converts any type to String
/// - **dateValue**: Returns Date if stored as date type
/// - **dataValue**: Returns Data if stored as binary data
/// - **arrayValue**: Returns array if type is array, nil otherwise
/// - **objectValue**: Returns dictionary if type is object, nil otherwise
///
/// ## Thread Safety
///
/// DataValue is fully thread-safe and conforms to `Sendable`, making it suitable
/// for use in concurrent contexts and actor-based architectures.
///
/// ## See Also
/// - ``DataSource``: Protocol for loading data from various sources
/// - ``DataLoaderRegistry``: Registry for managing data source loaders
/// - ``LoadOptions``: Configuration options for data loading
public enum DataValue: Sendable, Equatable {
    /// Represents a null/nil value
    case null
    
    /// Boolean value
    case bool(Bool)
    
    /// Integer value
    case int(Int)
    
    /// Floating-point value
    case double(Double)
    
    /// String value
    case string(String)
    
    /// Array of values
    case array([DataValue])
    
    /// Object/dictionary of key-value pairs
    case object([String: DataValue])
    
    /// Date/time value
    case date(Date)
    
    /// Raw data (for binary content)
    case data(Data)
}

// MARK: - Subscript Access

extension DataValue {
    /// Access object properties by key
    public subscript(key: String) -> DataValue {
        switch self {
        case .object(let dict):
            return dict[key] ?? .null
        default:
            return .null
        }
    }
    
    /// Access array elements by index
    public subscript(index: Int) -> DataValue {
        switch self {
        case .array(let arr):
            return index >= 0 && index < arr.count ? arr[index] : .null
        default:
            return .null
        }
    }
    
    /// Access nested values using dot notation
    public func value(at path: String) -> DataValue {
        let components = path.split(separator: ".").map(String.init)
        return value(at: components)
    }
    
    /// Access nested values using path components
    public func value(at path: [String]) -> DataValue {
        var current = self
        
        for component in path {
            // Check if component is an array index
            if let index = Int(component) {
                current = current[index]
            } else {
                current = current[component]
            }
            
            if case .null = current {
                return .null
            }
        }
        
        return current
    }
}

// MARK: - Type Conversion

extension DataValue {
    /// Convert to boolean
    public var boolValue: Bool {
        switch self {
        case .null:
            return false
        case .bool(let value):
            return value
        case .int(let value):
            return value != 0
        case .double(let value):
            return value != 0
        case .string(let value):
            return !value.isEmpty && value.lowercased() != "false" && value != "0"
        case .array(let value):
            return !value.isEmpty
        case .object(let value):
            return !value.isEmpty
        case .date:
            return true
        case .data(let value):
            return !value.isEmpty
        }
    }
    
    /// Convert to integer
    public var intValue: Int? {
        switch self {
        case .null:
            return nil
        case .bool(let value):
            return value ? 1 : 0
        case .int(let value):
            return value
        case .double(let value):
            return Int(value)
        case .string(let value):
            return Int(value)
        case .date(let value):
            return Int(value.timeIntervalSince1970)
        default:
            return nil
        }
    }
    
    /// Convert to double
    public var doubleValue: Double? {
        switch self {
        case .null:
            return nil
        case .bool(let value):
            return value ? 1.0 : 0.0
        case .int(let value):
            return Double(value)
        case .double(let value):
            return value
        case .string(let value):
            return Double(value)
        case .date(let value):
            return value.timeIntervalSince1970
        default:
            return nil
        }
    }
    
    /// Convert to string
    public var stringValue: String {
        switch self {
        case .null:
            return ""
        case .bool(let value):
            return String(value)
        case .int(let value):
            return String(value)
        case .double(let value):
            return String(value)
        case .string(let value):
            return value
        case .array:
            return description
        case .object:
            return description
        case .date(let value):
            return ISO8601DateFormatter().string(from: value)
        case .data(let value):
            return value.base64EncodedString()
        }
    }
    
    /// Convert to date
    public var dateValue: Date? {
        switch self {
        case .date(let value):
            return value
        case .string(let value):
            return ISO8601DateFormatter().date(from: value)
        case .int(let value):
            return Date(timeIntervalSince1970: TimeInterval(value))
        case .double(let value):
            return Date(timeIntervalSince1970: value)
        default:
            return nil
        }
    }
    
    /// Get as array if possible
    public var arrayValue: [DataValue]? {
        switch self {
        case .array(let value):
            return value
        default:
            return nil
        }
    }
    
    /// Get as object if possible
    public var objectValue: [String: DataValue]? {
        switch self {
        case .object(let value):
            return value
        default:
            return nil
        }
    }
}

// MARK: - Liquid Value Conversion

extension DataValue {
    /// Convert DataValue to a Liquid-compatible Any value
    public var liquidValue: Any {
        switch self {
        case .null:
            return NSNull()
        case .bool(let value):
            return value
        case .int(let value):
            return value
        case .double(let value):
            return value
        case .string(let value):
            return value
        case .array(let values):
            return values.map { $0.liquidValue }
        case .object(let dict):
            return dict.mapValues { $0.liquidValue }
        case .date(let value):
            return value
        case .data(let value):
            return value
        }
    }
    
    /// Create DataValue from Any
    public init(from value: Any) {
        switch value {
        case is NSNull:
            self = .null
        case let bool as Bool:
            self = .bool(bool)
        case let number as NSNumber:
            #if canImport(CoreFoundation)
            // CoreFoundation: precise boolean type discrimination
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                self = .bool(number.boolValue)
            } else if number.doubleValue.rounded(.towardZero) == number.doubleValue {
                self = .int(number.intValue)
            } else {
                self = .double(number.doubleValue)
            }
            #else
            // Portable fallback: NSNumber wrapping Bool uses 'c'.
            if number.objCType.pointee == UInt8(ascii: "c") {
                self = .bool(number.boolValue)
            } else if number.doubleValue.rounded(.towardZero) == number.doubleValue {
                self = .int(number.intValue)
            } else {
                self = .double(number.doubleValue)
            }
            #endif
        case let int as Int:
            self = .int(int)
        case let double as Double:
            self = .double(double)
        case let string as String:
            self = .string(string)
        case let date as Date:
            self = .date(date)
        case let data as Data:
            self = .data(data)
        case let array as NSArray:
            self = .array(array.map { DataValue(from: $0) })
        case let array as [Any]:
            self = .array(array.map { DataValue(from: $0) })
        case let dictionary as NSDictionary:
            if let bridged = dictionary as? [String: Any] {
                self = .object(bridged.mapValues { DataValue(from: $0) })
            } else {
                var object: [String: DataValue] = [:]
                object.reserveCapacity(dictionary.count)
                for (rawKey, rawValue) in dictionary {
                    guard let key = rawKey as? String else {
                        continue
                    }
                    object[key] = DataValue(from: rawValue)
                }
                self = .object(object)
            }
        case let dict as [String: Any]:
            self = .object(dict.mapValues { DataValue(from: $0) })
        default:
            self = .string(String(describing: value))
        }
    }
}

// MARK: - CustomStringConvertible

extension DataValue: CustomStringConvertible {
    public var description: String {
        switch self {
        case .null:
            return "null"
        case .bool(let value):
            return String(value)
        case .int(let value):
            return String(value)
        case .double(let value):
            return String(value)
        case .string(let value):
            return value
        case .array(let values):
            let items = values.map { $0.description }.joined(separator: ", ")
            return "[\(items)]"
        case .object(let dict):
            let pairs = dict.map { "\"\($0.key)\": \($0.value.description)" }
                .sorted()
                .joined(separator: ", ")
            return "{\(pairs)}"
        case .date(let value):
            return ISO8601DateFormatter().string(from: value)
        case .data(let value):
            return "<Data: \(value.count) bytes>"
        }
    }
}

// MARK: - Codable

extension DataValue: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let int = try? container.decode(Int.self) {
            self = .int(int)
        } else if let double = try? container.decode(Double.self) {
            self = .double(double)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let date = try? container.decode(Date.self) {
            self = .date(date)
        } else if let array = try? container.decode([DataValue].self) {
            self = .array(array)
        } else if let object = try? container.decode([String: DataValue].self) {
            self = .object(object)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unable to decode DataValue"
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .null:
            try container.encodeNil()
        case .bool(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .date(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        case .data(let value):
            try container.encode(value.base64EncodedString())
        }
    }
}
