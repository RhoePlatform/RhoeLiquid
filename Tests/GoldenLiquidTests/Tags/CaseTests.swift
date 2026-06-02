//
//  CaseTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: case", .serialized)
struct GoldenCaseTests {

    @Test("tags, case, 'when' expression using an identifier", .timeLimit(.minutes(1)))
    func whenExpressionUsingAnIdentifier() async throws {
        let ctx: [String: Any] = [
            "title": "Hello",
            "other": "Hello"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% case title %}{% when other %}foo{% when 'goodbye' %}bar{% endcase %}", context: ctx)
        #expect(result == "foo")
    }

    @Test("tags, case, 'when' expression using an out of scope identifier", .timeLimit(.minutes(1)))
    func whenExpressionUsingAnOutOfScopeIdentifier() async throws {
        let ctx: [String: Any] = [
            "title": "Hello"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% case title %}{% when nosuchthing %}foo{% when 'Hello' %}bar{% endcase %}", context: ctx)
        #expect(result == "bar")
    }

    @Test("tags, case, comma separated when expression", .timeLimit(.minutes(1)))
    func commaSeparatedWhenExpression() async throws {
        let ctx: [String: Any] = [
            "title": "Hello"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% case title %}{% when 'foo' %}foo{% when 'bar', 'Hello' %}bar{% endcase %}", context: ctx)
        #expect(result == "bar")
    }

    @Test("tags, case, comma string literal", .timeLimit(.minutes(1)))
    func commaStringLiteral() async throws {
        let ctx: [String: Any] = [
            "foo": ","
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% case foo %}{% when 'foo' %}bar{% when ',' %}comma{% endcase %}", context: ctx)
        #expect(result == "comma")
    }

