//
//  ErrorPropagation.swift
//  LiquidCore
//
//  Comprehensive error propagation and logging system
//  Ensures proper error handling throughout the engine
//

import Foundation

// MARK: - Error Propagation Framework

/// Comprehensive error propagation and recovery system
public actor ErrorPropagationManager {
    private var errorHistory: [ErrorRecord] = []
    private var errorHandlers: [ErrorType: ErrorHandlerProtocol] = [:]
    private let maxHistorySize: Int = 1000
    
    public init() {}
    
    /// Record an error with full context
    public func recordError(
        _ error: Error,
        context: EnhancedErrorContext,
        severity: ErrorSeverity = .error,
        recoveryStrategy: RecoveryStrategy = .propagate
    ) -> ErrorResult {
        let record = ErrorRecord(
            timestamp: Date(),
            error: error,
            context: context,
            severity: severity,
            recoveryStrategy: recoveryStrategy
        )
        
        // Add to history
        errorHistory.append(record)
        
        // Keep history size manageable
        if errorHistory.count > maxHistorySize {
            errorHistory.removeFirst(errorHistory.count - maxHistorySize)
        }
        
        // Get error type for handler lookup
        let errorType = ErrorType.from(error)
        
        // Apply error handler if available
        if let handler = errorHandlers[errorType] {
            return handler.handle(record)
        }
        
        // Default handling based on severity
        return handleDefault(record)
    }
    
    /// Register error handler for specific error types
    public func registerHandler(_ handler: ErrorHandlerProtocol, for type: ErrorType) {
        errorHandlers[type] = handler
    }
    
    /// Get recent error history
    public func getErrorHistory(limit: Int = 100) -> [ErrorRecord] {
        return Array(errorHistory.suffix(limit))
    }
    
    /// Get error statistics
    public func getErrorStatistics() -> ErrorStatistics {
        let now = Date()
        let oneHour = now.addingTimeInterval(-3600)
        let recentErrors = errorHistory.filter { $0.timestamp > oneHour }
        
        var severityCounts: [ErrorSeverity: Int] = [:]
        var typeCounts: [ErrorType: Int] = [:]
        
        for record in recentErrors {
            severityCounts[record.severity, default: 0] += 1
            let type = ErrorType.from(record.error)
            typeCounts[type, default: 0] += 1
        }
        
        return ErrorStatistics(
            totalErrors: errorHistory.count,
            recentErrors: recentErrors.count,
            severityCounts: severityCounts,
            typeCounts: typeCounts,
            timeRange: oneHour...now
        )
    }
    
    /// Clear error history (for testing/reset)
    public func clearHistory() {
        errorHistory.removeAll()
    }
    
    // MARK: - Default Error Handling
    
    private func handleDefault(_ record: ErrorRecord) -> ErrorResult {
        switch record.severity {
        case .debug:
            return .logged(record)
            
        case .info:
            return .logged(record)
            
        case .warning:
            logWarning(record)
            return .recovered(record, fallbackValue: nil)
            
        case .error:
            logError(record)
            return .propagated(record)
            
        case .critical:
            logCritical(record)
            return .propagated(record)
            
        case .fatal:
            logFatal(record)
            return .propagated(record)
        }
    }
    
    // MARK: - Logging Methods
    
    private func logWarning(_ record: ErrorRecord) {
        print("⚠️ WARNING [\(record.context.component ?? "unknown")]: \(record.error.localizedDescription)")
        if let details = record.context.metadata {
            print("   Context: \(details)")
        }
    }
    
    private func logError(_ record: ErrorRecord) {
        print("❌ ERROR [\(record.context.component ?? "unknown")]: \(record.error.localizedDescription)")
        print("   Location: \(record.context.sourceLocation?.description ?? "unknown")")
        if let details = record.context.metadata {
            print("   Context: \(details)")
        }
    }
    
    private func logCritical(_ record: ErrorRecord) {
        print("🔥 CRITICAL [\(record.context.component ?? "unknown")]: \(record.error.localizedDescription)")
        print("   Location: \(record.context.sourceLocation?.description ?? "unknown")")
        print("   Call Stack: \(record.context.callStack)")
        if let details = record.context.metadata {
            print("   Context: \(details)")
        }
    }
    
    private func logFatal(_ record: ErrorRecord) {
        print("💥 FATAL [\(record.context.component ?? "unknown")]: \(record.error.localizedDescription)")
        print("   This is a fatal error that may cause system instability")
        print("   Location: \(record.context.sourceLocation?.description ?? "unknown")")
        print("   Call Stack: \(record.context.callStack)")
        if let details = record.context.metadata {
            print("   Context: \(details)")
        }
    }
}

