//
//  AppendTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: append", .serialized)
struct GoldenAppendTests {

    @Test("filters, append, argument not a string", .timeLimit(.minutes(1)))
    func argumentNotAString() async throws {
        let result = try await renderWithTimeout(template: "{{ \"hello\" | append: 5 }}", context: [:])
        #expect(result == "hello5")
    }

    @Test("filters, append, concat", .timeLimit(.minutes(1)))
    func concat() async throws {
        let result = try await renderWithTimeout(template: "{{ \"hello\" | append: \"there\" }}", context: [:])
        #expect(result == "hellothere")
    }

    @Test("filters, append, missing argument", .timeLimit(.minutes(1)))
    func missingArgument() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ \"hello\" | append }}", context: [:])
            Issue.record("Expected error for \"filters, append, missing argument\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, append, not a string", .timeLimit(.minutes(1)))
    func notAString() async throws {
        let result = try await renderWithTimeout(template: "{{ 5 | append: 'there' }}", context: [:])
        #expect(result == "5there")
    }

    @Test("filters, append, too many arguments", .timeLimit(.minutes(1)))
    func tooManyArguments() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ \"hello\" | append: \"how\", \"are\", \"you\" }}", context: [:])
            Issue.record("Expected error for \"filters, append, too many arguments\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, append, undefined argument", .timeLimit(.minutes(1)))
    func undefinedArgument() async throws {
        let result = try await renderWithTimeout(template: "{{ \"hi\" | append: nosuchthing }}", context: [:])
        #expect(result == "hi")
    }

    @Test("filters, append, undefined left value", .timeLimit(.minutes(1)))
    func undefinedLeftValue() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | append: \"hi\" }}", context: [:])
        #expect(result == "hi")
    }
}
