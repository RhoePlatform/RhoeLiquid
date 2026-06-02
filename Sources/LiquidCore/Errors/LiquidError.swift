//
//  LiquidError.swift
//  LiquidCore
//
//  Created as part of RhoeLiquid
//  A high-performance Swift 6.3 implementation of the Liquid template language
//

import Foundation

/// Common protocol for all Liquid-related errors
public protocol LiquidError: Error, Sendable, CustomStringConvertible {
    /// The error category for grouping related errors
    var category: LiquidErrorCategory { get }
    
    /// Human-readable error message
    var message: String { get }
    
    /// Location in the source template where the error occurred
    var sourceLocation: LiquidSourceLocation? { get }
    
    /// Optional suggestion for fixing the error
    var suggestion: String? { get }
    
    /// Error severity level
    var severity: LiquidErrorSeverity { get }
    
    /// Creates a new error with additional context
    func withContext(_ context: ErrorContext) -> Self
}

/// Categories of errors that can occur
public enum LiquidErrorCategory: String, Sendable, CaseIterable {
    case lexing = "Lexing"
    case parsing = "Parsing"
    case rendering = "Rendering"
    case semantic = "Semantic"
    case runtime = "Runtime"
    case template = "Template"
}

/// Severity levels for errors
public enum LiquidErrorSeverity: String, Sendable, CaseIterable {
    case error = "Error"
    case warning = "Warning"
    case info = "Info"
    
    /// Whether this severity should stop template processing
    public var shouldStop: Bool {
        switch self {
        case .error:
            return true
        case .warning, .info:
            return false
        }
    }
}

/// Additional context for error reporting
public struct ErrorContext: Sendable {
    /// The source location where the error occurred
    public let sourceLocation: LiquidSourceLocation
    
    /// Optional template name or identifier
    public let templateName: String?
    
    /// Call stack or processing context
    public let callStack: [String]
    
    /// Additional metadata
    public let metadata: [String: String]
    
    /// Creates a new error context
    /// - Parameters:
    ///   - sourceLocation: Location in source template
    ///   - templateName: Optional template identifier
    ///   - callStack: Processing context stack
    ///   - metadata: Additional error metadata
    public init(
        sourceLocation: LiquidSourceLocation,
        templateName: String? = nil,
        callStack: [String] = [],
        metadata: [String: String] = [:]
    ) {
        self.sourceLocation = sourceLocation
        self.templateName = templateName
        self.callStack = callStack
        self.metadata = metadata
    }
    
    /// Creates error context from a token
    /// - Parameter token: The token to extract location from
    public init(from token: Token) {
        self.sourceLocation = LiquidSourceLocation(from: token)
        self.templateName = nil
        self.callStack = []
        self.metadata = [:]
    }
}

// MARK: - Default Implementation

extension LiquidError {
    public var description: String {
        var result = "[\(category.rawValue)] \(message)"
        
        if let location = sourceLocation {
            result = "\(location): \(result)"
        }
        
        if let suggestion = suggestion {
            result += "\n  Suggestion: \(suggestion)"
        }
        
        return result
    }
    
    public var suggestion: String? {
        return nil
    }
    
    public var severity: LiquidErrorSeverity {
        return .error
    }
}

// MARK: - Error Collection

/// A collection of errors that can be reported together
public struct ErrorCollection: Error, Sendable {
    /// The individual errors in this collection
    public let errors: [any LiquidError]
    
    /// Creates a new error collection
    /// - Parameter errors: The errors to include
    public init(errors: [any LiquidError]) {
        self.errors = errors
    }
    
    /// Whether this collection contains any errors that should stop processing
    public var hasStoppingErrors: Bool {
        return errors.contains { $0.severity.shouldStop }
    }
    
    /// Errors grouped by category
    public var errorsByCategory: [LiquidErrorCategory: [any LiquidError]] {
        return Dictionary(grouping: errors) { $0.category }
    }
}

// MARK: - Error Handler

/// Utility for handling and reporting errors
public struct ErrorHandler {
    /// Handles an operation that might throw, wrapping errors with context
    /// - Parameters:
    ///   - operation: The operation to perform
    ///   - context: Additional error context
    /// - Returns: The result of the operation
    /// - Throws: Enhanced error with context
    public static func handle<T>(
        _ operation: () throws -> T,
        context: ErrorContext
    ) throws -> T {
        do {
            return try operation()
        } catch let error as LiquidError {
            throw error.withContext(context)
        } catch {
            // Wrap unknown errors
            throw UnknownError(
                underlyingError: error,
                sourceLocation: context.sourceLocation
            )
        }
    }
    
    /// Handles an async operation that might throw
    /// - Parameters:
    ///   - operation: The async operation to perform
    ///   - context: Additional error context
    /// - Returns: The result of the operation
    /// - Throws: Enhanced error with context
    public static func handleAsync<T>(
        _ operation: () async throws -> T,
        context: ErrorContext
    ) async throws -> T {
        do {
            return try await operation()
        } catch let error as LiquidError {
            throw error.withContext(context)
        } catch {
            // Wrap unknown errors
            throw UnknownError(
                underlyingError: error,
                sourceLocation: context.sourceLocation
            )
        }
    }
}

// MARK: - Unknown Error Wrapper

/// Wraps unknown errors with Liquid error context
public struct UnknownError: LiquidError {
    /// The underlying error that was wrapped
    public let underlyingError: Error
    
    /// Location where the error occurred
    public let sourceLocation: LiquidSourceLocation?
    
    /// Creates a new unknown error wrapper
    /// - Parameters:
    ///   - underlyingError: The original error
    ///   - sourceLocation: Location in template
    public init(underlyingError: Error, sourceLocation: LiquidSourceLocation? = nil) {
        self.underlyingError = underlyingError
        self.sourceLocation = sourceLocation
    }
    
    // MARK: - LiquidError Implementation
    
    public var category: LiquidErrorCategory {
        return .runtime
    }
    
    public var message: String {
        return "Unknown error: \(underlyingError.localizedDescription)"
    }
    
    public var suggestion: String? {
        return "This is an unexpected error. Please report it as a bug."
    }
    
    public func withContext(_ context: ErrorContext) -> UnknownError {
        return UnknownError(
            underlyingError: underlyingError,
            sourceLocation: context.sourceLocation
        )
    }
}