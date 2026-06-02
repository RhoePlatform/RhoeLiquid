//
//  DebugTypes.swift
//  LiquidCore
//
//  Core types for template debugging
//

import Foundation

// MARK: - Sendable Wrapper for Any Values

/// Wrapper to make Any values Sendable for debugging
// SAFETY: Immutable Any wrapper; values are only used for display/logging
public struct SendableAnyValue: @unchecked Sendable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
}

// MARK: - Debug Breakpoint

/// Represents a debugging breakpoint
public struct DebugBreakpoint: Hashable, Sendable {
    /// Unique identifier
    public let id: UUID
    
    /// Source location for the breakpoint
    public let location: LiquidSourceLocation
    
    /// Optional condition that must be true for breakpoint to trigger
    public let condition: String?
    
    /// Whether this breakpoint is enabled
    public let enabled: Bool
    
    /// Hit count - how many times this breakpoint has been hit
    public private(set) var hitCount: Int
    
    /// Optional hit count condition (break after N hits)
    public let hitCountCondition: Int?
    
    public init(
        location: LiquidSourceLocation,
        condition: String? = nil,
        enabled: Bool = true,
        hitCountCondition: Int? = nil
    ) {
        self.id = UUID()
        self.location = location
        self.condition = condition
        self.enabled = enabled
        self.hitCount = 0
        self.hitCountCondition = hitCountCondition
    }
    
    /// Checks if this breakpoint matches the given location
    public func matches(location: LiquidSourceLocation) -> Bool {
        guard enabled else { return false }
        
        // Check location match
        if self.location.templateName != location.templateName {
            return false
        }
        
        if self.location.line != location.line {
            return false
        }
        
        // Check hit count condition
        if let hitCondition = hitCountCondition {
            return hitCount >= hitCondition
        }
        
        return true
    }
    
    /// Records a hit on this breakpoint
    public mutating func recordHit() {
        hitCount += 1
    }
    
    // Hashable conformance
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: DebugBreakpoint, rhs: DebugBreakpoint) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Debug Trace Entry

/// Represents an entry in the execution trace
public struct DebugTraceEntry: Sendable {
    /// Timestamp when this entry was created
    public let timestamp: Date
    
    /// Source location where this entry was created
    public let location: LiquidSourceLocation
    
    /// Type of AST node being executed
    public let nodeType: String
    
    /// Description of the operation
    public let operation: String
    
    /// Execution duration (if available)
    public let duration: TimeInterval?
    
    /// Input values (variables, parameters, etc.)
    public let inputs: [String: SendableAnyValue]
    
    /// Output value (if any)
    public let output: SendableAnyValue?
    
    /// Call stack depth
    public let stackDepth: Int
    
    /// Any additional context information
    public let context: [String: SendableAnyValue]
    
    public init(
        location: LiquidSourceLocation,
        nodeType: String,
        operation: String,
        duration: TimeInterval? = nil,
        inputs: [String: SendableAnyValue] = [:],
        output: SendableAnyValue? = nil,
        stackDepth: Int = 0,
        context: [String: SendableAnyValue] = [:]
    ) {
        self.timestamp = Date()
        self.location = location
        self.nodeType = nodeType
        self.operation = operation
        self.duration = duration
        self.inputs = inputs
        self.output = output
        self.stackDepth = stackDepth
        self.context = context
    }
}

// MARK: - Debug Frame

/// Represents a frame in the debug call stack
public struct DebugFrame: Sendable {
    /// Frame identifier
    public let id: UUID
    
    /// Template name
    public let templateName: String?
    
    /// Function/tag name
    public let functionName: String
    
    /// Source location
    public let location: LiquidSourceLocation
    
    /// Local variables in this frame
    public let locals: [String: SendableAnyValue]
    
    /// Frame type
    public let frameType: DebugFrameType
    
    /// Timestamp when frame was created
    public let timestamp: Date
    
