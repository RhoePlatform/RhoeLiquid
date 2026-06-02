//
//  RstripTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: rstrip", .serialized)
struct GoldenRstripTests {

    @Test("filters, rstrip, left and right padded", .timeLimit(.minutes(1)))
    func leftAndRightPadded() async throws {
        let result = try await renderWithTimeout(template: "{{ \" \t\r\n  hello  \t\r\n \" | rstrip }}", context: [:])
        #expect(result == " \t\r\n  hello")
    }

    @Test("filters, rstrip, left padded", .timeLimit(.minutes(1)))
    func leftPadded() async throws {
        let result = try await renderWithTimeout(template: "{{ \" \t\r\n  hello\" | rstrip }}", context: [:])
        #expect(result == " \t\r\n  hello")
    }

    @Test("filters, rstrip, not a string", .timeLimit(.minutes(1)))
    func notAString() async throws {
        let result = try await renderWithTimeout(template: "{{ 5 | rstrip }}", context: [:])
        #expect(result == "5")
    }

    @Test("filters, rstrip, right padded", .timeLimit(.minutes(1)))
    func rightPadded() async throws {
        let result = try await renderWithTimeout(template: "{{ \"hello \t\r\n  \" | rstrip }}", context: [:])
        #expect(result == "hello")
    }

    @Test("filters, rstrip, undefined left value", .timeLimit(.minutes(1)))
    func undefinedLeftValue() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | rstrip }}", context: [:])
        #expect(result == "")
    }

    @Test("filters, rstrip, unexpected argument", .timeLimit(.minutes(1)))
    func unexpectedArgument() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ \"hello\" | rstrip: 5 }}", context: [:])
            Issue.record("Expected error for \"filters, rstrip, unexpected argument\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }
}
