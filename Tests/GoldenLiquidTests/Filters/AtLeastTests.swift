//
//  AtLeastTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: at least", .serialized)
struct GoldenAtLeastTests {

    @Test("filters, at least, argument string not a number", .timeLimit(.minutes(1)))
    func argumentStringNotANumber() async throws {
        let result = try await renderWithTimeout(template: "{{ -1 | at_least: \"abc\" }}", context: [:])
        #expect(result == "0")
    }

    @Test("filters, at least, left value not a number", .timeLimit(.minutes(1)))
    func leftValueNotANumber() async throws {
        let result = try await renderWithTimeout(template: "{{ \"abc\" | at_least: 2 }}", context: [:])
        #expect(result == "2")
    }

    @Test("filters, at least, left value not a number negative argument", .timeLimit(.minutes(1)))
    func leftValueNotANumberNegativeArgument() async throws {
        let result = try await renderWithTimeout(template: "{{ \"abc\" | at_least: -2 }}", context: [:])
        #expect(result == "0")
    }

    @Test("filters, at least, missing arg", .timeLimit(.minutes(1)))
    func missingArg() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ 5 | at_least }}", context: [:])
            Issue.record("Expected error for \"filters, at least, missing arg\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, at least, negative integer < arg", .timeLimit(.minutes(1)))
    func negativeIntegerArg() async throws {
        let result = try await renderWithTimeout(template: "{{ -8 | at_least: 5 }}", context: [:])
        #expect(result == "5")
    }

    @Test("filters, at least, positive float < arg", .timeLimit(.minutes(1)))
    func positiveFloatArg() async throws {
        let result = try await renderWithTimeout(template: "{{ 5.4 | at_least: 8.9 }}", context: [:])
        #expect(result == "8.9")
    }

    @Test("filters, at least, positive float > arg", .timeLimit(.minutes(1)))
    func positiveFloatArg2() async throws {
        let result = try await renderWithTimeout(template: "{{ 8.4 | at_least: 5.9 }}", context: [:])
        #expect(result == "8.4")
    }

    @Test("filters, at least, positive integer < arg", .timeLimit(.minutes(1)))
    func positiveIntegerArg() async throws {
        let result = try await renderWithTimeout(template: "{{ 5 | at_least: 8 }}", context: [:])
        #expect(result == "8")
    }

    @Test("filters, at least, positive integer == arg", .timeLimit(.minutes(1)))
    func positiveIntegerArg2() async throws {
        let result = try await renderWithTimeout(template: "{{ 5 | at_least: 5 }}", context: [:])
        #expect(result == "5")
    }

    @Test("filters, at least, positive integer > arg", .timeLimit(.minutes(1)))
    func positiveIntegerArg3() async throws {
        let result = try await renderWithTimeout(template: "{{ 8 | at_least: 5 }}", context: [:])
        #expect(result == "8")
    }

    @Test("filters, at least, positive string > arg", .timeLimit(.minutes(1)))
    func positiveStringArg() async throws {
        let result = try await renderWithTimeout(template: "{{ \"9\" | at_least: 8 }}", context: [:])
        #expect(result == "9")
    }

    @Test("filters, at least, too many args", .timeLimit(.minutes(1)))
    func tooManyArgs() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ 5 | at_least: 1, 2}}", context: [:])
            Issue.record("Expected error for \"filters, at least, too many args\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, at least, undefined argument", .timeLimit(.minutes(1)))
    func undefinedArgument() async throws {
        let result = try await renderWithTimeout(template: "{{ 5 | at_least: nosuchthing }}", context: [:])
        #expect(result == "5")
    }

    @Test("filters, at least, undefined left value", .timeLimit(.minutes(1)))
    func undefinedLeftValue() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | at_least: 5 }}", context: [:])
        #expect(result == "5")
    }
}
