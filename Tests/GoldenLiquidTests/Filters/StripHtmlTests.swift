//
//  StripHtmlTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: strip html", .serialized)
struct GoldenStripHtmlTests {

    @Test("filters, strip html, html block", .timeLimit(.minutes(1)))
    func htmlBlock() async throws {
        let ctx: [String: Any] = [
            "s": "<div>test</div>"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ s | strip_html }}", context: ctx)
        #expect(result == "test")
    }

    @Test("filters, strip html, html block with id", .timeLimit(.minutes(1)))
    func htmlBlockWithId() async throws {
        let ctx: [String: Any] = [
            "s": "<div id='test'>test</div>"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ s | strip_html }}", context: ctx)
        #expect(result == "test")
    }

    @Test("filters, strip html, html block with newline", .timeLimit(.minutes(1)))
    func htmlBlockWithNewline() async throws {
        let ctx: [String: Any] = [
            "s": "<div\nclass='multiline'>test</div>"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ s | strip_html }}", context: ctx)
        #expect(result == "test")
    }

    @Test("filters, strip html, html comment with newline", .timeLimit(.minutes(1)))
    func htmlCommentWithNewline() async throws {
        let ctx: [String: Any] = [
            "s": "<!-- foo bar \n test -->test"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ s | strip_html }}", context: ctx)
        #expect(result == "test")
    }

    @Test("filters, strip html, not a string", .timeLimit(.minutes(1)))
    func notAString() async throws {
        let result = try await renderWithTimeout(template: "{{ 5 | strip_html }}", context: [:])
        #expect(result == "5")
    }

    @Test("filters, strip html, script block", .timeLimit(.minutes(1)))
    func scriptBlock() async throws {
        let ctx: [String: Any] = [
            "s": "<script type='text/javascript'>document.write('some stuff');</script>"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ s | strip_html }}", context: ctx)
        #expect(result == "")
    }

    @Test("filters, strip html, some HTML markup", .timeLimit(.minutes(1)))
    func someHtmlMarkup() async throws {
        let ctx: [String: Any] = [
            "s": "Have <em>you</em> read <strong>Ulysses</strong> &amp; &#20;?"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ s | strip_html }}", context: ctx)
        #expect(result == "Have you read Ulysses &amp; &#20;?")
    }

    @Test("filters, strip html, some HTML markup with HTML comment", .timeLimit(.minutes(1)))
    func someHtmlMarkupWithHtmlComment() async throws {
        let ctx: [String: Any] = [
            "s": "<!-- Have --><em>you</em> read <strong>Ulysses</strong> &amp; &#20;?"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ s | strip_html }}", context: ctx)
        #expect(result == "you read Ulysses &amp; &#20;?")
    }

    @Test("filters, strip html, style block", .timeLimit(.minutes(1)))
    func styleBlock() async throws {
        let ctx: [String: Any] = [
            "s": "<style type='text/css'>foo bar</style>"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ s | strip_html }}", context: ctx)
        #expect(result == "")
    }

    @Test("filters, strip html, undefined left value", .timeLimit(.minutes(1)))
    func undefinedLeftValue() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | strip_html }}", context: [:])
        #expect(result == "")
    }

    @Test("filters, strip html, unexpected argument", .timeLimit(.minutes(1)))
    func unexpectedArgument() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ \"hello\" | strip_html: 5 }}", context: [:])
            Issue.record("Expected error for \"filters, strip html, unexpected argument\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }
}
