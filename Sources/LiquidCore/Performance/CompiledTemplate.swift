//
//  CompiledTemplate.swift
//  LiquidCore
//
//  High-performance compiled template representation
//

import Foundation

/// A high-performance compiled representation of a Liquid template
/// that eliminates parsing overhead during rendering
@frozen
public struct CompiledTemplate: Sendable {
    /// Pre-compiled AST with optimizations applied
    public let optimizedAST: ASTNode
    
    /// Pre-computed static parts of the template
    public let staticSegments: [String]

    /// Pre-computed UTF-8 capacity hint for the static parts of the template.
    public let staticCapacityHint: Int
    
    /// Variable access patterns for optimization
    public let variableAccess: [String: AccessPattern]
    
    /// Filter usage statistics for caching
    public let filterUsage: [String: Int]
    
    /// Performance hints for the renderer
    public let performanceHints: PerformanceHints
    
    /// Compilation timestamp for cache invalidation
    public let compiledAt: Date
    
    /// Template complexity score for optimization decisions
    public let complexityScore: Int
    
    public init(
        optimizedAST: ASTNode,
        staticSegments: [String] = [],
        staticCapacityHint: Int? = nil,
        variableAccess: [String: AccessPattern] = [:],
        filterUsage: [String: Int] = [:],
        performanceHints: PerformanceHints = PerformanceHints(),
        complexityScore: Int = 0
    ) {
        self.optimizedAST = optimizedAST
        self.staticSegments = staticSegments
        self.staticCapacityHint = staticCapacityHint ?? staticSegments.reduce(0) { partial, segment in
            partial + segment.utf8.count
        }
        self.variableAccess = variableAccess
        self.filterUsage = filterUsage
        self.performanceHints = performanceHints
        self.compiledAt = Date()
        self.complexityScore = complexityScore
    }
}

/// Optimization patterns detected during compilation
@frozen
public struct AccessPattern: Sendable {
    public let path: [String]
    public let frequency: Int
    public let isDeepAccess: Bool
    public let isLoopVariable: Bool
    
    public init(path: [String], frequency: Int = 1, isDeepAccess: Bool = false, isLoopVariable: Bool = false) {
        self.path = path
        self.frequency = frequency
        self.isDeepAccess = isDeepAccess
        self.isLoopVariable = isLoopVariable
    }
}

/// Performance hints for the renderer
@frozen
public struct PerformanceHints: Sendable {
    public let hasNestedLoops: Bool
    public let maxLoopDepth: Int
    public let hasComplexFilters: Bool
    public let staticContentRatio: Double
    public let estimatedVariableCount: Int
    public let canSkipForloopObjectAnalysis: Bool
    public let canSkipTableRowLoopObjectAnalysis: Bool
    
    public init(
        hasNestedLoops: Bool = false,
        maxLoopDepth: Int = 0,
        hasComplexFilters: Bool = false,
        staticContentRatio: Double = 0.5,
        estimatedVariableCount: Int = 0,
        canSkipForloopObjectAnalysis: Bool = false,
        canSkipTableRowLoopObjectAnalysis: Bool = false
    ) {
        self.hasNestedLoops = hasNestedLoops
        self.maxLoopDepth = maxLoopDepth
        self.hasComplexFilters = hasComplexFilters
        self.staticContentRatio = staticContentRatio
        self.estimatedVariableCount = estimatedVariableCount
        self.canSkipForloopObjectAnalysis = canSkipForloopObjectAnalysis
        self.canSkipTableRowLoopObjectAnalysis = canSkipTableRowLoopObjectAnalysis
    }
}