    public init(
        templateName: String?,
        functionName: String,
        location: LiquidSourceLocation,
        locals: [String: SendableAnyValue] = [:],
        frameType: DebugFrameType = .template
    ) {
        self.id = UUID()
        self.templateName = templateName
        self.functionName = functionName
        self.location = location
        self.locals = locals
        self.frameType = frameType
        self.timestamp = Date()
    }
}

/// Types of debug frames
public enum DebugFrameType: Sendable {
    case template     // Main template execution
    case include      // Include/render operation
    case filter       // Filter execution
    case tag          // Custom tag execution
    case block        // Block execution (if, for, etc.)
    case expression   // Expression evaluation
}

// MARK: - Debug Variable Access

/// Represents a variable access operation
public struct DebugVariableAccess: Sendable {
    /// Timestamp of access
    public let timestamp: Date
    
    /// Variable name
    public let variableName: String
    
    /// Access type
    public let accessType: DebugVariableAccessType
    
    /// Variable value (before and after for modifications)
    public let value: SendableAnyValue?
    public let previousValue: SendableAnyValue?
    
    /// Source location where access occurred
    public let location: LiquidSourceLocation
    
    /// Call stack depth
    public let stackDepth: Int
    
    public init(
        variableName: String,
        accessType: DebugVariableAccessType,
        value: SendableAnyValue?,
        previousValue: SendableAnyValue? = nil,
        location: LiquidSourceLocation,
        stackDepth: Int = 0
    ) {
        self.timestamp = Date()
        self.variableName = variableName
        self.accessType = accessType
        self.value = value
        self.previousValue = previousValue
        self.location = location
        self.stackDepth = stackDepth
    }
}

/// Types of variable access
public enum DebugVariableAccessType: Sendable {
    case read
    case write
    case delete
    case create
}

// MARK: - Debug Variable Inspector

/// Provides variable inspection capabilities
public struct DebugVariableInspector: Sendable {
    /// Maximum inspection depth
    public let maxDepth: Int
    
    public init(maxDepth: Int = 10) {
        self.maxDepth = maxDepth
    }
    
    /// Inspects a variable and returns structured information
    public func inspect(_ value: Any, depth: Int = 0) -> DebugVariableInfo {
        guard depth < maxDepth else {
            return DebugVariableInfo(
                type: "...",
                value: "<max depth reached>",
                properties: [:],
                count: nil
            )
        }
        
        let type = String(describing: type(of: value))
        
        switch value {
        case let string as String:
            return DebugVariableInfo(
                type: "String",
                value: "\"\(string)\"",
                properties: ["length": DebugVariableInfo(type: "Int", value: "\(string.count)")],
                count: string.count
            )
            
        case let number as NSNumber:
            return DebugVariableInfo(
                type: "Number",
                value: "\(number)",
                properties: [:],
                count: nil
            )
            
        case let array as [Any]:
            var elements: [String: DebugVariableInfo] = [:]
            for (index, element) in array.enumerated() {
                if index < 20 { // Limit array inspection
                    elements["[\(index)]"] = inspect(element, depth: depth + 1)
                }
            }
            
            return DebugVariableInfo(
                type: "Array",
                value: "[\(array.count) elements]",
                properties: elements,
                count: array.count
            )
            
        case let dict as [String: Any]:
            var properties: [String: DebugVariableInfo] = [:]
            for (key, value) in dict {
                if properties.count < 20 { // Limit dict inspection
                    properties[key] = inspect(value, depth: depth + 1)
                }
            }
            
            return DebugVariableInfo(
                type: "Dictionary",
                value: "{\(dict.count) properties}",
                properties: properties,
                count: dict.count
            )
            
        case let bool as Bool:
            return DebugVariableInfo(
                type: "Boolean",
                value: bool ? "true" : "false",
                properties: [:],
                count: nil
            )
            
        case is NSNull:
            return DebugVariableInfo(
                type: "Null",
                value: "null",
                properties: [:],
                count: nil
            )
            
        default:
            return DebugVariableInfo(
                type: type,
                value: "\(value)",
                properties: [:],
                count: nil
            )
        }
    }
}

