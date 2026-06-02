//
//  SortNaturalTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: sort natural", .serialized)
struct GoldenSortNaturalTests {

    @Test("filters, sort natural, argument is undefined", .timeLimit(.minutes(1)))
    func argumentIsUndefined() async throws {
        let ctx: [String: Any] = [
            "a": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "foo" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "bar" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "Baz" as Any)
                ])] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign x = a | sort_natural: nosuchthing %}{% for obj in x %}{% for i in obj %}({{ i[0] }},{{ i[1] }}){% endfor %}{% endfor %}", context: ctx)
        #expect(result == "(title,bar)(title,Baz)(title,foo)")
    }

    @Test("filters, sort natural, array of objects with a key", .timeLimit(.minutes(1)))
    func arrayOfObjectsWithAKey() async throws {
        let ctx: [String: Any] = [
            "a": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "foo" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "bar" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "Baz" as Any)
                ])] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign x = a | sort_natural: 'title' %}{% for obj in x %}{% for i in obj %}({{ i[0] }},{{ i[1] }}){% endfor %}{% endfor %}", context: ctx)
        #expect(result == "(title,bar)(title,Baz)(title,foo)")
    }

    @Test("filters, sort natural, array of objects with a key gets stringified", .timeLimit(.minutes(1)))
    func arrayOfObjectsWithAKeyGetsStringified() async throws {
        let ctx: [String: Any] = [
            "a": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", 9 as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", 1111 as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", 87 as Any)
                ])] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign x = a | sort_natural: 'title' %}{% for obj in x %}{% for i in obj %}({{ i[0] }},{{ i[1] }}){% endfor %}{% endfor %}", context: ctx)
        #expect(result == "(title,1111)(title,87)(title,9)")
    }

    @Test("filters, sort natural, array of objects with a missing key", .timeLimit(.minutes(1)))
    func arrayOfObjectsWithAMissingKey() async throws {
        let ctx: [String: Any] = [
            "a": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "foo" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "bar" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("heading", "Baz" as Any)
                ])] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign x = a | sort_natural: 'title' %}{% for obj in x %}{% for i in obj %}({{ i[0] }},{{ i[1] }}){% endfor %}{% endfor %}", context: ctx)
        #expect(result == "(title,bar)(title,foo)(heading,Baz)")
    }

    @Test("filters, sort natural, array of strings", .timeLimit(.minutes(1)))
    func arrayOfStrings() async throws {
        let ctx: [String: Any] = [
            "a": ["b", "a", "C", "B", "A"]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | sort_natural | join: '#' }}", context: ctx)
        #expect(result == "a#A#b#B#C")
    }

    @Test("filters, sort natural, array of strings with a nul", .timeLimit(.minutes(1)))
    func arrayOfStringsWithANul() async throws {
        let ctx: [String: Any] = [
            "a": ["b", "a", NSNull(), "C", "B", "A"] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign x = a | sort_natural %}{% for i in x %}{{ i }}{% unless forloop.last %}#{% endunless %}{% endfor %}", context: ctx)
        #expect(result == "a#A#b#B#C#")
    }

    @Test("filters, sort natural, empty array", .timeLimit(.minutes(1)))
    func emptyArray() async throws {
        let ctx: [String: Any] = [
            "a": [Any]()
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign x = a | sort_natural %}{% for i in x %}{{ i }}{% unless forloop.last %}#{% endunless %}{% endfor %}", context: ctx)
        #expect(result == "")
    }

    @Test("filters, sort natural, incompatible types", .timeLimit(.minutes(1)))
    func incompatibleTypes() async throws {
        let ctx: [String: Any] = [
            "a": [OrderedDictionary<String, Any>(), 1, "4"] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | sort_natural }}", context: ctx)
        #expect(result == "14{}")
    }

    @Test("filters, sort natural, left value is not an array", .timeLimit(.minutes(1)))
    func leftValueIsNotAnArray() async throws {
        let ctx: [String: Any] = [
            "a": 123
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | sort_natural }}", context: ctx)
        #expect(result == "123")
    }

    @Test("filters, sort natural, left value is undefined", .timeLimit(.minutes(1)))
    func leftValueIsUndefined() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | sort_natural }}", context: [:])
        #expect(result == "")
    }
}
