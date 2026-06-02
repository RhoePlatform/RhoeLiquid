//
//  AtMostTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: at most", .serialized)
struct GoldenAtMostTests {

    @Test("filters, at most, left value not a number", .timeLimit(.minutes(1)))
    func leftValueNotANumber() async throws {
        let result = try await renderWithTimeout(template: "{{ \"abc\" | at_most: -2 }}", context: [:])
        #expect(result == "-2")
    }

    @Test("filters, at most, missing arg", .timeLimit(.minutes(1)))
    func missingArg() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ 5 | at_most }}", context: [:])
            Issue.record("Expected error for \"filters, at most, missing arg\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, at most, negative integer < arg", .timeLimit(.minutes(1)))
    func negativeIntegerArg() async throws {
        let result = try await renderWithTimeout(template: "{{ -8 | at_most: 5 }}", context: [:])
        #expect(result == "-8")
    }

    @Test("filters, at most, positive float < arg", .timeLimit(.minutes(1)))
    func positiveFloatArg() async throws {
        let result = try await renderWithTimeout(template: "{{ 5.4 | at_most: 8.9 }}", context: [:])
        #expect(result == "5.4")
    }

    @Test("filters, at most, positive float > arg", .timeLimit(.minutes(1)))
    func positiveFloatArg2() async throws {
        let result = try await renderWithTimeout(template: "{{ 8.4 | at_most: 5.9 }}", context: [:])
        #expect(result == "5.9")
    }

    @Test("filters, at most, positive integer < arg", .timeLimit(.minutes(1)))
    func positiveIntegerArg() async throws {
        let result = try await renderWithTimeout(template: "{{ 5 | at_most: 8 }}", context: [:])
        #expect(result == "5")
    }

    @Test("filters, at most, positive integer == arg", .timeLimit(.minutes(1)))
    func positiveIntegerArg2() async throws {
        let result = try await renderWithTimeout(template: "{{ 5 | at_most: 5 }}", context: [:])
        #expect(result == "5")
    }

    @Test("filters, at most, positive integer > arg", .timeLimit(.minutes(1)))
    func positiveIntegerArg3() async throws {
        let result = try await renderWithTimeout(template: "{{ 8 | at_most: 5 }}", context: [:])
        #expect(result == "5")
    }

    @Test("filters, at most, positive string > arg", .timeLimit(.minutes(1)))
    func positiveStringArg() async throws {
        let result = try await renderWithTimeout(template: "{{ \"9\" | at_most: 8 }}", context: [:])
        #expect(result == "8")
    }

    @Test("filters, at most, too many args", .timeLimit(.minutes(1)))
    func tooManyArgs() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ 5 | at_most: 1, 2}}", context: [:])
            Issue.record("Expected error for \"filters, at most, too many args\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, at most, undefined argument", .timeLimit(.minutes(1)))
    func undefinedArgument() async throws {
        let result = try await renderWithTimeout(template: "{{ 5 | at_most: nosuchthing }}", context: [:])
        #expect(result == "0")
    }

    @Test("filters, at most, undefined left value", .timeLimit(.minutes(1)))
    func undefinedLeftValue() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | at_most: 5 }}", context: [:])
        #expect(result == "0")
    }
}
