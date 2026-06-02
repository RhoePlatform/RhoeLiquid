//
//  IdentifiersTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: identifiers", .serialized)
struct GoldenIdentifiersTests {

    @Test("identifiers, ascii lowercase", .timeLimit(.minutes(1)))
    func asciiLowercase() async throws {
        let ctx: [String: Any] = [
            "bar": "goodbye"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign foo = 'hello' %}{{ foo }} {{ bar }}", context: ctx)
        #expect(result == "hello goodbye")
    }

    @Test("identifiers, ascii uppercase", .timeLimit(.minutes(1)))
    func asciiUppercase() async throws {
        let ctx: [String: Any] = [
            "BAR": "goodbye"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign FOO = 'hello' %}{{ FOO }} {{ BAR }}", context: ctx)
        #expect(result == "hello goodbye")
    }

    @Test("identifiers, at sign", .timeLimit(.minutes(1)))
    func atSign() async throws {
        let ctx: [String: Any] = [
            "@foo": "hello"
        ] as [String: Any]
        do {
            _ = try await renderWithTimeout(template: "{{ @foo }}", context: ctx)
            Issue.record("Expected error for \"identifiers, at sign\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("identifiers, capture ascii lowercase", .timeLimit(.minutes(1)))
    func captureAsciiLowercase() async throws {
        let result = try await renderWithTimeout(template: "{% capture foo %}hello{% endcapture %}{{ foo }}", context: [:])
        #expect(result == "hello")
    }

    @Test("identifiers, capture ascii uppercase", .timeLimit(.minutes(1)))
    func captureAsciiUppercase() async throws {
        let result = try await renderWithTimeout(template: "{% capture FOO %}hello{% endcapture %}{{ FOO }}", context: [:])
        #expect(result == "hello")
    }

    @Test("identifiers, capture digits", .timeLimit(.minutes(1)))
    func captureDigits() async throws {
        let result = try await renderWithTimeout(template: "{% capture foo1 %}hello{% endcapture %}{{ foo1 }}", context: [:])
        #expect(result == "hello")
    }

    @Test("identifiers, capture hyphens", .timeLimit(.minutes(1)))
    func captureHyphens() async throws {
        let ctx: [String: Any] = [
            "bar-b": "goodbye"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% capture foo-a %}hello {{ bar-b }}{% endcapture %}{{ foo-a }}", context: ctx)
        #expect(result == "hello goodbye")
    }

    @Test("identifiers, capture leading hyphen", .timeLimit(.minutes(1)))
    func captureLeadingHyphen() async throws {
        let ctx: [String: Any] = [
            "-bar": "goodbye"
        ] as [String: Any]
        do {
            _ = try await renderWithTimeout(template: "{% capture -foo %}hello {{ -bar }}{% endcapture %}{{ -foo }}", context: ctx)
            Issue.record("Expected error for \"identifiers, capture leading hyphen\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("identifiers, capture leading underscore", .timeLimit(.minutes(1)))
    func captureLeadingUnderscore() async throws {
        let ctx: [String: Any] = [
            "_bar": "goodbye"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% capture _foo %}hello {{ _bar }}{% endcapture %}{{ _foo }}", context: ctx)
        #expect(result == "hello goodbye")
    }

    @Test("identifiers, capture only digits", .timeLimit(.minutes(1)))
    func captureOnlyDigits() async throws {
        let result = try await renderWithTimeout(template: "{% capture 123 %}hello{% endcapture %}{{ 123 }}", context: [:])
        #expect(result == "123")
    }

    @Test("identifiers, capture only underscore", .timeLimit(.minutes(1)))
    func captureOnlyUnderscore() async throws {
        let ctx: [String: Any] = [
            "__": "goodbye"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% capture _ %}hello {{ __ }}{% endcapture %}{{ _ }}", context: ctx)
        #expect(result == "hello goodbye")
    }

    @Test("identifiers, capture underscore", .timeLimit(.minutes(1)))
    func captureUnderscore() async throws {
        let ctx: [String: Any] = [
            "bar_b": "goodbye"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% capture foo_a %}hello {{ bar_b }}{% endcapture %}{{ foo_a }}", context: ctx)
        #expect(result == "hello goodbye")
    }

    @Test("identifiers, decrement with a hyphen", .timeLimit(.minutes(1)))
    func decrementWithAHyphen() async throws {
        let result = try await renderWithTimeout(template: "{% decrement f-oo %}{% decrement f-oo %}", context: [:])
        #expect(result == "-1-2")
    }

    @Test("identifiers, digits", .timeLimit(.minutes(1)))
    func digits() async throws {
        let ctx: [String: Any] = [
            "bar2": "goodbye"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign foo1 = 'hello' %}{{ foo1 }} {{ bar2 }}", context: ctx)
        #expect(result == "hello goodbye")
    }

    @Test("identifiers, hyphen in for loop target", .timeLimit(.minutes(1)))
    func hyphenInForLoopTarget() async throws {
        let ctx: [String: Any] = [
            "f-oo": [1, 2, 3]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% for x in f-oo %}{{ x }}{% endfor %}", context: ctx)
        #expect(result == "123")
    }

    @Test("identifiers, hyphen in for loop variable", .timeLimit(.minutes(1)))
    func hyphenInForLoopVariable() async throws {
        let ctx: [String: Any] = [
            "foo": [1, 2, 3]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% for x-y in foo %}{{ x-y }}{% endfor %}", context: ctx)
        #expect(result == "123")
    }

    @Test("identifiers, hyphens", .timeLimit(.minutes(1)))
    func hyphens() async throws {
        let ctx: [String: Any] = [
            "bar-b": "goodbye"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign foo-a = 'hello' %}{{ foo-a }} {{ bar-b }}", context: ctx)
        #expect(result == "hello goodbye")
    }

    @Test("identifiers, increment with a hyphen", .timeLimit(.minutes(1)))
    func incrementWithAHyphen() async throws {
        let result = try await renderWithTimeout(template: "{% increment f-oo %}{% increment f-oo %}", context: [:])
        #expect(result == "01")
    }

    @Test("identifiers, leading hyphen", .timeLimit(.minutes(1)))
    func leadingHyphen() async throws {
        let ctx: [String: Any] = [
            "-bar": "goodbye"
        ] as [String: Any]
        do {
            _ = try await renderWithTimeout(template: "{% assign -foo = 'hello' %}{{ -foo }} {{ -bar }}", context: ctx)
            Issue.record("Expected error for \"identifiers, leading hyphen\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("identifiers, leading hyphen in for loop target", .timeLimit(.minutes(1)))
    func leadingHyphenInForLoopTarget() async throws {
        let ctx: [String: Any] = [
            "-foo": [1, 2, 3]
        ] as [String: Any]
        do {
            _ = try await renderWithTimeout(template: "{% for x in -foo %}{{ x }}{% endfor %}", context: ctx)
            Issue.record("Expected error for \"identifiers, leading hyphen in for loop target\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("identifiers, leading underscore", .timeLimit(.minutes(1)))
    func leadingUnderscore() async throws {
        let ctx: [String: Any] = [
            "_bar": "goodbye"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign _foo = 'hello' %}{{ _foo }} {{ _bar }}", context: ctx)
        #expect(result == "hello goodbye")
    }

    @Test("identifiers, only digits", .timeLimit(.minutes(1)))
    func onlyDigits() async throws {
        let ctx: [String: Any] = [
            "456": "goodbye"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign 123 = 'hello' %}{{ 123 }} {{ 456 }}", context: ctx)
        #expect(result == "123 456")
    }

    @Test("identifiers, only underscore", .timeLimit(.minutes(1)))
    func onlyUnderscore() async throws {
        let ctx: [String: Any] = [
            "__": "goodbye"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign _ = 'hello' %}{{ _ }} {{ __ }}", context: ctx)
        #expect(result == "hello goodbye")
    }

    @Test("identifiers, trailing question mark assign", .timeLimit(.minutes(1)))
    func trailingQuestionMarkAssign() async throws {
        do {
            _ = try await renderWithTimeout(template: "{% assign foo? = 'hello' %}{{ foo? }}", context: [:])
            Issue.record("Expected error for \"identifiers, trailing question mark assign\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("identifiers, trailing question mark in for loop target", .timeLimit(.minutes(1)))
    func trailingQuestionMarkInForLoopTarget() async throws {
        let ctx: [String: Any] = [
            "foo?": [1, 2, 3]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% for x in foo? %}{{ x }}{% endfor %}", context: ctx)
        #expect(result == "123")
    }

    @Test("identifiers, trailing question mark in for loop variable", .timeLimit(.minutes(1)))
    func trailingQuestionMarkInForLoopVariable() async throws {
        let ctx: [String: Any] = [
            "foo": [1, 2, 3]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% for x? in foo %}{{ x? }}{% endfor %}", context: ctx)
        #expect(result == "123")
    }

    @Test("identifiers, trailing question mark output", .timeLimit(.minutes(1)))
    func trailingQuestionMarkOutput() async throws {
        let ctx: [String: Any] = [
            "bar?": "goodbye"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ bar? }}", context: ctx)
        #expect(result == "goodbye")
    }

    @Test("identifiers, underscore", .timeLimit(.minutes(1)))
    func underscore() async throws {
        let ctx: [String: Any] = [
            "bar_b": "goodbye"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% assign foo_a = 'hello' %}{{ foo_a }} {{ bar_b }}", context: ctx)
        #expect(result == "hello goodbye")
    }
}
