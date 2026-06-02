//
//  LiquidTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: liquid", .serialized)
struct GoldenLiquidTests {

    @Test("tags, liquid, bare liquid tag in liquid tag", .timeLimit(.minutes(1)))
    func bareLiquidTagInLiquidTag() async throws {
        let result = try await renderWithTimeout(template: "{%- liquid\n  liquid\n  echo \"foo\"\n-%}", context: [:])
        #expect(result == "foo")
    }

    @Test("tags, liquid, can't close nested blocks", .timeLimit(.minutes(1)))
    func canTCloseNestedBlocks() async throws {
        do {
            _ = try await renderWithTimeout(template: "{%- if true -%}\n42\n{%- liquid endif -%}", context: [:])
            Issue.record("Expected error for \"tags, liquid, can't close nested blocks\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("tags, liquid, carriage return and newline terminated tags", .timeLimit(.minutes(1)))
    func carriageReturnAndNewlineTerminatedTags() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("title", "foo" as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% liquid\r\nif product.title\r\n   echo product.title | upcase\r\nelse\r\n   echo 'product-1' | upcase \r\nendif\r\n\r\nfor i in (0..5)\r\n   echo i\r\nendfor %}", context: ctx)
        #expect(result == "FOO012345")
    }

    @Test("tags, liquid, carriage return terminated tags", .timeLimit(.minutes(1)))
    func carriageReturnTerminatedTags() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("title", "foo" as Any)
            ])
        ] as [String: Any]
        do {
            _ = try await renderWithTimeout(template: "{% liquid\rif product.title\r   echo product.title | upcase\relse\r   echo 'product-1' | upcase \rendif\r\rfor i in (0..5)\r   echo i\rendfor %}", context: ctx)
            Issue.record("Expected error for \"tags, liquid, carriage return terminated tags\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("tags, liquid, empty liquid tag", .timeLimit(.minutes(1)))
    func emptyLiquidTag() async throws {
        let result = try await renderWithTimeout(template: "{% liquid %}", context: [:])
        #expect(result == "")
    }

    @Test("tags, liquid, liquid tag in liquid tag", .timeLimit(.minutes(1)))
    func liquidTagInLiquidTag() async throws {
        let result = try await renderWithTimeout(template: "{%- liquid\n  liquid echo 'bar'\n  echo \"foo\"\n-%}", context: [:])
        #expect(result == "barfoo")
    }

    @Test("tags, liquid, multi-line comment tag", .timeLimit(.minutes(1)))
    func multiLineCommentTag() async throws {
        let result = try await renderWithTimeout(template: "{% liquid\ncomment this is a comment\nsplit over two lines\nendcomment\n%}", context: [:])
        #expect(result == "")
    }

    @Test("tags, liquid, nested liquid", .timeLimit(.minutes(1)))
    func nestedLiquid() async throws {
        let result = try await renderWithTimeout(template: "{%- if true %}\n  {%- liquid\n    echo \"good\"\n  %}\n{%- endif -%}", context: [:])
        #expect(result == "good")
    }

    @Test("tags, liquid, nested liquid in liquid tag", .timeLimit(.minutes(1)))
    func nestedLiquidInLiquidTag() async throws {
        let result = try await renderWithTimeout(template: "{%- liquid liquid liquid echo \"foo\" -%}", context: [:])
        #expect(result == "foo")
    }

    @Test("tags, liquid, newline terminated tags", .timeLimit(.minutes(1)))
    func newlineTerminatedTags() async throws {
        let ctx: [String: Any] = [
            "product": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("title", "foo" as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% liquid\nif product.title\n   echo product.title | upcase\nelse\n   echo 'product-1' | upcase \nendif\n\nfor i in (0..5)\n   echo i\nendfor %}", context: ctx)
        #expect(result == "FOO012345")
    }

    @Test("tags, liquid, only whitespace", .timeLimit(.minutes(1)))
    func onlyWhitespace() async throws {
        let result = try await renderWithTimeout(template: "{% liquid\n   \n\n   \t \n\t\n  %}", context: [:])
        #expect(result == "")
    }

    @Test("tags, liquid, reference test #2", .timeLimit(.minutes(1)))
    func referenceTest2() async throws {
        let ctx: [String: Any] = [
            "array": [1, 2, 3]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{%- liquid\n  for value in array\n    echo value\n    unless forloop.last\n      echo '#'\n    endunless\n  endfor\n-%}", context: ctx)
        #expect(result == "1#2#3")
    }

    @Test("tags, liquid, reference test #3", .timeLimit(.minutes(1)))
    func referenceTest3() async throws {
        let ctx: [String: Any] = [
            "array": [1, 2, 3]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{%- liquid\n  for value in array\n    assign double_value = value | times: 2\n    echo double_value | times: 2\n    unless forloop.last\n      echo '#'\n    endunless\n  endfor\n\n  echo '#'\n  echo double_value\n-%}", context: ctx)
        #expect(result == "4#8#12#6")
    }

    @Test("tags, liquid, reference test #4", .timeLimit(.minutes(1)))
    func referenceTest4() async throws {
        let result = try await renderWithTimeout(template: "{%- liquid echo 'a' -%}\nb\n{%- liquid echo 'c' -%}", context: [:])
        #expect(result == "abc")
    }

    @Test("tags, liquid, single line comment tag", .timeLimit(.minutes(1)))
    func singleLineCommentTag() async throws {
        let result = try await renderWithTimeout(template: "{% liquid\ncomment this is a comment\nendcomment\n%}", context: [:])
        #expect(result == "")
    }

    @Test("tags, liquid, whitespace control", .timeLimit(.minutes(1)))
    func whitespaceControl() async throws {
        let result = try await renderWithTimeout(template: "Hello,     \n{%- liquid\n  echo ' World! '\n-%}\n   Goodbye.", context: [:])
        #expect(result == "Hello, World! Goodbye.")
    }
}
