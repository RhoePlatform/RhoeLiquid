//
//  RenderError.swift
//  LiquidCore
//
//  Created as part of RhoeLiquid
//  A high-performance Swift 6.3 implementation of the Liquid template language
//

import Foundation

/// Errors that can occur during the rendering phase (template execution)
///
/// These errors represent runtime problems during template execution, such as
/// undefined variables, missing filters, type mismatches, or resource limitations.
public enum RenderError: LiquidError, Equatable {
    /// A variable was referenced but not defined in the context
    case undefinedVariable(String, sourceLocation: LiquidSourceLocation? = nil)
    
    /// A filter was referenced but not registered
    case undefinedFilter(String, sourceLocation: LiquidSourceLocation? = nil)
    
    /// A block was referenced but not defined
    case undefinedBlock(String, sourceLocation: LiquidSourceLocation? = nil)
    
    /// Type mismatch in comparison or operation
    case invalidComparison(left: String, right: String, sourceLocation: LiquidSourceLocation? = nil)
    
    /// Invalid for loop collection or parameters
    case invalidForLoop(reason: String, sourceLocation: LiquidSourceLocation? = nil)
    
    /// Invalid range expression bounds
    case invalidRange(start: String, end: String, sourceLocation: LiquidSourceLocation? = nil)
    
    /// Filter execution failed
    case filterError(String, underlying: String, sourceLocation: LiquidSourceLocation? = nil)
    
    /// Tag execution failed
    case tagError(String, underlying: String, sourceLocation: LiquidSourceLocation? = nil)
    
    /// Include or render operation failed
    case includeError(String, reason: String, sourceLocation: LiquidSourceLocation? = nil)
    
    /// Circular dependency in includes or blocks
    case circularDependency([String], sourceLocation: LiquidSourceLocation? = nil)
    
    /// Template file not found
    case templateNotFound(String, sourceLocation: LiquidSourceLocation? = nil)
    
    /// Access to restricted or dangerous operation
    case accessDenied(String, sourceLocation: LiquidSourceLocation? = nil)
    
    /// Resource limit exceeded (memory, time, recursion depth)
    case resourceLimitExceeded(resource: String, limit: Int, sourceLocation: LiquidSourceLocation? = nil)
    
    /// Type error - wrong type for operation
    case typeError(expected: String, actual: String, operation: String, sourceLocation: LiquidSourceLocation? = nil)
    
    /// Division by zero or similar math error
    case arithmeticError(String, sourceLocation: LiquidSourceLocation? = nil)
    
    /// Custom error from user code
    case custom(String, sourceLocation: LiquidSourceLocation? = nil)
    
    /// Debugging session was aborted by user
    case debugAborted(sourceLocation: LiquidSourceLocation? = nil)
}

// MARK: - LiquidError Implementation

extension RenderError {
    public var category: LiquidErrorCategory {
        return .rendering
    }
    
    public var sourceLocation: LiquidSourceLocation? {
        switch self {
        case .undefinedVariable(_, let location),
             .undefinedFilter(_, let location),
             .undefinedBlock(_, let location),
             .invalidComparison(_, _, let location),
             .invalidForLoop(_, let location),
             .invalidRange(_, _, let location),
             .filterError(_, _, let location),
             .tagError(_, _, let location),
             .includeError(_, _, let location),
             .circularDependency(_, let location),
             .templateNotFound(_, let location),
             .accessDenied(_, let location),
             .resourceLimitExceeded(_, _, let location),
             .typeError(_, _, _, let location),
             .arithmeticError(_, let location),
             .custom(_, let location),
             .debugAborted(let location):
            return location
        }
    }
    
