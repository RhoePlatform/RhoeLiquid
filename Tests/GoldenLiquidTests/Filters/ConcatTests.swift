//
//  ConcatTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: concat", .serialized)
struct GoldenConcatTests {

    @Test("filters, concat, left value contains non string", .timeLimit(.minutes(1)))
    func leftValueContainsNonString() async throws {
        let ctx: [String: Any] = [
            "a": ["a", "b", 5] as [Any],
            "b": ["c", "d"]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | concat: b | join: '#' }}", context: ctx)
        #expect(result == "a#b#5#c#d")
    }

    @Test("filters, concat, left value is not array-like", .timeLimit(.minutes(1)))
    func leftValueIsNotArrayLike() async throws {
        let ctx: [String: Any] = [
            "a": "ab",
            "b": ["c", "d"]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | concat: b | join: '#' }}", context: ctx)
        #expect(result == "ab#c#d")
    }

    @Test("filters, concat, missing argument is an error", .timeLimit(.minutes(1)))
    func missingArgumentIsAnError() async throws {
        let ctx: [String: Any] = [
            "a": ["a", "b"]
        ] as [String: Any]
        do {
            _ = try await renderWithTimeout(template: "{{ a | concat | join: '#' }}", context: ctx)
            Issue.record("Expected error for \"filters, concat, missing argument is an error\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, concat, nested left value gets flattened", .timeLimit(.minutes(1)))
    func nestedLeftValueGetsFlattened() async throws {
        let ctx: [String: Any] = [
            "a": [["a", "x"], ["b", ["y", ["z"]] as [Any]] as [Any]] as [Any],
            "b": ["c", "d"]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | concat: b | join: '#' }}", context: ctx)
        #expect(result == "a#x#b#y#z#c#d")
    }

    @Test("filters, concat, non array-like argument is an error", .timeLimit(.minutes(1)))
    func nonArrayLikeArgumentIsAnError() async throws {
        let ctx: [String: Any] = [
            "a": ["a", "b"],
            "b": 5
        ] as [String: Any]
        do {
            _ = try await renderWithTimeout(template: "{{ a | concat: b | join: '#' }}", context: ctx)
            Issue.record("Expected error for \"filters, concat, non array-like argument is an error\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, concat, range literal concat filter left value", .timeLimit(.minutes(1)))
    func rangeLiteralConcatFilterLeftValue() async throws {
        let ctx: [String: Any] = [
            "foo": [5, 6, 7]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ (1..3) | concat: foo | join: '#' }}", context: ctx)
        #expect(result == "1#2#3#5#6#7")
    }

    @Test("filters, concat, two arrays of strings", .timeLimit(.minutes(1)))
    func twoArraysOfStrings() async throws {
        let ctx: [String: Any] = [
            "a": ["a", "b"],
            "b": ["c", "d"]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | concat: b | join: '#' }}", context: ctx)
        #expect(result == "a#b#c#d")
    }

    @Test("filters, concat, undefined argument is an error", .timeLimit(.minutes(1)))
    func undefinedArgumentIsAnError() async throws {
        let ctx: [String: Any] = [
            "a": ["a", "b"]
        ] as [String: Any]
        do {
            _ = try await renderWithTimeout(template: "{{ a | concat: nosuchthing | join: '#' }}", context: ctx)
            Issue.record("Expected error for \"filters, concat, undefined argument is an error\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, concat, undefined left value", .timeLimit(.minutes(1)))
    func undefinedLeftValue() async throws {
        let ctx: [String: Any] = [
            "b": ["c", "d"]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ nosuchthing | concat: b | join: '#' }}", context: ctx)
        #expect(result == "c#d")
    }
}
