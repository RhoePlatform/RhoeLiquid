//
//  ReplaceTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: replace", .serialized)
struct GoldenReplaceTests {

    @Test("filters, replace, argument not a string", .timeLimit(.minutes(1)))
    func argumentNotAString() async throws {
        let result = try await renderWithTimeout(template: "{{ \"hello\" | replace: 5, \"your\" }}", context: [:])
        #expect(result == "hello")
    }

    @Test("filters, replace, left value is an object", .timeLimit(.minutes(1)))
    func leftValueIsAnObject() async throws {
        let ctx: [String: Any] = [
            "a": OrderedDictionary<String, Any>()
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | replace: '{', '!' }}", context: ctx)
        #expect(result == "!}")
    }

    @Test("filters, replace, missing argument", .timeLimit(.minutes(1)))
    func missingArgument() async throws {
        let result = try await renderWithTimeout(template: "{{ \"hello\" | replace: \"ll\" }}", context: [:])
        #expect(result == "heo")
    }

    @Test("filters, replace, missing arguments", .timeLimit(.minutes(1)))
    func missingArguments() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ \"hello\" | replace }}", context: [:])
            Issue.record("Expected error for \"filters, replace, missing arguments\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, replace, not a string", .timeLimit(.minutes(1)))
    func notAString() async throws {
        let result = try await renderWithTimeout(template: "{{ 5 | replace: 'rain', 'foo' }}", context: [:])
        #expect(result == "5")
    }

    @Test("filters, replace, replace substrings", .timeLimit(.minutes(1)))
    func replaceSubstrings() async throws {
        let result = try await renderWithTimeout(template: "{{ \"Take my protein pills and put my helmet on\" | replace: \"my\", \"your\" }}", context: [:])
        #expect(result == "Take your protein pills and put your helmet on")
    }

    @Test("filters, replace, too many arguments", .timeLimit(.minutes(1)))
    func tooManyArguments() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ \"hello\" | replace: \"how\", \"are\", \"you\" }}", context: [:])
            Issue.record("Expected error for \"filters, replace, too many arguments\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, replace, undefined first argument", .timeLimit(.minutes(1)))
    func undefinedFirstArgument() async throws {
        let result = try await renderWithTimeout(template: "{{ \"Take my protein\" | replace: nosuchthing, \"#\" }}", context: [:])
        #expect(result == "#T#a#k#e# #m#y# #p#r#o#t#e#i#n#")
    }

    @Test("filters, replace, undefined left value", .timeLimit(.minutes(1)))
    func undefinedLeftValue() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | replace: \"my\", \"your\" }}", context: [:])
        #expect(result == "")
    }

    @Test("filters, replace, undefined second argument", .timeLimit(.minutes(1)))
    func undefinedSecondArgument() async throws {
        let result = try await renderWithTimeout(template: "{{ \"Take my protein pills and put my helmet on\" | replace: \"my\", nosuchthing }}", context: [:])
        #expect(result == "Take  protein pills and put  helmet on")
    }
}