    public func withContext(_ context: ErrorContext) -> RenderError {
        switch self {
        case .undefinedVariable(let name, _):
            return .undefinedVariable(name, sourceLocation: context.sourceLocation)
        case .undefinedFilter(let name, _):
            return .undefinedFilter(name, sourceLocation: context.sourceLocation)
        case .undefinedBlock(let name, _):
            return .undefinedBlock(name, sourceLocation: context.sourceLocation)
        case .invalidComparison(let left, let right, _):
            return .invalidComparison(left: left, right: right, sourceLocation: context.sourceLocation)
        case .invalidForLoop(let reason, _):
            return .invalidForLoop(reason: reason, sourceLocation: context.sourceLocation)
        case .invalidRange(let start, let end, _):
            return .invalidRange(start: start, end: end, sourceLocation: context.sourceLocation)
        case .filterError(let name, let underlying, _):
            return .filterError(name, underlying: underlying, sourceLocation: context.sourceLocation)
        case .tagError(let name, let underlying, _):
            return .tagError(name, underlying: underlying, sourceLocation: context.sourceLocation)
        case .includeError(let name, let reason, _):
            return .includeError(name, reason: reason, sourceLocation: context.sourceLocation)
        case .circularDependency(let chain, _):
            return .circularDependency(chain, sourceLocation: context.sourceLocation)
        case .templateNotFound(let name, _):
            return .templateNotFound(name, sourceLocation: context.sourceLocation)
        case .accessDenied(let operation, _):
            return .accessDenied(operation, sourceLocation: context.sourceLocation)
        case .resourceLimitExceeded(let resource, let limit, _):
            return .resourceLimitExceeded(resource: resource, limit: limit, sourceLocation: context.sourceLocation)
        case .typeError(let expected, let actual, let operation, _):
            return .typeError(expected: expected, actual: actual, operation: operation, sourceLocation: context.sourceLocation)
        case .arithmeticError(let message, _):
            return .arithmeticError(message, sourceLocation: context.sourceLocation)
        case .custom(let message, _):
            return .custom(message, sourceLocation: context.sourceLocation)
        case .debugAborted(_):
            return .debugAborted(sourceLocation: context.sourceLocation)
        }
    }
}

// MARK: - Error Messages

extension RenderError {
    /// Returns a human-readable description of the error
    public var message: String {
        switch self {
        case .undefinedVariable(let name, _):
            return "Undefined variable '\(name)'"
        case .undefinedFilter(let name, _):
            return "Undefined filter '\(name)'"
        case .undefinedBlock(let name, _):
            return "Undefined block '\(name)'"
        case .invalidComparison(let left, let right, _):
            return "Cannot compare \(left) with \(right)"
        case .invalidForLoop(let reason, _):
            return "Invalid for loop: \(reason)"
        case .invalidRange(let start, let end, _):
            return "Invalid range from \(start) to \(end)"
        case .filterError(let filter, let underlying, _):
            return "Filter '\(filter)' failed: \(underlying)"
        case .tagError(let tag, let underlying, _):
            return "Tag '\(tag)' failed: \(underlying)"
        case .includeError(let template, let reason, _):
            return "Include '\(template)' failed: \(reason)"
        case .circularDependency(let chain, _):
            return "Circular dependency: \(chain.joined(separator: " -> "))"
        case .templateNotFound(let name, _):
            return "Template not found: '\(name)'"
        case .accessDenied(let operation, _):
            return "Access denied: \(operation)"
        case .resourceLimitExceeded(let resource, let limit, _):
            return "Resource limit exceeded: \(resource) (limit: \(limit))"
        case .typeError(let expected, let actual, let operation, _):
            return "Type error in \(operation): expected \(expected), got \(actual)"
        case .arithmeticError(let reason, _):
            return "Arithmetic error: \(reason)"
        case .custom(let message, _):
            return message
        case .debugAborted(_):
            return "Debug session was aborted by user"
        }
    }
    
    /// Returns the error category for handling and recovery strategies
    public var renderErrorCategory: RenderErrorCategory {
        switch self {
        case .undefinedVariable, .undefinedFilter, .undefinedBlock, .templateNotFound:
            return .missing
        case .invalidComparison, .invalidForLoop, .invalidRange, .typeError:
            return .type
        case .filterError, .tagError:
            return .execution
        case .includeError, .circularDependency:
            return .template
        case .accessDenied:
            return .security
        case .resourceLimitExceeded:
            return .resource
        case .arithmeticError:
            return .arithmetic
        case .custom:
            return .custom
        case .debugAborted:
            return .execution
        }
    }
    
    /// Returns the severity level of the error
    public var severity: LiquidErrorSeverity {
        switch self {
        case .undefinedVariable:
            return .warning // Could be intentional in strict mode
        case .accessDenied, .circularDependency:
            return .error
        case .resourceLimitExceeded:
            return .error
        case .templateNotFound:
            return .error
        case .typeError, .arithmeticError:
            return .error
        default:
            return .error
        }
    }
}

// MARK: - Error Recovery and Suggestions

