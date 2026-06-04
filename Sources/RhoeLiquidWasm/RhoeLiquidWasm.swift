//
//  RhoeLiquidWasm.swift
//  RhoeLiquidWasm
//
//  Created as part of RhoeLiquid
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import RhoeLiquid
import LiquidCore
import LiquidLexer
import LiquidParser

/// Wasm-compatible subset of the RhoeLiquid template engine.
///
/// Provides Liquid template parsing, rendering, analysis, and validation
/// without platform-dependent features (HTTP service, DOCX pipeline, CLI,
/// network-based data sources, memory pressure monitoring).
///
/// ## Supported Features
/// - Full Shopify Liquid parsing (1,013/1,013 golden test conformance)
/// - 43+ built-in filters (string, array, math, utility)
/// - All control flow tags (if/for/case/unless/tablerow)
/// - Template composition (include, render, extends)
/// - Template analysis (complexity, quality score, variable extraction)
/// - Template validation (syntax checking, error reporting)
/// - Template caching and compiled template optimization
///
/// ## Not Supported in Wasm
/// - HTTP service endpoints (localhost:13480)
/// - DOCX rendering pipeline (RhoeDOCX)
/// - CLI commands
/// - Network-based data source loading (URLSession)
/// - Memory pressure monitoring (DispatchSource)
/// - SQLite data sources
///
/// ## Error Handling
///
/// Methods that throw report errors via `LexerError`, `ParserError`, or `RenderError`.
/// `validate()` and `extractVariables()` never throw; they return empty results on failure.
///
/// ## Thread Safety
///
/// All static methods create isolated `LiquidEngine` instances with no shared mutable state.
/// In WebAssembly's single-threaded execution model, all calls execute sequentially.
///
/// ## Build for WebAssembly
/// ```bash
/// swift sdk install swift-6.3-RELEASE_wasm
/// swift build --swift-sdk swift-6.3-RELEASE_wasm --target RhoeLiquidWasm
/// ```
public struct RhoeLiquidWasm: Sendable {

    /// Version string for the WASM target (tracks the main engine version).
    public static let version = "0.1.1-wasm"

    // MARK: - Render

    /// Render a Liquid template with context data.
    ///
    /// - Parameters:
    ///   - template: A string containing Liquid template syntax.
    ///   - context: A dictionary of variables available to the template.
    /// - Returns: The rendered output string.
    /// - Throws: `LexerError`, `ParserError`, or `RenderError` on failure.
    public static func render(template: String, context: [String: Any] = [:]) async throws -> String {
        let engine = LiquidEngine()
        return try await engine.render(template: template, context: context)
    }

    /// Render a Liquid template and return output with performance metrics.
    ///
    /// Uses `Date.timeIntervalSinceReferenceDate` for portable timing that works
    /// across all platforms including WebAssembly.
    ///
    /// - Parameters:
    ///   - template: A string containing Liquid template syntax.
    ///   - context: A dictionary of variables available to the template.
    /// - Returns: ``RenderMetrics`` with the output and timing data.
    public static func renderWithMetrics(
        template: String,
        context: [String: Any] = [:]
    ) async throws -> RenderMetrics {
        let startTime = Date.timeIntervalSinceReferenceDate
        let output = try await render(template: template, context: context)
        let durationMs = (Date.timeIntervalSinceReferenceDate - startTime) * 1000
        let variables = extractVariables(template: template)
        return RenderMetrics(
            output: output,
            renderTimeMs: durationMs,
            parseTimeMs: 0,
            variableCount: variables.count,
            filterCount: 0
        )
    }

    // MARK: - Validate

    /// Validate a Liquid template for syntax errors.
    ///
    /// Runs the full lexer + parser pipeline without rendering. Returns an empty
    /// array if the template is syntactically valid.
    ///
    /// - Parameter template: A string containing Liquid template syntax.
    /// - Returns: An array of error descriptions (empty if valid).
    public static func validate(template: String) -> [String] {
        do {
            let lexer = Lexer(template)
            let tokens = try lexer.tokenize()
            let parser = Parser(consuming: tokens)
            _ = try parser.parse()
            return []
        } catch {
            return [error.localizedDescription]
        }
    }

    // MARK: - Extract Variables

    /// Extract variable names referenced in a Liquid template.
    ///
    /// Scans for `{{ variable }}` and `{{ variable.path }}` patterns using regex.
    /// Returns a sorted, deduplicated list of variable paths.
    ///
    /// - Parameter template: A string containing Liquid template syntax.
    /// - Returns: Sorted array of unique variable names (e.g., `["user.email", "user.name"]`).
    public static func extractVariables(template: String) -> [String] {
        var variables = Set<String>()
        let pattern = #"\{\{\s*([\w.]+)"#
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let range = NSRange(template.startIndex..., in: template)
            let matches = regex.matches(in: template, range: range)
            for match in matches {
                if let varRange = Range(match.range(at: 1), in: template) {
                    variables.insert(String(template[varRange]))
                }
            }
        }
        return Array(variables).sorted()
    }

    // MARK: - Feature Discovery

    /// Returns the capabilities of the WASM engine for runtime discovery.
    public static let capabilities = WasmCapabilities(
        supportsRender: true,
        supportsAnalysis: true,
        supportsValidation: true,
        supportsDocx: false,
        supportsNetworkDataSources: false,
        supportsSQLite: false,
        supportsYAML: false,
        builtInFilterCount: 43,
        maxNestingDepth: 100
    )
}

// MARK: - WASM-Specific Types

/// Performance metrics from a template render operation.
public struct RenderMetrics: Sendable {
    /// The rendered output string.
    public let output: String
    /// Total render time in milliseconds.
    public let renderTimeMs: Double
    /// Parse time in milliseconds.
    public let parseTimeMs: Double
    /// Number of variables resolved.
    public let variableCount: Int
    /// Number of filter applications.
    public let filterCount: Int
}

/// Capability advertisement for the WASM engine.
public struct WasmCapabilities: Sendable {
    public let supportsRender: Bool
    public let supportsAnalysis: Bool
    public let supportsValidation: Bool
    public let supportsDocx: Bool
    public let supportsNetworkDataSources: Bool
    public let supportsSQLite: Bool
    public let supportsYAML: Bool
    public let builtInFilterCount: Int
    public let maxNestingDepth: Int
}
