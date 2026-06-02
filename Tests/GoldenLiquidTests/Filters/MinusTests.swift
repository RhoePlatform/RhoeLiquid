//
//  MinusTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: minus", .serialized)
struct GoldenMinusTests {

    @Test("filters, minus, arg string not a number", .timeLimit(.minutes(1)))
    func argStringNotANumber() async throws {
        let result = try await renderWithTimeout(template: "{{ \"10\" | minus: \"foo\" }}", context: [:])
        #expect(result == "10")
    }

    @Test("filters, minus, float value and float arg", .timeLimit(.minutes(1)))
    func floatValueAndFloatArg() async throws {
        let result = try await renderWithTimeout(template: "{{ 10.1 | minus: 2.2 }}", context: [:])
        #expect(result == "7.9")
    }

    @Test("filters, minus, integer value and float arg", .timeLimit(.minutes(1)))
    func integerValueAndFloatArg() async throws {
        let result = try await renderWithTimeout(template: "{{ 10 | minus: 2.0 }}", context: [:])
        #expect(result == "8.0")
    }

    @Test("filters, minus, integer value and integer arg", .timeLimit(.minutes(1)))
    func integerValueAndIntegerArg() async throws {
        let result = try await renderWithTimeout(template: "{{ 10 | minus: 2 }}", context: [:])
        #expect(result == "8")
    }

    @Test("filters, minus, not a string, int or float", .timeLimit(.minutes(1)))
    func notAStringIntOrFloat() async throws {
        let ctx: [String: Any] = [
            "a": OrderedDictionary<String, Any>()
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | minus: 1 }}", context: ctx)
        #expect(result == "-1")
    }

    @Test("filters, minus, string not a number", .timeLimit(.minutes(1)))
    func stringNotANumber() async throws {
        let result = try await renderWithTimeout(template: "{{ \"foo\" | minus: \"2.0\" }}", context: [:])
        #expect(result == "-2.0")
    }

    @Test("filters, minus, string value and string arg", .timeLimit(.minutes(1)))
    func stringValueAndStringArg() async throws {
        let result = try await renderWithTimeout(template: "{{ \"10.1\" | minus: \"2.2\" }}", context: [:])
        #expect(result == "7.9")
    }

    @Test("filters, minus, too many args", .timeLimit(.minutes(1)))
    func tooManyArgs() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ 5 | minus: 1, '5' }}", context: [:])
            Issue.record("Expected error for \"filters, minus, too many args\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, minus, undefined argument", .timeLimit(.minutes(1)))
    func undefinedArgument() async throws {
        let result = try await renderWithTimeout(template: "{{ 10 | minus: nosuchthing }}", context: [:])
        #expect(result == "10")
    }

    @Test("filters, minus, undefined left value", .timeLimit(.minutes(1)))
    func undefinedLeftValue() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | minus: 2 }}", context: [:])
        #expect(result == "-2")
    }
}
