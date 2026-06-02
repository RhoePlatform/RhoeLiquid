//
//  DecrementTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: decrement", .serialized)
struct GoldenDecrementTests {

    @Test("tags, decrement, increment and decrement named counter", .timeLimit(.minutes(1)))
    func incrementAndDecrementNamedCounter() async throws {
        let result = try await renderWithTimeout(template: "{% decrement foo %} {% decrement foo %} {% increment foo %}", context: [:])
        #expect(result == "-1 -2 -2")
    }

    @Test("tags, decrement, named counter", .timeLimit(.minutes(1)))
    func namedCounter() async throws {
        let result = try await renderWithTimeout(template: "{% decrement foo %}{{ foo }} {% decrement foo %}{{ foo }}", context: [:])
        #expect(result == "-1-1 -2-2")
    }
}
