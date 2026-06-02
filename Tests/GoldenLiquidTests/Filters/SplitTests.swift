//
//  SplitTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: split", .serialized)
struct GoldenSplitTests {

    @Test("filters, split, argument does not appear in string", .timeLimit(.minutes(1)))
    func argumentDoesNotAppearInString() async throws {
        let result = try await renderWithTimeout(template: "{% assign a = \"abc\" | split: \",\" %}{% for i in a %}#{{ forloop.index0 }}{{ i }}{% endfor %}", context: [:])
        #expect(result == "#0abc")
    }

    @Test("filters, split, argument is a newline", .timeLimit(.minutes(1)))
    func argumentIsANewline() async throws {
        let ctx: [String: Any] = [
            "x": "\n"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign a = \"a b\nc\" | split: x %}{% for i in a %}#{{ forloop.index0 }}{{ i }}{% endfor %}", context: ctx)
        #expect(result == "#0a b#1c")
    }

    @Test("filters, split, argument is a single space", .timeLimit(.minutes(1)))
    func argumentIsASingleSpace() async throws {
        let result = try await renderWithTimeout(template: "{% assign a = \"a b\nc\" | split: \" \" %}{% for i in a %}#{{ forloop.index0 }}{{ i }}{% endfor %}", context: [:])
        #expect(result == "#0a#1b#2c")
    }

    @Test("filters, split, argument is false", .timeLimit(.minutes(1)))
    func argumentIsFalse() async throws {
        let result = try await renderWithTimeout(template: "{{ \"Hello there\" | split: false | join: \"#\" }}", context: [:])
        #expect(result == "Hello there")
    }

    @Test("filters, split, argument is nil", .timeLimit(.minutes(1)))
    func argumentIsNil() async throws {
        let result = try await renderWithTimeout(template: "{{ \"Hello there\" | split: nil | join: \"#\" }}", context: [:])
        #expect(result == "H#e#l#l#o# #t#h#e#r#e")
    }

    @Test("filters, split, argument not a string", .timeLimit(.minutes(1)))
    func argumentNotAString() async throws {
        let result = try await renderWithTimeout(template: "{{ \"hello th1ere\" | split: 1 | join: \"#\" }}", context: [:])
        #expect(result == "hello th#ere")
    }

    @Test("filters, split, empty string and empty argument", .timeLimit(.minutes(1)))
    func emptyStringAndEmptyArgument() async throws {
        let result = try await renderWithTimeout(template: "{% assign a = \"\" | split: \"\" %}{% for i in a %}{{ forloop.index0 }}{{ i }}{% endfor %}", context: [:])
        #expect(result == "")
    }

    @Test("filters, split, empty string and single char argument", .timeLimit(.minutes(1)))
    func emptyStringAndSingleCharArgument() async throws {
        let result = try await renderWithTimeout(template: "{% assign a = \"\" | split: \",\" %}{% for i in a %}{{ forloop.index0 }}{{ i }}{% endfor %}", context: [:])
        #expect(result == "")
    }

    @Test("filters, split, empty string argument", .timeLimit(.minutes(1)))
    func emptyStringArgument() async throws {
        let result = try await renderWithTimeout(template: "{% assign a = \"abc\" | split: \"\" %}{% for i in a %}#{{ forloop.index0 }}{{ i }}{% endfor %}", context: [:])
        #expect(result == "#0a#1b#2c")
    }

    @Test("filters, split, left matches argument", .timeLimit(.minutes(1)))
    func leftMatchesArgument() async throws {
        let result = try await renderWithTimeout(template: "{% assign a = \",\" | split: \",\" %}{% for i in a %}{{ forloop.index0 }}{{ i }}{% endfor %}", context: [:])
        #expect(result == "")
    }

    @Test("filters, split, left matches string repr of argument", .timeLimit(.minutes(1)))
    func leftMatchesStringReprOfArgument() async throws {
        let result = try await renderWithTimeout(template: "{% assign a = \"1\" | split: 1 %}{% for i in a %}{{ forloop.index0 }}{{ i }}{% endfor %}", context: [:])
        #expect(result == "")
    }

    @Test("filters, split, missing argument", .timeLimit(.minutes(1)))
    func missingArgument() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ \"hello there\" | split }}", context: [:])
            Issue.record("Expected error for \"filters, split, missing argument\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, split, not a string", .timeLimit(.minutes(1)))
    func notAString() async throws {
        let result = try await renderWithTimeout(template: "{{ 56 | split: ' ' | first }}", context: [:])
        #expect(result == "56")
    }

    @Test("filters, split, split string", .timeLimit(.minutes(1)))
    func splitString() async throws {
        let result = try await renderWithTimeout(template: "{{ \"Hi, how are you today?\" | split: \" \" | join: \"#\" }}", context: [:])
        #expect(result == "Hi,#how#are#you#today?")
    }

    @Test("filters, split, too many arguments", .timeLimit(.minutes(1)))
    func tooManyArguments() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ \"hello there\" | split: \" \", \",\" }}", context: [:])
            Issue.record("Expected error for \"filters, split, too many arguments\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, split, undefined argument", .timeLimit(.minutes(1)))
    func undefinedArgument() async throws {
        let result = try await renderWithTimeout(template: "{{ \"Hello there\" | split: nosuchthing | join: \"#\" }}", context: [:])
        #expect(result == "H#e#l#l#o# #t#h#e#r#e")
    }

    @Test("filters, split, undefined left value", .timeLimit(.minutes(1)))
    func undefinedLeftValue() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | split: \" \" }}", context: [:])
        #expect(result == "")
    }
}
