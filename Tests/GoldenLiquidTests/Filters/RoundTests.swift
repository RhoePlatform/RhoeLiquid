//
//  RoundTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: round", .serialized)
struct GoldenRoundTests {

    @Test("filters, round, argument is a float", .timeLimit(.minutes(1)))
    func argumentIsAFloat() async throws {
        let result = try await renderWithTimeout(template: "{{ 5.666 | round: 1.2 }}", context: [:])
        #expect(result == "5.7")
    }

    @Test("filters, round, argument is a negative", .timeLimit(.minutes(1)))
    func argumentIsANegative() async throws {
        let result = try await renderWithTimeout(template: "{{ 5.666 | round: -2 }}", context: [:])
        #expect(result == "0")
    }

    @Test("filters, round, argument is a string", .timeLimit(.minutes(1)))
    func argumentIsAString() async throws {
        let result = try await renderWithTimeout(template: "{{ 5.666 | round: 'foo' }}", context: [:])
        #expect(result == "6")
    }

    @Test("filters, round, argument is a string representation of an integer", .timeLimit(.minutes(1)))
    func argumentIsAStringRepresentationOfAnInteger() async throws {
        let result = try await renderWithTimeout(template: "{{ 5.666 | round: '1' }}", context: [:])
        #expect(result == "5.7")
    }

    @Test("filters, round, argument is a string representation of zero", .timeLimit(.minutes(1)))
    func argumentIsAStringRepresentationOfZero() async throws {
        let result = try await renderWithTimeout(template: "{{ 5.666 | round: '1' }}", context: [:])
        #expect(result == "5.7")
    }

    @Test("filters, round, argument is a zero", .timeLimit(.minutes(1)))
    func argumentIsAZero() async throws {
        let result = try await renderWithTimeout(template: "{{ 5.666 | round: 0 }}", context: [:])
        #expect(result == "6")
    }

    @Test("filters, round, decimal places", .timeLimit(.minutes(1)))
    func decimalPlaces() async throws {
        let result = try await renderWithTimeout(template: "{{ \"5.666666\" | round: 2 }}", context: [:])
        #expect(result == "5.67")
    }

    @Test("filters, round, float as a string", .timeLimit(.minutes(1)))
    func floatAsAString() async throws {
        let result = try await renderWithTimeout(template: "{{ \"5.6\" | round }}", context: [:])
        #expect(result == "6")
    }

    @Test("filters, round, float round down", .timeLimit(.minutes(1)))
    func floatRoundDown() async throws {
        let result = try await renderWithTimeout(template: "{{ 5.1 | round }}", context: [:])
        #expect(result == "5")
    }

    @Test("filters, round, float round up", .timeLimit(.minutes(1)))
    func floatRoundUp() async throws {
        let result = try await renderWithTimeout(template: "{{ 5.6 | round }}", context: [:])
        #expect(result == "6")
    }

    @Test("filters, round, integer", .timeLimit(.minutes(1)))
    func integer() async throws {
        let result = try await renderWithTimeout(template: "{{ 5 | round }}", context: [:])
        #expect(result == "5")
    }

    @Test("filters, round, string argument", .timeLimit(.minutes(1)))
    func stringArgument() async throws {
        let result = try await renderWithTimeout(template: "{{ 5.666 | round: \"1\" }}", context: [:])
        #expect(result == "5.7")
    }

    @Test("filters, round, too many args", .timeLimit(.minutes(1)))
    func tooManyArgs() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ 5 | round: 1, 2 }}", context: [:])
            Issue.record("Expected error for \"filters, round, too many args\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, round, undefined argument", .timeLimit(.minutes(1)))
    func undefinedArgument() async throws {
        let result = try await renderWithTimeout(template: "{{ 5.666 | round: nosuchthing }}", context: [:])
        #expect(result == "6")
    }

    @Test("filters, round, undefined left value", .timeLimit(.minutes(1)))
    func undefinedLeftValue() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | round: 2 }}", context: [:])
        #expect(result == "0")
    }
}
