//
//  ReplaceLastTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: replace last", .serialized)
struct GoldenReplaceLastTests {

    @Test("filters, replace last, argument not a string", .timeLimit(.minutes(1)))
    func argumentNotAString() async throws {
        let result = try await renderWithTimeout(template: "{{ \"hello5\" | replace_last: 5, \"your\" }}", context: [:])
        #expect(result == "helloyour")
    }

    @Test("filters, replace last, missing argument", .timeLimit(.minutes(1)))
    func missingArgument() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ \"hello\" | replace_last: \"ll\" }}", context: [:])
            Issue.record("Expected error for \"filters, replace last, missing argument\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, replace last, missing arguments", .timeLimit(.minutes(1)))
    func missingArguments() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ \"hello\" | replace_last }}", context: [:])
            Issue.record("Expected error for \"filters, replace last, missing arguments\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, replace last, not a string", .timeLimit(.minutes(1)))
    func notAString() async throws {
        let result = try await renderWithTimeout(template: "{{ 5 | replace_last: 'rain', 'foo' }}", context: [:])
        #expect(result == "5")
    }

    @Test("filters, replace last, replace substrings", .timeLimit(.minutes(1)))
    func replaceSubstrings() async throws {
        let result = try await renderWithTimeout(template: "{{ \"Take my protein pills and put my helmet on\" | replace_last: \"my\", \"your\" }}", context: [:])
        #expect(result == "Take my protein pills and put your helmet on")
    }

    @Test("filters, replace last, too many arguments", .timeLimit(.minutes(1)))
    func tooManyArguments() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ \"hello\" | replace_last: \"how\", \"are\", \"you\" }}", context: [:])
            Issue.record("Expected error for \"filters, replace last, too many arguments\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, replace last, undefined first argument", .timeLimit(.minutes(1)))
    func undefinedFirstArgument() async throws {
        let result = try await renderWithTimeout(template: "{{ \"Take my protein\" | replace_last: nosuchthing, \"#\" }}", context: [:])
        #expect(result == "Take my protein#")
    }

    @Test("filters, replace last, undefined left value", .timeLimit(.minutes(1)))
    func undefinedLeftValue() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | replace_last: \"my\", \"your\" }}", context: [:])
        #expect(result == "")
    }

    @Test("filters, replace last, undefined second argument", .timeLimit(.minutes(1)))
    func undefinedSecondArgument() async throws {
        let result = try await renderWithTimeout(template: "{{ \"Take my protein pills and put my helmet on\" | replace_last: \"my\", nosuchthing }}", context: [:])
        #expect(result == "Take my protein pills and put  helmet on")
    }
}
