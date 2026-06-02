//
//  PrependTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: prepend", .serialized)
struct GoldenPrependTests {

    @Test("filters, prepend, argument not a string", .timeLimit(.minutes(1)))
    func argumentNotAString() async throws {
        let result = try await renderWithTimeout(template: "{{ \"hello\" | prepend: 5 }}", context: [:])
        #expect(result == "5hello")
    }

    @Test("filters, prepend, concat", .timeLimit(.minutes(1)))
    func concat() async throws {
        let result = try await renderWithTimeout(template: "{{ \"hello\" | prepend: \"there\" }}", context: [:])
        #expect(result == "therehello")
    }

    @Test("filters, prepend, missing argument", .timeLimit(.minutes(1)))
    func missingArgument() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ \"hello\" | prepend }}", context: [:])
            Issue.record("Expected error for \"filters, prepend, missing argument\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, prepend, not a string", .timeLimit(.minutes(1)))
    func notAString() async throws {
        let result = try await renderWithTimeout(template: "{{ 5 | prepend: 'there' }}", context: [:])
        #expect(result == "there5")
    }

    @Test("filters, prepend, too many arguments", .timeLimit(.minutes(1)))
    func tooManyArguments() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ \"hello\" | prepend: \"how\", \"are\", \"you\" }}", context: [:])
            Issue.record("Expected error for \"filters, prepend, too many arguments\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, prepend, undefined argument", .timeLimit(.minutes(1)))
    func undefinedArgument() async throws {
        let result = try await renderWithTimeout(template: "{{ \"hi\" | prepend: nosuchthing }}", context: [:])
        #expect(result == "hi")
    }

    @Test("filters, prepend, undefined left value", .timeLimit(.minutes(1)))
    func undefinedLeftValue() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | prepend: \"hi\" }}", context: [:])
        #expect(result == "hi")
    }
}
