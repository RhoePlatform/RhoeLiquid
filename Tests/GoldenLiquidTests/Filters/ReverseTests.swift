//
//  ReverseTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: reverse", .serialized)
struct GoldenReverseTests {

    @Test("filters, reverse, array of strings", .timeLimit(.minutes(1)))
    func arrayOfStrings() async throws {
        let ctx: [String: Any] = [
            "a": ["b", "a", "B", "A"]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | reverse | join: '#' }}", context: ctx)
        #expect(result == "A#B#a#b")
    }

    @Test("filters, reverse, array of things", .timeLimit(.minutes(1)))
    func arrayOfThings() async throws {
        let ctx: [String: Any] = [
            "a": ["a", "b", 1, [Any](), OrderedDictionary<String, Any>()] as [Any]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | reverse | join: '#' }}", context: ctx)
        #expect(result == "{}#1#b#a")
    }

    @Test("filters, reverse, empty array", .timeLimit(.minutes(1)))
    func emptyArray() async throws {
        let ctx: [String: Any] = [
            "a": [Any]()
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | reverse | join: '#' }}", context: ctx)
        #expect(result == "")
    }

    @Test("filters, reverse, left value is undefined", .timeLimit(.minutes(1)))
    func leftValueIsUndefined() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | reverse | join: '#' }}", context: [:])
        #expect(result == "")
    }

    @Test("filters, reverse, left value not an array", .timeLimit(.minutes(1)))
    func leftValueNotAnArray() async throws {
        let ctx: [String: Any] = [
            "a": 123
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | reverse | join: '#' }}", context: ctx)
        #expect(result == "123")
    }

    @Test("filters, reverse, unexpected argument", .timeLimit(.minutes(1)))
    func unexpectedArgument() async throws {
        let ctx: [String: Any] = [
            "a": [Any]()
        ] as [String: Any]
        do {
            _ = try await renderWithTimeout(template: "{{ a | reverse: 0 | join: '#' }}", context: ctx)
            Issue.record("Expected error for \"filters, reverse, unexpected argument\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }
}
