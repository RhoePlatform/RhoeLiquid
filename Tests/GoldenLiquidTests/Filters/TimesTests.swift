//
//  TimesTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: times", .serialized)
struct GoldenTimesTests {

    @Test("filters, times, float times float", .timeLimit(.minutes(1)))
    func floatTimesFloat() async throws {
        let result = try await renderWithTimeout(template: "{{ 5.0 | times: 2.1 }}", context: [:])
        #expect(result == "10.5")
    }

    @Test("filters, times, int times float", .timeLimit(.minutes(1)))
    func intTimesFloat() async throws {
        let result = try await renderWithTimeout(template: "{{ 5 | times: 2.1 }}", context: [:])
        #expect(result == "10.5")
    }

    @Test("filters, times, int times int", .timeLimit(.minutes(1)))
    func intTimesInt() async throws {
        let result = try await renderWithTimeout(template: "{{ 5 | times: 2 }}", context: [:])
        #expect(result == "10")
    }

    @Test("filters, times, missing arg", .timeLimit(.minutes(1)))
    func missingArg() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ 5 | times }}", context: [:])
            Issue.record("Expected error for \"filters, times, missing arg\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, times, negative multiplication", .timeLimit(.minutes(1)))
    func negativeMultiplication() async throws {
        let result = try await renderWithTimeout(template: "{{ -5 | times: 2 }}", context: [:])
        #expect(result == "-10")
    }

    @Test("filters, times, string times string", .timeLimit(.minutes(1)))
    func stringTimesString() async throws {
        let result = try await renderWithTimeout(template: "{{ \"5.0\" | times: \"2.1\" }}", context: [:])
        #expect(result == "10.5")
    }

    @Test("filters, times, too many args", .timeLimit(.minutes(1)))
    func tooManyArgs() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ 5 | times: 1, 2 }}", context: [:])
            Issue.record("Expected error for \"filters, times, too many args\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, times, undefined argument", .timeLimit(.minutes(1)))
    func undefinedArgument() async throws {
        let result = try await renderWithTimeout(template: "{{ 5 | times: nosuchthing }}", context: [:])
        #expect(result == "0")
    }

    @Test("filters, times, undefined left value", .timeLimit(.minutes(1)))
    func undefinedLeftValue() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | times: 2 }}", context: [:])
        #expect(result == "0")
    }
}
