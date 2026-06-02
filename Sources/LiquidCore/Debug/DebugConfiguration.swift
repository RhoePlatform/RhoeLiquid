//
//  DebugConfiguration.swift
//  LiquidCore
//
//  Template debugging configuration and settings
//

import Foundation

/// Configuration for template debugging features
public struct DebugConfiguration: Sendable {
    /// Whether debugging is enabled
    public let enabled: Bool
    
    /// Debug step mode for execution control
    public let stepMode: DebugStepMode
    
    /// Whether to collect execution traces
    public let collectTraces: Bool
    
    /// Whether to track variable accesses
    public let trackVariables: Bool
    
    /// Whether to collect performance profiling data
    public let profileExecution: Bool
    
    /// Maximum depth for variable inspection
    public let maxInspectionDepth: Int
    
    /// Maximum number of trace entries to keep
    public let maxTraceEntries: Int
    
    /// Whether to break on errors
    public let breakOnErrors: Bool
    
    /// Whether to break on warnings
    public let breakOnWarnings: Bool
    
    /// Custom debug output handler
    public let outputHandler: DebugOutputHandler?
    
    public init(
        enabled: Bool = false,
        stepMode: DebugStepMode = .run,
        collectTraces: Bool = false,
        trackVariables: Bool = false,
        profileExecution: Bool = false,
        maxInspectionDepth: Int = 10,
        maxTraceEntries: Int = 1000,
        breakOnErrors: Bool = false,
        breakOnWarnings: Bool = false,
        outputHandler: DebugOutputHandler? = nil
    ) {
        self.enabled = enabled
        self.stepMode = stepMode
        self.collectTraces = collectTraces
        self.trackVariables = trackVariables
        self.profileExecution = profileExecution
        self.maxInspectionDepth = maxInspectionDepth
        self.maxTraceEntries = maxTraceEntries
        self.breakOnErrors = breakOnErrors
        self.breakOnWarnings = breakOnWarnings
        self.outputHandler = outputHandler
    }
}

// MARK: - Predefined Configurations

extension DebugConfiguration {
    /// Disabled debugging (default)
    public static let disabled = DebugConfiguration()
    
    /// Basic debugging with variable tracking
    public static let basic = DebugConfiguration(
        enabled: true,
        trackVariables: true
    )
    
    /// Full debugging with all features enabled
    public static let full = DebugConfiguration(
        enabled: true,
        stepMode: .stepInto,
        collectTraces: true,
        trackVariables: true,
        profileExecution: true,
        breakOnErrors: true
    )
    
    /// Performance profiling mode
    public static let profiling = DebugConfiguration(
        enabled: true,
        collectTraces: true,
        profileExecution: true,
        maxTraceEntries: 10000
    )
    
    /// Development mode with comprehensive debugging
    public static let development = DebugConfiguration(
        enabled: true,
        stepMode: .stepOver,
        collectTraces: true,
        trackVariables: true,
        profileExecution: true,
        maxInspectionDepth: 15,
        breakOnErrors: true,
        breakOnWarnings: true
    )
}

/// Debug step modes for execution control
public enum DebugStepMode: Sendable {
    /// Run continuously without stopping
    case run
    
    /// Step over each statement (don't step into functions/includes)
    case stepOver
    
    /// Step into each sub-execution (includes, filters, etc.)
    case stepInto
    
    /// Step out of current scope
    case stepOut
    
    /// Run until next breakpoint
    case runToBreakpoint
}

/// Protocol for handling debug output
public protocol DebugOutputHandler: Sendable {
    /// Called when debug information should be output
    func handleDebugOutput(_ output: DebugOutput)
    
    /// Called when a breakpoint is hit
    func handleBreakpoint(_ breakpoint: DebugBreakpoint, context: DebugContext) async -> DebugAction
    
    /// Called when an error occurs during debugging
    func handleDebugError(_ error: Error, context: DebugContext)
}

/// Debug output types
public enum DebugOutput: Sendable {
    case trace(DebugTraceEntry)
    case variableAccess(DebugVariableAccess)
    case profiling(DebugProfilingData)
    case message(String, level: DebugLevel)
    case expressionEvaluation(DebugExpressionEvaluation)
    case filterExecution(DebugFilterExecution)
}

/// Debug message levels
public enum DebugLevel: Sendable {
    case verbose
    case info
    case warning
    case error
}

/// Actions that can be taken at a breakpoint
public enum DebugAction: Sendable, Equatable {
    case `continue`
    case stepOver
    case stepInto
    case stepOut
    case abort
    case evaluate(String) // Evaluate expression in current context
}