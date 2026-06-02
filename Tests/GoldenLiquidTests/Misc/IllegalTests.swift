//
//  IllegalTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: illegal", .serialized)
struct GoldenIllegalTests {

    @Test("illegal, no addition operator", .timeLimit(.minutes(1)))
    func noAdditionOperator() async throws {
        do {
            _ = try await renderWithTimeout(template: "{% assign x = 1 + 2 %}{{ x }}", context: [:])
            Issue.record("Expected error for \"illegal, no addition operator\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("illegal, no multiplication operator", .timeLimit(.minutes(1)))
    func noMultiplicationOperator() async throws {
        do {
            _ = try await renderWithTimeout(template: "{% assign x = 2 %}{{ x * 3 }}", context: [:])
            Issue.record("Expected error for \"illegal, no multiplication operator\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("illegal, no subtraction operator", .timeLimit(.minutes(1)))
    func noSubtractionOperator() async throws {
        do {
            _ = try await renderWithTimeout(template: "{% assign x = 1 - 2 %}{{ x }}", context: [:])
            Issue.record("Expected error for \"illegal, no subtraction operator\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }

    @Test("illegal, unknown tag", .timeLimit(.minutes(1)))
    func unknownTag() async throws {
        do {
            _ = try await renderWithTimeout(template: "{% nosuchthing %}", context: [:])
            Issue.record("Expected error for \"illegal, unknown tag\" but rendering succeeded")
        } catch is GoldenTestTimeoutError {
            throw GoldenTestTimeoutError(seconds: 2.0)
        } catch {
            // Expected error
        }
    }
}
