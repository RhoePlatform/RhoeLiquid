//
//  UrlDecodeTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: url decode", .serialized)
struct GoldenUrlDecodeTests {

    @Test("filters, url decode, not a string", .timeLimit(.minutes(1)))
    func notAString() async throws {
        let result = try await renderWithTimeout(template: "{{ 5 | url_decode }}", context: [:])
        #expect(result == "5")
    }

    @Test("filters, url decode, some special URL characters", .timeLimit(.minutes(1)))
    func someSpecialUrlCharacters() async throws {
        let result = try await renderWithTimeout(template: "{{ \"email+address+is+bob%40example.com%21\" | url_decode }}", context: [:])
        #expect(result == "email address is bob@example.com!")
    }

    @Test("filters, url decode, undefined left value", .timeLimit(.minutes(1)))
    func undefinedLeftValue() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | url_decode }}", context: [:])
        #expect(result == "")
    }

    @Test("filters, url decode, unexpected argument", .timeLimit(.minutes(1)))
    func unexpectedArgument() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ \"hello\" | url_decode: 5 }}", context: [:])
            Issue.record("Expected error for \"filters, url decode, unexpected argument\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }
}
