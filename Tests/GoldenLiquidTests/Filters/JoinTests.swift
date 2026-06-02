//
//  JoinTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: join", .serialized)
struct GoldenJoinTests {

    @Test("filters, join, argument is not a string", .timeLimit(.minutes(1)))
    func argumentIsNotAString() async throws {
        let ctx: [String: Any] = [
            "arr": ["a", "b"]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ arr | join: 5 }}", context: ctx)
        #expect(result == "a5b")
    }

    @Test("filters, join, join an array of integers", .timeLimit(.minutes(1)))
    func joinAnArrayOfIntegers() async throws {
        let ctx: [String: Any] = [
            "arr": [1, 2]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ arr | join: '#' }}", context: ctx)
        #expect(result == "1#2")
    }

    @Test("filters, join, join an array of strings", .timeLimit(.minutes(1)))
    func joinAnArrayOfStrings() async throws {
        let ctx: [String: Any] = [
            "arr": ["a", "b"]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ arr | join: '#' }}", context: ctx)
        #expect(result == "a#b")
    }

    @Test("filters, join, joining a string is a noop", .timeLimit(.minutes(1)))
    func joiningAStringIsANoop() async throws {
        let result = try await renderWithTimeout(template: "{{ 'a,b' | join: '#' }}", context: [:])
        #expect(result == "a,b")
    }

    @Test("filters, join, joining an int is a noop", .timeLimit(.minutes(1)))
    func joiningAnIntIsANoop() async throws {
        let result = try await renderWithTimeout(template: "{{ 123 | join: '#' }}", context: [:])
        #expect(result == "123")
    }

    @Test("filters, join, left value contains non string", .timeLimit(.minutes(1)))
    func leftValueContainsNonString() async throws {
        let ctx: [String: Any] = [
            "arr": ["a", "b", 1] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ arr | join: '#' }}", context: ctx)
        #expect(result == "a#b#1")
    }

    @Test("filters, join, missing argument defaults to a space", .timeLimit(.minutes(1)))
    func missingArgumentDefaultsToASpace() async throws {
        let ctx: [String: Any] = [
            "arr": ["a", "b"]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ arr | join }}", context: ctx)
        #expect(result == "a b")
    }

    @Test("filters, join, range literal join filter left value", .timeLimit(.minutes(1)))
    func rangeLiteralJoinFilterLeftValue() async throws {
        let result = try await renderWithTimeout(template: "{{ (1..3) | join: '#' }}", context: [:])
        #expect(result == "1#2#3")
    }

    @Test("filters, join, too many arguments", .timeLimit(.minutes(1)))
    func tooManyArguments() async throws {
        let ctx: [String: Any] = [
            "arr": ["a", "b"]
        ] as [String: Any]
        do {
            _ = try await renderWithTimeout(template: "{{ arr | join: '#', 42 }}", context: ctx)
            Issue.record("Expected error for \"filters, join, too many arguments\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, join, undefined argument", .timeLimit(.minutes(1)))
    func undefinedArgument() async throws {
        let ctx: [String: Any] = [
            "arr": ["a", "b"]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ arr | join: nosuchthing }}", context: ctx)
        #expect(result == "ab")
    }

    @Test("filters, join, undefined left value", .timeLimit(.minutes(1)))
    func undefinedLeftValue() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | join: '#' }}", context: [:])
        #expect(result == "")
    }
}
