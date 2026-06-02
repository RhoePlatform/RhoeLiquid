//
//  DividedByTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: divided by", .serialized)
struct GoldenDividedByTests {

    @Test("filters, divided by, arg string not a number", .timeLimit(.minutes(1)))
    func argStringNotANumber() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ \"10\" | divided_by: \"foo\" }}", context: [:])
            Issue.record("Expected error for \"filters, divided by, arg string not a number\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, divided by, divied by zero", .timeLimit(.minutes(1)))
    func diviedByZero() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ 10 | divided_by: 0 }}", context: [:])
            Issue.record("Expected error for \"filters, divided by, divied by zero\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, divided by, float division", .timeLimit(.minutes(1)))
    func floatDivision() async throws {
        let result = try await renderWithTimeout(template: "{{ 20 | divided_by: 7.0 }}", context: [:])
        #expect(result == "2.857142857142857")
    }

    @Test("filters, divided by, float value and integer arg", .timeLimit(.minutes(1)))
    func floatValueAndIntegerArg() async throws {
        let result = try await renderWithTimeout(template: "{{ 9.0 | divided_by: 2 }}", context: [:])
        #expect(result == "4.5")
    }

    @Test("filters, divided by, integer division", .timeLimit(.minutes(1)))
    func integerDivision() async throws {
        let result = try await renderWithTimeout(template: "{{ 9 | divided_by: 2 }}", context: [:])
        #expect(result == "4")
    }

    @Test("filters, divided by, integer value and float arg", .timeLimit(.minutes(1)))
    func integerValueAndFloatArg() async throws {
        let result = try await renderWithTimeout(template: "{{ 10 | divided_by: 2.0 }}", context: [:])
        #expect(result == "5.0")
    }

    @Test("filters, divided by, integer value and integer arg", .timeLimit(.minutes(1)))
    func integerValueAndIntegerArg() async throws {
        let result = try await renderWithTimeout(template: "{{ 10 | divided_by: 2 }}", context: [:])
        #expect(result == "5")
    }

    @Test("filters, divided by, issue", .timeLimit(.minutes(1)))
    func issue() async throws {
        let result = try await renderWithTimeout(template: "{{ 5 | divided_by: 3 }}", context: [:])
        #expect(result == "1")
    }

    @Test("filters, divided by, left value is an empty string", .timeLimit(.minutes(1)))
    func leftValueIsAnEmptyString() async throws {
        let result = try await renderWithTimeout(template: "{{ '' | divided_by: 2 }}", context: [:])
        #expect(result == "0")
    }

    @Test("filters, divided by, not a string, int or float", .timeLimit(.minutes(1)))
    func notAStringIntOrFloat() async throws {
        let ctx: [String: Any] = [
            "a": OrderedDictionary<String, Any>()
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | divided_by: 1 }}", context: ctx)
        #expect(result == "0")
    }

    @Test("filters, divided by, render", .timeLimit(.minutes(1)))
    func render() async throws {
        let result = try await renderWithTimeout(template: "{{ 5.0 }} {{ 5 }}", context: [:])
        #expect(result == "5.0 5")
    }

    @Test("filters, divided by, string not a number", .timeLimit(.minutes(1)))
    func stringNotANumber() async throws {
        let result = try await renderWithTimeout(template: "{{ \"foo\" | divided_by: \"2\" }}", context: [:])
        #expect(result == "0")
    }

    @Test("filters, divided by, string value and argument", .timeLimit(.minutes(1)))
    func stringValueAndArgument() async throws {
        let result = try await renderWithTimeout(template: "{{ \"10\" | divided_by: \"2\" }}", context: [:])
        #expect(result == "5")
    }

    @Test("filters, divided by, too many args", .timeLimit(.minutes(1)))
    func tooManyArgs() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ 5 | divided_by: 1, '5' }}", context: [:])
            Issue.record("Expected error for \"filters, divided by, too many args\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, divided by, undefined argument", .timeLimit(.minutes(1)))
    func undefinedArgument() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ 10 | divided_by: nosuchthing }}", context: [:])
            Issue.record("Expected error for \"filters, divided by, undefined argument\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, divided by, undefined left value", .timeLimit(.minutes(1)))
    func undefinedLeftValue() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | divided_by: 2 }}", context: [:])
        #expect(result == "0")
    }

    @Test("filters, divided by, zero divided by float", .timeLimit(.minutes(1)))
    func zeroDividedByFloat() async throws {
        let result = try await renderWithTimeout(template: "{{ 0 | divided_by: 1.1 }}", context: [:])
        #expect(result == "0.0")
    }

    @Test("filters, divided by, zero divided by integer", .timeLimit(.minutes(1)))
    func zeroDividedByInteger() async throws {
        let result = try await renderWithTimeout(template: "{{ 0 | divided_by: 1 }}", context: [:])
        #expect(result == "0")
    }
}
