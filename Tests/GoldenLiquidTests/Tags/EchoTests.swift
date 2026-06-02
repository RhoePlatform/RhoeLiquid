//
//  EchoTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: echo", .serialized)
struct GoldenEchoTests {

    @Test("tags, echo, access an array item by index", .timeLimit(.minutes(1)))
    func accessAnArrayItemByIndex() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("tags", ["sports", "garden"] as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% echo product.tags[1] %}", context: ctx)
        #expect(result == "garden")
    }

    @Test("tags, echo, access an array item by negative index", .timeLimit(.minutes(1)))
    func accessAnArrayItemByNegativeIndex() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("tags", ["sports", "garden"] as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% echo product.tags[-2] %}", context: ctx)
        #expect(result == "sports")
    }

    @Test("tags, echo, access an undefined variable by index", .timeLimit(.minutes(1)))
    func accessAnUndefinedVariableByIndex() async throws {
        let result = try await renderWithTimeout(template: "{% echo nosuchthing[0] %}", context: [:])
        #expect(result == "")
    }

    @Test("tags, echo, access array item by index stored in a local variable", .timeLimit(.minutes(1)))
    func accessArrayItemByIndexStoredInALocalVariable() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("tags", ["sports", "garden"] as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign i = 1 %}{% echo product.tags[i] %}", context: ctx)
        #expect(result == "garden")
    }

    @Test("tags, echo, assign a variable the value of an existing variable", .timeLimit(.minutes(1)))
    func assignAVariableTheValueOfAnExistingVariable() async throws {
        let result = try await renderWithTimeout(template: "{% capture some %}hello{% endcapture %}{% assign other = some %}{% assign some = 'foo' %}{% echo some %}-{% echo other %}", context: [:])
        #expect(result == "foo-hello")
    }

    @Test("tags, echo, dump an array from the global context", .timeLimit(.minutes(1)))
    func dumpAnArrayFromTheGlobalContext() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("tags", ["sports", "garden"] as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% echo product.tags %}", context: ctx)
        #expect(result == "sportsgarden")
    }

    @Test("tags, echo, nothing to echo", .timeLimit(.minutes(1)))
    func nothingToEcho() async throws {
        let result = try await renderWithTimeout(template: "{% echo %}", context: [:])
        #expect(result == "")
    }

    @Test("tags, echo, render a float literal", .timeLimit(.minutes(1)))
    func renderAFloatLiteral() async throws {
        let result = try await renderWithTimeout(template: "{% echo 1.23 %}", context: [:])
        #expect(result == "1.23")
    }

    @Test("tags, echo, render a global identifier with a filter", .timeLimit(.minutes(1)))
    func renderAGlobalIdentifierWithAFilter() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("title", "foo" as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% echo product.title | upcase %}", context: ctx)
        #expect(result == "FOO")
    }

    @Test("tags, echo, render a string literal", .timeLimit(.minutes(1)))
    func renderAStringLiteral() async throws {
        let result = try await renderWithTimeout(template: "{% echo 'hello' %}", context: [:])
        #expect(result == "hello")
    }

    @Test("tags, echo, render a variable from the global namespace", .timeLimit(.minutes(1)))
    func renderAVariableFromTheGlobalNamespace() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("title", "foo" as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% echo product.title %}", context: ctx)
        #expect(result == "foo")
    }

    @Test("tags, echo, render a variable from the local namespace", .timeLimit(.minutes(1)))
    func renderAVariableFromTheLocalNamespace() async throws {
        let result = try await renderWithTimeout(template: "{% assign name = 'Brian' %}{% echo name %}", context: [:])
        #expect(result == "Brian")
    }

    @Test("tags, echo, render an integer literal", .timeLimit(.minutes(1)))
    func renderAnIntegerLiteral() async throws {
        let result = try await renderWithTimeout(template: "{% echo 123 %}", context: [:])
        #expect(result == "123")
    }

    @Test("tags, echo, render an undefined property", .timeLimit(.minutes(1)))
    func renderAnUndefinedProperty() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("title", "foo" as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% echo product.age %}", context: ctx)
        #expect(result == "")
    }

    @Test("tags, echo, render an undefined variable", .timeLimit(.minutes(1)))
    func renderAnUndefinedVariable() async throws {
        let result = try await renderWithTimeout(template: "{% echo age %}", context: [:])
        #expect(result == "")
    }

    @Test("tags, echo, traverse variables with bracketed identifiers", .timeLimit(.minutes(1)))
    func traverseVariablesWithBracketedIdentifiers() async throws {
        let ctx: [String: Any] = [
            "site": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("data", OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("menu", OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                        ("foo", OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                            ("bar", "it works!" as Any)
                        ]) as Any)
                    ]) as Any)
                ]) as Any)
            ]),
            "include": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("menu", "foo" as Any),
                ("locale", "bar" as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% echo site.data.menu[include.menu][include.locale] %}", context: ctx)
        #expect(result == "it works!")
    }
}
