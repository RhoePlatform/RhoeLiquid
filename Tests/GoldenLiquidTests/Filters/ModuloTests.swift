//
//  ModuloTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: modulo", .serialized)
struct GoldenModuloTests {

    @Test("filters, modulo, arg string not a number", .timeLimit(.minutes(1)))
    func argStringNotANumber() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ \"10\" | modulo: \"foo\" }}", context: [:])
            Issue.record("Expected error for \"filters, modulo, arg string not a number\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, modulo, float value and float arg", .timeLimit(.minutes(1)))
    func floatValueAndFloatArg() async throws {
        let result = try await renderWithTimeout(template: "{{ 10.1 | modulo: 7.0 }}", context: [:])
        #expect(result == "3.1")
    }

    @Test("filters, modulo, integer value and float arg", .timeLimit(.minutes(1)))
    func integerValueAndFloatArg() async throws {
        let result = try await renderWithTimeout(template: "{{ 10 | modulo: 2.0 }}", context: [:])
        #expect(result == "0.0")
    }

    @Test("filters, modulo, integer value and integer arg", .timeLimit(.minutes(1)))
    func integerValueAndIntegerArg() async throws {
        let result = try await renderWithTimeout(template: "{{ 10 | modulo: 2 }}", context: [:])
        #expect(result == "0")
    }

    @Test("filters, modulo, not a string, int or float", .timeLimit(.minutes(1)))
    func notAStringIntOrFloat() async throws {
        let ctx: [String: Any] = [
            "a": OrderedDictionary<String, Any>()
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | modulo: 1 }}", context: ctx)
        #expect(result == "0")
    }

    @Test("filters, modulo, string not a number", .timeLimit(.minutes(1)))
    func stringNotANumber() async throws {
        let result = try await renderWithTimeout(template: "{{ \"foo\" | modulo: \"2.0\" }}", context: [:])
        #expect(result == "0.0")
    }

    @Test("filters, modulo, string value and argument", .timeLimit(.minutes(1)))
    func stringValueAndArgument() async throws {
        let result = try await renderWithTimeout(template: "{{ \"10\" | modulo: \"2.0\" }}", context: [:])
        #expect(result == "0.0")
    }

    @Test("filters, modulo, too many args", .timeLimit(.minutes(1)))
    func tooManyArgs() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ 5 | modulo: 1, '5' }}", context: [:])
            Issue.record("Expected error for \"filters, modulo, too many args\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, modulo, undefined argument", .timeLimit(.minutes(1)))
    func undefinedArgument() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ 5 | modulo: nosuchthing }}", context: [:])
            Issue.record("Expected error for \"filters, modulo, undefined argument\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, modulo, undefined left value", .timeLimit(.minutes(1)))
    func undefinedLeftValue() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | modulo: 2 }}", context: [:])
        #expect(result == "0")
    }
}
