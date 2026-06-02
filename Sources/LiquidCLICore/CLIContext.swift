//
//  CLIContext.swift
//  LiquidCLICore
//
//  Created as part of RhoeLiquid
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import RhoeLiquid

/// Shared CLI context providing engine access and metrics tracking.
actor CLIContext {
    let engine: LiquidEngine
    private(set) var renderCount: Int = 0
    private(set) var totalRenderTime: TimeInterval = 0

    init() {
        self.engine = LiquidEngine()
    }

    func render(template: String, context: sending [String: Any] = [:]) async throws -> String {
        let start = Date().timeIntervalSinceReferenceDate
        let result = try await engine.render(template: template, context: context)
        totalRenderTime += Date().timeIntervalSinceReferenceDate - start
        renderCount += 1
        return result
    }

    var averageRenderTime: TimeInterval {
        renderCount > 0 ? totalRenderTime / Double(renderCount) : 0
    }
}
