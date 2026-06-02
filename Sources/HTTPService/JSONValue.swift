import Foundation
#if canImport(CoreFoundation)
import CoreFoundation
#endif

enum JSONValue: Codable, Sendable {
    case array([JSONValue])
    case bool(Bool)
    case int(Int)
    case null
    case object([String: JSONValue])
    case double(Double)
    case string(String)

    init(from decoder: Decoder) throws {
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
        } else if let object = try? container.decode([String: JSONValue].self) {
            self = .object(object)
        } else if let array = try? container.decode([JSONValue].self) {
            self = .array(array)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported JSON value"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .array(let values):
            try container.encode(values)
        case .bool(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        case .object(let values):
            try container.encode(values)
        case .double(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        }
    }

    init(any value: Any) throws {
        switch value {
        case let value as JSONValue:
            self = value
        case let value as String:
            self = .string(value)
        case let value as Bool:
            self = .bool(value)
        case let value as Int:
            self = .int(value)
        case let value as Double:
            self = .double(value)
        case let value as Float:
            self = .double(Double(value))
        case let value as NSNumber:
            #if canImport(CoreFoundation)
            if CFGetTypeID(value) == CFBooleanGetTypeID() {
                self = .bool(value.boolValue)
            } else if value.doubleValue.rounded(.towardZero) == value.doubleValue {
                self = .int(value.intValue)
            } else {
                self = .double(value.doubleValue)
            }
            #else
            if value.objCType.pointee == UInt8(ascii: "c") {
                self = .bool(value.boolValue)
            } else if value.doubleValue.rounded(.towardZero) == value.doubleValue {
                self = .int(value.intValue)
            } else {
                self = .double(value.doubleValue)
            }
            #endif
        case let value as [String: Any]:
            self = .object(try Self.encodeDictionary(value))
        case let value as [Any]:
            self = .array(try value.map(Self.init(any:)))
        case _ as NSNull:
            self = .null
        default:
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(codingPath: [], debugDescription: "Unsupported JSON value")
            )
        }
    }

    var anyValue: Any {
        switch self {
        case .array(let values):
            return values.map(\.anyValue)
        case .bool(let value):
            return value
        case .int(let value):
            return value
        case .null:
            return NSNull()
        case .object(let values):
            return values.mapValues(\.anyValue)
        case .double(let value):
            return value
        case .string(let value):
            return value
        }
    }

    static func encodeDictionary(_ values: [String: Any]) throws -> [String: JSONValue] {
        try values.mapValues(Self.init(any:))
    }

    static func decodeDictionary(_ values: [String: JSONValue]) -> [String: Any] {
        values.mapValues(\.anyValue)
    }
}