    @Test("tags, case, empty when tag", .timeLimit(.minutes(1)))
    func emptyWhenTag() async throws {
        let ctx: [String: Any] = [
            "foo": "bar"
        ] as [String: Any]
        do {
            _ = try await renderWithTimeout(template: "{% case foo %}{% when %}bar{% endcase %}", context: ctx)
            Issue.record("Expected error for \"tags, case, empty when tag\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("tags, case, evaluate multiple matching blocks", .timeLimit(.minutes(1)))
    func evaluateMultipleMatchingBlocks() async throws {
        let ctx: [String: Any] = [
            "title": "Hello",
            "a": "Hello"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% case title %}{% when 'Hello' %}foo{% when a, 'Hello' %}bar{% endcase %}", context: ctx)
        #expect(result == "foobarbar")
    }

    @Test("tags, case, falsy when before and truthy when after else", .timeLimit(.minutes(1)))
    func falsyWhenBeforeAndTruthyWhenAfterElse() async throws {
        let result = try await renderWithTimeout(template: "{% case 'x' %}{% when 'y' %}foo{% else %}bar{% when 'x' %}baz{% endcase %}", context: [:])
        #expect(result == "barbaz")
    }

    @Test("tags, case, falsy when before and truthy when after multiple else blocks", .timeLimit(.minutes(1)))
    func falsyWhenBeforeAndTruthyWhenAfterMultipleElseBlocks() async throws {
        let result = try await renderWithTimeout(template: "{% case 'x' %}{% when 'y' %}foo{% else %}bar{% else %}baz{% when 'x' %}qux{% endcase %}", context: [:])
        #expect(result == "barbazqux")
    }

    @Test("tags, case, mix or and comma separated when expression", .timeLimit(.minutes(1)))
    func mixOrAndCommaSeparatedWhenExpression() async throws {
        let ctx: [String: Any] = [
            "title": "Hello"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% case title %}{% when 'foo' %}foo{% when 'bar' or 'Hello', 'Hello' %}bar{% endcase %}", context: ctx)
        #expect(result == "barbar")
    }

    @Test("tags, case, multiple else blocks", .timeLimit(.minutes(1)))
    func multipleElseBlocks() async throws {
        let result = try await renderWithTimeout(template: "{% case 'x' %}{% when 'y' %}foo{% else %}bar{% else %}baz{% endcase %}", context: [:])
        #expect(result == "barbaz")
    }

    @Test("tags, case, name not in scope", .timeLimit(.minutes(1)))
    func nameNotInScope() async throws {
        let result = try await renderWithTimeout(template: "{% case nosuchthing %}{% when 'foo' %}foo{% when 'bar' %}bar{% endcase %}", context: [:])
        #expect(result == "")
    }

    @Test("tags, case, no match and no default", .timeLimit(.minutes(1)))
    func noMatchAndNoDefault() async throws {
        let ctx: [String: Any] = [
            "title": "Hello"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% case title %}{% when 'foo' %}foo{% when 'bar' %}bar{% endcase %}", context: ctx)
        #expect(result == "")
    }

    @Test("tags, case, no whens", .timeLimit(.minutes(1)))
    func noWhens() async throws {
        let ctx: [String: Any] = [
            "title": "Hello"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% case title %}{% else %}bar{% endcase %}", context: ctx)
        #expect(result == "bar")
    }

    @Test("tags, case, no whens or default", .timeLimit(.minutes(1)))
    func noWhensOrDefault() async throws {
        let ctx: [String: Any] = [
            "title": "Hello"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% case title %}{% endcase %}", context: ctx)
        #expect(result == "")
    }

    @Test("tags, case, or separated when expression", .timeLimit(.minutes(1)))
    func orSeparatedWhenExpression() async throws {
        let ctx: [String: Any] = [
            "title": "Hello"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% case title %}{% when 'foo' %}foo{% when 'bar' or 'Hello' %}bar{% endcase %}", context: ctx)
        #expect(result == "bar")
    }

    @Test("tags, case, simple case/when", .timeLimit(.minutes(1)))
    func simpleCaseWhen() async throws {
        let ctx: [String: Any] = [
            "title": "Hello"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% case title %}{% when 'foo' %}foo{% when 'Hello' %}bar{% endcase %}", context: ctx)
        #expect(result == "bar")
    }

    @Test("tags, case, switch on array", .timeLimit(.minutes(1)))
    func switchOnArray() async throws {
        let ctx: [String: Any] = [
            "x": ["a", "b", "c"],
            "y": ["a", "b", "c"]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% case x %}{% when y %}foo{% endcase %}", context: ctx)
        #expect(result == "foo")
    }

    @Test("tags, case, tags inside when block", .timeLimit(.minutes(1)))
    func tagsInsideWhenBlock() async throws {
        let ctx: [String: Any] = [
            "title": "Hello",
            "other": "Hello"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% case title %}{% when other %}{% if true %}foo{% endif %}{% when 'goodbye' %}bar{% endcase %}", context: ctx)
        #expect(result == "foo")
    }

    @Test("tags, case, truthy and empty when block before else", .timeLimit(.minutes(1)))
    func truthyAndEmptyWhenBlockBeforeElse() async throws {
        let result = try await renderWithTimeout(template: "{% case 'x' %}{% when 'x' %}{% else %}bar{% endcase %}", context: [:])
        #expect(result == "")
    }

    @Test("tags, case, truthy when before and after else", .timeLimit(.minutes(1)))
    func truthyWhenBeforeAndAfterElse() async throws {
        let result = try await renderWithTimeout(template: "{% case 'x' %}{% when 'x' %}foo{% else %}bar{% when 'x' %}baz{% endcase %}", context: [:])
        #expect(result == "foobaz")
    }

    @Test("tags, case, unexpected when token", .timeLimit(.minutes(1)))
    func unexpectedWhenToken() async throws {
        let ctx: [String: Any] = [
            "title": "Hello"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% case title %}{% when 'foo' %}foo{% when 'bar' and 'Hello', 'Hello' %}bar{% endcase %}", context: ctx)
        #expect(result == "")
    }

    @Test("tags, case, unexpected when token, strict2", .timeLimit(.minutes(1)), .disabled("Feature not yet implemented in RhoeLiquid"))
    func unexpectedWhenTokenStrict2() async throws {
        do {
            _ = try await renderWithTimeout(template: "{% case title %}{% when 'foo' %}foo{% when 'bar' and 'Hello', 'Hello' %}bar{% endcase %}", context: [:])
            Issue.record("Expected error for \"tags, case, unexpected when token, strict2\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("tags, case, whitespace", .timeLimit(.minutes(1)))
    func whitespace() async throws {
        let ctx: [String: Any] = [
            "title": "Hello"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% case title %}  \n\t{% when 'foo' %}foo\n{% when 'Hello' %}bar{% endcase %}", context: ctx)
        #expect(result == "bar")
    }

    @Test("tags, case, with default", .timeLimit(.minutes(1)))
    func withDefault() async throws {
        let ctx: [String: Any] = [
            "title": "Hello"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% case title %}{% when 'foo' %}foo{% else %}bar{% endcase %}", context: ctx)
        #expect(result == "bar")
    }
}
