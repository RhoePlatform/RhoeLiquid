//
//  LstripTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: lstrip", .serialized)
struct GoldenLstripTests {

    @Test("filters, lstrip, left and right padded", .timeLimit(.minutes(1)))
    func leftAndRightPadded() async throws {
        let result = try await renderWithTimeout(template: "{{ \" \t\r\n  hello  \t\r\n \" | lstrip }}", context: [:])
        #expect(result == "hello  \t\r\n ")
    }

    @Test("filters, lstrip, left padded", .timeLimit(.minutes(1)))
    func leftPadded() async throws {
        let result = try await renderWithTimeout(template: "{{ \" \t\r\n  hello\" | lstrip }}", context: [:])
        #expect(result == "hello")
    }

    @Test("filters, lstrip, not a string", .timeLimit(.minutes(1)))
    func notAString() async throws {
        let result = try await renderWithTimeout(template: "{{ 5 | lstrip }}", context: [:])
        #expect(result == "5")
    }

    @Test("filters, lstrip, right padded", .timeLimit(.minutes(1)))
    func rightPadded() async throws {
        let result = try await renderWithTimeout(template: "{{ \"hello \t\r\n  \" | lstrip }}", context: [:])
        #expect(result == "hello \t\r\n  ")
    }

    @Test("filters, lstrip, undefined left value", .timeLimit(.minutes(1)))
    func undefinedLeftValue() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | lstrip }}", context: [:])
        #expect(result == "")
    }

    @Test("filters, lstrip, unexpected argument", .timeLimit(.minutes(1)))
    func unexpectedArgument() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ \"hello\" | lstrip: 5 }}", context: [:])
            Issue.record("Expected error for \"filters, lstrip, unexpected argument\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }
}
