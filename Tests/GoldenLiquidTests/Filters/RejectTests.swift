//
//  RejectTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: reject", .serialized)
struct GoldenRejectTests {

    @Test("filters, reject, array containing an int, default value", .timeLimit(.minutes(1)))
    func arrayContainingAnIntDefaultValue() async throws {
        let ctx: [String: Any] = [
            "a": ["x", "y", "cat", 1] as [Any]
        ] as [String: Any]
        do {
            _ = try await renderWithTimeout(template: "{{ a | reject: 'c' }}", context: ctx)
            Issue.record("Expected error for \"filters, reject, array containing an int, default value\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, reject, array containing null, default value", .timeLimit(.minutes(1)))
    func arrayContainingNullDefaultValue() async throws {
        let ctx: [String: Any] = [
            "a": ["x", "y", "cat", NSNull()] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | reject: 'c' }}", context: ctx)
        #expect(result == "")
    }

    @Test("filters, reject, array of hashes, default value", .timeLimit(.minutes(1)))
    func arrayOfHashesDefaultValue() async throws {
        let ctx: [String: Any] = [
            "a": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "foo" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", false as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", NSNull() as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("heading", "baz" as Any)
                ])] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign b = a | reject: 'title' %}{% for obj in b %}{% for itm in obj %}({{ itm[0] }},{{ itm[1] }}), {% endfor %}{% endfor %}", context: ctx)
        #expect(result == "(title,false), (title,), (heading,baz), ")
    }

    @Test("filters, reject, array of hashes, explicit false", .timeLimit(.minutes(1)))
    func arrayOfHashesExplicitFalse() async throws {
        let ctx: [String: Any] = [
            "a": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", false as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "bar" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", NSNull() as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("heading", "baz" as Any)
                ])] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign b = a | reject: 'title', false %}{% for obj in b %}{% for itm in obj %}({{ itm[0] }},{{ itm[1] }}), {% endfor %}{% endfor %}", context: ctx)
        #expect(result == "(title,bar), (title,), (heading,baz), ")
    }

    @Test("filters, reject, array of hashes, explicit nil", .timeLimit(.minutes(1)))
    func arrayOfHashesExplicitNil() async throws {
        let ctx: [String: Any] = [
            "a": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "foo" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", false as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", NSNull() as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("heading", "baz" as Any)
                ])] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign b = a | reject: 'title', nil %}{% for obj in b %}{% for itm in obj %}({{ itm[0] }},{{ itm[1] }}), {% endfor %}{% endfor %}", context: ctx)
        #expect(result == "(title,false), (title,), (heading,baz), ")
    }

    @Test("filters, reject, array of hashes, explicit true", .timeLimit(.minutes(1)))
    func arrayOfHashesExplicitTrue() async throws {
        let ctx: [String: Any] = [
            "a": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", true as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "bar" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", NSNull() as Any)
                ])] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign b = a | reject: 'title', true %}{% for obj in b %}{% for itm in obj %}({{ itm[0] }},{{ itm[1] }}), {% endfor %}{% endfor %}", context: ctx)
        #expect(result == "(title,bar), (title,), ")
    }

    @Test("filters, reject, array of hashes, missing property", .timeLimit(.minutes(1)))
    func arrayOfHashesMissingProperty() async throws {
        let ctx: [String: Any] = [
            "a": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("heading", "foo" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "bar" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", NSNull() as Any)
                ])] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign b = a | reject: 'title', 'bar' %}{% for obj in b %}{% for itm in obj %}({{ itm[0] }},{{ itm[1] }}), {% endfor %}{% endfor %}", context: ctx)
        #expect(result == "(heading,foo), (title,), ")
    }

    @Test("filters, reject, array of hashes, string value", .timeLimit(.minutes(1)))
    func arrayOfHashesStringValue() async throws {
        let ctx: [String: Any] = [
            "a": [OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "foo" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", "bar" as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("title", NSNull() as Any)
                ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                    ("heading", "baz" as Any)
                ])] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign b = a | reject: 'title', 'bar' %}{% for obj in b %}{% for itm in obj %}({{ itm[0] }},{{ itm[1] }}), {% endfor %}{% endfor %}", context: ctx)
        #expect(result == "(title,foo), (title,), (heading,baz), ")
    }

    @Test("filters, reject, array of strings, default value", .timeLimit(.minutes(1)))
    func arrayOfStringsDefaultValue() async throws {
        let ctx: [String: Any] = [
            "a": ["x", "y", "cat"]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign b = a | reject: 'c' %}{% for obj in b %}{{ obj }}, {% endfor %}", context: ctx)
        #expect(result == "x, y, ")
    }

    @Test("filters, reject, first argument is undefined", .timeLimit(.minutes(1)))
    func firstArgumentIsUndefined() async throws {
        let ctx: [String: Any] = [
            "a": ["x", "y", "cat"]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign b = a | reject: nosuchthing %}{% for obj in b %}{{ obj }}, {% endfor %}", context: ctx)
        #expect(result == "")
    }

    @Test("filters, reject, input is a hash, default value", .timeLimit(.minutes(1)))
    func inputIsAHashDefaultValue() async throws {
        let ctx: [String: Any] = [
            "h": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("foo", 1 as Any),
                ("bar", 2 as Any),
                ("baz", 3 as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign b = h | reject: 'bar' %}{% for obj in b %}{{ obj }}, {% endfor %}", context: ctx)
        #expect(result == "")
    }

    @Test("filters, reject, input is a hash, default value, nil match", .timeLimit(.minutes(1)))
    func inputIsAHashDefaultValueNilMatch() async throws {
        let ctx: [String: Any] = [
            "h": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("foo", 1 as Any),
                ("bar", NSNull() as Any),
                ("baz", 3 as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign b = h | reject: 'bar' %}{% for obj in b %}{% for itm in obj %}({{ itm[0] }},{{ itm[1] }}), {% endfor %}{% endfor %}", context: ctx)
        #expect(result == "(foo,1), (bar,), (baz,3), ")
    }

    @Test("filters, reject, input is a hash, default value, no match", .timeLimit(.minutes(1)))
    func inputIsAHashDefaultValueNoMatch() async throws {
        let ctx: [String: Any] = [
            "h": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("foo", 1 as Any),
                ("bar", 2 as Any),
                ("baz", 3 as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign b = h | reject: 'barbar' %}{% for obj in b %}{% for itm in obj %}({{ itm[0] }},{{ itm[1] }}), {% endfor %}{% endfor %}", context: ctx)
        #expect(result == "(foo,1), (bar,2), (baz,3), ")
    }

    @Test("filters, reject, input is a hash, explicit nil match", .timeLimit(.minutes(1)))
    func inputIsAHashExplicitNilMatch() async throws {
        let ctx: [String: Any] = [
            "h": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("foo", 1 as Any),
                ("bar", NSNull() as Any),
                ("baz", 3 as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign b = h | reject: 'bar', nil %}{% for obj in b %}{% for itm in obj %}({{ itm[0] }},{{ itm[1] }}), {% endfor %}{% endfor %}", context: ctx)
        #expect(result == "(foo,1), (bar,), (baz,3), ")
    }

    @Test("filters, reject, input is a hash, int value, match", .timeLimit(.minutes(1)))
    func inputIsAHashIntValueMatch() async throws {
        let ctx: [String: Any] = [
            "h": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("foo", 1 as Any),
                ("bar", 2 as Any),
                ("baz", 3 as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign b = h | reject: 'bar', 2 %}{% for obj in b %}{% for itm in obj %}({{ itm[0] }},{{ itm[1] }}), {% endfor %}{% endfor %}", context: ctx)
        #expect(result == "")
    }

    @Test("filters, reject, input is a hash, int value, no match", .timeLimit(.minutes(1)))
    func inputIsAHashIntValueNoMatch() async throws {
        let ctx: [String: Any] = [
            "h": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("foo", 1 as Any),
                ("bar", 2 as Any),
                ("baz", 3 as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign b = h | reject: 'bar', 1 %}{% for obj in b %}{% for itm in obj %}({{ itm[0] }},{{ itm[1] }}), {% endfor %}{% endfor %}", context: ctx)
        #expect(result == "(foo,1), (bar,2), (baz,3), ")
    }

    @Test("filters, reject, input is undefined", .timeLimit(.minutes(1)))
    func inputIsUndefined() async throws {
        let result = try await renderWithTimeout(template: "{% assign b = nosuchthing | reject: 'c' %}{% for obj in b %}{{ obj }}, {% endfor %}", context: [:])
        #expect(result == "")
    }

    @Test("filters, reject, missing argument", .timeLimit(.minutes(1)))
    func missingArgument() async throws {
        let ctx: [String: Any] = [
            "a": ["x", "y", "cat"]
        ] as [String: Any]
        do {
            _ = try await renderWithTimeout(template: "{% assign b = a | reject %}{% for obj in b %}{{ obj }}, {% endfor %}", context: ctx)
            Issue.record("Expected error for \"filters, reject, missing argument\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, reject, nested array of hashes gets flattened", .timeLimit(.minutes(1)))
    func nestedArrayOfHashesGetsFlattened() async throws {
        let ctx: [String: Any] = [
            "a": [[OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                        ("title", "foo" as Any)
                    ]), OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                        ("title", "bar" as Any)
                    ])] as [Any], [[OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                            ("title", NSNull() as Any)
                        ])] as [Any]] as [Any]] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign b = a | reject: 'title', 'bar' %}{% for obj in b %}{% for itm in obj %}({{ itm[0] }},{{ itm[1] }}), {% endfor %}{% endfor %}", context: ctx)
        #expect(result == "(title,foo), (title,), ")
    }

    @Test("filters, reject, second argument is undefined", .timeLimit(.minutes(1)))
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
        let result = try await renderWithTimeout(template: "{% assign b = a | reject: 'title', nosuchthing %}{% for obj in b %}{% for itm in obj %}({{ itm[0] }},{{ itm[1] }}), {% endfor %}{% endfor %}", context: ctx)
        #expect(result == "(title,), ")
    }

    @Test("filters, reject, string input becomes a single element array, no match", .timeLimit(.minutes(1)))
    func stringInputBecomesASingleElementArrayNoMatch() async throws {
        let ctx: [String: Any] = [
            "s": "foobar"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign b = s | reject: 'xx' %}{% for obj in b %}{{ obj }}, {% endfor %}", context: ctx)
        #expect(result == "foobar, ")
    }

    @Test("filters, reject, string input becomes a single element array, substring match", .timeLimit(.minutes(1)))
    func stringInputBecomesASingleElementArraySubstringMatch() async throws {
        let ctx: [String: Any] = [
            "s": "foobar"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign b = s | reject: 'oo' %}{% for obj in b %}{{ obj }}, {% endfor %}", context: ctx)
        #expect(result == "")
    }

    @Test("filters, reject, too many arguments", .timeLimit(.minutes(1)))
    func tooManyArguments() async throws {
        do {
            _ = try await renderWithTimeout(template: "{% assign b = a | reject: 'x', 'y', 'z' %}{% for obj in b %}{{ obj }}, {% endfor %}", context: [:])
            Issue.record("Expected error for \"filters, reject, too many arguments\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }
}
