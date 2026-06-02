//
//  ReplaceFirstTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: replace first", .serialized)
struct GoldenReplaceFirstTests {

    @Test("filters, replace first, argument not a string", .timeLimit(.minutes(1)))
    func argumentNotAString() async throws {
        let result = try await renderWithTimeout(template: "{{ \"hello5\" | replace_first: 5, \"your\" }}", context: [:])
        #expect(result == "helloyour")
    }

    @Test("filters, replace first, missing argument", .timeLimit(.minutes(1)))
    func missingArgument() async throws {
        let result = try await renderWithTimeout(template: "{{ \"hello\" | replace_first: \"ll\" }}", context: [:])
        #expect(result == "heo")
    }

    @Test("filters, replace first, missing arguments", .timeLimit(.minutes(1)))
    func missingArguments() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ \"hello\" | replace_first }}", context: [:])
            Issue.record("Expected error for \"filters, replace first, missing arguments\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, replace first, not a string", .timeLimit(.minutes(1)))
    func notAString() async throws {
        let result = try await renderWithTimeout(template: "{{ 5 | replace_first: 'rain', 'foo' }}", context: [:])
        #expect(result == "5")
    }

    @Test("filters, replace first, replace substrings", .timeLimit(.minutes(1)))
    func replaceSubstrings() async throws {
        let result = try await renderWithTimeout(template: "{{ \"Take my protein pills and put my helmet on\" | replace_first: \"my\", \"your\" }}", context: [:])
        #expect(result == "Take your protein pills and put my helmet on")
    }

    @Test("filters, replace first, too many arguments", .timeLimit(.minutes(1)))
    func tooManyArguments() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ \"hello\" | replace_first: \"how\", \"are\", \"you\" }}", context: [:])
            Issue.record("Expected error for \"filters, replace first, too many arguments\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, replace first, undefined first argument", .timeLimit(.minutes(1)))
    func undefinedFirstArgument() async throws {
        let result = try await renderWithTimeout(template: "{{ \"Take my protein\" | replace_first: nosuchthing, \"#\" }}", context: [:])
        #expect(result == "#Take my protein")
    }

    @Test("filters, replace first, undefined left value", .timeLimit(.minutes(1)))
    func undefinedLeftValue() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | replace_first: \"my\", \"your\" }}", context: [:])
        #expect(result == "")
    }

    @Test("filters, replace first, undefined second argument", .timeLimit(.minutes(1)))
    func undefinedSecondArgument() async throws {
        let result = try await renderWithTimeout(template: "{{ \"Take my protein pills and put my helmet on\" | replace_first: \"my\", nosuchthing }}", context: [:])
        #expect(result == "Take  protein pills and put my helmet on")
    }
}
