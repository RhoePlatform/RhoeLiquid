//
//  SliceTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: slice", .serialized)
struct GoldenSliceTests {

    @Test("filters, slice, first argument is a float", .timeLimit(.minutes(1)))
    func firstArgumentIsAFloat() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ 'Liquid' | slice: 2.2 }}", context: [:])
            Issue.record("Expected error for \"filters, slice, first argument is a float\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, slice, first argument is a string", .timeLimit(.minutes(1)))
    func firstArgumentIsAString() async throws {
        let result = try await renderWithTimeout(template: "{{ \"hello\" | slice: \"2\" }}", context: [:])
        #expect(result == "l")
    }

    @Test("filters, slice, first argument not an integer", .timeLimit(.minutes(1)))
    func firstArgumentNotAnInteger() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ \"hello\" | slice: \"foo\" }}", context: [:])
            Issue.record("Expected error for \"filters, slice, first argument not an integer\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, slice, missing arguments", .timeLimit(.minutes(1)))
    func missingArguments() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ \"hello\" | slice }}", context: [:])
            Issue.record("Expected error for \"filters, slice, missing arguments\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, slice, negative first argument", .timeLimit(.minutes(1)))
    func negativeFirstArgument() async throws {
        let result = try await renderWithTimeout(template: "{{ 'Liquid' | slice: -2 }}", context: [:])
        #expect(result == "i")
    }

    @Test("filters, slice, negative first argument and length out of range", .timeLimit(.minutes(1)))
    func negativeFirstArgumentAndLengthOutOfRange() async throws {
        let result = try await renderWithTimeout(template: "{{ 'Liquid' | slice: -2, 99 }}", context: [:])
        #expect(result == "id")
    }

    @Test("filters, slice, negative first argument and negative length", .timeLimit(.minutes(1)))
    func negativeFirstArgumentAndNegativeLength() async throws {
        let result = try await renderWithTimeout(template: "{{ 'Liquid' | slice: -2, -1 }}", context: [:])
        #expect(result == "")
    }

    @Test("filters, slice, negative first argument and positive length", .timeLimit(.minutes(1)))
    func negativeFirstArgumentAndPositiveLength() async throws {
        let result = try await renderWithTimeout(template: "{{ 'Liquid' | slice: -2, 2 }}", context: [:])
        #expect(result == "id")
    }

    @Test("filters, slice, not a string", .timeLimit(.minutes(1)))
    func notAString() async throws {
        let result = try await renderWithTimeout(template: "{{ 5 | slice: 1 }}", context: [:])
        #expect(result == "")
    }

    @Test("filters, slice, one", .timeLimit(.minutes(1)))
    func one() async throws {
        let result = try await renderWithTimeout(template: "{{ \"hello\" | slice: 1 }}", context: [:])
        #expect(result == "e")
    }

    @Test("filters, slice, one length three", .timeLimit(.minutes(1)))
    func oneLengthThree() async throws {
        let result = try await renderWithTimeout(template: "{{ \"hello\" | slice: 1, 3 }}", context: [:])
        #expect(result == "ell")
    }

    @Test("filters, slice, out of range", .timeLimit(.minutes(1)))
    func outOfRange() async throws {
        let result = try await renderWithTimeout(template: "{{ \"hello\" | slice: 99 }}", context: [:])
        #expect(result == "")
    }

    @Test("filters, slice, second argument is a float", .timeLimit(.minutes(1)))
    func secondArgumentIsAFloat() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ 'Liquid' | slice: 1, 2.2 }}", context: [:])
            Issue.record("Expected error for \"filters, slice, second argument is a float\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, slice, second argument is a string", .timeLimit(.minutes(1)))
    func secondArgumentIsAString() async throws {
        let result = try await renderWithTimeout(template: "{{ \"hello\" | slice: 3, \"2\" }}", context: [:])
        #expect(result == "lo")
    }

    @Test("filters, slice, second argument not an integer", .timeLimit(.minutes(1)))
    func secondArgumentNotAnInteger() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ \"hello\" | slice: 5, \"foo\" }}", context: [:])
            Issue.record("Expected error for \"filters, slice, second argument not an integer\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, slice, slice an array of numbers", .timeLimit(.minutes(1)))
    func sliceAnArrayOfNumbers() async throws {
        let ctx: [String: Any] = [
            "a": [1, 2, 3, 4, 5]
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{{ a | slice: 2, 3 | join: '#' }}", context: ctx)
        #expect(result == "3#4#5")
    }

    @Test("filters, slice, too many arguments", .timeLimit(.minutes(1)))
    func tooManyArguments() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ \"hello\" | slice: 1, 2, 3 }}", context: [:])
            Issue.record("Expected error for \"filters, slice, too many arguments\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, slice, undefined first argument", .timeLimit(.minutes(1)))
    func undefinedFirstArgument() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ \"hello\" | slice: nosuchthing, 3 }}", context: [:])
            Issue.record("Expected error for \"filters, slice, undefined first argument\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, slice, undefined left value", .timeLimit(.minutes(1)))
    func undefinedLeftValue() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | slice: 1, 3 }}", context: [:])
        #expect(result == "")
    }

    @Test("filters, slice, undefined second argument", .timeLimit(.minutes(1)))
    func undefinedSecondArgument() async throws {
        let result = try await renderWithTimeout(template: "{{ \"hello\" | slice: 1, nosuchthing }}", context: [:])
        #expect(result == "e")
    }

    @Test("filters, slice, zero", .timeLimit(.minutes(1)))
    func zero() async throws {
        let result = try await renderWithTimeout(template: "{{ \"hello\" | slice: 0 }}", context: [:])
        #expect(result == "h")
    }
}
