//
//  DateTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: date", .serialized)
struct GoldenDateTests {

    @Test("filters, date, literal percent", .timeLimit(.minutes(1)))
    func literalPercent() async throws {
        let result = try await renderWithTimeout(template: "{{ 'March 14, 2016' | date: '%%%b %d, %y' }}", context: [:])
        #expect(result == "%Mar 14, 16")
    }

    @Test("filters, date, missing argument", .timeLimit(.minutes(1)))
    func missingArgument() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ 'March 14, 2016' | date }}", context: [:])
            Issue.record("Expected error for \"filters, date, missing argument\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, date, negative timestamp string", .timeLimit(.minutes(1)))
    func negativeTimestampString() async throws {
        let result = try await renderWithTimeout(template: "{{ '-1152098955' | date: '%m/%d/%Y' }}", context: [:])
        #expect(result == "-1152098955")
    }

    @Test("filters, date, seconds since epoch format directive", .timeLimit(.minutes(1)))
    func secondsSinceEpochFormatDirective() async throws {
        let result = try await renderWithTimeout(template: "{{ 'March 14, 2016' | date: '%s' }}", context: [:])
        #expect(result == "1457913600")
    }

    @Test("filters, date, timestamp integer", .timeLimit(.minutes(1)))
    func timestampInteger() async throws {
        let result = try await renderWithTimeout(template: "{{ 1152098955 | date: '%m/%d/%Y' }}", context: [:])
        #expect(result == "07/05/2006")
    }

    @Test("filters, date, timestamp string", .timeLimit(.minutes(1)))
    func timestampString() async throws {
        let result = try await renderWithTimeout(template: "{{ '1152098955' | date: '%m/%d/%Y' }}", context: [:])
        #expect(result == "07/05/2006")
    }

    @Test("filters, date, too many arguments", .timeLimit(.minutes(1)))
    func tooManyArguments() async throws {
        do {
            _ = try await renderWithTimeout(template: "{{ 'March 14, 2016' | date: '%b %d, %y', 'foo' }}", context: [:])
            Issue.record("Expected error for \"filters, date, too many arguments\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("filters, date, undefined argument", .timeLimit(.minutes(1)))
    func undefinedArgument() async throws {
        let result = try await renderWithTimeout(template: "{{ 'March 14, 2016' | date: nosuchthing }}", context: [:])
        #expect(result == "March 14, 2016")
    }

    @Test("filters, date, undefined left value", .timeLimit(.minutes(1)))
    func undefinedLeftValue() async throws {
        let result = try await renderWithTimeout(template: "{{ nosuchthing | date: '%b %d, %y' }}", context: [:])
        #expect(result == "")
    }

    @Test("filters, date, well formed string", .timeLimit(.minutes(1)))
    func wellFormedString() async throws {
        let result = try await renderWithTimeout(template: "{{ 'March 14, 2016' | date: '%b %d, %y' }}", context: [:])
        #expect(result == "Mar 14, 16")
    }
}
