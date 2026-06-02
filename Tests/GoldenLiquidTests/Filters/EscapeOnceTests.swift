//
//  EscapeOnceTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: escape once", .serialized)
struct GoldenEscapeOnceTests {

    @Test("filters, escape once, make HTML-safe", .timeLimit(.minutes(1)))
    func makeHtmlSafe() async throws {
        let result = try await renderWithTimeout(template: "{{ \"&lt;p&gt;test&lt;/p&gt;\" | escape_once }}", context: [:])
        #expect(result == "&lt;p&gt;test&lt;/p&gt;")
    }

    @Test("filters, escape once, make HTML-safe from mixed safe and markup.", .timeLimit(.minutes(1)))
    func makeHtmlSafeFromMixedSafeAndMarkup() async throws {
        let result = try await renderWithTimeout(template: "{{ \"&lt;p&gt;test&lt;/p&gt;<p>test</p>\" | escape_once }}", context: [:])
        #expect(result == "&lt;p&gt;test&lt;/p&gt;&lt;p&gt;test&lt;/p&gt;")
    }

    @Test("filters, escape once, not a string", .timeLimit(.minutes(1)))
    func notAString() async throws {
        let result = try await renderWithTimeout(template: "{{ 5 | escape_once }}", context: [:])
        #expect(result == "5")
    }

    @Test("filters, escape once, undefined left value", .timeLimit(.minutes(1)))
    func undefinedLeftValue() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | escape_once }}", context: [:])
        #expect(result == "")
    }

    @Test("filters, escape once, unexpected argument", .timeLimit(.minutes(1)))
    func unexpectedArgument() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ \"HELLO\" | escape_once: 5 }}", context: [:])
            Issue.record("Expected error for \"filters, escape once, unexpected argument\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }
}
