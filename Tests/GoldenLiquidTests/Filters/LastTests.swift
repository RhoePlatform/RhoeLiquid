//
//  LastTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: last", .serialized)
struct GoldenLastTests {

    @Test("filters, last, array of strings", .timeLimit(.minutes(1)))
    func arrayOfStrings() async throws {
        let ctx: [String: Any] = [
            "arr": ["a", "b"]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ arr | last }}", context: ctx)
        #expect(result == "b")
    }

    @Test("filters, last, array of things", .timeLimit(.minutes(1)))
    func arrayOfThings() async throws {
        let ctx: [String: Any] = [
            "arr": ["a", "b", 1, [Any](), OrderedDictionary<String, Any>()] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ arr | last }}", context: ctx)
        #expect(result == "{}")
    }

    @Test("filters, last, empty array", .timeLimit(.minutes(1)))
    func emptyArray() async throws {
        let ctx: [String: Any] = [
            "arr": [Any]()
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ arr | last }}", context: ctx)
        #expect(result == "")
    }

    @Test("filters, last, last of a hash", .timeLimit(.minutes(1)))
    func lastOfAHash() async throws {
        let ctx: [String: Any] = [
            "a": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("b", 1 as Any),
                ("c", 2 as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | last }}", context: ctx)
        #expect(result == "")
    }

    @Test("filters, last, last of a string", .timeLimit(.minutes(1)))
    func lastOfAString() async throws {
        let result = try await renderWithTimeout(template: "{{ 'hello' | last }}", context: [:])
        let validResults: [String] = ["", "o"]
        #expect(validResults.contains(result), "Got \(result)")
    }

    @Test("filters, last, left value is undefined", .timeLimit(.minutes(1)))
    func leftValueIsUndefined() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | last }}", context: [:])
        #expect(result == "")
    }

    @Test("filters, last, left value not an array", .timeLimit(.minutes(1)))
    func leftValueNotAnArray() async throws {
        let ctx: [String: Any] = [
            "arr": 12
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ arr | last }}", context: ctx)
        #expect(result == "")
    }

    @Test("filters, last, range literal last filter left value", .timeLimit(.minutes(1)))
    func rangeLiteralLastFilterLeftValue() async throws {
        let result = try await renderWithTimeout(template: "{{ (1..3) | last }}", context: [:])
        #expect(result == "3")
    }
}
