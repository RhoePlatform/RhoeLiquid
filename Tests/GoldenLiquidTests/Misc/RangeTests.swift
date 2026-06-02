//
//  RangeTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: range", .serialized)
struct GoldenRangeTests {

    @Test("range, end is less than start", .timeLimit(.minutes(1)))
    func endIsLessThanStart() async throws {
        let ctx: [String: Any] = [
            "start": 5,
            "end": 1
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ (start..end) | join: '#' }}", context: ctx)
        #expect(result == "")
    }

    @Test("range, end is not a number", .timeLimit(.minutes(1)))
    func endIsNotANumber() async throws {
        let ctx: [String: Any] = [
            "start": "1",
            "end": "foo"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ (start..end) | join: '#' }}", context: ctx)
        #expect(result == "")
    }

    @Test("range, integer literals", .timeLimit(.minutes(1)))
    func integerLiterals() async throws {
        let result = try await renderWithTimeout(template: "{{ (1..5) | join: '#' }}", context: [:])
        #expect(result == "1#2#3#4#5")
    }

    @Test("range, start and end are negative", .timeLimit(.minutes(1)))
    func startAndEndAreNegative() async throws {
        let ctx: [String: Any] = [
            "start": -5,
            "end": -2
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ (start..end) | join: '#' }}", context: ctx)
        #expect(result == "-5#-4#-3#-2")
    }

    @Test("range, start is negative", .timeLimit(.minutes(1)))
    func startIsNegative() async throws {
        let ctx: [String: Any] = [
            "start": -5,
            "end": 1
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ (start..end) | join: '#' }}", context: ctx)
        #expect(result == "-5#-4#-3#-2#-1#0#1")
    }

    @Test("range, start is not a number", .timeLimit(.minutes(1)))
    func startIsNotANumber() async throws {
        let ctx: [String: Any] = [
            "start": "foo",
            "end": 5
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ (start..end) | join: '#' }}", context: ctx)
        #expect(result == "0#1#2#3#4#5")
    }

    @Test("range, whitespace after dots", .timeLimit(.minutes(1)))
    func whitespaceAfterDots() async throws {
        let result = try await renderWithTimeout(template: "{{ (1.. \n\t5) | join: '#' }}", context: [:])
        #expect(result == "1#2#3#4#5")
    }

    @Test("range, whitespace after stop", .timeLimit(.minutes(1)))
    func whitespaceAfterStop() async throws {
        let result = try await renderWithTimeout(template: "{{ (1..5 \n\t) | join: '#' }}", context: [:])
        #expect(result == "1#2#3#4#5")
    }

    @Test("range, whitespace before and after dots", .timeLimit(.minutes(1)))
    func whitespaceBeforeAndAfterDots() async throws {
        let result = try await renderWithTimeout(template: "{{ (1 .. 5) | join: '#' }}", context: [:])
        #expect(result == "1#2#3#4#5")
    }

    @Test("range, whitespace before and after dots, for loop", .timeLimit(.minutes(1)))
    func forLoop() async throws {
        let result = try await renderWithTimeout(template: "{% for x in (1 .. 5) %}{{ x }},{% endfor %}", context: [:])
        #expect(result == "1,2,3,4,5,")
    }

    @Test("range, whitespace before dots", .timeLimit(.minutes(1)))
    func whitespaceBeforeDots() async throws {
        let result = try await renderWithTimeout(template: "{{ (1 \n\t..5) | join: '#' }}", context: [:])
        #expect(result == "1#2#3#4#5")
    }

    @Test("range, whitespace before start", .timeLimit(.minutes(1)))
    func whitespaceBeforeStart() async throws {
        let result = try await renderWithTimeout(template: "{{ ( \n\t1..5) | join: '#' }}", context: [:])
        #expect(result == "1#2#3#4#5")
    }
}
