//
//  HasTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: has", .serialized)
struct GoldenHasTests {

    @Test("filters, has, array of hashes, false property", .timeLimit(.minutes(1)))
    func arrayOfHashesFalseProperty() async throws {
        let ctx: [String: Any] = [
            "a": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("x", 99 as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("z", 42 as Any)
                ])] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | has: false }}", context: ctx)
        #expect(result == "false")
    }

    @Test("filters, has, array of hashes, int property", .timeLimit(.minutes(1)))
    func arrayOfHashesIntProperty() async throws {
        let ctx: [String: Any] = [
            "a": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("x", 99 as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("z", 42 as Any)
                ])] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | has: 42 }}", context: ctx)
        #expect(result == "false")
    }

    @Test("filters, has, array of hashes, int value, match", .timeLimit(.minutes(1)))
    func arrayOfHashesIntValueMatch() async throws {
        let ctx: [String: Any] = [
            "a": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("x", 99 as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("z", 42 as Any)
                ])] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | has: 'z', 42 }}", context: ctx)
        #expect(result == "true")
    }

    @Test("filters, has, array of hashes, int value, no match", .timeLimit(.minutes(1)))
    func arrayOfHashesIntValueNoMatch() async throws {
        let ctx: [String: Any] = [
            "a": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("x", 99 as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("z", 42 as Any)
                ])] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | has: 'z', 7 }}", context: ctx)
        #expect(result == "false")
    }

    @Test("filters, has, array of hashes, nil property", .timeLimit(.minutes(1)))
    func arrayOfHashesNilProperty() async throws {
        let ctx: [String: Any] = [
            "a": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("x", 99 as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("z", 42 as Any)
                ])] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | has: nil }}", context: ctx)
        #expect(result == "false")
    }

    @Test("filters, has, array of hashes, with a nil", .timeLimit(.minutes(1)))
    func arrayOfHashesWithANil() async throws {
        let ctx: [String: Any] = [
            "a": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("x", 99 as Any)
                ]), NSNull(), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("z", 42 as Any)
                ])] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | has: 'z', 42 }}", context: ctx)
        #expect(result == "")
    }

    @Test("filters, has, array of ints, default value", .timeLimit(.minutes(1)))
    func arrayOfIntsDefaultValue() async throws {
        let ctx: [String: Any] = [
            "a": [1, 2, 3]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | has: 2 }}", context: ctx)
        #expect(result == "true")
    }

    @Test("filters, has, array of ints, string argument, default value", .timeLimit(.minutes(1)))
    func arrayOfIntsStringArgumentDefaultValue() async throws {
        let ctx: [String: Any] = [
            "a": [1, 2, 3]
        ] as [String: Any]
        do {
            _ = try await renderWithTimeout(template: "{{ a | has: '2' }}", context: ctx)
            Issue.record("Expected error for \"filters, has, array of ints, string argument, default value\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, has, array of strings, default value", .timeLimit(.minutes(1)))
    func arrayOfStringsDefaultValue() async throws {
        let ctx: [String: Any] = [
            "a": ["x", "y", "z"]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | has: 'z' }}", context: ctx)
        #expect(result == "true")
    }

    @Test("filters, has, array of strings, default value, no match", .timeLimit(.minutes(1)))
    func arrayOfStringsDefaultValueNoMatch() async throws {
        let ctx: [String: Any] = [
            "a": ["x", "y", "z"]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | has: ':(' }}", context: ctx)
        #expect(result == "false")
    }

    @Test("filters, has, array of strings, default value, substring match", .timeLimit(.minutes(1)))
    func arrayOfStringsDefaultValueSubstringMatch() async throws {
        let ctx: [String: Any] = [
            "a": ["x", "y", "zoo"]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | has: 'z' }}", context: ctx)
        #expect(result == "true")
    }

    @Test("filters, has, hash input, default value, match", .timeLimit(.minutes(1)))
    func hashInputDefaultValueMatch() async throws {
        let ctx: [String: Any] = [
            "a": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("z", 42 as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | has: 'z' }}", context: ctx)
        #expect(result == "true")
    }

    @Test("filters, has, hash input, default value, no match", .timeLimit(.minutes(1)))
    func hashInputDefaultValueNoMatch() async throws {
        let ctx: [String: Any] = [
            "a": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("x", 42 as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | has: 'z' }}", context: ctx)
        #expect(result == "false")
    }

    @Test("filters, has, hash input, explicit nil, match", .timeLimit(.minutes(1)))
    func hashInputExplicitNilMatch() async throws {
        let ctx: [String: Any] = [
            "a": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("z", NSNull() as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | has: 'z', nil }}", context: ctx)
        #expect(result == "false")
    }

    @Test("filters, has, hash input, explicit nil, no match", .timeLimit(.minutes(1)))
    func hashInputExplicitNilNoMatch() async throws {
        let ctx: [String: Any] = [
            "a": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("z", 42 as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | has: 'z', nil }}", context: ctx)
        #expect(result == "true")
    }

    @Test("filters, has, hash input, false value, match", .timeLimit(.minutes(1)))
    func hashInputFalseValueMatch() async throws {
        let ctx: [String: Any] = [
            "a": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("z", false as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | has: 'z', false }}", context: ctx)
        #expect(result == "true")
    }

    @Test("filters, has, hash input, int value, match", .timeLimit(.minutes(1)))
    func hashInputIntValueMatch() async throws {
        let ctx: [String: Any] = [
            "a": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("z", 42 as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | has: 'z', 42 }}", context: ctx)
        #expect(result == "true")
    }

    @Test("filters, has, hash input, int value, no match", .timeLimit(.minutes(1)))
    func hashInputIntValueNoMatch() async throws {
        let ctx: [String: Any] = [
            "a": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("z", 42 as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | has: 'z', 99 }}", context: ctx)
        #expect(result == "false")
    }

    @Test("filters, has, hash input, string value, no type coercion", .timeLimit(.minutes(1)))
    func hashInputStringValueNoTypeCoercion() async throws {
        let ctx: [String: Any] = [
            "a": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("z", 42 as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | has: 'z', '42' }}", context: ctx)
        #expect(result == "false")
    }

    @Test("filters, has, mixed array, default value", .timeLimit(.minutes(1)))
    func mixedArrayDefaultValue() async throws {
        let ctx: [String: Any] = [
            "a": ["x", NSNull(), "z", false, true] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | has: 'z' }}", context: ctx)
        #expect(result == "")
    }

    @Test("filters, has, string input, default value, match", .timeLimit(.minutes(1)))
    func stringInputDefaultValueMatch() async throws {
        let ctx: [String: Any] = [
            "a": "zoo"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | has: 'z' }}", context: ctx)
        #expect(result == "true")
    }

    @Test("filters, has, string input, default value, no match", .timeLimit(.minutes(1)))
    func stringInputDefaultValueNoMatch() async throws {
        let ctx: [String: Any] = [
            "a": "foo"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | has: 'z' }}", context: ctx)
        #expect(result == "false")
    }
}
