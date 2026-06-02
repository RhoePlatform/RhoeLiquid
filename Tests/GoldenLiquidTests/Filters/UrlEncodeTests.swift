//
//  UrlEncodeTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: url encode", .serialized)
struct GoldenUrlEncodeTests {

    @Test("filters, url encode, not a string", .timeLimit(.minutes(1)))
    func notAString() async throws {
        let result = try await renderWithTimeout(template: "{{ 5 | url_encode }}", context: [:])
        #expect(result == "5")
    }

    @Test("filters, url encode, some special URL characters", .timeLimit(.minutes(1)))
    func someSpecialUrlCharacters() async throws {
        let result = try await renderWithTimeout(template: "{{ \"email address is bob@example.com!\" | url_encode }}", context: [:])
        #expect(result == "email+address+is+bob%40example.com%21")
    }

    @Test("filters, url encode, undefined left value", .timeLimit(.minutes(1)))
    func undefinedLeftValue() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | url_encode }}", context: [:])
        #expect(result == "")
    }

    @Test("filters, url encode, unexpected argument", .timeLimit(.minutes(1)))
    func unexpectedArgument() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ \"hello\" | url_encode: 5 }}", context: [:])
            Issue.record("Expected error for \"filters, url encode, unexpected argument\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }
}
