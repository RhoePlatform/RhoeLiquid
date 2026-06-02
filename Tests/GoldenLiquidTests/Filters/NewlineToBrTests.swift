//
//  NewlineToBrTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: newline to br", .serialized)
struct GoldenNewlineToBrTests {

    @Test("filters, newline to br, not a string", .timeLimit(.minutes(1)))
    func notAString() async throws {
        let result = try await renderWithTimeout(template: "{{ 5 | newline_to_br }}", context: [:])
        #expect(result == "5")
    }

    @Test("filters, newline to br, reference implementation test 1", .timeLimit(.minutes(1)))
    func referenceImplementationTest1() async throws {
        let result = try await renderWithTimeout(template: "{{ \"a\nb\nc\" | newline_to_br }}", context: [:])
        #expect(result == "a<br />\nb<br />\nc")
    }

    @Test("filters, newline to br, reference implementation test 2", .timeLimit(.minutes(1)))
    func referenceImplementationTest2() async throws {
        let result = try await renderWithTimeout(template: "{{ \"a\r\nb\nc\" | newline_to_br }}", context: [:])
        #expect(result == "a<br />\nb<br />\nc")
    }

    @Test("filters, newline to br, string with newlines", .timeLimit(.minutes(1)))
    func stringWithNewlines() async throws {
        let result = try await renderWithTimeout(template: "{{ \"- apples\n- oranges\n\" | newline_to_br }}", context: [:])
        #expect(result == "- apples<br />\n- oranges<br />\n")
    }

    @Test("filters, newline to br, undefined left value", .timeLimit(.minutes(1)))
    func undefinedLeftValue() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | newline_to_br }}", context: [:])
        #expect(result == "")
    }

    @Test("filters, newline to br, unexpected argument", .timeLimit(.minutes(1)))
    func unexpectedArgument() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ \"hello\" | newline_to_br: 5 }}", context: [:])
            Issue.record("Expected error for \"filters, newline to br, unexpected argument\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }
}
