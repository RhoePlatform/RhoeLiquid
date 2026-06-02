//
//  DebugContext.swift
//  LiquidCore
//
//  Core debugging context for template execution
//

import Foundation

/// Main debugging context that tracks execution state
public actor DebugContext {
    /// Debug configuration
    nonisolated public let configuration: DebugConfiguration
    
    /// Current execution state
    private var executionState: DebugExecutionState = .running
    
    /// Active breakpoints
    private var breakpoints: Set<DebugBreakpoint> = []
    
    /// Variable watches
    private var watches: Set<String> = []
    
    /// Execution trace entries
    private var traces: [DebugTraceEntry] = []
    
    /// Call stack
    private var callStack: [DebugFrame] = []
    
    /// Current execution statistics
    private var stats: DebugStatistics = DebugStatistics()
    
    /// Variable access history
    private var variableHistory: [DebugVariableAccess] = []
    
    /// Current template name
    private var currentTemplate: String?
    
    public init(configuration: DebugConfiguration = .disabled) {
        self.configuration = configuration
    }
    
    // MARK: - Execution Control
    
    /// Checks if execution should pause at current location
    public func shouldBreak(at location: LiquidSourceLocation, node: ASTNode) -> Bool {
        guard configuration.enabled else { return false }
        
        // Check for breakpoints
        if hasBreakpoint(at: location) {
            return true
        }
        
        // Check step mode
        switch configuration.stepMode {
        case .run, .runToBreakpoint:
            return false
        case .stepOver:
            return callStack.count <= getCurrentStepDepth()
        case .stepInto:
            return true
        case .stepOut:
            return callStack.count < getCurrentStepDepth()
        }
    }
    
    /// Sets execution state
    public func setExecutionState(_ state: DebugExecutionState) {
        executionState = state
    }
    
    /// Gets current execution state
    public func getExecutionState() -> DebugExecutionState {
        return executionState
    }
    
    // MARK: - Breakpoints
    
    /// Adds a breakpoint
    public func addBreakpoint(_ breakpoint: DebugBreakpoint) {
        breakpoints.insert(breakpoint)
    }
    
    /// Removes a breakpoint
    public func removeBreakpoint(_ breakpoint: DebugBreakpoint) {
        breakpoints.remove(breakpoint)
    }
    
    /// Checks if there's a breakpoint at location
    public func hasBreakpoint(at location: LiquidSourceLocation) -> Bool {
        return breakpoints.contains { breakpoint in
            breakpoint.matches(location: location)
        }
    }
    
    /// Gets all breakpoints
    public func getBreakpoints() -> Set<DebugBreakpoint> {
        return breakpoints
    }
    
    // MARK: - Variable Watching
    
    /// Adds a variable to watch list
    public func addWatch(_ variableName: String) {
        watches.insert(variableName)
    }
    
    /// Removes a variable from watch list
    public func removeWatch(_ variableName: String) {
        watches.remove(variableName)
    }
    
    /// Checks if variable is being watched
    public func isWatched(_ variableName: String) -> Bool {
        return watches.contains(variableName)
    }
    
    /// Records variable access
    public func recordVariableAccess(_ access: DebugVariableAccess) {
        guard configuration.trackVariables else { return }
        
        variableHistory.append(access)
        
        // Trim history if needed
        if variableHistory.count > configuration.maxTraceEntries {
            variableHistory.removeFirst(variableHistory.count - configuration.maxTraceEntries)
        }
        
        // Send to output handler if watched
        if isWatched(access.variableName) {
            configuration.outputHandler?.handleDebugOutput(.variableAccess(access))
        }
    }
    
    /// Records expression evaluation
    public func recordExpressionEvaluation(_ evaluation: DebugExpressionEvaluation) {
        guard configuration.collectTraces else { return }
        
        // Store in expression history if we add that later
        // For now, send directly to output handler
        configuration.outputHandler?.handleDebugOutput(.expressionEvaluation(evaluation))
    }
    
    /// Records filter execution
    public func recordFilterExecution(_ execution: DebugFilterExecution) {
        guard configuration.collectTraces else { return }
        
        // Store in filter history if we add that later
        // For now, send directly to output handler
        configuration.outputHandler?.handleDebugOutput(.filterExecution(execution))
    }
    
    // MARK: - Execution Tracing
    
    /// Records trace entry
    public func recordTrace(_ entry: DebugTraceEntry) {
        guard configuration.collectTraces else { return }
        
        traces.append(entry)
        
        // Trim traces if needed
        if traces.count > configuration.maxTraceEntries {
            traces.removeFirst(traces.count - configuration.maxTraceEntries)
        }
        
        configuration.outputHandler?.handleDebugOutput(.trace(entry))
    }
    
    /// Gets execution traces
    public func getTraces() -> [DebugTraceEntry] {
        return traces
    }
    
    // MARK: - Call Stack Management
    
    /// Pushes frame onto call stack
    public func pushFrame(_ frame: DebugFrame) {
        callStack.append(frame)
    }
    
    /// Pops frame from call stack
    public func popFrame() -> DebugFrame? {
        return callStack.popLast()
    }
    
    /// Gets current call stack
    public func getCallStack() -> [DebugFrame] {
        return callStack
    }
    
    /// Gets current frame
    public func getCurrentFrame() -> DebugFrame? {
        return callStack.last
    }
    
    // MARK: - Statistics
    
    /// Records node execution
    public func recordNodeExecution(_ node: ASTNode, duration: TimeInterval) {
        guard configuration.profileExecution else { return }
        
        stats.totalNodes += 1
        stats.totalExecutionTime += duration
        
        // Track per-node-type statistics
        let nodeType = String(describing: type(of: node))
        stats.nodeTypeCounts[nodeType, default: 0] += 1
        stats.nodeTypeTime[nodeType, default: 0] += duration
    }
    
    /// Gets execution statistics
    public func getStatistics() -> DebugStatistics {
        return stats
    }
    
    // MARK: - Template Context
    
    /// Sets current template name
    public func setCurrentTemplate(_ name: String?) {
        currentTemplate = name
    }
    
    /// Gets current template name
    public func getCurrentTemplate() -> String? {
        return currentTemplate
    }
    
    // MARK: - Private Helpers
    
    private func getCurrentStepDepth() -> Int {
        // Implementation for step depth tracking
        return callStack.count
    }
}

/// Debug execution states
public enum DebugExecutionState: Sendable {
    case running
    case paused
    case stepping
    case error
    case completed
}

/// Debug statistics for profiling
public struct DebugStatistics: Sendable {
    public var totalNodes: Int = 0
    public var totalExecutionTime: TimeInterval = 0
    public var nodeTypeCounts: [String: Int] = [:]
    public var nodeTypeTime: [String: TimeInterval] = [:]
    
    public var averageNodeTime: TimeInterval {
        return totalNodes > 0 ? totalExecutionTime / Double(totalNodes) : 0
    }
    
    public var nodesPerSecond: Double {
        return totalExecutionTime > 0 ? Double(totalNodes) / totalExecutionTime : 0
    }
}