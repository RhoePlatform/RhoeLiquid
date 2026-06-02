//
//  StripNewlinesTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: strip newlines", .serialized)
struct GoldenStripNewlinesTests {

    @Test("filters, strip newlines, newline and other whitespace", .timeLimit(.minutes(1)))
    func newlineAndOtherWhitespace() async throws {
        let result = try await renderWithTimeout(template: "{{ \"hello there\nyou\" | strip_newlines }}", context: [:])
        #expect(result == "hello thereyou")
    }

    @Test("filters, strip newlines, not a string", .timeLimit(.minutes(1)))
    func notAString() async throws {
        let result = try await renderWithTimeout(template: "{{ 5 | strip_newlines }}", context: [:])
        #expect(result == "5")
    }

    @Test("filters, strip newlines, reference implementation test 1", .timeLimit(.minutes(1)))
    func referenceImplementationTest1() async throws {
        let result = try await renderWithTimeout(template: "{{ \"a\nb\nc\" | strip_newlines }}", context: [:])
        #expect(result == "abc")
    }

    @Test("filters, strip newlines, reference implementation test 2", .timeLimit(.minutes(1)))
    func referenceImplementationTest2() async throws {
        let result = try await renderWithTimeout(template: "{{ \"a\r\nb\nc\" | strip_newlines }}", context: [:])
        #expect(result == "abc")
    }

    @Test("filters, strip newlines, undefined left value", .timeLimit(.minutes(1)))
    func undefinedLeftValue() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | strip_newlines }}", context: [:])
        #expect(result == "")
    }

    @Test("filters, strip newlines, unexpected argument", .timeLimit(.minutes(1)))
    func unexpectedArgument() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ \"hello\" | strip_newlines: 5 }}", context: [:])
            Issue.record("Expected error for \"filters, strip newlines, unexpected argument\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }
}
