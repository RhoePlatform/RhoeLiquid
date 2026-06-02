//
//  DefaultTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: default", .serialized)
struct GoldenDefaultTests {

    @Test("filters, default, 0.0 is not falsy", .timeLimit(.minutes(1)))
    func test00isnotfalsy() async throws {
        let result = try await renderWithTimeout(template: "{{ 0.0 | default: \"bar\" }}", context: [:])
        #expect(result == "0.0")
    }

    @Test("filters, default, allow false", .timeLimit(.minutes(1)))
    func allowFalse() async throws {
        let result = try await renderWithTimeout(template: "{{ false | default: 'bar', allow_false:true }}", context: [:])
        #expect(result == "false")
    }

    @Test("filters, default, allow false from context", .timeLimit(.minutes(1)))
    func allowFalseFromContext() async throws {
        let ctx: [String: Any] = [
            "foo": true
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ false | default: 'bar', allow_false:foo }}", context: ctx)
        #expect(result == "false")
    }

    @Test("filters, default, empty", .timeLimit(.minutes(1)))
    func empty() async throws {
        let result = try await renderWithTimeout(template: "{{ empty | default: bar }}", context: [:])
        #expect(result == "")
    }

    @Test("filters, default, empty array", .timeLimit(.minutes(1)))
    func emptyArray() async throws {
        let ctx: [String: Any] = [
            "a": [Any]()
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | default: 'foo' }}", context: ctx)
        #expect(result == "foo")
    }

    @Test("filters, default, empty object", .timeLimit(.minutes(1)))
    func emptyObject() async throws {
        let ctx: [String: Any] = [
            "a": OrderedDictionary<String, Any>()
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | default: 'foo' }}", context: ctx)
        #expect(result == "foo")
    }

    @Test("filters, default, empty string", .timeLimit(.minutes(1)))
    func emptyString() async throws {
        let result = try await renderWithTimeout(template: "{{ \"\" | default: \"foo\" }}", context: [:])
        #expect(result == "foo")
    }

    @Test("filters, default, false", .timeLimit(.minutes(1)))
    func falseTest() async throws {
        let result = try await renderWithTimeout(template: "{{ False | default: 'foo' }}", context: [:])
        #expect(result == "foo")
    }

    @Test("filters, default, false keyword argument before positional", .timeLimit(.minutes(1)))
    func falseKeywordArgumentBeforePositional() async throws {
        let result = try await renderWithTimeout(template: "{{ false | default: allow_false: false, \"bar\" }}", context: [:])
        #expect(result == "bar")
    }

    @Test("filters, default, missing argument", .timeLimit(.minutes(1)))
    func missingArgument() async throws {
        let result = try await renderWithTimeout(template: "{{ false | default }}", context: [:])
        #expect(result == "")
    }

    @Test("filters, default, nil", .timeLimit(.minutes(1)))
    func nilTest() async throws {
        let result = try await renderWithTimeout(template: "{{ nil | default: 'foo' }}", context: [:])
        #expect(result == "foo")
    }

    @Test("filters, default, not empty list", .timeLimit(.minutes(1)))
    func notEmptyList() async throws {
        let ctx: [String: Any] = [
            "a": ["hello", "world"]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | default: \"foo\" | join: \"#\" }}", context: ctx)
        #expect(result == "hello#world")
    }

    @Test("filters, default, not empty object", .timeLimit(.minutes(1)))
    func notEmptyObject() async throws {
        let ctx: [String: Any] = [
            "a": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("greeting", "hello" as Any)
            ]),
            "foo": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("greeting", "goodbye" as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign b = a | default: foo %}{% for item in b %}({{ item[0] }},{{ item[1] }}){% endfor %}", context: ctx)
        #expect(result == "(greeting,hello)")
    }

    @Test("filters, default, not empty string", .timeLimit(.minutes(1)))
    func notEmptyString() async throws {
        let result = try await renderWithTimeout(template: "{{ \"hello\" | default: \"foo\" }}", context: [:])
        #expect(result == "hello")
    }

    @Test("filters, default, too many arguments", .timeLimit(.minutes(1)))
    func tooManyArguments() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ None | default: 'foo', 'bar', 'baz' }}", context: [:])
            Issue.record("Expected error for \"filters, default, too many arguments\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, default, true keyword argument before positional", .timeLimit(.minutes(1)))
    func trueKeywordArgumentBeforePositional() async throws {
        let result = try await renderWithTimeout(template: "{{ false | default: allow_false: true, \"bar\" }}", context: [:])
        #expect(result == "false")
    }

    @Test("filters, default, undefined left value", .timeLimit(.minutes(1)))
    func undefinedLeftValue() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | default: \"bar\" }}", context: [:])
        #expect(result == "bar")
    }

    @Test("filters, default, zero is not falsy", .timeLimit(.minutes(1)))
    func zeroIsNotFalsy() async throws {
        let result = try await renderWithTimeout(template: "{{ 0 | default: \"bar\" }}", context: [:])
        #expect(result == "0")
    }

    @Test("filters, default, zero is not falsy with allow_false", .timeLimit(.minutes(1)))
    func zeroIsNotFalsyWithAllowFalse() async throws {
        let result = try await renderWithTimeout(template: "{{ 0 | default: \"bar\", allow_false: true }}", context: [:])
        #expect(result == "0")
    }
}