extension RenderError {
    /// Suggests how to fix this error
    public var suggestion: String? {
        switch self {
        case .undefinedVariable(let name, _):
            return "Define '\(name)' in the template context or use the 'default' filter"
        case .undefinedFilter(let name, _):
            return checkFilterNameSuggestion(for: name)
        case .undefinedBlock(let name, _):
            return "Define the block '\(name)' before trying to render it"
        case .invalidComparison:
            return "Ensure both values are of compatible types (both numbers, both strings, etc.)"
        case .invalidForLoop(let reason, _):
            return getForLoopSuggestion(for: reason)
        case .invalidRange:
            return "Use numeric values for range bounds and ensure start <= end"
        case .filterError(let filter, _, _):
            return "Check the arguments passed to filter '\(filter)'"
        case .tagError(let tag, _, _):
            return "Check the syntax and arguments for tag '\(tag)'"
        case .includeError(let template, _, _):
            return "Ensure template '\(template)' exists and is accessible"
        case .circularDependency(let chain, _):
            return "Break the circular dependency in: \(chain.joined(separator: " -> "))"
        case .templateNotFound(let name, _):
            return "Check the template path and ensure '\(name)' exists"
        case .accessDenied(let operation, _):
            return "This operation is restricted: \(operation)"
        case .resourceLimitExceeded(let resource, let limit, _):
            return "Optimize template to use less \(resource) (current limit: \(limit))"
        case .typeError(let expected, _, let operation, _):
            return "Provide a \(expected) value for \(operation)"
        case .arithmeticError:
            return "Check for division by zero or invalid numeric operations"
        case .custom:
            return nil
        case .debugAborted:
            return "Debugging was stopped. You can resume or restart the debug session."
        }
    }
    
    /// Checks for common filter name typos and suggests corrections
    private func checkFilterNameSuggestion(for filter: String) -> String? {
        let commonFilters = [
            "upcase", "downcase", "capitalize", "strip", "lstrip", "rstrip",
            "size", "first", "last", "join", "split", "append", "prepend",
            "plus", "minus", "times", "divided_by", "modulo", "round", "ceil", "floor",
            "abs", "default", "escape", "where", "map", "sort", "sort_by", "reverse",
            "uniq", "compact", "group_by", "find", "json", "date", "url_encode"
        ]
        
        // Find similar filter names
        let suggestions = commonFilters.filter { levenshteinDistance(filter, $0) <= 2 }
        
        if !suggestions.isEmpty {
            return "Did you mean: \(suggestions.joined(separator: ", "))?"
        } else {
            return "Register this filter or use a built-in filter"
        }
    }
    
    /// Provides suggestions for for loop errors
    private func getForLoopSuggestion(for reason: String) -> String? {
        if reason.contains("collection") {
            return "Ensure you're iterating over an array or range"
        } else if reason.contains("limit") {
            return "Use a positive number for the limit parameter"
        } else if reason.contains("offset") {
            return "Use a non-negative number for the offset parameter"
        } else {
            return "Check the for loop syntax and parameters"
        }
    }
    
    /// Returns the default value to use when this error occurs in lax mode
    public var defaultValue: String {
        switch renderErrorCategory {
        case .missing:
            return "" // Undefined variables render as empty
        case .type, .arithmetic:
            return "" // Type errors render as empty
        default:
            return "" // Most errors render as empty in lax mode
        }
    }
}

/// Categories of render errors for error handling strategies
public enum RenderErrorCategory: String, Sendable, CaseIterable {
    case missing = "Missing Resource"
    case type = "Type Error"
    case execution = "Execution Error"
    case template = "Template Error"
    case security = "Security Error"
    case resource = "Resource Error"
    case arithmetic = "Arithmetic Error"
    case custom = "Custom Error"
}


// MARK: - Utility Functions

/// Calculates the Levenshtein distance between two strings (copied from ParserError for independence)
private func levenshteinDistance(_ a: String, _ b: String) -> Int {
    let aChars = Array(a)
    let bChars = Array(b)
    let aCount = aChars.count
    let bCount = bChars.count
    
    if aCount == 0 { return bCount }
    if bCount == 0 { return aCount }
    
    var matrix = Array(repeating: Array(repeating: 0, count: bCount + 1), count: aCount + 1)
    
    for i in 0...aCount { matrix[i][0] = i }
    for j in 0...bCount { matrix[0][j] = j }
    
    for i in 1...aCount {
        for j in 1...bCount {
            let cost = aChars[i-1] == bChars[j-1] ? 0 : 1
            matrix[i][j] = min(
                matrix[i-1][j] + 1,     // deletion
                matrix[i][j-1] + 1,     // insertion
                matrix[i-1][j-1] + cost // substitution
            )
        }
    }
    
    return matrix[aCount][bCount]
}

// MARK: - CustomStringConvertible

extension RenderError: CustomStringConvertible {
    public var description: String {
        let suggestion = self.suggestion.map { " (\($0))" } ?? ""
        return "\(category.rawValue): \(message)\(suggestion)"
    }
}

extension RenderError: LocalizedError {
    public var errorDescription: String? {
        return description
    }
    
    public var recoverySuggestion: String? {
        return suggestion
    }
}