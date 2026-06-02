//
//  DowncaseTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: downcase", .serialized)
struct GoldenDowncaseTests {

    @Test("filters, downcase, make lower case", .timeLimit(.minutes(1)))
    func makeLowerCase() async throws {
        let result = try await renderWithTimeout(template: "{{ \"HELLO\" | downcase }}", context: [:])
        #expect(result == "hello")
    }

    @Test("filters, downcase, not a string", .timeLimit(.minutes(1)))
    func notAString() async throws {
        let result = try await renderWithTimeout(template: "{{ 5 | downcase }}", context: [:])
        #expect(result == "5")
    }

    @Test("filters, downcase, undefined left value", .timeLimit(.minutes(1)))
    func undefinedLeftValue() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | downcase }}", context: [:])
        #expect(result == "")
    }

    @Test("filters, downcase, unexpected argument", .timeLimit(.minutes(1)))
    func unexpectedArgument() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ \"HELLO\" | downcase: 5 }}", context: [:])
            Issue.record("Expected error for \"filters, downcase, unexpected argument\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }
}
