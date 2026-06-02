//
//  RemoveFirstTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: remove first", .serialized)
struct GoldenRemoveFirstTests {

    @Test("filters, remove first, argument not a string", .timeLimit(.minutes(1)))
    func argumentNotAString() async throws {
        let result = try await renderWithTimeout(template: "{{ \"hello\" | remove_first: 5 }}", context: [:])
        #expect(result == "hello")
    }

    @Test("filters, remove first, missing argument", .timeLimit(.minutes(1)))
    func missingArgument() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ \"hello\" | remove_first }}", context: [:])
            Issue.record("Expected error for \"filters, remove first, missing argument\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, remove first, not a string", .timeLimit(.minutes(1)))
    func notAString() async throws {
        let result = try await renderWithTimeout(template: "{{ 5 | remove_first: 'rain' }}", context: [:])
        #expect(result == "5")
    }

    @Test("filters, remove first, remove substrings", .timeLimit(.minutes(1)))
    func removeSubstrings() async throws {
        let result = try await renderWithTimeout(template: "{{ \"I strained to see the train through the rain\" | remove_first: \"rain\" }}", context: [:])
        #expect(result == "I sted to see the train through the rain")
    }

    @Test("filters, remove first, too many arguments", .timeLimit(.minutes(1)))
    func tooManyArguments() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ \"hello\" | remove_first: \"how\", \"are\", \"you\" }}", context: [:])
            Issue.record("Expected error for \"filters, remove first, too many arguments\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, remove first, undefined argument", .timeLimit(.minutes(1)))
    func undefinedArgument() async throws {
        let result = try await renderWithTimeout(template: "{{ \"hello\" | remove_first: nosuchthing }}", context: [:])
        #expect(result == "hello")
    }

    @Test("filters, remove first, undefined left value", .timeLimit(.minutes(1)))
    func undefinedLeftValue() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | remove_first: \"rain\" }}", context: [:])
        #expect(result == "")
    }
}
