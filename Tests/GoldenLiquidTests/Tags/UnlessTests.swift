//
//  UnlessTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: unless", .serialized)
struct GoldenUnlessTests {

    @Test("tags, unless, alternative block", .timeLimit(.minutes(1)))
    func alternativeBlock() async throws {
        let result = try await renderWithTimeout(template: "{% unless true %}foo{% else %}bar{% endunless %}", context: [:])
        #expect(result == "bar")
    }

    @Test("tags, unless, array is equal to array", .timeLimit(.minutes(1)))
    func arrayIsEqualToArray() async throws {
        let result = try await renderWithTimeout(template: "{% assign x = 'a,b,c' | split: ',' %}{% assign y = 'a,b,c' | split: ',' %}{% unless x == y %}true{% else %}false{% endunless %}", context: [:])
        #expect(result == "false")
    }

    @Test("tags, unless, array is equal to array from context", .timeLimit(.minutes(1)))
    func arrayIsEqualToArrayFromContext() async throws {
        let ctx: [String: Any] = [
            "x": ["a", "b", "c"]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign y = 'a,b,c' | split: ',' %}{% unless x == y %}true{% else %}false{% endunless %}", context: ctx)
        #expect(result == "false")
    }

    @Test("tags, unless, blocks that contain only whitespace are not rendered", .timeLimit(.minutes(1)))
    func blocksThatContainOnlyWhitespaceAreNotRendered() async throws {
        let result = try await renderWithTimeout(template: "{% unless false %}  {% endunless %}", context: [:])
        #expect(result == "")
    }

    @Test("tags, unless, conditional alternative block", .timeLimit(.minutes(1)))
    func conditionalAlternativeBlock() async throws {
        let result = try await renderWithTimeout(template: "{% unless true %}foo{% elsif true %}bar{% endunless %}", context: [:])
        #expect(result == "bar")
    }

    @Test("tags, unless, conditional alternative block with default", .timeLimit(.minutes(1)))
    func conditionalAlternativeBlockWithDefault() async throws {
        let result = try await renderWithTimeout(template: "{% unless true %}foo{% elsif false %}bar{% else %}hello{% endunless %}", context: [:])
        #expect(result == "hello")
    }

    @Test("tags, unless, else tag expressions are ignored", .timeLimit(.minutes(1)))
    func elseTagExpressionsAreIgnored() async throws {
        let result = try await renderWithTimeout(template: "{% unless true %}1{% else nonsense %}2{% endunless %}", context: [:])
        #expect(result == "2")
    }

    @Test("tags, unless, extra else blocks are ignored", .timeLimit(.minutes(1)))
    func extraElseBlocksAreIgnored() async throws {
        let result = try await renderWithTimeout(template: "{% unless true %}1{% else %}2{% else %}3{% endunless %}", context: [:])
        #expect(result == "2")
    }

    @Test("tags, unless, extra elsif blocks are ignored", .timeLimit(.minutes(1)))
    func extraElsifBlocksAreIgnored() async throws {
        let result = try await renderWithTimeout(template: "{% unless true %}1{% else %}2{% elsif true %}3{% endunless %}", context: [:])
        #expect(result == "2")
    }

    @Test("tags, unless, literal false condition", .timeLimit(.minutes(1)))
    func literalFalseCondition() async throws {
        let result = try await renderWithTimeout(template: "{% unless false %}foo{% endunless %}", context: [:])
        #expect(result == "foo")
    }

    @Test("tags, unless, literal true condition", .timeLimit(.minutes(1)))
    func literalTrueCondition() async throws {
        let result = try await renderWithTimeout(template: "{% unless true %}foo{% endunless %}", context: [:])
        #expect(result == "")
    }

    @Test("tags, unless, one is not equal to true", .timeLimit(.minutes(1)))
    func oneIsNotEqualToTrue() async throws {
        let result = try await renderWithTimeout(template: "{% unless 1 == true %}Hello{% else %}Goodbye{% endunless %}", context: [:])
        #expect(result == "Hello")
    }

    @Test("tags, unless, zero is not equal to false", .timeLimit(.minutes(1)))
    func zeroIsNotEqualToFalse() async throws {
        let result = try await renderWithTimeout(template: "{% unless 0 == false %}Hello{% else %}Goodbye{% endunless %}", context: [:])
        #expect(result == "Hello")
    }

    @Test("tags, unless, zero is truthy", .timeLimit(.minutes(1)))
    func zeroIsTruthy() async throws {
        let result = try await renderWithTimeout(template: "{% unless 0 %}Hello{% else %}Goodbye{% endunless %}", context: [:])
        #expect(result == "Goodbye")
    }
}
