//
//  Base64EncodeTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: base64 encode", .serialized)
struct GoldenBase64EncodeTests {

    @Test("filters, base64 encode, from string", .timeLimit(.minutes(1)))
    func fromString() async throws {
        let result = try await renderWithTimeout(template: "{{ \"_#/.\" | base64_encode }}", context: [:])
        #expect(result == "XyMvLg==")
    }

    @Test("filters, base64 encode, from string with URL unsafe", .timeLimit(.minutes(1)))
    func fromStringWithUrlUnsafe() async throws {
        let ctx: [String: Any] = [
            "a": "abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ 1234567890 !@#$%^&*()-=_+/?.:;[]{}\\|"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | base64_encode }}", context: ctx)
        #expect(result == "YWJjZGVmZ2hpamtsbW5vcHFyc3R1dnd4eXogQUJDREVGR0hJSktMTU5PUFFSU1RVVldYWVogMTIzNDU2Nzg5MCAhQCMkJV4mKigpLT1fKy8/Ljo7W117fVx8")
    }

    @Test("filters, base64 encode, not a string", .timeLimit(.minutes(1)))
    func notAString() async throws {
        let result = try await renderWithTimeout(template: "{{ 5 | base64_encode }}", context: [:])
        #expect(result == "NQ==")
    }

    @Test("filters, base64 encode, undefined left value", .timeLimit(.minutes(1)))
    func undefinedLeftValue() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | base64_encode }}", context: [:])
        #expect(result == "")
    }

    @Test("filters, base64 encode, unexpected argument", .timeLimit(.minutes(1)))
    func unexpectedArgument() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ \"hello\" | base64_encode: 5 }}", context: [:])
            Issue.record("Expected error for \"filters, base64 encode, unexpected argument\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }
}
