//
//  GoldenLiquidFixture.swift
//  GoldenLiquidTests
//
//  Created as part of RhoeLiquid
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import Testing

// MARK: - Top-Level Suite

struct GoldenLiquidSuite: Decodable, Sendable {
    let description: String?
    let tests: [GoldenLiquidTestCase]
}

// MARK: - Test Case

struct GoldenLiquidTestCase: Decodable, Sendable {
    let name: String
    let template: String
    let data: JSONValue?
    let result: String?
    let results: [String]?
    let invalid: Bool?
    let templates: [String: String]?
    let tags: [String]?
}

// MARK: - Test ID Wrapper (for readable parameterized test names)

struct GoldenTestID: Sendable, CustomTestStringConvertible {
    let testCase: GoldenLiquidTestCase
    var testDescription: String { testCase.name }
}

// MARK: - JSONValue (recursive, Sendable, preserves Int vs Double)

enum JSONValue: Sendable {
    case string(String)
    case int(Int)
    case number(Double)
    case bool(Bool)
    case null
    case array([JSONValue])
    case object([String: JSONValue])

    /// Convert to `Any` for LiquidEngine context dictionaries.
    func toAny() -> Any {
        switch self {
        case .string(let s): return s
        case .int(let i): return i
        case .number(let d): return d
        case .bool(let b): return b
        case .null: return NSNull()
        case .array(let arr): return arr.map { $0.toAny() }
        case .object(let dict):
            var result: [String: Any] = [:]
            for (key, value) in dict {
                result[key] = value.toAny()
            }
            return result
        }
    }
}

extension JSONValue: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Bool must come before Int/Double because JSON booleans can decode as numbers
        if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
        } else if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if let doubleValue = try? container.decode(Double.self) {
            self = .number(doubleValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if container.decodeNil() {
            self = .null
        } else if let arrayValue = try? container.decode([JSONValue].self) {
            self = .array(arrayValue)
        } else if let objectValue = try? container.decode([String: JSONValue].self) {
            self = .object(objectValue)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported JSON value type"
            )
        }
    }
}
