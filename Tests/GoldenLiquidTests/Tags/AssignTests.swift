//
//  AssignTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: assign", .serialized)
struct GoldenAssignTests {

    @Test("tags, assign, assign a filtered literal", .timeLimit(.minutes(1)))
    func assignAFilteredLiteral() async throws {
        let result = try await renderWithTimeout(template: "{% assign foo = 'foo' | upcase %}{{ foo }}", context: [:])
        #expect(result == "FOO")
    }

    @Test("tags, assign, assign a range literal", .timeLimit(.minutes(1)))
    func assignARangeLiteral() async throws {
        let result = try await renderWithTimeout(template: "{% assign foo = (1..3) %}{{ foo | join: '#' }}", context: [:])
        #expect(result == "1#2#3")
    }

    @Test("tags, assign, assign an existing array", .timeLimit(.minutes(1)))
    func assignAnExistingArray() async throws {
        let ctx: [String: Any] = [
            "bar": ["a", "b", "c"]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign foo = bar %}{{ foo[0] }}/{{ foo[1] }}", context: ctx)
        #expect(result == "a/b")
    }

    @Test("tags, assign, assign an item from an existing object with quoted notation", .timeLimit(.minutes(1)))
    func assignAnItemFromAnExistingObjectWithQuotedNotation() async throws {
        let ctx: [String: Any] = [
            "bar": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("baz", "hello" as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign foo = bar['baz'] %}{{ foo }}", context: ctx)
        #expect(result == "hello")
    }

    @Test("tags, assign, assign to variable with a hyphen", .timeLimit(.minutes(1)))
    func assignToVariableWithAHyphen() async throws {
        let result = try await renderWithTimeout(template: "{% assign some-thing = 'foo' %}{{ some-thing }}", context: [:])
        #expect(result == "foo")
    }

    @Test("tags, assign, assign with quoted notation and extra whitespace", .timeLimit(.minutes(1)))
    func assignWithQuotedNotationAndExtraWhitespace() async throws {
        let ctx: [String: Any] = [
            "bar": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("baz", "hello" as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign foo = bar[ 'baz'  ] %}{{ foo }}", context: ctx)
        #expect(result == "hello")
    }

    @Test("tags, assign, local variables shadow global variables", .timeLimit(.minutes(1)))
    func localVariablesShadowGlobalVariables() async throws {
        let ctx: [String: Any] = [
            "foo": "bar"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ foo }}{% assign foo = 'foo' | upcase %}{{ foo }}", context: ctx)
        #expect(result == "barFOO")
    }
}
