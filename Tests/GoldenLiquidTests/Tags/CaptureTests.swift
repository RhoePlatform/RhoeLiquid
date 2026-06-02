//
//  CaptureTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: capture", .serialized)
struct GoldenCaptureTests {

    @Test("tags, capture, assign to a variable from a captured variable", .timeLimit(.minutes(1)))
    func assignToAVariableFromACapturedVariable() async throws {
        let result = try await renderWithTimeout(template: "{% capture some %}hello{% endcapture %}{% assign other = some %}{{ some }}-{{ other }}", context: [:])
        #expect(result == "hello-hello")
    }

    @Test("tags, capture, capture into a variable with a hyphen", .timeLimit(.minutes(1)))
    func captureIntoAVariableWithAHyphen() async throws {
        let ctx: [String: Any] = [
            "customer": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("first_name", "Holly" as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% capture this-thing %}Hello, {{ customer.first_name }}.{% endcapture %}{{ this-thing }}", context: ctx)
        #expect(result == "Hello, Holly.")
    }

    @Test("tags, capture, capture template literal and global variable", .timeLimit(.minutes(1)))
    func captureTemplateLiteralAndGlobalVariable() async throws {
        let ctx: [String: Any] = [
            "customer": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("first_name", "Holly" as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% capture greeting %}Hello, {{ customer.first_name }}.{% endcapture %}{{ greeting }}", context: ctx)
        #expect(result == "Hello, Holly.")
    }
}
