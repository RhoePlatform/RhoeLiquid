//
//  RawTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: raw", .serialized)
struct GoldenRawTests {

    @Test("tags, raw, continue after raw", .timeLimit(.minutes(1)))
    func continueAfterRaw() async throws {
        let result = try await renderWithTimeout(template: "{% raw %} {% some raw content %} {% endraw %}a literal", context: [:])
        #expect(result == " {% some raw content %} a literal")
    }

    @Test("tags, raw, literal", .timeLimit(.minutes(1)))
    func literal() async throws {
        let result = try await renderWithTimeout(template: "{% raw %}foo{% endraw %}", context: [:])
        #expect(result == "foo")
    }

    @Test("tags, raw, output statement", .timeLimit(.minutes(1)))
    func outputStatement() async throws {
        let result = try await renderWithTimeout(template: "{% raw %}{{ foo }}{% endraw %}", context: [:])
        #expect(result == "{{ foo }}")
    }

    @Test("tags, raw, partial tag", .timeLimit(.minutes(1)))
    func partialTag() async throws {
        let result = try await renderWithTimeout(template: "{% raw %} %} {% }} {{ {% endraw %}", context: [:])
        #expect(result == " %} {% }} {{ ")
    }

    @Test("tags, raw, tag", .timeLimit(.minutes(1)))
    func tag() async throws {
        let result = try await renderWithTimeout(template: "{% raw %}{% assign x = 1 %}{% endraw %}", context: [:])
        #expect(result == "{% assign x = 1 %}")
    }
}