// MARK: - Supporting Types

/// Error record with full context
public struct ErrorRecord: Sendable {
    public let timestamp: Date
    public let error: Error
    public let context: EnhancedErrorContext
    public let severity: ErrorSeverity
    public let recoveryStrategy: RecoveryStrategy
    
    public var id: UUID = UUID()
}

/// Enhanced error context with more detailed information
public struct EnhancedErrorContext: Sendable {
    public let component: String?
    public let operation: String?
    public let sourceLocation: LiquidSourceLocation?
    public let templateName: String?
    public let callStack: [String]
    public let metadata: [String: String]?
    public let userContext: [String: String]?
    
    public init(
        component: String? = nil,
        operation: String? = nil,
        sourceLocation: LiquidSourceLocation? = nil,
        templateName: String? = nil,
        callStack: [String] = [],
        metadata: [String: String]? = nil,
        userContext: [String: String]? = nil
    ) {
        self.component = component
        self.operation = operation
        self.sourceLocation = sourceLocation
        self.templateName = templateName
        #if !os(WASI)
        self.callStack = callStack.isEmpty ? Thread.callStackSymbols : callStack
        #else
        self.callStack = callStack
        #endif
        self.metadata = metadata
        self.userContext = userContext
    }
}

/// Error severity levels
public enum ErrorSeverity: String, CaseIterable, Sendable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case critical = "CRITICAL"
    case fatal = "FATAL"
    
    public var numericValue: Int {
        switch self {
        case .debug: return 0
        case .info: return 1
        case .warning: return 2
        case .error: return 3
        case .critical: return 4
        case .fatal: return 5
        }
    }
}

/// Recovery strategies for different error types
public enum RecoveryStrategy: Sendable {
    case propagate                          // Re-throw the error
    case recover(fallbackValue: String?)   // Use fallback value
    case retry(maxAttempts: Int)           // Retry operation
    case skipAndContinue                   // Skip current operation
    case gracefulDegradation               // Reduce functionality
    case circuitBreaker                    // Prevent further operations
}

/// Error handling result
public enum ErrorResult: Sendable {
    case logged(ErrorRecord)
    case recovered(ErrorRecord, fallbackValue: String?)
    case propagated(ErrorRecord)
    case retrying(ErrorRecord, attempt: Int)
}

/// Error type classification
public enum ErrorType: Hashable, Sendable {
    case liquid(LiquidErrorCategory)
    case system(SystemErrorType)
    case network(NetworkErrorType)
    case security(SecurityErrorType)
    case performance(PerformanceErrorType)
    case unknown
    
    public static func from(_ error: Error) -> ErrorType {
        switch error {
        case let liquidError as LiquidError:
            return .liquid(liquidError.category)
        case is DecodingError, is EncodingError:
            return .system(.serialization)
        case let nsError as NSError where nsError.domain == NSURLErrorDomain:
            return .network(.urlError)
        case let error where error.localizedDescription.contains("security"):
            return .security(.validation)
        default:
            return .unknown
        }
    }
}

public enum SystemErrorType: Sendable {
    case fileSystem
    case memory
    case serialization
    case concurrency
}

public enum NetworkErrorType: Sendable {
    case urlError
    case timeout
    case connectionFailed
    case invalidResponse
}

public enum SecurityErrorType: Sendable {
    case validation
    case unauthorized
    case injection
    case resourceExhaustion
}

public enum PerformanceErrorType: Sendable {
    case timeout
    case memoryPressure
    case cpuExhaustion
    case rateLimited
}

/// Error handler protocol
public protocol ErrorHandlerProtocol: Sendable {
    func handle(_ record: ErrorRecord) -> ErrorResult
}

/// Error statistics
public struct ErrorStatistics: Sendable {
    public let totalErrors: Int
    public let recentErrors: Int
    public let severityCounts: [ErrorSeverity: Int]
    public let typeCounts: [ErrorType: Int]
    public let timeRange: ClosedRange<Date>
    
    public var criticalErrorRate: Double {
        let criticalCount = severityCounts[.critical, default: 0] + severityCounts[.fatal, default: 0]
        return recentErrors > 0 ? Double(criticalCount) / Double(recentErrors) : 0.0
    }
    
    public var errorRate: Double {
        let errorCount = severityCounts[.error, default: 0]
        return recentErrors > 0 ? Double(errorCount) / Double(recentErrors) : 0.0
    }
}

// MARK: - Enhanced Liquid Error


// MARK: - Global Error Manager

/// Global error propagation manager instance
public let globalErrorManager = ErrorPropagationManager()

