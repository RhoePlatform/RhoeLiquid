//
//  ASTOptimizer.swift
//  LiquidRenderer
//
//  Lightweight compatibility shim for the archived optimization pipeline.
//

import Foundation

/// Namespace for optimization-related compatibility types.
///
/// The active engine now optimizes through `TemplateCompiler` and the live
/// `OptimizedRenderer` path. This namespace remains only to preserve older source
/// compatibility around archived optimizer settings and statistics payloads.
public enum ASTOptimizer {
    /// Optimization hints preserved for source compatibility.
    ///
    /// Active today:
    /// - `enableConstantFolding`
    /// - `enableDeadCodeElimination`
    /// - `enableLoopOptimization`
    /// - `enableTemplateInlining`
    ///
    /// Compatibility-only today:
    /// - `maxLoopUnrollSize`
    /// - `maxOptimizationPasses`
    ///
    /// The active engine maps the boolean flags onto `TemplateCompiler` behavior.
    /// The archived numeric pass controls are now on a formal deprecation path:
    /// they remain source-compatible payload fields for 1.x, but they do not
    /// reactivate the older optimizer pipeline and will be removed in the next
    /// major release.
    public struct OptimizationOptions: Sendable {
        private static func makeOptions(
            enableConstantFolding: Bool,
            enableDeadCodeElimination: Bool,
            enableLoopOptimization: Bool,
            enableTemplateInlining: Bool,
            maxLoopUnrollSize: Int,
            maxOptimizationPasses: Int
        ) -> Self {
            Self(
                enableConstantFolding: enableConstantFolding,
                enableDeadCodeElimination: enableDeadCodeElimination,
                enableLoopOptimization: enableLoopOptimization,
                enableTemplateInlining: enableTemplateInlining,
                maxLoopUnrollSize: maxLoopUnrollSize,
                maxOptimizationPasses: maxOptimizationPasses,
                _deprecatedShim: ()
            )
        }

        /// Enables constant folding in the active compiler path.
        public let enableConstantFolding: Bool

        /// Enables dead code elimination in the active compiler path.
        public let enableDeadCodeElimination: Bool

        /// Enables loop-related compiler optimizations in the active compiler path.
        public let enableLoopOptimization: Bool

        /// Enables inline-oriented compiler optimizations in the active compiler path.
        public let enableTemplateInlining: Bool

        private let maxLoopUnrollSizeStorage: Int
        private let maxOptimizationPassesStorage: Int

        /// Archived compatibility field. Loop unrolling is not separately configurable today.
        @available(*, deprecated, message: "Archived compatibility field. Use OptimizationOptions.active(...) and the live boolean flags instead. This field will be removed in the next major release.")
        public var maxLoopUnrollSize: Int { maxLoopUnrollSizeStorage }

        /// Archived compatibility field. Multi-pass optimizer counts are not separately configurable today.
        @available(*, deprecated, message: "Archived compatibility field. Use OptimizationOptions.active(...) and the live boolean flags instead. This field will be removed in the next major release.")
        public var maxOptimizationPasses: Int { maxOptimizationPassesStorage }

        /// Preferred factory for the live optimizer profile.
        public static func active(
            enableConstantFolding: Bool = true,
            enableDeadCodeElimination: Bool = true,
            enableLoopOptimization: Bool = true,
            enableTemplateInlining: Bool = true
        ) -> Self {
            makeOptions(
                enableConstantFolding: enableConstantFolding,
                enableDeadCodeElimination: enableDeadCodeElimination,
                enableLoopOptimization: enableLoopOptimization,
                enableTemplateInlining: enableTemplateInlining,
                maxLoopUnrollSize: 10,
                maxOptimizationPasses: 3
            )
        }

        @available(*, deprecated, message: "Use OptimizationOptions.active(...) instead. maxLoopUnrollSize and maxOptimizationPasses are archived compatibility fields and will be removed in the next major release.")
        public init(
            enableConstantFolding: Bool = true,
            enableDeadCodeElimination: Bool = true,
            enableLoopOptimization: Bool = true,
            enableTemplateInlining: Bool = true,
            maxLoopUnrollSize: Int = 10,
            maxOptimizationPasses: Int = 3
        ) {
            self = Self.makeOptions(
                enableConstantFolding: enableConstantFolding,
                enableDeadCodeElimination: enableDeadCodeElimination,
                enableLoopOptimization: enableLoopOptimization,
                enableTemplateInlining: enableTemplateInlining,
                maxLoopUnrollSize: maxLoopUnrollSize,
                maxOptimizationPasses: maxOptimizationPasses
            )
        }

        private init(
            enableConstantFolding: Bool,
            enableDeadCodeElimination: Bool,
            enableLoopOptimization: Bool,
            enableTemplateInlining: Bool,
            maxLoopUnrollSize: Int,
            maxOptimizationPasses: Int,
            _deprecatedShim: Void
        ) {
            self.enableConstantFolding = enableConstantFolding
            self.enableDeadCodeElimination = enableDeadCodeElimination
            self.enableLoopOptimization = enableLoopOptimization
            self.enableTemplateInlining = enableTemplateInlining
            self.maxLoopUnrollSizeStorage = maxLoopUnrollSize
            self.maxOptimizationPassesStorage = maxOptimizationPasses
        }

        public static let aggressive = active()
        public static let balanced = active(
            enableTemplateInlining: false,
        )
        public static let conservative = active(
            enableLoopOptimization: false,
            enableTemplateInlining: false,
        )
    }

    /// Compatibility statistics surfaced by the active renderer.
    ///
    /// These counters preserve the older statistics shape, but only fields backed
    /// by the live `OptimizedRenderer` pipeline should be treated as active signal.
    public struct OptimizationStatistics: Sendable {
        public var expressionsOptimized: Int
        public var branchesEliminated: Int
        public var loopsUnrolled: Int
        public var filtersOptimized: Int
        public var deadAssignmentsEliminated: Int
        public var conditionalsMerged: Int
        public var templatesInlined: Int

        public init(
            expressionsOptimized: Int = 0,
            branchesEliminated: Int = 0,
            loopsUnrolled: Int = 0,
            filtersOptimized: Int = 0,
            deadAssignmentsEliminated: Int = 0,
            conditionalsMerged: Int = 0,
            templatesInlined: Int = 0
        ) {
            self.expressionsOptimized = expressionsOptimized
            self.branchesEliminated = branchesEliminated
            self.loopsUnrolled = loopsUnrolled
            self.filtersOptimized = filtersOptimized
            self.deadAssignmentsEliminated = deadAssignmentsEliminated
            self.conditionalsMerged = conditionalsMerged
            self.templatesInlined = templatesInlined
        }
    }
}

public typealias OptimizationOptions = ASTOptimizer.OptimizationOptions
public typealias OptimizationStatistics = ASTOptimizer.OptimizationStatistics
