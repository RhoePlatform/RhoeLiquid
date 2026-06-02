//
//  FindTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: find", .serialized)
struct GoldenFindTests {

    @Test("filters, find, array of hashes, int value, match", .timeLimit(.minutes(1)))
    func arrayOfHashesIntValueMatch() async throws {
        let ctx: [String: Any] = [
            "a": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("x", 99 as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("z", 42 as Any),
                    ("foo", "bar" as Any)
                ])] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign b = a | find: 'z', 42 %}{{ b.foo }}", context: ctx)
        #expect(result == "bar")
    }

    @Test("filters, find, array of hashes, with a nil", .timeLimit(.minutes(1)))
    func arrayOfHashesWithANil() async throws {
        let ctx: [String: Any] = [
            "a": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("x", 99 as Any)
                ]), NSNull(), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("z", 42 as Any),
                    ("foo", "bar" as Any)
                ])] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign b = a | find: 'z', 42 %}{{ b.foo }}", context: ctx)
        #expect(result == "")
    }

    @Test("filters, find, array of strings, default value", .timeLimit(.minutes(1)))
    func arrayOfStringsDefaultValue() async throws {
        let ctx: [String: Any] = [
            "a": ["x", "y", "z"]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | find: 'z' }}", context: ctx)
        #expect(result == "z")
    }

    @Test("filters, find, array of strings, default value, no match", .timeLimit(.minutes(1)))
    func arrayOfStringsDefaultValueNoMatch() async throws {
        let ctx: [String: Any] = [
            "a": ["x", "y", "zoo"]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | find: 'foo' }}", context: ctx)
        #expect(result == "")
    }

    @Test("filters, find, array of strings, substring match, default value", .timeLimit(.minutes(1)))
    func arrayOfStringsSubstringMatchDefaultValue() async throws {
        let ctx: [String: Any] = [
            "a": ["x", "y", "zoo"]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | find: 'oo' }}", context: ctx)
        #expect(result == "zoo")
    }

    @Test("filters, find, hash input, default value, match", .timeLimit(.minutes(1)))
    func hashInputDefaultValueMatch() async throws {
        let ctx: [String: Any] = [
            "a": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("z", 42 as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign b = a | find: 'z' %}{{ b.z }}", context: ctx)
        #expect(result == "42")
    }

    @Test("filters, find, hash input, default value, no match", .timeLimit(.minutes(1)))
    func hashInputDefaultValueNoMatch() async throws {
        let ctx: [String: Any] = [
            "a": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("z", 42 as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign b = a | find: 'foo' %}{{ b }}", context: ctx)
        #expect(result == "")
    }

    @Test("filters, find, hash input, explicit nil, match", .timeLimit(.minutes(1)))
    func hashInputExplicitNilMatch() async throws {
        let ctx: [String: Any] = [
            "a": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("z", NSNull() as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign b = a | find: 'z', nil %}{{ b.z }}", context: ctx)
        #expect(result == "")
    }

    @Test("filters, find, hash input, int value, match", .timeLimit(.minutes(1)))
    func hashInputIntValueMatch() async throws {
        let ctx: [String: Any] = [
            "a": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("z", 42 as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign b = a | find: 'z', 42 %}{{ b.z }}", context: ctx)
        #expect(result == "42")
    }

    @Test("filters, find, mixed array, default value", .timeLimit(.minutes(1)))
    func mixedArrayDefaultValue() async throws {
        let ctx: [String: Any] = [
            "a": ["x", NSNull(), "z", false, true] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | find: 'z' }}", context: ctx)
        #expect(result == "")
    }

    @Test("filters, find, string input, default value, match", .timeLimit(.minutes(1)))
    func stringInputDefaultValueMatch() async throws {
        let ctx: [String: Any] = [
            "a": "zoo"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | find: 'z' }}", context: ctx)
        #expect(result == "zoo")
    }

    @Test("filters, find, string input, string value, match", .timeLimit(.minutes(1)))
    func stringInputStringValueMatch() async throws {
        let ctx: [String: Any] = [
            "a": "zoo"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | find: 'z', 'z' }}", context: ctx)
        #expect(result == "zoo")
    }

    @Test("filters, find, string input, string value, no match", .timeLimit(.minutes(1)))
    func stringInputStringValueNoMatch() async throws {
        let ctx: [String: Any] = [
            "a": "zoo"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | find: 'z', 'y' }}", context: ctx)
        #expect(result == "")
    }
}
