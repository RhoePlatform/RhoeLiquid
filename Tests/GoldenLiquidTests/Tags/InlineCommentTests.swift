//
//  InlineCommentTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: inline comment", .serialized)
struct GoldenInlineCommentTests {

    @Test("tags, inline comment, can't comment tags", .timeLimit(.minutes(1)))
    func canTCommentTags() async throws {
        let result = try await renderWithTimeout(template: "{%- # {% echo 'hello world' %} -%}", context: [:])
        #expect(result == " -%}")
    }

    @Test("tags, inline comment, comment with double quote", .timeLimit(.minutes(1)))
    func commentWithDoubleQuote() async throws {
        let result = try await renderWithTimeout(template: "{%# some \"comment %}", context: [:])
        #expect(result == "")
    }

    @Test("tags, inline comment, comment with double quoted string", .timeLimit(.minutes(1)))
    func commentWithDoubleQuotedString() async throws {
        let result = try await renderWithTimeout(template: "{%# some \"comment\" %}", context: [:])
        #expect(result == "")
    }

    @Test("tags, inline comment, comment with single quote", .timeLimit(.minutes(1)))
    func commentWithSingleQuote() async throws {
        let result = try await renderWithTimeout(template: "{%# some 'comment %}", context: [:])
        #expect(result == "")
    }

    @Test("tags, inline comment, comment with single quoted string", .timeLimit(.minutes(1)))
    func commentWithSingleQuotedString() async throws {
        let result = try await renderWithTimeout(template: "{%# some 'comment' %}", context: [:])
        #expect(result == "")
    }

    @Test("tags, inline comment, comment with u2018", .timeLimit(.minutes(1)))
    func commentWithU2018() async throws {
        let result = try await renderWithTimeout(template: "{%# some ‘comment %}", context: [:])
        #expect(result == "")
    }

    @Test("tags, inline comment, comment with u201C", .timeLimit(.minutes(1)))
    func commentWithU201c() async throws {
        let result = try await renderWithTimeout(template: "{%# some “comment %}", context: [:])
        #expect(result == "")
    }

    @Test("tags, inline comment, empty", .timeLimit(.minutes(1)))
    func empty() async throws {
        let result = try await renderWithTimeout(template: "{%#%}", context: [:])
        #expect(result == "")
    }

    @Test("tags, inline comment, enforce leading hash", .timeLimit(.minutes(1)))
    func enforceLeadingHash() async throws {
        do {
            _ = try await renderWithTimeout(template: "{%-\n  # spread inline comments\n  over multiple lines\n-%}", context: [:])
            Issue.record("Expected error for \"tags, inline comment, enforce leading hash\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("tags, inline comment, liquid tag", .timeLimit(.minutes(1)))
    func liquidTag() async throws {
        let result = try await renderWithTimeout(template: "{% liquid \n  # first comment line\n  # second comment line\n\n  # another comment line\n  echo 'Hello '\n\n  # more comments\n  echo 'goodbye'\n-%}", context: [:])
        #expect(result == "Hello goodbye")
    }

    @Test("tags, inline comment, lots of hashes in a liquid tag", .timeLimit(.minutes(1)))
    func lotsOfHashesInALiquidTag() async throws {
        let result = try await renderWithTimeout(template: "{% liquid\n  ##########################\n  # spread inline comments #\n  ##########################\n-%}", context: [:])
        #expect(result == "")
    }

    @Test("tags, inline comment, multiple lines", .timeLimit(.minutes(1)))
    func multipleLines() async throws {
        let result = try await renderWithTimeout(template: "{%-\n  # spread inline comments\n  # over multiple lines\n-%}", context: [:])
        #expect(result == "")
    }

    @Test("tags, inline comment, no padding after the hash", .timeLimit(.minutes(1)))
    func noPaddingAfterTheHash() async throws {
        let result = try await renderWithTimeout(template: "{%#some comment %}", context: [:])
        #expect(result == "")
    }

    @Test("tags, inline comment, no whitespace control no padding", .timeLimit(.minutes(1)))
    func noWhitespaceControlNoPadding() async throws {
        let result = try await renderWithTimeout(template: "{%# some comment %}", context: [:])
        #expect(result == "")
    }

    @Test("tags, inline comment, no whitespace control with padding", .timeLimit(.minutes(1)))
    func noWhitespaceControlWithPadding() async throws {
        let result = try await renderWithTimeout(template: "{% # some comment %}", context: [:])
        #expect(result == "")
    }

    @Test("tags, inline comment, with whitespace control and padding", .timeLimit(.minutes(1)))
    func withWhitespaceControlAndPadding() async throws {
        let result = try await renderWithTimeout(template: "{%- # some comment -%}", context: [:])
        #expect(result == "")
    }

    @Test("tags, inline comment, with whitespace control no padding", .timeLimit(.minutes(1)))
    func withWhitespaceControlNoPadding() async throws {
        let result = try await renderWithTimeout(template: "{%-# some comment -%}", context: [:])
        #expect(result == "")
    }
}
