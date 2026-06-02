//
//  SumTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: sum", .serialized)
struct GoldenSumTests {

    @Test("filters, sum, empty sequence", .timeLimit(.minutes(1)))
    func emptySequence() async throws {
        let ctx: [String: Any] = [
            "a": [Any]()
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | sum }}", context: ctx)
        #expect(result == "0")
    }

    @Test("filters, sum, hashes with numeric strings and property argument", .timeLimit(.minutes(1)))
    func hashesWithNumericStringsAndPropertyArgument() async throws {
        let ctx: [String: Any] = [
            "a": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("k", "1" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("k", "2" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("k", "3" as Any)
                ])] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | sum: 'k' }}", context: ctx)
        #expect(result == "6")
    }

    @Test("filters, sum, hashes with property argument", .timeLimit(.minutes(1)))
    func hashesWithPropertyArgument() async throws {
        let ctx: [String: Any] = [
            "a": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("k", 1 as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("k", 2 as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("k", 3 as Any)
                ])] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | sum: 'k' }}", context: ctx)
        #expect(result == "6")
    }

    @Test("filters, sum, hashes with some missing properties", .timeLimit(.minutes(1)))
    func hashesWithSomeMissingProperties() async throws {
        let ctx: [String: Any] = [
            "a": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("k", 1 as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("k", 2 as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("x", 3 as Any)
                ])] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | sum: 'k' }}", context: ctx)
        #expect(result == "3")
    }

    @Test("filters, sum, hashes without property argument", .timeLimit(.minutes(1)))
    func hashesWithoutPropertyArgument() async throws {
        let ctx: [String: Any] = [
            "a": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("k", 1 as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("k", 2 as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("k", 3 as Any)
                ])] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | sum }}", context: ctx)
        #expect(result == "0")
    }

    @Test("filters, sum, ints", .timeLimit(.minutes(1)))
    func ints() async throws {
        let ctx: [String: Any] = [
            "a": [1, 2, 3]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | sum }}", context: ctx)
        #expect(result == "6")
    }

    @Test("filters, sum, negative ints", .timeLimit(.minutes(1)))
    func negativeInts() async throws {
        let ctx: [String: Any] = [
            "a": [-1, -2, -3]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | sum }}", context: ctx)
        #expect(result == "-6")
    }

    @Test("filters, sum, negative strings", .timeLimit(.minutes(1)))
    func negativeStrings() async throws {
        let ctx: [String: Any] = [
            "a": ["-1", "-2", "-3"]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | sum }}", context: ctx)
        #expect(result == "-6")
    }

    @Test("filters, sum, nested ints", .timeLimit(.minutes(1)))
    func nestedInts() async throws {
        let ctx: [String: Any] = [
            "a": [1, [2, [3]] as [Any]] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | sum }}", context: ctx)
        #expect(result == "6")
    }

    @Test("filters, sum, only zeros", .timeLimit(.minutes(1)))
    func onlyZeros() async throws {
        let ctx: [String: Any] = [
            "a": [0, 0, 0]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | sum }}", context: ctx)
        #expect(result == "0")
    }

    @Test("filters, sum, positive and negative ints", .timeLimit(.minutes(1)))
    func positiveAndNegativeInts() async throws {
        let ctx: [String: Any] = [
            "a": [-2, -3, 10]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | sum }}", context: ctx)
        #expect(result == "5")
    }

    @Test("filters, sum, properties arguments with non-hash items", .timeLimit(.minutes(1)))
    func propertiesArgumentsWithNonHashItems() async throws {
        let ctx: [String: Any] = [
            "a": [1, 2, 3]
        ] as [String: Any]
        do {
            _ = try await renderWithTimeout(template: "{{ a | sum: 'k' }}", context: ctx)
            Issue.record("Expected error for \"filters, sum, properties arguments with non-hash items\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }
}
