//
//  EscapeTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: escape", .serialized)
struct GoldenEscapeTests {

    @Test("filters, escape, make HTML-safe", .timeLimit(.minutes(1)))
    func makeHtmlSafe() async throws {
        let result = try await renderWithTimeout(template: "{{ \"<p>test</p>\" | escape }}", context: [:])
        #expect(result == "&lt;p&gt;test&lt;/p&gt;")
    }

    @Test("filters, escape, not a string", .timeLimit(.minutes(1)))
    func notAString() async throws {
        let result = try await renderWithTimeout(template: "{{ 5 | escape }}", context: [:])
        #expect(result == "5")
    }

    @Test("filters, escape, undefined left value", .timeLimit(.minutes(1)))
    func undefinedLeftValue() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | escape }}", context: [:])
        #expect(result == "")
    }

    @Test("filters, escape, unexpected argument", .timeLimit(.minutes(1)))
    func unexpectedArgument() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ \"HELLO\" | escape: 5 }}", context: [:])
            Issue.record("Expected error for \"filters, escape, unexpected argument\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }
}
