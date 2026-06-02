//
//  RemoveTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: remove", .serialized)
struct GoldenRemoveTests {

    @Test("filters, remove, argument not a string", .timeLimit(.minutes(1)))
    func argumentNotAString() async throws {
        let result = try await renderWithTimeout(template: "{{ \"hello\" | remove: 5 }}", context: [:])
        #expect(result == "hello")
    }

    @Test("filters, remove, missing argument", .timeLimit(.minutes(1)))
    func missingArgument() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ \"hello\" | remove }}", context: [:])
            Issue.record("Expected error for \"filters, remove, missing argument\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, remove, not a string", .timeLimit(.minutes(1)))
    func notAString() async throws {
        let result = try await renderWithTimeout(template: "{{ 5 | remove: 'there' }}", context: [:])
        #expect(result == "5")
    }

    @Test("filters, remove, remove substrings", .timeLimit(.minutes(1)))
    func removeSubstrings() async throws {
        let result = try await renderWithTimeout(template: "{{ \"I strained to see the train through the rain\" | remove: \"rain\" }}", context: [:])
        #expect(result == "I sted to see the t through the ")
    }

    @Test("filters, remove, too many arguments", .timeLimit(.minutes(1)))
    func tooManyArguments() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ \"hello\" | remove: \"how\", \"are\", \"you\" }}", context: [:])
            Issue.record("Expected error for \"filters, remove, too many arguments\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, remove, undefined argument", .timeLimit(.minutes(1)))
    func undefinedArgument() async throws {
        let result = try await renderWithTimeout(template: "{{ \"hello\" | remove: nosuchthing }}", context: [:])
        #expect(result == "hello")
    }

    @Test("filters, remove, undefined left value", .timeLimit(.minutes(1)))
    func undefinedLeftValue() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | remove: \"rain\" }}", context: [:])
        #expect(result == "")
    }
}
