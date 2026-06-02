//
//  DocTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: doc", .serialized)
struct GoldenDocTests {

    @Test("tags, doc, doc arguments is an error", .timeLimit(.minutes(1)), .disabled("Feature not yet implemented in RhoeLiquid"))
    func docArgumentsIsAnError() async throws {
        do {
            _ = try await renderWithTimeout(template: "{% doc hello %}don't render me{% enddoc %}", context: [:])
            Issue.record("Expected error for \"tags, doc, doc arguments is an error\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("tags, doc, doc tag block must be closed", .timeLimit(.minutes(1)), .disabled("Feature not yet implemented in RhoeLiquid"))
    func docTagBlockMustBeClosed() async throws {
        do {
            _ = try await renderWithTimeout(template: "{% doc %}don't render me", context: [:])
            Issue.record("Expected error for \"tags, doc, doc tag block must be closed\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("tags, doc, doc text is not parsed", .timeLimit(.minutes(1)), .disabled("Feature not yet implemented in RhoeLiquid"))
    func docTextIsNotParsed() async throws {
        let result = try await renderWithTimeout(template: "{% doc %}    {% if true %}    {% if ... %}    {%- for ? -%}    {% while true %}    {%    unless if    %}    {% endcase %}    {% raw %}{% enddoc %}", context: [:])
        #expect(result == "")
    }

    @Test("tags, doc, docs containing unclosed output are ok", .timeLimit(.minutes(1)), .disabled("Feature not yet implemented in RhoeLiquid"))
    func docsContainingUnclosedOutputAreOk() async throws {
        let result = try await renderWithTimeout(template: "{% doc %}{{ foo {% enddoc %}", context: [:])
        #expect(result == "")
    }

    @Test("tags, doc, docs containing unclosed tags are ok", .timeLimit(.minutes(1)), .disabled("Feature not yet implemented in RhoeLiquid"))
    func docsContainingUnclosedTagsAreOk() async throws {
        let result = try await renderWithTimeout(template: "{% doc %}{% assign x = y {% enddoc %}", context: [:])
        #expect(result == "")
    }

    @Test("tags, doc, don't render docs", .timeLimit(.minutes(1)), .disabled("Feature not yet implemented in RhoeLiquid"))
    func donTRenderDocs() async throws {
        let result = try await renderWithTimeout(template: "{% doc %}don't render me{% enddoc %}", context: [:])
        #expect(result == "")
    }

    @Test("tags, doc, nested docs are not allowed", .timeLimit(.minutes(1)), .disabled("Feature not yet implemented in RhoeLiquid"))
    func nestedDocsAreNotAllowed() async throws {
        do {
            _ = try await renderWithTimeout(template: "{% doc hello %}Hello{% doc %}{% enddoc %}", context: [:])
            Issue.record("Expected error for \"tags, doc, nested docs are not allowed\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("tags, doc, whitespace control", .timeLimit(.minutes(1)), .disabled("Feature not yet implemented in RhoeLiquid"))
    func whitespaceControl() async throws {
        let result = try await renderWithTimeout(template: "foo\n {%- doc %}I'm a doc comment{% enddoc -%}  \tbar", context: [:])
        #expect(result == "foobar")
    }
}
