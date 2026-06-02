//
//  PlusTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: plus", .serialized)
struct GoldenPlusTests {

    @Test("filters, plus, arg string not a number", .timeLimit(.minutes(1)))
    func argStringNotANumber() async throws {
        let result = try await renderWithTimeout(template: "{{ \"10\" | plus: \"foo\" }}", context: [:])
        #expect(result == "10")
    }

    @Test("filters, plus, float value and float arg", .timeLimit(.minutes(1)))
    func floatValueAndFloatArg() async throws {
        let result = try await renderWithTimeout(template: "{{ 10.1 | plus: 2.2 }}", context: [:])
        #expect(result == "12.3")
    }

    @Test("filters, plus, integer value and float arg", .timeLimit(.minutes(1)))
    func integerValueAndFloatArg() async throws {
        let result = try await renderWithTimeout(template: "{{ 10 | plus: 2.0 }}", context: [:])
        #expect(result == "12.0")
    }

    @Test("filters, plus, integer value and integer arg", .timeLimit(.minutes(1)))
    func integerValueAndIntegerArg() async throws {
        let result = try await renderWithTimeout(template: "{{ 10 | plus: 2 }}", context: [:])
        #expect(result == "12")
    }

    @Test("filters, plus, integer value and negative integer arg", .timeLimit(.minutes(1)))
    func integerValueAndNegativeIntegerArg() async throws {
        let result = try await renderWithTimeout(template: "{{ 10 | plus: -2 }}", context: [:])
        #expect(result == "8")
    }

    @Test("filters, plus, not a string, int or float", .timeLimit(.minutes(1)))
    func notAStringIntOrFloat() async throws {
        let ctx: [String: Any] = [
            "a": OrderedDictionary<String, Any>()
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | plus: 1 }}", context: ctx)
        #expect(result == "1")
    }

    @Test("filters, plus, string not a number", .timeLimit(.minutes(1)))
    func stringNotANumber() async throws {
        let result = try await renderWithTimeout(template: "{{ \"foo\" | plus: \"2.0\" }}", context: [:])
        #expect(result == "2.0")
    }

    @Test("filters, plus, string value and string arg", .timeLimit(.minutes(1)))
    func stringValueAndStringArg() async throws {
        let result = try await renderWithTimeout(template: "{{ \"10.1\" | plus: \"2.2\" }}", context: [:])
        #expect(result == "12.3")
    }

    @Test("filters, plus, too many args", .timeLimit(.minutes(1)))
    func tooManyArgs() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ 5 | plus: 1, '5' }}", context: [:])
            Issue.record("Expected error for \"filters, plus, too many args\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, plus, undefined argument", .timeLimit(.minutes(1)))
    func undefinedArgument() async throws {
        let result = try await renderWithTimeout(template: "{{ 10 | plus: nosuchthing }}", context: [:])
        #expect(result == "10")
    }

    @Test("filters, plus, undefined left value", .timeLimit(.minutes(1)))
    func undefinedLeftValue() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | plus: 2 }}", context: [:])
        #expect(result == "2")
    }
}
