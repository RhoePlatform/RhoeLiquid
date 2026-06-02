//
//  Base64DecodeTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: base64 decode", .serialized)
struct GoldenBase64DecodeTests {

    @Test("filters, base64 decode, from string", .timeLimit(.minutes(1)))
    func fromString() async throws {
        let result = try await renderWithTimeout(template: "{{ \"XyMvLg==\" | base64_decode }}", context: [:])
        #expect(result == "_#/.")
    }

    @Test("filters, base64 decode, from string with URL unsafe", .timeLimit(.minutes(1)))
    func fromStringWithUrlUnsafe() async throws {
        let ctx: [String: Any] = [
            "a": "YWJjZGVmZ2hpamtsbW5vcHFyc3R1dnd4eXogQUJDREVGR0hJSktMTU5PUFFSU1RVVldYWVogMTIzNDU2Nzg5MCAhQCMkJV4mKigpLT1fKy8/Ljo7W117fVx8"
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | base64_decode }}", context: ctx)
        #expect(result == "abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ 1234567890 !@#$%^&*()-=_+/?.:;[]{}\\|")
    }

    @Test("filters, base64 decode, not a string", .timeLimit(.minutes(1)))
    func notAString() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ 5 | base64_decode }}", context: [:])
            Issue.record("Expected error for \"filters, base64 decode, not a string\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, base64 decode, undefined left value", .timeLimit(.minutes(1)))
    func undefinedLeftValue() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | base64_decode }}", context: [:])
        #expect(result == "")
    }

    @Test("filters, base64 decode, unexpected argument", .timeLimit(.minutes(1)))
    func unexpectedArgument() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ \"hello\" | base64_decode: 5 }}", context: [:])
            Issue.record("Expected error for \"filters, base64 decode, unexpected argument\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }
}
