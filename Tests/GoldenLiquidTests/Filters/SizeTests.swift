//
//  SizeTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: size", .serialized)
struct GoldenSizeTests {

    @Test("filters, size, size of a hash", .timeLimit(.minutes(1)))
    func sizeOfAHash() async throws {
        let ctx: [String: Any] = [
            "a": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("a", 1 as Any),
                ("b", 2 as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | size }}", context: ctx)
        #expect(result == "2")
    }

    @Test("filters, size, size of a string", .timeLimit(.minutes(1)))
    func sizeOfAString() async throws {
        let ctx: [String: Any] = [
            "a": "abc"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | size }}", context: ctx)
        #expect(result == "3")
    }

    @Test("filters, size, size of an array", .timeLimit(.minutes(1)))
    func sizeOfAnArray() async throws {
        let ctx: [String: Any] = [
            "a": ["a", "b", "c"]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | size }}", context: ctx)
        #expect(result == "3")
    }

    @Test("filters, size, size of an empty array", .timeLimit(.minutes(1)))
    func sizeOfAnEmptyArray() async throws {
        let ctx: [String: Any] = [
            "a": [Any]()
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | size }}", context: ctx)
        #expect(result == "0")
    }

    @Test("filters, size, undefined left value", .timeLimit(.minutes(1)))
    func undefinedLeftValue() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | size }}", context: [:])
        #expect(result == "0")
    }

    @Test("filters, size, unexpected argument", .timeLimit(.minutes(1)))
    func unexpectedArgument() async throws {
        let ctx: [String: Any] = [
            "a": [1, 2, 3]
        ] as [String: Any]
        do {
            _ = try await renderWithTimeout(template: "{{ a | size: 'foo' }}", context: ctx)
            Issue.record("Expected error for \"filters, size, unexpected argument\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }
}