/// Information about a variable for debugging
public struct DebugVariableInfo: Sendable {
    /// Variable type
    public let type: String
    
    /// String representation of value
    public let value: String
    
    /// Properties/children of this variable
    public let properties: [String: DebugVariableInfo]
    
    /// Count (for collections)
    public let count: Int?
    
    public init(
        type: String,
        value: String,
        properties: [String: DebugVariableInfo] = [:],
        count: Int? = nil
    ) {
        self.type = type
        self.value = value
        self.properties = properties
        self.count = count
    }
}

// MARK: - Debug Profiling Data

/// Profiling information for performance analysis
public struct DebugProfilingData: Sendable {
    /// Operation that was profiled
    public let operation: String
    
    /// Duration of the operation
    public let duration: TimeInterval
    
    /// Source location
    public let location: LiquidSourceLocation
    
    /// Memory usage (if available)
    public let memoryUsage: Int?
    
    /// Additional metrics
    public let metrics: [String: Double]
    
    public init(
        operation: String,
        duration: TimeInterval,
        location: LiquidSourceLocation,
        memoryUsage: Int? = nil,
        metrics: [String: Double] = [:]
    ) {
        self.operation = operation
        self.duration = duration
        self.location = location
        self.memoryUsage = memoryUsage
        self.metrics = metrics
    }
}

// MARK: - Expression Evaluation Debug

/// Debug information for expression evaluation
public struct DebugExpressionEvaluation: Sendable {
    /// Expression type (literal, variable, binary, etc.)
    public let expressionType: String
    
    /// String representation of the expression
    public let expression: String
    
    /// Input values/operands
    public let inputs: [String: SendableAnyValue]
    
    /// Result value
    public let result: SendableAnyValue?
    
    /// Source location
    public let location: LiquidSourceLocation
    
    /// Evaluation duration
    public let duration: TimeInterval
    
    /// Stack depth at evaluation
    public let stackDepth: Int
    
    /// Error if evaluation failed
    public let error: String?
    
    public init(
        expressionType: String,
        expression: String,
        inputs: [String: SendableAnyValue] = [:],
        result: SendableAnyValue? = nil,
        location: LiquidSourceLocation,
        duration: TimeInterval = 0,
        stackDepth: Int = 0,
        error: String? = nil
    ) {
        self.expressionType = expressionType
        self.expression = expression
        self.inputs = inputs
        self.result = result
        self.location = location
        self.duration = duration
        self.stackDepth = stackDepth
        self.error = error
    }
}

// MARK: - Filter Execution Debug

/// Debug information for filter execution
public struct DebugFilterExecution: Sendable {
    /// Filter name
    public let filterName: String
    
    /// Input value before filter application
    public let inputValue: SendableAnyValue
    
    /// Filter arguments
    public let arguments: [SendableAnyValue]
    
    /// Result value after filter application
    public let resultValue: SendableAnyValue?
    
    /// Source location where filter was applied
    public let location: LiquidSourceLocation
    
    /// Filter execution duration
    public let duration: TimeInterval
    
    /// Stack depth at execution
    public let stackDepth: Int
    
    /// Error if filter execution failed
    public let error: String?
    
    /// Whether this filter is chained with others
    public let isChained: Bool
    
    /// Position in filter chain (0-based)
    public let chainPosition: Int
    
    public init(
        filterName: String,
        inputValue: SendableAnyValue,
        arguments: [SendableAnyValue] = [],
        resultValue: SendableAnyValue? = nil,
        location: LiquidSourceLocation,
        duration: TimeInterval = 0,
        stackDepth: Int = 0,
        error: String? = nil,
        isChained: Bool = false,
        chainPosition: Int = 0
    ) {
        self.filterName = filterName
        self.inputValue = inputValue
        self.arguments = arguments
        self.resultValue = resultValue
        self.location = location
        self.duration = duration
        self.stackDepth = stackDepth
        self.error = error
        self.isChained = isChained
        self.chainPosition = chainPosition
    }
}