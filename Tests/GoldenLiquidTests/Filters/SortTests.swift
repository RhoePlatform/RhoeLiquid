//
//  SortTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: sort", .serialized)
struct GoldenSortTests {

    @Test("filters, sort, argument is undefined", .timeLimit(.minutes(1)))
    func argumentIsUndefined() async throws {
        let ctx: [String: Any] = [
            "a": ["b", "a"]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | sort: nosuchthing | join: '#' }}", context: ctx)
        #expect(result == "a#b")
    }

    @Test("filters, sort, array of integers", .timeLimit(.minutes(1)))
    func arrayOfIntegers() async throws {
        let ctx: [String: Any] = [
            "a": [1, 1000, 3, 30]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | sort | join: '#' }}", context: ctx)
        #expect(result == "1#3#30#1000")
    }

    @Test("filters, sort, array of objects", .timeLimit(.minutes(1)))
    func arrayOfObjects() async throws {
        let ctx: [String: Any] = [
            "a": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "foo" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "Baz" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "bar" as Any)
                ])] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign x = a | sort: 'title' %}{% for obj in x %}{% for i in obj %}({{ i[0] }},{{ i[1] }}){% endfor %}{% endfor %}", context: ctx)
        #expect(result == "(title,Baz)(title,bar)(title,foo)")
    }

    @Test("filters, sort, array of objects with missing key", .timeLimit(.minutes(1)))
    func arrayOfObjectsWithMissingKey() async throws {
        let ctx: [String: Any] = [
            "a": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "foo" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("heading", "Baz" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "bar" as Any)
                ])] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign x = a | sort: 'title' %}{% for obj in x %}{% for i in obj %}({{ i[0] }},{{ i[1] }}){% endfor %}{% endfor %}", context: ctx)
        #expect(result == "(title,bar)(title,foo)(heading,Baz)")
    }

    @Test("filters, sort, array of strings", .timeLimit(.minutes(1)))
    func arrayOfStrings() async throws {
        let ctx: [String: Any] = [
            "a": ["b", "a", "C", "B", "A"]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | sort | join: '#' }}", context: ctx)
        #expect(result == "A#B#C#a#b")
    }

    @Test("filters, sort, empty array", .timeLimit(.minutes(1)))
    func emptyArray() async throws {
        let ctx: [String: Any] = [
            "a": [Any]()
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | sort | join: '#' }}", context: ctx)
        #expect(result == "")
    }

    @Test("filters, sort, incompatible types", .timeLimit(.minutes(1)))
    func incompatibleTypes() async throws {
        let ctx: [String: Any] = [
            "a": [[Any](), OrderedDictionary<String, Any>(), 1, "4"] as [Any]
        ] as [String: Any]
        do {
            _ = try await renderWithTimeout(template: "{{ a | sort }}", context: ctx)
            Issue.record("Expected error for \"filters, sort, incompatible types\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, sort, left value is not an array", .timeLimit(.minutes(1)))
    func leftValueIsNotAnArray() async throws {
        let ctx: [String: Any] = [
            "a": 123
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | sort | join: '#' }}", context: ctx)
        #expect(result == "123")
    }

    @Test("filters, sort, left value is undefined", .timeLimit(.minutes(1)))
    func leftValueIsUndefined() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | sort | join: '#' }}", context: [:])
        #expect(result == "")
    }

    @Test("filters, sort, sort a string", .timeLimit(.minutes(1)))
    func sortAString() async throws {
        let result = try await renderWithTimeout(template: "{{ 'BzAa4' | sort | join: '#' }}", context: [:])
        #expect(result == "BzAa4")
    }

    @Test("filters, sort, too many arguments", .timeLimit(.minutes(1)))
    func tooManyArguments() async throws {
        let ctx: [String: Any] = [
            "a": ["b", "a"]
        ] as [String: Any]
        do {
            _ = try await renderWithTimeout(template: "{{ a | sort: 'title', 'foo' | join: '#' }}", context: ctx)
            Issue.record("Expected error for \"filters, sort, too many arguments\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }
}
