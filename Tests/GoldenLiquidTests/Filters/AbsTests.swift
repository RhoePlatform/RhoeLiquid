//
//  AbsTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: abs", .serialized)
struct GoldenAbsTests {

    @Test("filters, abs, negative float", .timeLimit(.minutes(1)))
    func negativeFloat() async throws {
        let result = try await renderWithTimeout(template: "{{ -5.4 | abs }}", context: [:])
        #expect(result == "5.4")
    }

    @Test("filters, abs, negative integer", .timeLimit(.minutes(1)))
    func negativeInteger() async throws {
        let result = try await renderWithTimeout(template: "{{ -5 | abs }}", context: [:])
        #expect(result == "5")
    }

    @Test("filters, abs, negative string float", .timeLimit(.minutes(1)))
    func negativeStringFloat() async throws {
        let result = try await renderWithTimeout(template: "{{ '-5.1' | abs }}", context: [:])
        #expect(result == "5.1")
    }

    @Test("filters, abs, negative string integer", .timeLimit(.minutes(1)))
    func negativeStringInteger() async throws {
        let result = try await renderWithTimeout(template: "{{ '-5' | abs }}", context: [:])
        #expect(result == "5")
    }

    @Test("filters, abs, not a string, int or float", .timeLimit(.minutes(1)))
    func notAStringIntOrFloat() async throws {
        let ctx: [String: Any] = [
            "a": OrderedDictionary<String, Any>()
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | abs }}", context: ctx)
        #expect(result == "0")
    }

    @Test("filters, abs, positive float", .timeLimit(.minutes(1)))
    func positiveFloat() async throws {
        let result = try await renderWithTimeout(template: "{{ 5.4 | abs }}", context: [:])
        #expect(result == "5.4")
    }

    @Test("filters, abs, positive integer", .timeLimit(.minutes(1)))
    func positiveInteger() async throws {
        let result = try await renderWithTimeout(template: "{{ 5 | abs }}", context: [:])
        #expect(result == "5")
    }

    @Test("filters, abs, positive string float", .timeLimit(.minutes(1)))
    func positiveStringFloat() async throws {
        let result = try await renderWithTimeout(template: "{{ '5.1' | abs }}", context: [:])
        #expect(result == "5.1")
    }

    @Test("filters, abs, positive string integer", .timeLimit(.minutes(1)))
    func positiveStringInteger() async throws {
        let result = try await renderWithTimeout(template: "{{ '5' | abs }}", context: [:])
        #expect(result == "5")
    }

    @Test("filters, abs, string not a number", .timeLimit(.minutes(1)))
    func stringNotANumber() async throws {
        let result = try await renderWithTimeout(template: "{{ 'hello' | abs }}", context: [:])
        #expect(result == "0")
    }

    @Test("filters, abs, undefined left value", .timeLimit(.minutes(1)))
    func undefinedLeftValue() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | abs }}", context: [:])
        #expect(result == "0")
    }

    @Test("filters, abs, unexpected argument", .timeLimit(.minutes(1)))
    func unexpectedArgument() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ -3 | abs: 1 }}", context: [:])
            Issue.record("Expected error for \"filters, abs, unexpected argument\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, abs, zero", .timeLimit(.minutes(1)))
    func zero() async throws {
        let result = try await renderWithTimeout(template: "{{ 0 | abs }}", context: [:])
        #expect(result == "0")
    }
}
