//
//  GoldenLiquidTestRunner.swift
//  GoldenLiquidTests
//
//  Created as part of RhoeLiquid
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
@testable import RhoeLiquid

// MARK: - Fixture Loader

/// Loads the golden_liquid.json fixture for scripting/analysis purposes.
/// Individual test files are auto-generated with inline fixtures —
/// this loader is NOT used at test runtime.
enum GoldenLiquidLoader {
    static func loadFixture() throws -> GoldenLiquidSuite {
        guard let url = Bundle.module.url(
            forResource: "golden_liquid",
            withExtension: "json",
            subdirectory: "Fixtures"
        ) else {
            throw GoldenLiquidError.fixtureNotFound
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(GoldenLiquidSuite.self, from: data)
    }
}

enum GoldenLiquidError: Error {
    case fixtureNotFound
}
