//
//  MapTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: map", .serialized)
struct GoldenMapTests {

    @Test("filters, map, argument is explicit nil", .timeLimit(.minutes(1)))
    func argumentIsExplicitNil() async throws {
        let ctx: [String: Any] = [
            "a": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "foo" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "bar" as Any)
                ])] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign b = a | map: nil %}{% for x in b %}{% for y in x %}{{ y[0] }}:{{ y[1] }},{% endfor %}{% endfor %}", context: ctx)
        #expect(result == "")
    }

    @Test("filters, map, array containing a non object", .timeLimit(.minutes(1)))
    func arrayContainingANonObject() async throws {
        let ctx: [String: Any] = [
            "a": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "foo" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "bar" as Any)
                ]), 5, [Any]()] as [Any]
        ] as [String: Any]
        do {
            _ = try await renderWithTimeout(template: "{{ a | map: 'title' | join: '#' }}", context: ctx)
            Issue.record("Expected error for \"filters, map, array containing a non object\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, map, array of objects", .timeLimit(.minutes(1)))
    func arrayOfObjects() async throws {
        let ctx: [String: Any] = [
            "a": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "foo" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "bar" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "baz" as Any)
                ])] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | map: 'title' | join: '#' }}", context: ctx)
        #expect(result == "foo#bar#baz")
    }

    @Test("filters, map, input is a hash", .timeLimit(.minutes(1)))
    func inputIsAHash() async throws {
        let ctx: [String: Any] = [
            "a": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("title", "foo" as Any),
                ("some", "thing" as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | map: 'title' | join: '#' }}", context: ctx)
        #expect(result == "foo")
    }

    @Test("filters, map, left value not an array", .timeLimit(.minutes(1)))
    func leftValueNotAnArray() async throws {
        let ctx: [String: Any] = [
            "a": 123
        ] as [String: Any]
        do {
            _ = try await renderWithTimeout(template: "{{ a | map: 'title' | join: '#' }}", context: ctx)
            Issue.record("Expected error for \"filters, map, left value not an array\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, map, missing property", .timeLimit(.minutes(1)))
    func missingProperty() async throws {
        let ctx: [String: Any] = [
            "a": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "foo" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "bar" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("heading", "baz" as Any)
                ])] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | map: 'title' | join: '#' }}", context: ctx)
        #expect(result == "foo#bar#")
    }

    @Test("filters, map, nested arrays get flattened", .timeLimit(.minutes(1)))
    func nestedArraysGetFlattened() async throws {
        let ctx: [String: Any] = [
            "a": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "foo" as Any)
                ]), [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                        ("title", "bar" as Any)
                    ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                        ("title", "baz" as Any)
                    ])] as [Any]] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | map: 'title' | join: '#' }}", context: ctx)
        #expect(result == "foo#bar#baz")
    }

    @Test("filters, map, undefined argument", .timeLimit(.minutes(1)))
    func undefinedArgument() async throws {
        let ctx: [String: Any] = [
            "a": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "foo" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "bar" as Any)
                ])] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign b = a | map: nosuchthing %}{% for x in b %}{% for y in x %}{{ y[0] }}:{{ y[1] }},{% endfor %}{% endfor %}", context: ctx)
        #expect(result == "")
    }
}
