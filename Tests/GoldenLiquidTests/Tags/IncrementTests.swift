//
//  IncrementTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: increment", .serialized)
struct GoldenIncrementTests {

    @Test("tags, increment, assign and increment", .timeLimit(.minutes(1)))
    func assignAndIncrement() async throws {
        let result = try await renderWithTimeout(template: "{% assign foo = 5 %}{{ foo }} {% increment foo %} {% increment foo %} {{ foo }}", context: [:])
        #expect(result == "5 0 1 5")
    }

    @Test("tags, increment, incrementing counter renders before incrementing", .timeLimit(.minutes(1)))
    func incrementingCounterRendersBeforeIncrementing() async throws {
        let result = try await renderWithTimeout(template: "{% increment foo %} {{ foo }}", context: [:])
        #expect(result == "0 1")
    }

    @Test("tags, increment, multiple named counters", .timeLimit(.minutes(1)))
    func multipleNamedCounters() async throws {
        let result = try await renderWithTimeout(template: "{% increment foo %} {% increment bar %} {% increment foo %} {% increment bar %}", context: [:])
        #expect(result == "0 0 1 1")
    }

    @Test("tags, increment, named counter", .timeLimit(.minutes(1)))
    func namedCounter() async throws {
        let result = try await renderWithTimeout(template: "{% increment foo %} {% increment foo %} {% increment foo %}", context: [:])
        #expect(result == "0 1 2")
    }

    @Test("tags, increment, named counters are in scope for subsequent expressions", .timeLimit(.minutes(1)))
    func namedCountersAreInScopeForSubsequentExpressions() async throws {
        let result = try await renderWithTimeout(template: "{% increment foo %} {% increment foo %} {% if foo > 0 %}{{ foo }}{% endif %}", context: [:])
        #expect(result == "0 1 2")
    }
}
