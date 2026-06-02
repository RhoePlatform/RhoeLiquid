//
//  WhitespaceControlTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: whitespace control", .serialized)
struct GoldenWhitespaceControlTests {

    @Test("whitespace control, don't suppress whitespace only blocks containing echo", .timeLimit(.minutes(1)))
    func donTSuppressWhitespaceOnlyBlocksContainingEcho() async throws {
        let result = try await renderWithTimeout(template: "!{% if true %}\n\n{% assign bar = 'foo' %}\n    {% echo '' %}\n\n    {% assign foo = 'bar' %}\n\n\n\n{% endif %}!", context: [:])
        #expect(result == "!\n\n\n    \n\n    \n\n\n\n!")
    }

    @Test("whitespace control, don't suppress whitespace only blocks containing output", .timeLimit(.minutes(1)))
    func donTSuppressWhitespaceOnlyBlocksContainingOutput() async throws {
        let result = try await renderWithTimeout(template: "!{% if true %}\n\n{% assign bar = 'foo' %}\n    {{ '' }}\n\n    {% assign foo = 'bar' %}\n\n\n\n{% endif %}!", context: [:])
        #expect(result == "!\n\n\n    \n\n    \n\n\n\n!")
    }

    @Test("whitespace control, don't suppress whitespace only blocks containing output in nested block", .timeLimit(.minutes(1)))
    func donTSuppressWhitespaceOnlyBlocksContainingOutputInNestedBlock() async throws {
        let result = try await renderWithTimeout(template: "!{% if 1 %}\n\n{% assign bar = 'foo' %}\n{% if 2 %}\n    {{ '' }}\n\n    {% assign foo = 'bar' %}\n\n{% endif %}\n\n\n{% endif %}!", context: [:])
        #expect(result == "!\n\n\n\n    \n\n    \n\n\n\n\n!")
    }

    @Test("whitespace control, don't suppress whitespace only blocks containing output in unreachable blocks", .timeLimit(.minutes(1)))
    func donTSuppressWhitespaceOnlyBlocksContainingOutputInUnreachableBlocks() async throws {
        let result = try await renderWithTimeout(template: "!{% if 1 %}\n\n{% assign bar = 'foo' %}\n{% if true %}\n\n    {% assign foo = 'bar' %}\n\n{% else %}\n    {{ '' }}\n{% endif %}\n\n\n{% endif %}!", context: [:])
        #expect(result == "!\n\n\n\n\n    \n\n\n\n\n!")
    }

    @Test("whitespace control, don't suppress whitespace only case blocks containing output", .timeLimit(.minutes(1)))
    func donTSuppressWhitespaceOnlyCaseBlocksContainingOutput() async throws {
        let result = try await renderWithTimeout(template: "!{% assign x = 1 %}{% case x %}\n\n  {% when 1 %}\n    {% assign foo = 'bar' %}\n\n  {% when 2 %}\n    {{ '' }}\n\n{% endcase %}!", context: [:])
        #expect(result == "!\n    \n\n  !")
    }

    @Test("whitespace control, don't suppress whitespace only unless blocks containing output in nested blocks", .timeLimit(.minutes(1)))
    func donTSuppressWhitespaceOnlyUnlessBlocksContainingOutputInNestedBlocks() async throws {
        let result = try await renderWithTimeout(template: "!{% unless false %}\n\n{% assign bar = 'foo' %}\n{% unless false %}\n    {{ '' }}\n\n    {% assign foo = 'bar' %}\n\n{% endunless %}\n\n\n{% endunless %}!", context: [:])
        #expect(result == "!\n\n\n\n    \n\n    \n\n\n\n\n!")
    }

    @Test("whitespace control, suppress whitespace only case blocks", .timeLimit(.minutes(1)))
    func suppressWhitespaceOnlyCaseBlocks() async throws {
        let result = try await renderWithTimeout(template: "!{% assign x = 1 %}{% case x %}\n\n  {% when 1 %}\n    {% assign foo = 'bar' %}\n\n\n{% endcase %}!", context: [:])
        #expect(result == "!!")
    }

