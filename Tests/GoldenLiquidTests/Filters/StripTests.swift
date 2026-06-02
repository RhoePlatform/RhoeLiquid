//
//  StripTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: strip", .serialized)
struct GoldenStripTests {

    @Test("filters, strip, left and right padded", .timeLimit(.minutes(1)))
    func leftAndRightPadded() async throws {
        let result = try await renderWithTimeout(template: "{{ \" \t\r\n  hello  \t\r\n \" | strip }}", context: [:])
        #expect(result == "hello")
    }

    @Test("filters, strip, left padded", .timeLimit(.minutes(1)))
    func leftPadded() async throws {
        let result = try await renderWithTimeout(template: "{{ \" \t\r\n  hello\" | strip }}", context: [:])
        #expect(result == "hello")
    }

    @Test("filters, strip, not a string", .timeLimit(.minutes(1)))
    func notAString() async throws {
        let result = try await renderWithTimeout(template: "{{ 5 | strip }}", context: [:])
        #expect(result == "5")
    }

    @Test("filters, strip, right padded", .timeLimit(.minutes(1)))
    func rightPadded() async throws {
        let result = try await renderWithTimeout(template: "{{ \"hello \t\r\n  \" | strip }}", context: [:])
        #expect(result == "hello")
    }

    @Test("filters, strip, undefined left value", .timeLimit(.minutes(1)))
    func undefinedLeftValue() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | strip }}", context: [:])
        #expect(result == "")
    }

    @Test("filters, strip, unexpected argument", .timeLimit(.minutes(1)))
    func unexpectedArgument() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ \"hello\" | strip: 5 }}", context: [:])
            Issue.record("Expected error for \"filters, strip, unexpected argument\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }
}
