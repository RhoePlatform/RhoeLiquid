//
//  CycleTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: cycle", .serialized)
struct GoldenCycleTests {

    @Test("tags, cycle, changing variable name", .timeLimit(.minutes(1)))
    func changingVariableName() async throws {
        let ctx: [String: Any] = [
            "a": "foo"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% cycle a: 1, 2, 3 %}{% assign a = 'bar' %}{% cycle a: 1, 2, 3 %}{% cycle a: 1, 2, 3 %}", context: ctx)
        #expect(result == "112")
    }

    @Test("tags, cycle, different items", .timeLimit(.minutes(1)))
    func differentItems() async throws {
        let result = try await renderWithTimeout(template: "{% cycle '1', '2', '3' %}{% cycle '1', '2' %}{% cycle '1', '2', '3' %}", context: [:])
        #expect(result == "112")
    }

    @Test("tags, cycle, integers", .timeLimit(.minutes(1)))
    func integers() async throws {
        let result = try await renderWithTimeout(template: "{% cycle 1, 2, 3 %}{% cycle 1, 2, 3 %}{% cycle 1, 2, 3 %}", context: [:])
        #expect(result == "123")
    }

    @Test("tags, cycle, multiple undefined variable names", .timeLimit(.minutes(1)))
    func multipleUndefinedVariableNames() async throws {
        let result = try await renderWithTimeout(template: "{% cycle a: 1, 2, 3 %}{% cycle b: 1, 2, 3 %}{% cycle a: 1, 2, 3 %}", context: [:])
        #expect(result == "123")
    }

    @Test("tags, cycle, named with different items", .timeLimit(.minutes(1)))
    func namedWithDifferentItems() async throws {
        let result = try await renderWithTimeout(template: "{% cycle 'a': 1, 2, 3 %}{% cycle 'a': 7, 8, 9 %}{% cycle 'a': 1, 2, 3 %}", context: [:])
        #expect(result == "183")
    }

    @Test("tags, cycle, named with different number of arguments", .timeLimit(.minutes(1)))
    func namedWithDifferentNumberOfArguments() async throws {
        let result = try await renderWithTimeout(template: "{% cycle a: '1', '2' %}{% cycle a: '1', '2', '3' %}{% cycle a: '1' %}", context: [:])
        #expect(result == "12")
    }

    @Test("tags, cycle, named with growing number of arguments", .timeLimit(.minutes(1)))
    func namedWithGrowingNumberOfArguments() async throws {
        let result = try await renderWithTimeout(template: "{% cycle a: '1' %}{% cycle a: '1', '2' %}{% cycle a: '1', '2', '3' %}", context: [:])
        #expect(result == "112")
    }

    @Test("tags, cycle, named with shrinking number of arguments", .timeLimit(.minutes(1)))
    func namedWithShrinkingNumberOfArguments() async throws {
        let result = try await renderWithTimeout(template: "{% cycle a: '1', '2', '3' %}{% cycle a: '1', '2' %}{% cycle a: '1' %}", context: [:])
        #expect(result == "121")
    }

    @Test("tags, cycle, no identifier", .timeLimit(.minutes(1)))
    func noIdentifier() async throws {
        let result = try await renderWithTimeout(template: "{% cycle 'some', 'other' %}{% cycle 'some', 'other' %}{% cycle 'some', 'other' %}", context: [:])
        #expect(result == "someothersome")
    }

    @Test("tags, cycle, undefined variable names mixed with no name", .timeLimit(.minutes(1)))
    func undefinedVariableNamesMixedWithNoName() async throws {
        let result = try await renderWithTimeout(template: "{% cycle a: 1, 2, 3 %}{% cycle b: 1, 2, 3 %}{% cycle 1, 2, 3 %}", context: [:])
        #expect(result == "121")
    }

    @Test("tags, cycle, variable name", .timeLimit(.minutes(1)))
    func variableName() async throws {
        let ctx: [String: Any] = [
            "a": "foo"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% cycle a: 1, 2, 3 %}{% cycle a: 1, 2, 3 %}{% cycle a: 1, 2, 3 %}", context: ctx)
        #expect(result == "123")
    }

    @Test("tags, cycle, with identifier", .timeLimit(.minutes(1)))
    func withIdentifier() async throws {
        let result = try await renderWithTimeout(template: "{% cycle 'foo': 'some', 'other' %}{% cycle 'some', 'other' %}{% cycle 'foo': 'some', 'other' %}", context: [:])
        #expect(result == "somesomeother")
    }
}
