//
//  UpcaseTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: upcase", .serialized)
struct GoldenUpcaseTests {

    @Test("filters, upcase, make lower case", .timeLimit(.minutes(1)))
    func makeLowerCase() async throws {
        let result = try await renderWithTimeout(template: "{{ \"hello\" | upcase }}", context: [:])
        #expect(result == "HELLO")
    }

    @Test("filters, upcase, not a string", .timeLimit(.minutes(1)))
    func notAString() async throws {
        let result = try await renderWithTimeout(template: "{{ 5 | upcase }}", context: [:])
        #expect(result == "5")
    }

    @Test("filters, upcase, undefined left value", .timeLimit(.minutes(1)))
    func undefinedLeftValue() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | upcase }}", context: [:])
        #expect(result == "")
    }

    @Test("filters, upcase, unexpected argument", .timeLimit(.minutes(1)))
    func unexpectedArgument() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ \"hello\" | upcase: 5 }}", context: [:])
            Issue.record("Expected error for \"filters, upcase, unexpected argument\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }
}
