//
//  CeilTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: ceil", .serialized)
struct GoldenCeilTests {

    @Test("filters, ceil, negative float", .timeLimit(.minutes(1)))
    func negativeFloat() async throws {
        let result = try await renderWithTimeout(template: "{{ -5.4 | ceil }}", context: [:])
        #expect(result == "-5")
    }

    @Test("filters, ceil, negative integer", .timeLimit(.minutes(1)))
    func negativeInteger() async throws {
        let result = try await renderWithTimeout(template: "{{ -5 | ceil }}", context: [:])
        #expect(result == "-5")
    }

    @Test("filters, ceil, negative string float", .timeLimit(.minutes(1)))
    func negativeStringFloat() async throws {
        let result = try await renderWithTimeout(template: "{{ \"-5.1\" | ceil }}", context: [:])
        #expect(result == "-5")
    }

    @Test("filters, ceil, not a string, int or float", .timeLimit(.minutes(1)))
    func notAStringIntOrFloat() async throws {
        let ctx: [String: Any] = [
            "a": OrderedDictionary<String, Any>()
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | ceil }}", context: ctx)
        #expect(result == "0")
    }

    @Test("filters, ceil, positive float", .timeLimit(.minutes(1)))
    func positiveFloat() async throws {
        let result = try await renderWithTimeout(template: "{{ 5.4 | ceil }}", context: [:])
        #expect(result == "6")
    }

    @Test("filters, ceil, positive integer", .timeLimit(.minutes(1)))
    func positiveInteger() async throws {
        let result = try await renderWithTimeout(template: "{{ 5 | ceil }}", context: [:])
        #expect(result == "5")
    }

    @Test("filters, ceil, positive string float", .timeLimit(.minutes(1)))
    func positiveStringFloat() async throws {
        let result = try await renderWithTimeout(template: "{{ \"5.1\" | ceil }}", context: [:])
        #expect(result == "6")
    }

    @Test("filters, ceil, string not a number", .timeLimit(.minutes(1)))
    func stringNotANumber() async throws {
        let result = try await renderWithTimeout(template: "{{ \"hello\" | ceil }}", context: [:])
        #expect(result == "0")
    }

    @Test("filters, ceil, undefined left value", .timeLimit(.minutes(1)))
    func undefinedLeftValue() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | ceil }}", context: [:])
        #expect(result == "0")
    }

    @Test("filters, ceil, unexpected argument", .timeLimit(.minutes(1)))
    func unexpectedArgument() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ -3.1 | ceil: 1 }}", context: [:])
            Issue.record("Expected error for \"filters, ceil, unexpected argument\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, ceil, zero", .timeLimit(.minutes(1)))
    func zero() async throws {
        let result = try await renderWithTimeout(template: "{{ 0 | ceil }}", context: [:])
        #expect(result == "0")
    }
}
