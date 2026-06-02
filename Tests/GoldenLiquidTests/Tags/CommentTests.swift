//
//  CommentTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: comment", .serialized)
struct GoldenCommentTests {

    @Test("tags, comment, comment inside liquid tag", .timeLimit(.minutes(1)))
    func commentInsideLiquidTag() async throws {
        let result = try await renderWithTimeout(template: "{% liquid\n    if 1 != 1\n    comment\n    else\n    echo 123\n    endcomment\n    endif\n%}", context: [:])
        #expect(result == "")
    }

    @Test("tags, comment, commented tags are not parsed", .timeLimit(.minutes(1)))
    func commentedTagsAreNotParsed() async throws {
        let result = try await renderWithTimeout(template: "{% comment %}    {% if true %}    {% if ... %}    {%- for ? -%}    {% while true %}    {%    unless if    %}    {% endcase %}{% endcomment %}", context: [:])
        #expect(result == "")
    }

    @Test("tags, comment, don't render comments", .timeLimit(.minutes(1)))
    func donTRenderComments() async throws {
        let result = try await renderWithTimeout(template: "{% comment %}foo{% endcomment %}", context: [:])
        #expect(result == "")
    }

    @Test("tags, comment, don't render comments with tags", .timeLimit(.minutes(1)))
    func donTRenderCommentsWithTags() async throws {
        let result = try await renderWithTimeout(template: "{% comment %}{% if true %}{{ title }}{% endif %}{% endcomment %}", context: [:])
        #expect(result == "")
    }

    @Test("tags, comment, incomplete tags are not parsed", .timeLimit(.minutes(1)))
    func incompleteTagsAreNotParsed() async throws {
        do {
            _ = try await renderWithTimeout(template: "{% comment %}{% {{ {%- endcomment %}", context: [:])
            Issue.record("Expected error for \"tags, comment, incomplete tags are not parsed\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("tags, comment, malformed tags are not parsed", .timeLimit(.minutes(1)))
    func malformedTagsAreNotParsed() async throws {
        do {
            _ = try await renderWithTimeout(template: "{% comment %}{% assign foo = '1'{% endcomment %}", context: [:])
            Issue.record("Expected error for \"tags, comment, malformed tags are not parsed\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("tags, comment, nested comment blocks", .timeLimit(.minutes(1)))
    func nestedCommentBlocks() async throws {
        let result = try await renderWithTimeout(template: "{% comment %}    {% comment %}    {% comment %}{%    endcomment     %}    {% endcomment %}{% endcomment %}", context: [:])
        #expect(result == "")
    }

    @Test("tags, comment, nested comment blocks, with nested tags", .timeLimit(.minutes(1)))
    func nestedCommentBlocksWithNestedTags() async throws {
        let result = try await renderWithTimeout(template: "{% comment %}    {% comment %}    {% comment %}{% if true %}hello{%endif%}{%    endcomment     %}    {% endcomment %}{% endcomment %}", context: [:])
        #expect(result == "")
    }

    @Test("tags, comment, raw inside comment block", .timeLimit(.minutes(1)))
    func rawInsideCommentBlock() async throws {
        let result = try await renderWithTimeout(template: "{% comment %}    {% raw %}    {% endcomment %}    {% endraw %}{% endcomment %}", context: [:])
        #expect(result == "")
    }

    @Test("tags, comment, respect whitespace control in comments", .timeLimit(.minutes(1)))
    func respectWhitespaceControlInComments() async throws {
        let result = try await renderWithTimeout(template: "\n{%- comment %}foo{% endcomment -%}\t \r", context: [:])
        #expect(result == "")
    }

    @Test("tags, comment, unclosed nested comment blocks", .timeLimit(.minutes(1)))
    func unclosedNestedCommentBlocks() async throws {
        do {
            _ = try await renderWithTimeout(template: "{% comment %}    {% comment %}    {% comment %}    {% endcomment %}{% endcomment %}", context: [:])
            Issue.record("Expected error for \"tags, comment, unclosed nested comment blocks\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }
}
