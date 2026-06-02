//
//  RemoveLastTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: remove last", .serialized)
struct GoldenRemoveLastTests {

    @Test("filters, remove last, argument not a string", .timeLimit(.minutes(1)))
    func argumentNotAString() async throws {
        let result = try await renderWithTimeout(template: "{{ \"hello\" | remove_last: 5 }}", context: [:])
        #expect(result == "hello")
    }

    @Test("filters, remove last, missing argument", .timeLimit(.minutes(1)))
    func missingArgument() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ \"hello\" | remove_last }}", context: [:])
            Issue.record("Expected error for \"filters, remove last, missing argument\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, remove last, not a string", .timeLimit(.minutes(1)))
    func notAString() async throws {
        let result = try await renderWithTimeout(template: "{{ 5 | remove_last: 'rain' }}", context: [:])
        #expect(result == "5")
    }

    @Test("filters, remove last, remove substrings", .timeLimit(.minutes(1)))
    func removeSubstrings() async throws {
        let result = try await renderWithTimeout(template: "{{ \"I strained to see the train through the rain\" | remove_last: \"rain\" }}", context: [:])
        #expect(result == "I strained to see the train through the ")
    }

    @Test("filters, remove last, too many arguments", .timeLimit(.minutes(1)))
    func tooManyArguments() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ \"hello\" | remove_last: \"how\", \"are\", \"you\" }}", context: [:])
            Issue.record("Expected error for \"filters, remove last, too many arguments\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, remove last, undefined argument", .timeLimit(.minutes(1)))
    func undefinedArgument() async throws {
        let result = try await renderWithTimeout(template: "{{ \"hello\" | remove_last: nosuchthing }}", context: [:])
        #expect(result == "hello")
    }

    @Test("filters, remove last, undefined left value", .timeLimit(.minutes(1)))
    func undefinedLeftValue() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | remove_last: \"rain\" }}", context: [:])
        #expect(result == "")
    }
}
