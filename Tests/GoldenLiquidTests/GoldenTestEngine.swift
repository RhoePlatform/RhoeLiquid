//
//  GoldenTestEngine.swift
//  GoldenLiquidTests
//
//  Created as part of RhoeLiquid
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
@testable import RhoeLiquid

// MARK: - Shared Engine

/// Shared LiquidEngine for all golden conformance tests.
enum GoldenTestEngine {
    static let shared = LiquidEngine()
}

// MARK: - Sendable Context Wrapper

struct SendableContext: @unchecked Sendable {
    let value: [String: Any]
    init(_ value: [String: Any]) { self.value = value }
}

// MARK: - Timeout

struct GoldenTestTimeoutError: Error, CustomStringConvertible {
    let seconds: Double
    var description: String { "Test timed out after \(seconds)s" }
}

/// Renders a template using the shared engine.
/// The renderer checks Task.isCancelled at each node and loop iteration,
/// and Swift Testing's .timeLimit(.minutes(1)) provides the safety net.
func renderWithTimeout(
    template: String,
    context: [String: Any] = [:],
    seconds: Double = 2.0
) async throws -> String {
    try await GoldenTestEngine.shared.render(template: template, context: context)
}

/// Renders with template inheritance using the shared engine.
func renderWithInheritanceTimeout(
    templatePath: String,
    context: [String: Any] = [:],
    baseDirectory: URL,
    seconds: Double = 2.0
) async throws -> String {
    try await GoldenTestEngine.shared.renderWithInheritance(
        templatePath: templatePath, context: context,
        baseDirectory: baseDirectory)
}
