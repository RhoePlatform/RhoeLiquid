//
//  TruncateTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: truncate", .serialized)
struct GoldenTruncateTests {

    @Test("filters, truncate, custom end", .timeLimit(.minutes(1)))
    func customEnd() async throws {
        let result = try await renderWithTimeout(template: "{{ \"Ground control to Major Tom.\" | truncate: 25, \", and so on\" }}", context: [:])
        #expect(result == "Ground control, and so on")
    }

    @Test("filters, truncate, default end", .timeLimit(.minutes(1)))
    func defaultEnd() async throws {
        let result = try await renderWithTimeout(template: "{{ \"Ground control to Major Tom.\" | truncate: 20 }}", context: [:])
        #expect(result == "Ground control to...")
    }

    @Test("filters, truncate, default length is 50", .timeLimit(.minutes(1)))
    func defaultLengthIs50() async throws {
        let result = try await renderWithTimeout(template: "{{ \"Ground control to Major Tom. Ground control to Major Tom.\" | truncate }}", context: [:])
        #expect(result == "Ground control to Major Tom. Ground control to ...")
    }

    @Test("filters, truncate, no end", .timeLimit(.minutes(1)))
    func noEnd() async throws {
        let result = try await renderWithTimeout(template: "{{ \"Ground control to Major Tom.\" | truncate: 20, \"\" }}", context: [:])
        #expect(result == "Ground control to Ma")
    }

    @Test("filters, truncate, not a string", .timeLimit(.minutes(1)))
    func notAString() async throws {
        let result = try await renderWithTimeout(template: "{{ 5 | truncate: 10 }}", context: [:])
        #expect(result == "5")
    }

    @Test("filters, truncate, string is shorter than length", .timeLimit(.minutes(1)))
    func stringIsShorterThanLength() async throws {
        let result = try await renderWithTimeout(template: "{{ \"Ground control\" | truncate: 20 }}", context: [:])
        #expect(result == "Ground control")
    }

    @Test("filters, truncate, too many arguments", .timeLimit(.minutes(1)))
    func tooManyArguments() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ \"hello\" | truncate: 5, \"foo\", \"bar\" }}", context: [:])
            Issue.record("Expected error for \"filters, truncate, too many arguments\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, truncate, undefined first argument", .timeLimit(.minutes(1)))
    func undefinedFirstArgument() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ \"Ground control to Major Tom.\" | truncate: nosuchthing }}", context: [:])
            Issue.record("Expected error for \"filters, truncate, undefined first argument\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, truncate, undefined left value", .timeLimit(.minutes(1)))
    func undefinedLeftValue() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | truncate: 5 }}", context: [:])
        #expect(result == "")
    }

    @Test("filters, truncate, undefined second argument", .timeLimit(.minutes(1)))
    func undefinedSecondArgument() async throws {
        let result = try await renderWithTimeout(template: "{{ \"Ground control to Major Tom.\" | truncate: 20, nosuchthing }}", context: [:])
        #expect(result == "Ground control to Ma")
    }
}
