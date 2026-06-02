//
//  WhereTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: where", .serialized)
struct GoldenWhereTests {

    @Test("filters, where, array of hashes", .timeLimit(.minutes(1)))
    func arrayOfHashes() async throws {
        let ctx: [String: Any] = [
            "a": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "foo" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "bar" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", NSNull() as Any)
                ])] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign x = a | where: 'title' %}{% for obj in x %}{% for i in obj %}({{ i[0] }},{{ i[1] }}){% endfor %}{% endfor %}", context: ctx)
        #expect(result == "(title,foo)(title,bar)")
    }

    @Test("filters, where, array of hashes with a missing key", .timeLimit(.minutes(1)))
    func arrayOfHashesWithAMissingKey() async throws {
        let ctx: [String: Any] = [
            "a": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("heading", "foo" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "bar" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", NSNull() as Any)
                ])] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign x = a | where: 'title', 'bar' %}{% for obj in x %}{% for i in obj %}({{ i[0] }},{{ i[1] }}){% endfor %}{% endfor %}", context: ctx)
        #expect(result == "(title,bar)")
    }

    @Test("filters, where, array of hashes with equality test", .timeLimit(.minutes(1)))
    func arrayOfHashesWithEqualityTest() async throws {
        let ctx: [String: Any] = [
            "a": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "foo" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "bar" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", NSNull() as Any)
                ])] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign x = a | where: 'title', 'bar' %}{% for obj in x %}{% for i in obj %}({{ i[0] }},{{ i[1] }}){% endfor %}{% endfor %}", context: ctx)
        #expect(result == "(title,bar)")
    }

    @Test("filters, where, both arguments are undefined", .timeLimit(.minutes(1)))
    func bothArgumentsAreUndefined() async throws {
        let ctx: [String: Any] = [
            "a": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "foo" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "bar" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", NSNull() as Any)
                ])] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | where: nosuchthing, nothing }}", context: ctx)
        #expect(result == "")
    }

    @Test("filters, where, first argument is undefined", .timeLimit(.minutes(1)))
    func firstArgumentIsUndefined() async throws {
        let ctx: [String: Any] = [
            "a": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "foo" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "bar" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", NSNull() as Any)
                ])] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | where: nosuchthing }}", context: ctx)
        #expect(result == "")
    }

    @Test("filters, where, left value is not an array", .timeLimit(.minutes(1)))
    func leftValueIsNotAnArray() async throws {
        let ctx: [String: Any] = [
            "a": 123
        ] as [String: Any]
        do {
            _ = try await renderWithTimeout(template: "{{ a | where: 'title' }}", context: ctx)
            Issue.record("Expected error for \"filters, where, left value is not an array\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, where, left value is undefined", .timeLimit(.minutes(1)))
    func leftValueIsUndefined() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | where: 'title' }}", context: [:])
        #expect(result == "")
    }

    @Test("filters, where, missing argument", .timeLimit(.minutes(1)))
    func missingArgument() async throws {
        let ctx: [String: Any] = [
            "a": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "foo" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "bar" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", NSNull() as Any)
                ])] as [Any]
        ] as [String: Any]
        do {
            _ = try await renderWithTimeout(template: "{{ a | where }}", context: ctx)
            Issue.record("Expected error for \"filters, where, missing argument\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, where, second argument is undefined", .timeLimit(.minutes(1)))
    func secondArgumentIsUndefined() async throws {
        let ctx: [String: Any] = [
            "a": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "foo" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "bar" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", NSNull() as Any)
                ])] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign x = a | where: 'title', nosuchthing %}{% for obj in x %}{% for i in obj %}({{ i[0] }},{{ i[1] }}){% endfor %}{% endfor %}", context: ctx)
        #expect(result == "(title,foo)(title,bar)")
    }

    @Test("filters, where, too many arguments", .timeLimit(.minutes(1)))
    func tooManyArguments() async throws {
        let ctx: [String: Any] = [
            "a": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "foo" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "bar" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", NSNull() as Any)
                ])] as [Any]
        ] as [String: Any]
        do {
            _ = try await renderWithTimeout(template: "{{ a | where: 'title', 'foo', 'bar' }}", context: ctx)
            Issue.record("Expected error for \"filters, where, too many arguments\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, where, value is explicit nil", .timeLimit(.minutes(1)))
    func valueIsExplicitNil() async throws {
        let ctx: [String: Any] = [
            "a": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("b", false as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("b", "bar" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("b", NSNull() as Any)
                ])] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign x =  a | where: 'b', nil %}{% for obj in x %}{% for i in obj %}({{ i[0] }},{{ i[1] }}){% endfor %}{% endfor %}", context: ctx)
        #expect(result == "(b,bar)")
    }

    @Test("filters, where, value is false", .timeLimit(.minutes(1)))
    func valueIsFalse() async throws {
        let ctx: [String: Any] = [
            "a": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("b", false as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("b", "bar" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("b", NSNull() as Any)
                ])] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign x =  a | where: 'b', false %}{% for obj in x %}{% for i in obj %}({{ i[0] }},{{ i[1] }}){% endfor %}{% endfor %}", context: ctx)
        #expect(result == "(b,false)")
    }
}
