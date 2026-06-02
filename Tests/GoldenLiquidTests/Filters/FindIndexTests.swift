//
//  FindIndexTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: find index", .serialized)
struct GoldenFindIndexTests {

    @Test("filters, find index, array of hashes, explicit nil, match", .timeLimit(.minutes(1)))
    func arrayOfHashesExplicitNilMatch() async throws {
        let ctx: [String: Any] = [
            "a": ["foo", "bar", OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("z", NSNull() as Any)
                ])] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | find_index: 'z', nil }}", context: ctx)
        #expect(result == "")
    }

    @Test("filters, find index, array of hashes, int value, match", .timeLimit(.minutes(1)))
    func arrayOfHashesIntValueMatch() async throws {
        let ctx: [String: Any] = [
            "a": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("x", 99 as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("z", 42 as Any),
                    ("foo", "bar" as Any)
                ])] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | find_index: 'z', 42 }}", context: ctx)
        #expect(result == "1")
    }

    @Test("filters, find index, array of hashes, with a nil", .timeLimit(.minutes(1)))
    func arrayOfHashesWithANil() async throws {
        let ctx: [String: Any] = [
            "a": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("x", 99 as Any)
                ]), NSNull(), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("z", 42 as Any),
                    ("foo", "bar" as Any)
                ])] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign b = a | find_index: 'z', 42 %}{{ b.foo }}", context: ctx)
        #expect(result == "")
    }

    @Test("filters, find index, array of strings, default value", .timeLimit(.minutes(1)))
    func arrayOfStringsDefaultValue() async throws {
        let ctx: [String: Any] = [
            "a": ["x", "y", "z"]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | find_index: 'z' }}", context: ctx)
        #expect(result == "2")
    }

    @Test("filters, find index, array of strings, default value, no match", .timeLimit(.minutes(1)))
    func arrayOfStringsDefaultValueNoMatch() async throws {
        let ctx: [String: Any] = [
            "a": ["x", "y", "zoo"]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | find_index: 'foo' }}", context: ctx)
        #expect(result == "")
    }

    @Test("filters, find index, array of strings, substring match, default value", .timeLimit(.minutes(1)))
    func arrayOfStringsSubstringMatchDefaultValue() async throws {
        let ctx: [String: Any] = [
            "a": ["x", "y", "zoo"]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | find_index: 'oo' }}", context: ctx)
        #expect(result == "2")
    }

    @Test("filters, find index, hash input, default value, match", .timeLimit(.minutes(1)))
    func hashInputDefaultValueMatch() async throws {
        let ctx: [String: Any] = [
            "a": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("z", 42 as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | find_index: 'z' }}", context: ctx)
        #expect(result == "0")
    }

    @Test("filters, find index, hash input, default value, no match", .timeLimit(.minutes(1)))
    func hashInputDefaultValueNoMatch() async throws {
        let ctx: [String: Any] = [
            "a": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("z", 42 as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | find_index: 'foo' }}", context: ctx)
        #expect(result == "")
    }

    @Test("filters, find index, hash input, explicit nil, match", .timeLimit(.minutes(1)))
    func hashInputExplicitNilMatch() async throws {
        let ctx: [String: Any] = [
            "a": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("z", NSNull() as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | find_index: 'z', nil }}", context: ctx)
        #expect(result == "")
    }

    @Test("filters, find index, hash input, int value, match", .timeLimit(.minutes(1)))
    func hashInputIntValueMatch() async throws {
        let ctx: [String: Any] = [
            "a": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("z", 42 as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | find_index: 'z', 42 }}", context: ctx)
        #expect(result == "0")
    }

    @Test("filters, find index, mixed array, default value", .timeLimit(.minutes(1)))
    func mixedArrayDefaultValue() async throws {
        let ctx: [String: Any] = [
            "a": ["x", NSNull(), "z", false, true] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | find_index: 'z' }}", context: ctx)
        #expect(result == "")
    }

    @Test("filters, find index, string input, default value, match", .timeLimit(.minutes(1)))
    func stringInputDefaultValueMatch() async throws {
        let ctx: [String: Any] = [
            "a": "zoo"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | find_index: 'z' }}", context: ctx)
        #expect(result == "0")
    }

    @Test("filters, find index, string input, string value, match", .timeLimit(.minutes(1)))
    func stringInputStringValueMatch() async throws {
        let ctx: [String: Any] = [
            "a": "zoo"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | find_index: 'z', 'z' }}", context: ctx)
        #expect(result == "0")
    }

    @Test("filters, find index, string input, string value, no match", .timeLimit(.minutes(1)))
    func stringInputStringValueNoMatch() async throws {
        let ctx: [String: Any] = [
            "a": "zoo"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | find_index: 'z', 'y' }}", context: ctx)
        #expect(result == "")
    }
}
