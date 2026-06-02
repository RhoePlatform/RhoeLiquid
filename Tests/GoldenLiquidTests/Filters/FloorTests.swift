//
//  FloorTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: floor", .serialized)
struct GoldenFloorTests {

    @Test("filters, floor, negative float", .timeLimit(.minutes(1)))
    func negativeFloat() async throws {
        let result = try await renderWithTimeout(template: "{{ -5.4 | floor }}", context: [:])
        #expect(result == "-6")
    }

    @Test("filters, floor, negative integer", .timeLimit(.minutes(1)))
    func negativeInteger() async throws {
        let result = try await renderWithTimeout(template: "{{ -5 | floor }}", context: [:])
        #expect(result == "-5")
    }

    @Test("filters, floor, negative string float", .timeLimit(.minutes(1)))
    func negativeStringFloat() async throws {
        let result = try await renderWithTimeout(template: "{{ \"-5.1\" | floor }}", context: [:])
        #expect(result == "-6")
    }

    @Test("filters, floor, not a string, int or float", .timeLimit(.minutes(1)))
    func notAStringIntOrFloat() async throws {
        let ctx: [String: Any] = [
            "a": OrderedDictionary<String, Any>()
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | floor }}", context: ctx)
        #expect(result == "0")
    }

    @Test("filters, floor, positive float", .timeLimit(.minutes(1)))
    func positiveFloat() async throws {
        let result = try await renderWithTimeout(template: "{{ 5.4 | floor }}", context: [:])
        #expect(result == "5")
    }

    @Test("filters, floor, positive integer", .timeLimit(.minutes(1)))
    func positiveInteger() async throws {
        let result = try await renderWithTimeout(template: "{{ 5 | floor }}", context: [:])
        #expect(result == "5")
    }

    @Test("filters, floor, positive string float", .timeLimit(.minutes(1)))
    func positiveStringFloat() async throws {
        let result = try await renderWithTimeout(template: "{{ \"5.1\" | floor }}", context: [:])
        #expect(result == "5")
    }

    @Test("filters, floor, string not a number", .timeLimit(.minutes(1)))
    func stringNotANumber() async throws {
        let result = try await renderWithTimeout(template: "{{ \"hello\" | floor }}", context: [:])
        #expect(result == "0")
    }

    @Test("filters, floor, undefined left value", .timeLimit(.minutes(1)))
    func undefinedLeftValue() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | floor }}", context: [:])
        #expect(result == "0")
    }

    @Test("filters, floor, unexpected argument", .timeLimit(.minutes(1)))
    func unexpectedArgument() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ -3.1 | floor: 1 }}", context: [:])
            Issue.record("Expected error for \"filters, floor, unexpected argument\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, floor, zero", .timeLimit(.minutes(1)))
    func zero() async throws {
        let result = try await renderWithTimeout(template: "{{ 0 | floor }}", context: [:])
        #expect(result == "0")
    }
}
