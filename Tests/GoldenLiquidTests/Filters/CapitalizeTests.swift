//
//  CapitalizeTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: capitalize", .serialized)
struct GoldenCapitalizeTests {

    @Test("filters, capitalize, already capitalized string", .timeLimit(.minutes(1)))
    func alreadyCapitalizedString() async throws {
        let result = try await renderWithTimeout(template: "{{ \"Hello\" | capitalize }}", context: [:])
        #expect(result == "Hello")
    }

    @Test("filters, capitalize, lower case string", .timeLimit(.minutes(1)))
    func lowerCaseString() async throws {
        let result = try await renderWithTimeout(template: "{{ \"hello\" | capitalize }}", context: [:])
        #expect(result == "Hello")
    }

    @Test("filters, capitalize, undefined left value", .timeLimit(.minutes(1)))
    func undefinedLeftValue() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | capitalize }}", context: [:])
        #expect(result == "")
    }

    @Test("filters, capitalize, unexpected argument", .timeLimit(.minutes(1)))
    func unexpectedArgument() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ \"hello\" | capitalize: 2 }}", context: [:])
            Issue.record("Expected error for \"filters, capitalize, unexpected argument\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }
}
