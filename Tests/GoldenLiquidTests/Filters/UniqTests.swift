//
//  UniqTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: uniq", .serialized)
struct GoldenUniqTests {

    @Test("filters, uniq, array of objects with key property", .timeLimit(.minutes(1)))
    func arrayOfObjectsWithKeyProperty() async throws {
        let ctx: [String: Any] = [
            "a": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "foo" as Any),
                    ("name", "a" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "foo" as Any),
                    ("name", "b" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "bar" as Any),
                    ("name", "c" as Any)
                ])] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign x = a | uniq: 'title' %}{% for obj in x %}{% for i in obj %}({{ i[0] }},{{ i[1] }}){% endfor %}{% endfor %}", context: ctx)
        #expect(result == "(title,foo)(name,a)(title,bar)(name,c)")
    }

    @Test("filters, uniq, array of objects with missing key property", .timeLimit(.minutes(1)))
    func arrayOfObjectsWithMissingKeyProperty() async throws {
        let ctx: [String: Any] = [
            "a": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "foo" as Any),
                    ("name", "a" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "foo" as Any),
                    ("name", "b" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "bar" as Any),
                    ("name", "c" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("heading", "bar" as Any),
                    ("name", "c" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("heading", "baz" as Any),
                    ("name", "d" as Any)
                ])] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign x = a | uniq: 'title' %}{% for obj in x %}{% for i in obj %}({{ i[0] }},{{ i[1] }}){% endfor %}{% endfor %}", context: ctx)
        #expect(result == "(title,foo)(name,a)(title,bar)(name,c)(heading,bar)(name,c)")
    }

    @Test("filters, uniq, array of strings", .timeLimit(.minutes(1)))
    func arrayOfStrings() async throws {
        let ctx: [String: Any] = [
            "a": ["a", "b", "b", "a"]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | uniq | join: '#' }}", context: ctx)
        #expect(result == "a#b")
    }

    @Test("filters, uniq, array of things", .timeLimit(.minutes(1)))
    func arrayOfThings() async throws {
        let ctx: [String: Any] = [
            "a": ["a", "b", 1, 1] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | uniq | join: '#' }}", context: ctx)
        #expect(result == "a#b#1")
    }

    @Test("filters, uniq, empty array", .timeLimit(.minutes(1)))
    func emptyArray() async throws {
        let ctx: [String: Any] = [
            "a": [Any]()
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | uniq | join: '#' }}", context: ctx)
        #expect(result == "")
    }

    @Test("filters, uniq, left value is not an array", .timeLimit(.minutes(1)))
    func leftValueIsNotAnArray() async throws {
        let ctx: [String: Any] = [
            "a": 123
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | uniq | join: '#' }}", context: ctx)
        #expect(result == "123")
    }

    @Test("filters, uniq, left value is undefined", .timeLimit(.minutes(1)))
    func leftValueIsUndefined() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | uniq | join: '#' }}", context: [:])
        #expect(result == "")
    }

    @Test("filters, uniq, too many arguments", .timeLimit(.minutes(1)))
    func tooManyArguments() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ nosuchthing | uniq: 'foo', 'bar' }}", context: [:])
            Issue.record("Expected error for \"filters, uniq, too many arguments\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, uniq, unhashable items", .timeLimit(.minutes(1)))
    func unhashableItems() async throws {
        let ctx: [String: Any] = [
            "a": ["a", "b", [Any](), OrderedDictionary<String, Any>(), OrderedDictionary<String, Any>()] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | uniq | join: '#' }}", context: ctx)
        #expect(result == "a#b#{}")
    }
}
