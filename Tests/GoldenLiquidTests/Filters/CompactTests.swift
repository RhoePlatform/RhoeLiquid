//
//  CompactTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: compact", .serialized)
struct GoldenCompactTests {

    @Test("filters, compact, array of objects with key property", .timeLimit(.minutes(1)))
    func arrayOfObjectsWithKeyProperty() async throws {
        let ctx: [String: Any] = [
            "a": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "foo" as Any),
                    ("name", "a" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", NSNull() as Any),
                    ("name", "b" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "bar" as Any),
                    ("name", "c" as Any)
                ])] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign x = a | compact: 'title' %}{% for obj in x %}{% for i in obj %}({{ i[0] }},{{ i[1] }}){% endfor %}{% endfor %}", context: ctx)
        #expect(result == "(title,foo)(name,a)(title,bar)(name,c)")
    }

    @Test("filters, compact, array with a nil", .timeLimit(.minutes(1)))
    func arrayWithANil() async throws {
        let ctx: [String: Any] = [
            "a": ["b", "a", NSNull(), "A"] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | compact | join: '#' }}", context: ctx)
        #expect(result == "b#a#A")
    }

    @Test("filters, compact, empty array", .timeLimit(.minutes(1)))
    func emptyArray() async throws {
        let ctx: [String: Any] = [
            "a": [Any]()
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | compact | join: '#' }}", context: ctx)
        #expect(result == "")
    }

    @Test("filters, compact, left value is not an array", .timeLimit(.minutes(1)))
    func leftValueIsNotAnArray() async throws {
        let ctx: [String: Any] = [
            "a": 123
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | compact | first }}", context: ctx)
        #expect(result == "123")
    }

    @Test("filters, compact, left value is undefined", .timeLimit(.minutes(1)))
    func leftValueIsUndefined() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | compact }}", context: [:])
        #expect(result == "")
    }

    @Test("filters, compact, too many arguments", .timeLimit(.minutes(1)))
    func tooManyArguments() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ a | compact: 'foo', 'bar' }}", context: [:])
            Issue.record("Expected error for \"filters, compact, too many arguments\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }
}