    @Test("whitespace control, suppress whitespace only if blocks", .timeLimit(.minutes(1)))
    func suppressWhitespaceOnlyIfBlocks() async throws {
        let result = try await renderWithTimeout(template: "!{% if true %}\n\n{% assign bar = 'foo' %}\n{% if true %}\n\n\n    {% assign foo = 'bar' %}\n\n{% endif %}\n\n\n{% endif %}!", context: [:])
        #expect(result == "!!")
    }

    @Test("whitespace control, suppress whitespace only unless blocks", .timeLimit(.minutes(1)))
    func suppressWhitespaceOnlyUnlessBlocks() async throws {
        let result = try await renderWithTimeout(template: "!{% unless false %}\n\n{% assign bar = 'foo' %}\n{% unless false %}\n\n\n    {% assign foo = 'bar' %}\n\n{% endunless %}\n\n\n{% endunless %}!", context: [:])
        #expect(result == "!!")
    }

    @Test("whitespace control, suppress whitespace surrounding a capture block", .timeLimit(.minutes(1)))
    func suppressWhitespaceSurroundingACaptureBlock() async throws {
        let result = try await renderWithTimeout(template: "!{% if true %}\n\n{% capture foo %}\n{{ '' }}\n{% endcapture %}\n\n{% endif %}!", context: [:])
        #expect(result == "!!")
    }

    @Test("whitespace control, suppress whitespace surrounding an empty capture block", .timeLimit(.minutes(1)))
    func suppressWhitespaceSurroundingAnEmptyCaptureBlock() async throws {
        let result = try await renderWithTimeout(template: "!{% if true %}\n\n{% capture foo %}{% endcapture %}\n\n{% endif %}!", context: [:])
        #expect(result == "!!")
    }

    @Test("whitespace control, white space control with  carriage return, newline and spaces", .timeLimit(.minutes(1)))
    func newlineAndSpaces() async throws {
        let ctx: [String: Any] = [
            "customer": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("first_name", "Holly" as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "\r\n{% if customer -%}\r\nWelcome back,  {{ customer.first_name -}} !\r\n {%- endif -%}", context: ctx)
        #expect(result == "\r\nWelcome back,  Holly!")
    }

    @Test("whitespace control, white space control with carriage return and spaces", .timeLimit(.minutes(1)))
    func whiteSpaceControlWithCarriageReturnAndSpaces() async throws {
        let ctx: [String: Any] = [
            "customer": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("first_name", "Holly" as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "\r{% if customer -%}\rWelcome back,  {{ customer.first_name -}} !\r {%- endif -%}", context: ctx)
        #expect(result == "\rWelcome back,  Holly!")
    }

    @Test("whitespace control, white space control with newlines and spaces", .timeLimit(.minutes(1)))
    func whiteSpaceControlWithNewlinesAndSpaces() async throws {
        let ctx: [String: Any] = [
            "customer": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("first_name", "Holly" as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "\n{% if customer -%}\nWelcome back,  {{ customer.first_name -}} !\n {%- endif -%}", context: ctx)
        #expect(result == "\nWelcome back,  Holly!")
    }

    @Test("whitespace control, white space control with newlines, tabs and spaces", .timeLimit(.minutes(1)))
    func tabsAndSpaces() async throws {
        let ctx: [String: Any] = [
            "customer": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("first_name", "Holly" as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "\n\t{% if customer -%}\t\nWelcome back,  {{ customer.first_name -}}\t !\r\n {%- endif -%}", context: ctx)
        #expect(result == "\n\tWelcome back,  Holly!")
    }

    @Test("whitespace control, white space control with raw tags", .timeLimit(.minutes(1)))
    func whiteSpaceControlWithRawTags() async throws {
        let result = try await renderWithTimeout(template: "! {% raw %}{{ hello }}{% endraw %} !\n! {%- raw -%}{{ hello }}{%- endraw -%} !", context: [:])
        #expect(result == "! {{ hello }} !\n!{{ hello }}!")
    }
}
