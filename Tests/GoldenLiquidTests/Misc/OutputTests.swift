//
//  OutputTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: output", .serialized)
struct GoldenOutputTests {

    @Test("output, access an array item by index", .timeLimit(.minutes(1)))
    func accessAnArrayItemByIndex() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("tags", ["sports", "garden"] as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ product.tags[1] }}", context: ctx)
        #expect(result == "garden")
    }

    @Test("output, access an array item by negative index", .timeLimit(.minutes(1)))
    func accessAnArrayItemByNegativeIndex() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("tags", ["sports", "garden"] as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ product.tags[-2] }}", context: ctx)
        #expect(result == "sports")
    }

    @Test("output, access an undefined variable by index", .timeLimit(.minutes(1)))
    func accessAnUndefinedVariableByIndex() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing[0] }}", context: [:])
        #expect(result == "")
    }

    @Test("output, access array item by index stored in a local variable", .timeLimit(.minutes(1)))
    func accessArrayItemByIndexStoredInALocalVariable() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("tags", ["sports", "garden"] as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign i = 1 %}{{ product.tags[i] }}", context: ctx)
        #expect(result == "garden")
    }

    @Test("output, array index out of bounds", .timeLimit(.minutes(1)))
    func arrayIndexOutOfBounds() async throws {
        let ctx: [String: Any] = [
            "a": [1, 2, 3]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a[3] }}", context: ctx)
        #expect(result == "")
    }

    @Test("output, assign a variable the value of an existing variable", .timeLimit(.minutes(1)))
    func assignAVariableTheValueOfAnExistingVariable() async throws {
        let result = try await renderWithTimeout(template: "{% capture some %}hello{% endcapture %}{% assign other = some %}{% assign some = 'foo' %}{{ some }}-{{ other }}", context: [:])
        #expect(result == "foo-hello")
    }

    @Test("output, bracketed variable resolves to a string", .timeLimit(.minutes(1)))
    func bracketedVariableResolvesToAString() async throws {
        let ctx: [String: Any] = [
            "foo": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("hello", "goodbye" as Any)
            ]),
            "something": "hello"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ foo[something] }}", context: ctx)
        #expect(result == "goodbye")
    }

    @Test("output, bracketed variable resolves to a string without leading identifier", .timeLimit(.minutes(1)))
    func bracketedVariableResolvesToAStringWithoutLeadingIdentifier() async throws {
        let ctx: [String: Any] = [
            "something": "hello",
            "hello": "goodbye"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ [something] }}", context: ctx)
        #expect(result == "goodbye")
    }

    @Test("output, chained bracketed identifier index", .timeLimit(.minutes(1)))
    func chainedBracketedIdentifierIndex() async throws {
        let ctx: [String: Any] = [
            "products": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "shoe" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "hat" as Any)
                ])] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ products[0].title }}", context: ctx)
        #expect(result == "shoe")
    }

    @Test("output, chained bracketed identifier index no dot", .timeLimit(.minutes(1)))
    func chainedBracketedIdentifierIndexNoDot() async throws {
        let ctx: [String: Any] = [
            "products": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "shoe" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "hat" as Any)
                ])] as [Any]
        ] as [String: Any]
        do {
            _ = try await renderWithTimeout(template: "{{ products[0]title }}", context: ctx)
            Issue.record("Expected error for \"output, chained bracketed identifier index no dot\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("output, chained identifier dot separated index", .timeLimit(.minutes(1)))
    func chainedIdentifierDotSeparatedIndex() async throws {
        let ctx: [String: Any] = [
            "products": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "shoe" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "hat" as Any)
                ])] as [Any]
        ] as [String: Any]
        do {
            _ = try await renderWithTimeout(template: "{{ products.0.title }}", context: ctx)
            Issue.record("Expected error for \"output, chained identifier dot separated index\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("output, dot followed by bracket", .timeLimit(.minutes(1)))
    func dotFollowedByBracket() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("title", "shoe" as Any)
            ])
        ] as [String: Any]
        do {
            _ = try await renderWithTimeout(template: "{{ product.['title'] }}", context: ctx)
            Issue.record("Expected error for \"output, dot followed by bracket\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("output, double dot", .timeLimit(.minutes(1)))
    func doubleDot() async throws {
        let ctx: [String: Any] = [
            "foo": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("bar", 42 as Any)
            ])
        ] as [String: Any]
        do {
            _ = try await renderWithTimeout(template: "{{ foo..bar }}", context: ctx)
            Issue.record("Expected error for \"output, double dot\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("output, dump an array from the global context", .timeLimit(.minutes(1)))
    func dumpAnArrayFromTheGlobalContext() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("tags", ["sports", "garden"] as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ product.tags | join: '#' }}", context: ctx)
        #expect(result == "sports#garden")
    }

    @Test("output, negative array index out of bounds", .timeLimit(.minutes(1)))
    func negativeArrayIndexOutOfBounds() async throws {
        let ctx: [String: Any] = [
            "a": [1, 2, 3]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a[-4] }}", context: ctx)
        #expect(result == "")
    }

    @Test("output, nested bracketed variable resolving to a string", .timeLimit(.minutes(1)))
    func nestedBracketedVariableResolvingToAString() async throws {
        let ctx: [String: Any] = [
            "list": ["foo"],
            "settings": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("zero", 0 as Any)
            ]),
            "foo": "bar"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ [list[settings.zero]] }}", context: ctx)
        #expect(result == "bar")
    }

    @Test("output, quoted, bracketed variable name", .timeLimit(.minutes(1)))
    func bracketedVariableName() async throws {
        let ctx: [String: Any] = [
            "foo": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("bar", 42 as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ foo['bar'] }}", context: ctx)
        #expect(result == "42")
    }

    @Test("output, quoted, bracketed variable name with whitespace", .timeLimit(.minutes(1)))
    func bracketedVariableNameWithWhitespace() async throws {
        let ctx: [String: Any] = [
            "foo": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("bar baz", 42 as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ foo['bar baz'] }}", context: ctx)
        #expect(result == "42")
    }

    @Test("output, render a default given a literal false", .timeLimit(.minutes(1)))
    func renderADefaultGivenALiteralFalse() async throws {
        let result = try await renderWithTimeout(template: "{{ false | default: 'bar' }}", context: [:])
        #expect(result == "bar")
    }

    @Test("output, render a default given a literal false with 'allow false' equal to false", .timeLimit(.minutes(1)))
    func renderADefaultGivenALiteralFalseWithAllowFalseEqualToFalse() async throws {
        let result = try await renderWithTimeout(template: "{{ false | default: 'bar', allow_false: false }}", context: [:])
        #expect(result == "bar")
    }

    @Test("output, render a default given a literal false with 'allow false' equal to true", .timeLimit(.minutes(1)))
    func renderADefaultGivenALiteralFalseWithAllowFalseEqualToTrue() async throws {
        let result = try await renderWithTimeout(template: "{{ false | default: 'bar', allow_false: true }}", context: [:])
        #expect(result == "false")
    }

    @Test("output, render a float literal", .timeLimit(.minutes(1)))
    func renderAFloatLiteral() async throws {
        let result = try await renderWithTimeout(template: "{{ 1.23 }}", context: [:])
        #expect(result == "1.23")
    }

    @Test("output, render a global variable with a filter", .timeLimit(.minutes(1)))
    func renderAGlobalVariableWithAFilter() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("title", "foo" as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ product.title | upcase }}", context: ctx)
        #expect(result == "FOO")
    }

    @Test("output, render a negative integer literal", .timeLimit(.minutes(1)))
    func renderANegativeIntegerLiteral() async throws {
        let result = try await renderWithTimeout(template: "{{ -123 }}", context: [:])
        #expect(result == "-123")
    }

    @Test("output, render a range object", .timeLimit(.minutes(1)))
    func renderARangeObject() async throws {
        let result = try await renderWithTimeout(template: "{{ (1..5) | join: '#' }}", context: [:])
        #expect(result == "1#2#3#4#5")
    }

    @Test("output, render a range object that uses a float", .timeLimit(.minutes(1)))
    func renderARangeObjectThatUsesAFloat() async throws {
        let result = try await renderWithTimeout(template: "{{ (1.4..5) | join: '#' }}", context: [:])
        #expect(result == "1#2#3#4#5")
    }

    @Test("output, render a range object that uses an identifier", .timeLimit(.minutes(1)))
    func renderARangeObjectThatUsesAnIdentifier() async throws {
        let ctx: [String: Any] = [
            "foo": 2
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ (foo..5) | join: '#' }}", context: ctx)
        #expect(result == "2#3#4#5")
    }

    @Test("output, render a string literal", .timeLimit(.minutes(1)))
    func renderAStringLiteral() async throws {
        let result = try await renderWithTimeout(template: "{{ 'hello' }}", context: [:])
        #expect(result == "hello")
    }

    @Test("output, render a variable from the global namespace", .timeLimit(.minutes(1)))
    func renderAVariableFromTheGlobalNamespace() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("title", "foo" as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ product.title }}", context: ctx)
        #expect(result == "foo")
    }

    @Test("output, render a variable from the local namespace", .timeLimit(.minutes(1)))
    func renderAVariableFromTheLocalNamespace() async throws {
        let result = try await renderWithTimeout(template: "{% assign name = 'Brian' %}{{ name }}", context: [:])
        #expect(result == "Brian")
    }

    @Test("output, render an integer literal", .timeLimit(.minutes(1)))
    func renderAnIntegerLiteral() async throws {
        let result = try await renderWithTimeout(template: "{{ 123 }}", context: [:])
        #expect(result == "123")
    }

    @Test("output, render an output start sequence as a string literal", .timeLimit(.minutes(1)))
    func renderAnOutputStartSequenceAsAStringLiteral() async throws {
        let result = try await renderWithTimeout(template: "{{ '{{' }}", context: [:])
        #expect(result == "{{")
    }

    @Test("output, render an undefined property", .timeLimit(.minutes(1)))
    func renderAnUndefinedProperty() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("title", "foo" as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ product.age }}", context: ctx)
        #expect(result == "")
    }

    @Test("output, render an undefined variable", .timeLimit(.minutes(1)))
    func renderAnUndefinedVariable() async throws {
        let result = try await renderWithTimeout(template: "{{ age }}", context: [:])
        #expect(result == "")
    }

    @Test("output, render nil", .timeLimit(.minutes(1)))
    func renderNil() async throws {
        let result = try await renderWithTimeout(template: "{{ nil }}", context: [:])
        #expect(result == "")
    }

    @Test("output, reverse a range", .timeLimit(.minutes(1)))
    func reverseARange() async throws {
        let ctx: [String: Any] = [
            "foo": 2
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ (foo..5) | reverse | join: '#' }}", context: ctx)
        #expect(result == "5#4#3#2")
    }

    @Test("output, top-level quoted, bracketed variable name with whitespace", .timeLimit(.minutes(1)))
    func bracketedVariableNameWithWhitespace2() async throws {
        let ctx: [String: Any] = [
            "bar baz": 42
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ ['bar baz'] }}", context: ctx)
        #expect(result == "42")
    }

    @Test("output, top-level quoted, bracketed variable name with whitespace followed by dot notation", .timeLimit(.minutes(1)))
    func bracketedVariableNameWithWhitespaceFollowedByDotNotation() async throws {
        let ctx: [String: Any] = [
            "bar baz": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("qux", 42 as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ ['bar baz'].qux }}", context: ctx)
        #expect(result == "42")
    }

    @Test("output, traverse variables with bracketed identifiers", .timeLimit(.minutes(1)))
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
        let result = try await renderWithTimeout(template: "{{ site.data.menu[include.menu][include.locale] }}", context: ctx)
        #expect(result == "it works!")
    }

    @Test("output, unexpected left value for the `join` filter passes through", .timeLimit(.minutes(1)))
    func unexpectedLeftValueForTheJoinFilterPassesThrough() async throws {
        let result = try await renderWithTimeout(template: "{{ 12 | join: '#' }}", context: [:])
        #expect(result == "12")
    }

    @Test("output, whitespace between bracket notation", .timeLimit(.minutes(1)))
    func whitespaceBetweenBracketNotation() async throws {
        let ctx: [String: Any] = [
            "foo": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("bar", 42 as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ ['foo'] \n\t['bar'] }}", context: ctx)
        #expect(result == "42")
    }

    @Test("output, whitespace between dot and word", .timeLimit(.minutes(1)))
    func whitespaceBetweenDotAndWord() async throws {
        let ctx: [String: Any] = [
            "foo": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("bar", 42 as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ foo. \n\tbar }}", context: ctx)
        #expect(result == "42")
    }

    @Test("output, whitespace between word and dot", .timeLimit(.minutes(1)))
    func whitespaceBetweenWordAndDot() async throws {
        let ctx: [String: Any] = [
            "foo": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("bar", 42 as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ foo \n\t.bar }}", context: ctx)
        #expect(result == "42")
    }

    @Test("output, whitespace between words", .timeLimit(.minutes(1)))
    func whitespaceBetweenWords() async throws {
        let ctx: [String: Any] = [
            "foo": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("bar", 42 as Any)
            ])
        ] as [String: Any]
        do {
            _ = try await renderWithTimeout(template: "{{ foo \n\tbar }}", context: ctx)
            Issue.record("Expected error for \"output, whitespace between words\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }
}
