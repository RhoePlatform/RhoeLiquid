//
//  SpecialTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: special", .serialized)
struct GoldenSpecialTests {

    @Test("special, first of a string", .timeLimit(.minutes(1)))
    func firstOfAString() async throws {
        let ctx: [String: Any] = [
            "s": "hello"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ s.first }}", context: ctx)
        let validResults: [String] = ["h", ""]
        #expect(validResults.contains(result), "Got \(result)")
    }

    @Test("special, first of an array", .timeLimit(.minutes(1)))
    func firstOfAnArray() async throws {
        let ctx: [String: Any] = [
            "a": [3, 2, 1]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a.first }}", context: ctx)
        #expect(result == "3")
    }

    @Test("special, first of an empty object", .timeLimit(.minutes(1)))
    func firstOfAnEmptyObject() async throws {
        let ctx: [String: Any] = [
            "obj": OrderedDictionary<String, Any>()
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ obj.first | join: '#' }}", context: ctx)
        #expect(result == "")
    }

    @Test("special, first of an object", .timeLimit(.minutes(1)))
    func firstOfAnObject() async throws {
        let ctx: [String: Any] = [
            "obj": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("a", 1 as Any),
                ("b", 2 as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ obj.first | join: '#' }}", context: ctx)
        #expect(result == "a#1")
    }

    @Test("special, first of an object with a first property", .timeLimit(.minutes(1)))
    func firstOfAnObjectWithAFirstProperty() async throws {
        let ctx: [String: Any] = [
            "obj": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("a", 1 as Any),
                ("first", 99 as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ obj.first }}", context: ctx)
        #expect(result == "99")
    }

    @Test("special, last of a object", .timeLimit(.minutes(1)))
    func lastOfAObject() async throws {
        let ctx: [String: Any] = [
            "obj": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("a", 1 as Any),
                ("b", 2 as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ obj.last }}", context: ctx)
        #expect(result == "")
    }

    @Test("special, last of a string", .timeLimit(.minutes(1)))
    func lastOfAString() async throws {
        let ctx: [String: Any] = [
            "s": "hello"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ s.last }}", context: ctx)
        let validResults: [String] = ["o", ""]
        #expect(validResults.contains(result), "Got \(result)")
    }

    @Test("special, last of an array", .timeLimit(.minutes(1)))
    func lastOfAnArray() async throws {
        let ctx: [String: Any] = [
            "a": [3, 2, 1]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a.last }}", context: ctx)
        #expect(result == "1")
    }

    @Test("special, last of an object with a last property", .timeLimit(.minutes(1)))
    func lastOfAnObjectWithALastProperty() async throws {
        let ctx: [String: Any] = [
            "obj": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("a", 1 as Any),
                ("last", 99 as Any),
                ("b", 42 as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ obj.last }}", context: ctx)
        #expect(result == "99")
    }

    @Test("special, size of a string", .timeLimit(.minutes(1)))
    func sizeOfAString() async throws {
        let ctx: [String: Any] = [
            "s": "hello"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ s.size }}", context: ctx)
        #expect(result == "5")
    }

    @Test("special, size of an array", .timeLimit(.minutes(1)))
    func sizeOfAnArray() async throws {
        let ctx: [String: Any] = [
            "a": [3, 2, 1]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a.size }}", context: ctx)
        #expect(result == "3")
    }

    @Test("special, size of an object with a size property", .timeLimit(.minutes(1)))
    func sizeOfAnObjectWithASizeProperty() async throws {
        let ctx: [String: Any] = [
            "obj": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("size", 99 as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ obj.size }}", context: ctx)
        #expect(result == "99")
    }

    @Test("special, size of undefined", .timeLimit(.minutes(1)))
    func sizeOfUndefined() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing.last }}", context: [:])
        #expect(result == "")
    }
}
