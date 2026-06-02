//
//  TruncatewordsTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: truncatewords", .serialized)
struct GoldenTruncatewordsTests {

    @Test("filters, truncatewords, all whitespace is clobbered", .timeLimit(.minutes(1)))
    func allWhitespaceIsClobbered() async throws {
        let result = try await renderWithTimeout(template: "{{ \"    one    two three    four  \" | truncatewords: 2 }}", context: [:])
        #expect(result == "one two...")
    }

    @Test("filters, truncatewords, custom end", .timeLimit(.minutes(1)))
    func customEnd() async throws {
        let result = try await renderWithTimeout(template: "{{ \"Ground control to Major Tom.\" | truncatewords: 3, \"--\" }}", context: [:])
        #expect(result == "Ground control to--")
    }

    @Test("filters, truncatewords, default end", .timeLimit(.minutes(1)))
    func defaultEnd() async throws {
        let result = try await renderWithTimeout(template: "{{ \"Ground control to Major Tom.\" | truncatewords: 3 }}", context: [:])
        #expect(result == "Ground control to...")
    }

    @Test("filters, truncatewords, fewer words than word count", .timeLimit(.minutes(1)))
    func fewerWordsThanWordCount() async throws {
        let result = try await renderWithTimeout(template: "{{ \"Ground control\" | truncatewords: 3 }}", context: [:])
        #expect(result == "Ground control")
    }

    @Test("filters, truncatewords, no end", .timeLimit(.minutes(1)))
    func noEnd() async throws {
        let result = try await renderWithTimeout(template: "{{ \"Ground control to Major Tom.\" | truncatewords: 3, \"\" }}", context: [:])
        #expect(result == "Ground control to")
    }

    @Test("filters, truncatewords, not a string", .timeLimit(.minutes(1)))
    func notAString() async throws {
        let result = try await renderWithTimeout(template: "{{ 5 | truncatewords: 10 }}", context: [:])
        #expect(result == "5")
    }

    @Test("filters, truncatewords, number of words defaults to 15", .timeLimit(.minutes(1)))
    func numberOfWordsDefaultsTo15() async throws {
        let result = try await renderWithTimeout(template: "{{ \"a b c d e f g h i j k l m n o p q\" | truncatewords }}", context: [:])
        #expect(result == "a b c d e f g h i j k l m n o...")
    }

    @Test("filters, truncatewords, reference implementation test 1", .timeLimit(.minutes(1)))
    func referenceImplementationTest1() async throws {
        let result = try await renderWithTimeout(template: "{{ \"测试测试测试测试\" | truncatewords: 5 }}", context: [:])
        #expect(result == "测试测试测试测试")
    }

    @Test("filters, truncatewords, reference implementation test 2", .timeLimit(.minutes(1)))
    func referenceImplementationTest2() async throws {
        let result = try await renderWithTimeout(template: "{{ \"one two three\" | truncatewords: 2, 1 }}", context: [:])
        #expect(result == "one two1")
    }

    @Test("filters, truncatewords, reference implementation test 3", .timeLimit(.minutes(1)))
    func referenceImplementationTest3() async throws {
        let result = try await renderWithTimeout(template: "{{ \"one  two\tthree\nfour\" | truncatewords: 3 }}", context: [:])
        #expect(result == "one two three...")
    }

    @Test("filters, truncatewords, reference implementation test 4", .timeLimit(.minutes(1)))
    func referenceImplementationTest4() async throws {
        let result = try await renderWithTimeout(template: "{{ \"one two three four\" | truncatewords: 2 }}", context: [:])
        #expect(result == "one two...")
    }

    @Test("filters, truncatewords, reference implementation test 5", .timeLimit(.minutes(1)))
    func referenceImplementationTest5() async throws {
        let result = try await renderWithTimeout(template: "{{ \"one two three four\" | truncatewords: 0 }}", context: [:])
        #expect(result == "one...")
    }

    @Test("filters, truncatewords, too many arguments", .timeLimit(.minutes(1)))
    func tooManyArguments() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ \"hello\" | truncatewords: 5, \"foo\", \"bar\" }}", context: [:])
            Issue.record("Expected error for \"filters, truncatewords, too many arguments\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, truncatewords, undefined first argument", .timeLimit(.minutes(1)))
    func undefinedFirstArgument() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ \"one two three four\" | truncatewords: nosuchthing }}", context: [:])
            Issue.record("Expected error for \"filters, truncatewords, undefined first argument\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, truncatewords, undefined left value", .timeLimit(.minutes(1)))
    func undefinedLeftValue() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | truncatewords: 5 }}", context: [:])
        #expect(result == "")
    }

    @Test("filters, truncatewords, undefined second argument", .timeLimit(.minutes(1)))
    func undefinedSecondArgument() async throws {
        let result = try await renderWithTimeout(template: "{{ \"one two three four\" | truncatewords: 2, nosuchthing }}", context: [:])
        #expect(result == "one two")
    }
}
