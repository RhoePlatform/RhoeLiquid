//
//  FirstTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: first", .serialized)
struct GoldenFirstTests {

    @Test("filters, first, array of strings", .timeLimit(.minutes(1)))
    func arrayOfStrings() async throws {
        let ctx: [String: Any] = [
            "arr": ["a", "b"]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ arr | first }}", context: ctx)
        #expect(result == "a")
    }

    @Test("filters, first, array of things", .timeLimit(.minutes(1)))
    func arrayOfThings() async throws {
        let ctx: [String: Any] = [
            "arr": ["a", "b", 1, [Any](), OrderedDictionary<String, Any>()] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ arr | first }}", context: ctx)
        #expect(result == "a")
    }

    @Test("filters, first, empty left value", .timeLimit(.minutes(1)))
    func emptyLeftValue() async throws {
        let ctx: [String: Any] = [
            "arr": [Any]()
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ arr | first }}", context: ctx)
        #expect(result == "")
    }

    @Test("filters, first, first of a hash", .timeLimit(.minutes(1)))
    func firstOfAHash() async throws {
        let ctx: [String: Any] = [
            "a": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("b", 1 as Any),
                ("c", 2 as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign x = a | first %}({{ x[0] }},{{ x[1] }})", context: ctx)
        #expect(result == "(b,1)")
    }

    @Test("filters, first, first of a string", .timeLimit(.minutes(1)))
    func firstOfAString() async throws {
        let result = try await renderWithTimeout(template: "{{ 'hello' | first }}", context: [:])
        let validResults: [String] = ["", "h"]
        #expect(validResults.contains(result), "Got \(result)")
    }

    @Test("filters, first, left value is not an array", .timeLimit(.minutes(1)))
    func leftValueIsNotAnArray() async throws {
        let ctx: [String: Any] = [
            "arr": 12
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ arr | first }}", context: ctx)
        #expect(result == "")
    }

    @Test("filters, first, left value is undefined", .timeLimit(.minutes(1)))
    func leftValueIsUndefined() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | first }}", context: [:])
        #expect(result == "")
    }

    @Test("filters, first, range literal first filter left value", .timeLimit(.minutes(1)))
    func rangeLiteralFirstFilterLeftValue() async throws {
        let result = try await renderWithTimeout(template: "{{ (1..3) | first }}", context: [:])
        #expect(result == "1")
    }
}
