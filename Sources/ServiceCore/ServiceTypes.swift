/**
 * ServiceTypes.swift
 * 
 * Core types and models for RhoeLiquid Native Service
 * Defines data structures used across all service components
 */

import Foundation
import RhoeLiquid
import RhoeDOCX

// MARK: - Service Configuration

/// Comprehensive configuration for the RhoeLiquid Native Service.
///
/// `ServiceConfiguration` controls all aspects of service operation including
/// network settings, performance tuning, security policies, and logging.
///
/// ## Predefined Configurations
/// - `.production`: Default balanced settings for production use
/// - `.highPerformance`: Optimized for maximum throughput
/// - `.development`: Debug-friendly with verbose logging
///
/// ## Example
/// ```swift
/// // Custom configuration
/// let config = ServiceConfiguration(
///     httpPort: 8080,
///     maxConcurrentRequests: 200,
///     performanceMode: .performance,
///     logLevel: .warning
/// )
/// 
/// // Use predefined configuration
/// let service = ServiceManager(configuration: .production)
/// ```
///
/// - Note: Changes to configuration require service restart to take effect
public struct ServiceConfiguration: Sendable, Codable {
    /// HTTP server port (default: 13480)
    public let httpPort: Int
    
    /// Maximum concurrent requests
    public let maxConcurrentRequests: Int
    
    /// Request timeout in seconds
    public let requestTimeoutSeconds: Double
    
    /// Enable security middleware
    public let enableSecurity: Bool
    
    /// Rate limiting configuration
    public let rateLimits: RateLimitConfiguration

    /// Performance mode
    public let performanceMode: PerformanceMode

    /// Optional storage directory for durable service state.
    public let storageDirectory: URL?

    /// How long completed or terminal async jobs should be retained on disk.
    public let jobRetentionSeconds: Double

    /// Logging level
    public let logLevel: LogLevel

    public init(
        httpPort: Int = 13480,
        maxConcurrentRequests: Int = 100,
        requestTimeoutSeconds: Double = 30.0,
        enableSecurity: Bool = true,
        rateLimits: RateLimitConfiguration = RateLimitConfiguration(),
        performanceMode: PerformanceMode = .balanced,
        storageDirectory: URL? = nil,
        jobRetentionSeconds: Double = 24 * 60 * 60,
        logLevel: LogLevel = .info
    ) {
        self.httpPort = httpPort
        self.maxConcurrentRequests = maxConcurrentRequests
        self.requestTimeoutSeconds = requestTimeoutSeconds
        self.enableSecurity = enableSecurity
        self.rateLimits = rateLimits
        self.performanceMode = performanceMode
        self.storageDirectory = storageDirectory
        self.jobRetentionSeconds = jobRetentionSeconds
        self.logLevel = logLevel
    }
    
    /// Default production configuration
    public static let production = ServiceConfiguration()
    
    /// High-performance configuration
    public static let highPerformance = ServiceConfiguration(
        maxConcurrentRequests: 500,
        requestTimeoutSeconds: 10.0,
        performanceMode: .performance,
        logLevel: .warning
    )
    
    /// Development configuration with verbose logging
    public static let development = ServiceConfiguration(
        httpPort: 13481,
        enableSecurity: false,
        performanceMode: .development,
        logLevel: .debug
    )
}

// MARK: - Rate Limiting

/// Configuration for request rate limiting and resource protection.
///
/// Rate limiting prevents service overload and ensures fair resource allocation
/// across clients. Limits are enforced per client IP address.
///
/// ## Default Limits
/// - 1000 requests per minute per client
/// - 50 request burst allowance
/// - 10MB maximum template size
/// - 5MB maximum context data size
///
/// ## Example
/// ```swift
/// let rateLimits = RateLimitConfiguration(
///     requestsPerMinute: 500,
///     burstLimit: 25,
///     maxTemplateSizeBytes: 1_048_576  // 1MB
/// )
/// ```
///
/// - Important: Rate limits help prevent DoS attacks and resource exhaustion
public struct RateLimitConfiguration: Sendable, Codable {
    /// Requests per minute per client
    public let requestsPerMinute: Int
    
    /// Burst limit for short periods
    public let burstLimit: Int
    
    /// Maximum template size in bytes
    public let maxTemplateSizeBytes: Int
    
    /// Maximum context data size in bytes
    public let maxContextSizeBytes: Int
    
    public init(
        requestsPerMinute: Int = 1000,
        burstLimit: Int = 50,
        maxTemplateSizeBytes: Int = 10 * 1024 * 1024, // 10MB
        maxContextSizeBytes: Int = 5 * 1024 * 1024     // 5MB
    ) {
        self.requestsPerMinute = requestsPerMinute
        self.burstLimit = burstLimit
        self.maxTemplateSizeBytes = maxTemplateSizeBytes
        self.maxContextSizeBytes = maxContextSizeBytes
    }
}

// MARK: - Performance Configuration

/// Performance optimization mode for the service.
///
/// Each mode provides different trade-offs between speed, memory usage,
/// and feature availability. Choose based on your deployment environment
/// and workload characteristics.
///
/// ## Available Modes
/// - `.development`: Full debugging and monitoring features
/// - `.balanced`: Recommended for most production deployments
/// - `.performance`: Maximum speed, minimal overhead
/// - `.memory`: Optimized for low-memory environments
///
/// ## Mode Selection Guide
/// ```swift
/// // Development and testing
/// let config = ServiceConfiguration(performanceMode: .development)
/// 
/// // Production with mixed workloads
/// let config = ServiceConfiguration(performanceMode: .balanced)
/// 
/// // High-throughput API servers
/// let config = ServiceConfiguration(performanceMode: .performance)
/// 
/// // Resource-constrained environments
/// let config = ServiceConfiguration(performanceMode: .memory)
/// ```
public enum PerformanceMode: String, Sendable, Codable, CaseIterable {
    case development = "development"
    case balanced = "balanced"
    case performance = "performance"
    case memory = "memory"
    
    /// Get engine configuration for this performance mode
    public func engineConfiguration() -> LiquidConfiguration {
        switch self {
        case .development:
            return LiquidConfiguration.nativeService(
                resourceLimits: .moderate,
                caching: .basic,
                concurrency: .singleThreaded
            )
        case .balanced:
            return LiquidConfiguration.nativeService(
                resourceLimits: .generous,
                caching: .moderate,
                concurrency: .balanced
            )
        case .performance:
            return LiquidConfiguration.nativeService(
                resourceLimits: .unlimited,
                caching: .aggressive,
                concurrency: .systemOptimal
            )
        case .memory:
            return LiquidConfiguration.nativeService(
                resourceLimits: .conservative,
                caching: .minimal,
                concurrency: .singleThreaded
            )
        }
    }
    
    public var description: String {
        switch self {
        case .development:
            return "Development (Debug features enabled)"
        case .balanced:
            return "Balanced (Recommended)"
        case .performance:
            return "High Performance (Maximum speed)"
        case .memory:
            return "Memory Optimized (Low resource usage)"
        }
    }
}

// MARK: - Service Metrics

/// Real-time performance and health metrics for the service.
///
/// `ServiceMetrics` provides comprehensive insights into service operation,
/// helping with monitoring, debugging, and capacity planning.
///
/// ## Metrics Overview
/// - **Performance**: Render times, cache effectiveness
/// - **Resource Usage**: Memory, CPU utilization
/// - **Traffic**: Request counts, error rates
/// - **Availability**: Uptime, active connections
///
/// ## Usage Example
/// ```swift
/// let metrics = serviceManager.metrics
/// 
/// if metrics.errorRate > 0.05 {
///     print("High error rate: \(metrics.errorRate * 100)%")
/// }
/// 
/// if metrics.averageRenderTime > 0.1 {
///     print("Slow average render time: \(metrics.averageRenderTime)s")
/// }
/// ```
///
/// - Note: Metrics are updated every 5 seconds
/// - Tip: Use metrics for alerting and auto-scaling decisions
public struct ServiceMetrics: Sendable, Codable {
    /// Service uptime in seconds
    public let uptime: TimeInterval
    
    /// Total requests processed
    public let totalRequests: Int
    
    /// Requests processed today
    public let requestsToday: Int
    
    /// Average render time in seconds
    public let averageRenderTime: Double
    
    /// Current memory usage in bytes
    public let memoryUsage: Int
    
    /// CPU usage percentage
    public let cpuUsage: Double
    
    /// Cache hit rate (0.0 to 1.0)
    public let cacheHitRate: Double
    
    /// Active connections
    public let activeConnections: Int
    
    /// Error rate (0.0 to 1.0)
    public let errorRate: Double
    
    /// Queue depth
    public let queueDepth: Int
    
    public init(
        uptime: TimeInterval = 0,
        totalRequests: Int = 0,
        requestsToday: Int = 0,
        averageRenderTime: Double = 0,
        memoryUsage: Int = 0,
        cpuUsage: Double = 0,
        cacheHitRate: Double = 0,
        activeConnections: Int = 0,
        errorRate: Double = 0,
        queueDepth: Int = 0
    ) {
        self.uptime = uptime
        self.totalRequests = totalRequests
        self.requestsToday = requestsToday
        self.averageRenderTime = averageRenderTime
        self.memoryUsage = memoryUsage
        self.cpuUsage = cpuUsage
        self.cacheHitRate = cacheHitRate
        self.activeConnections = activeConnections
        self.errorRate = errorRate
        self.queueDepth = queueDepth
    }
}

// MARK: - Processing Activity

/// Record of a single template processing request.
///
/// Each `ProcessingActivity` captures detailed information about a template
/// render operation, useful for debugging, auditing, and performance analysis.
///
/// ## Tracked Information
/// - Timestamp and unique identifier
/// - Template identification (optional)
/// - Render performance metrics
/// - Success/failure status
/// - Client information
/// - Error details (if applicable)
///
/// ## Example
/// ```swift
/// let recentActivity = serviceManager.recentActivity
/// 
/// // Find slow renders
/// let slowRenders = recentActivity.filter { $0.renderTime > 0.1 }
/// 
/// // Check error rate
/// let errors = recentActivity.filter { $0.status == .error }
/// let errorRate = Double(errors.count) / Double(recentActivity.count)
/// ```
///
/// - Note: Service maintains last 100 activities in memory
public struct ProcessingActivity: Sendable, Codable, Identifiable {
    public let id: UUID
    public let timestamp: Date
    public let templateId: String?
    public let renderTime: TimeInterval
    public let status: ProcessingStatus
    public let clientIP: String?
    public let errorMessage: String?
    
    public init(
        id: UUID = UUID(),
        templateId: String? = nil,
        renderTime: TimeInterval,
        status: ProcessingStatus,
        clientIP: String? = nil,
        errorMessage: String? = nil
    ) {
        self.id = id
        self.timestamp = Date()
        self.templateId = templateId
        self.renderTime = renderTime
        self.status = status
        self.clientIP = clientIP
        self.errorMessage = errorMessage
    }
}

/// Status of a template processing operation.
///
/// Indicates the outcome of a template render request with
/// visual indicators for quick status recognition.
///
/// ## Status Types
/// - `.success`: Template rendered successfully
/// - `.warning`: Rendered with non-critical issues
/// - `.error`: Failed due to template or system error
/// - `.timeout`: Exceeded time limit
/// - `.rateLimited`: Rejected due to rate limiting
///
/// ## Example
/// ```swift
/// switch activity.status {
/// case .success:
///     print("✅ Rendered in \(activity.renderTime)s")
/// case .error:
///     print("❌ Failed: \(activity.errorMessage ?? "Unknown")")
/// case .rateLimited:
///     print("🚫 Rate limit exceeded")
/// default:
///     break
/// }
/// ```
public enum ProcessingStatus: String, Sendable, Codable, CaseIterable {
    case success = "success"
    case warning = "warning"
    case error = "error"
    case timeout = "timeout"
    case rateLimited = "rate_limited"
    
    public var emoji: String {
        switch self {
        case .success: return "✅"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .timeout: return "⏱️"
        case .rateLimited: return "🚫"
        }
    }
}

// MARK: - Service Status

/// Overall operational status of the RhoeLiquid Native Service.
///
/// Represents the service lifecycle state with visual indicators
/// for UI display and monitoring systems.
///
/// ## Status Lifecycle
/// ```
/// stopped → starting → active → stopping → stopped
///            ↓                      ↓
///          error                  error
/// ```
///
/// ## Example
/// ```swift
/// @Published var serviceManager: ServiceManager
/// 
/// var statusView: some View {
///     HStack {
///         Text(serviceManager.status.emoji)
///         Text(serviceManager.status.description)
///     }
///     .foregroundColor(statusColor(for: serviceManager.status))
/// }
/// ```
///
/// - Important: Only `.active` status indicates the service is ready for requests
public enum ServiceStatus: String, Sendable, Codable, CaseIterable {
    case starting = "starting"
    case active = "active"
    case stopping = "stopping"
    case stopped = "stopped"
    case error = "error"
    
    public var emoji: String {
        switch self {
        case .starting: return "🔄"
        case .active: return "🟢"
        case .stopping: return "🟡"
        case .stopped: return "🔴"
        case .error: return "❌"
        }
    }
    
    public var description: String {
        switch self {
        case .starting: return "Starting"
        case .active: return "Active"
        case .stopping: return "Stopping"
        case .stopped: return "Stopped"
        case .error: return "Error"
        }
    }
}

// MARK: - Log Level

/// Logging levels
public enum LogLevel: String, Sendable, Codable, CaseIterable {
    case trace = "trace"
    case debug = "debug"
    case info = "info"
    case notice = "notice"
    case warning = "warning"
    case error = "error"
    case critical = "critical"
}

// MARK: - Service Info

/// Complete service information for API responses.
///
/// Provides a comprehensive snapshot of service state, version information,
/// and current performance metrics. Used by the root API endpoint.
///
/// ## API Response Example
/// ```json
/// {
///   "service": "RhoeLiquid Native Service",
///   "version": "0.1.1",
///   "engine": "RhoeLiquid 0.1.1",
///   "status": "active",
///   "uptime": 3600,
///   "requestsProcessed": 1523,
///   "performance": {
///     "averageRenderTime": 0.005,
///     "cacheHitRate": 0.85,
///     "memoryUsage": 26214400,
///     "cpuUsage": 12.5
///   }
/// }
/// ```
///
/// - Note: All time values are in seconds, memory in bytes
public struct ServiceInfo: Sendable, Codable {
    public let service: String
    public let version: String
    public let engine: String
    public let status: ServiceStatus
    public let uptime: TimeInterval
    public let requestsProcessed: Int
    public let performance: PerformanceInfo
    
    public init(
        service: String = "RhoeLiquid Native Service",
        version: String = "0.1.1",
        engine: String = "RhoeLiquid 0.1.1",
        status: ServiceStatus,
        uptime: TimeInterval,
        requestsProcessed: Int,
        performance: PerformanceInfo
    ) {
        self.service = service
        self.version = version
        self.engine = engine
        self.status = status
        self.uptime = uptime
        self.requestsProcessed = requestsProcessed
        self.performance = performance
    }
}

/// Performance information
public struct PerformanceInfo: Sendable, Codable {
    public let averageRenderTime: Double
    public let cacheHitRate: Double
    public let memoryUsage: Int
    public let cpuUsage: Double
    
    public init(
        averageRenderTime: Double,
        cacheHitRate: Double,
        memoryUsage: Int,
        cpuUsage: Double
    ) {
        self.averageRenderTime = averageRenderTime
        self.cacheHitRate = cacheHitRate
        self.memoryUsage = memoryUsage
        self.cpuUsage = cpuUsage
    }
}

// MARK: - Wave 13 Capability Contracts

public struct ServiceCapabilities: Sendable, Codable, Equatable {
    public let serviceVersion: String
    public let engineVersion: String
    public let schemaVersion: String
    public let profile: CompatibilityProfile
    public let sandboxPolicy: SandboxPolicy
    public let supportedTags: [String]
    public let supportedFilters: [String]
    public let supportedJobKinds: [ServiceJobKind]
    public let preferredExecution: ServicePreferredExecution
    public let supportsMacros: Bool
    public let supportsInputContracts: Bool
    public let supportsExpressionCallMacros: Bool
    public let docx: DOCXServiceCapabilities
    public let supportsAnalysis: Bool
    public let supportsValidation: Bool
    public let supportsAsyncJobs: Bool

    public init(
        serviceVersion: String,
        engineVersion: String,
        schemaVersion: String,
        profile: CompatibilityProfile,
        sandboxPolicy: SandboxPolicy,
        supportedTags: [String],
        supportedFilters: [String],
        supportedJobKinds: [ServiceJobKind],
        preferredExecution: ServicePreferredExecution,
        supportsMacros: Bool,
        supportsInputContracts: Bool,
        supportsExpressionCallMacros: Bool,
        docx: DOCXServiceCapabilities,
        supportsAnalysis: Bool,
        supportsValidation: Bool,
        supportsAsyncJobs: Bool
    ) {
        self.serviceVersion = serviceVersion
        self.engineVersion = engineVersion
        self.schemaVersion = schemaVersion
        self.profile = profile
        self.sandboxPolicy = sandboxPolicy
        self.supportedTags = supportedTags
        self.supportedFilters = supportedFilters
        self.supportedJobKinds = supportedJobKinds
        self.preferredExecution = preferredExecution
        self.supportsMacros = supportsMacros
        self.supportsInputContracts = supportsInputContracts
        self.supportsExpressionCallMacros = supportsExpressionCallMacros
        self.docx = docx
        self.supportsAnalysis = supportsAnalysis
        self.supportsValidation = supportsValidation
        self.supportsAsyncJobs = supportsAsyncJobs
    }
}

public enum ServicePreferredExecution: String, Sendable, Codable, CaseIterable {
    case serviceAuthoritative = "service_authoritative"
    case wasmFallback = "wasm_fallback"
}

public struct DOCXCoverageSummary: Sendable, Codable, Equatable {
    public let trustedSubsetVersion: String
    public let structuredSupportedParts: [String]
    public let supportedPartCount: Int
    public let unsupportedPartCount: Int
    public let preservesUnsupportedParts: Bool
    public let unsupportedConstructBehavior: String

    public init(
        trustedSubsetVersion: String,
        structuredSupportedParts: [String],
        supportedPartCount: Int,
        unsupportedPartCount: Int,
        preservesUnsupportedParts: Bool,
        unsupportedConstructBehavior: String
    ) {
        self.trustedSubsetVersion = trustedSubsetVersion
        self.structuredSupportedParts = structuredSupportedParts
        self.supportedPartCount = supportedPartCount
        self.unsupportedPartCount = unsupportedPartCount
        self.preservesUnsupportedParts = preservesUnsupportedParts
        self.unsupportedConstructBehavior = unsupportedConstructBehavior
    }
}

public struct DOCXServiceCapabilities: Sendable, Codable, Equatable {
    public let supportedStructuredParts: [String]
    public let preservesMediaRelationships: Bool
    public let preservesNumberingAndStyles: Bool
    public let preservesUnsupportedParts: Bool
    public let coverageSummary: DOCXCoverageSummary
    public let notes: [String]

    public init(
        supportedStructuredParts: [String],
        preservesMediaRelationships: Bool,
        preservesNumberingAndStyles: Bool,
        preservesUnsupportedParts: Bool,
        coverageSummary: DOCXCoverageSummary,
        notes: [String]
    ) {
        self.supportedStructuredParts = supportedStructuredParts
        self.preservesMediaRelationships = preservesMediaRelationships
        self.preservesNumberingAndStyles = preservesNumberingAndStyles
        self.preservesUnsupportedParts = preservesUnsupportedParts
        self.coverageSummary = coverageSummary
        self.notes = notes
    }
}

public struct ServiceSchema: Sendable, Codable, Equatable {
    public let version: String
    public let endpoints: [ServiceSchemaEndpoint]
    public let components: [ServiceSchemaComponent]

    public init(
        version: String = "v1rc1",
        endpoints: [ServiceSchemaEndpoint],
        components: [ServiceSchemaComponent]
    ) {
        self.version = version
        self.endpoints = endpoints
        self.components = components
    }
}

public enum ServiceSchemaComponentKind: String, Sendable, Codable, CaseIterable {
    case request
    case response
}

public struct ServiceSchemaComponent: Sendable, Codable, Equatable {
    public let name: String
    public let kind: ServiceSchemaComponentKind
    public let summary: String
    public let fields: [String: String]

    public init(
        name: String,
        kind: ServiceSchemaComponentKind,
        summary: String,
        fields: [String: String]
    ) {
        self.name = name
        self.kind = kind
        self.summary = summary
        self.fields = fields
    }
}

public struct ServiceSchemaEndpoint: Sendable, Codable, Equatable {
    public let method: String
    public let path: String
    public let summary: String
    public let requestComponent: String?
    public let responseComponents: [String: String]
    public let capabilityIdentifiers: [String]

    public init(
        method: String,
        path: String,
        summary: String,
        requestComponent: String? = nil,
        responseComponents: [String: String] = [:],
        capabilityIdentifiers: [String] = []
    ) {
        self.method = method
        self.path = path
        self.summary = summary
        self.requestComponent = requestComponent
        self.responseComponents = responseComponents
        self.capabilityIdentifiers = capabilityIdentifiers
    }
}

public enum ServiceJobKind: String, Sendable, Codable, CaseIterable {
    case render
    case renderDocx = "render_docx"
    case batch
    case pipeline
}

public enum ServiceJobStatus: String, Sendable, Codable, CaseIterable {
    case queued
    case running
    case completed
    case failed
    case cancelled

    public var isTerminal: Bool {
        switch self {
        case .completed, .failed, .cancelled:
            return true
        case .queued, .running:
            return false
        }
    }
}

public struct JobDiagnostics: Sendable, Codable {
    public let warnings: [String]
    public let errors: [String]
    public let templateAnalysis: TemplateAnalysis?
    public let docxAnalysis: DOCXTemplateAnalysis?

    public init(
        warnings: [String] = [],
        errors: [String] = [],
        templateAnalysis: TemplateAnalysis? = nil,
        docxAnalysis: DOCXTemplateAnalysis? = nil
    ) {
        self.warnings = warnings
        self.errors = errors
        self.templateAnalysis = templateAnalysis
        self.docxAnalysis = docxAnalysis
    }
}

public struct JobProgress: Sendable, Codable, Equatable {
    public let fractionCompleted: Double
    public let currentStep: String
    public let completedSteps: Int?
    public let totalSteps: Int?

    public init(
        fractionCompleted: Double,
        currentStep: String,
        completedSteps: Int? = nil,
        totalSteps: Int? = nil
    ) {
        self.fractionCompleted = fractionCompleted
        self.currentStep = currentStep
        self.completedSteps = completedSteps
        self.totalSteps = totalSteps
    }
}

public struct JobPayload: Sendable, Codable {
    public let output: String?
    public let docxData: String?
    public let batchResult: BatchProcessingResult?
    public let processingTime: TimeInterval?

    public init(
        output: String? = nil,
        docxData: String? = nil,
        batchResult: BatchProcessingResult? = nil,
        processingTime: TimeInterval? = nil
    ) {
        self.output = output
        self.docxData = docxData
        self.batchResult = batchResult
        self.processingTime = processingTime
    }
}

public struct JobHandle: Sendable, Codable, Identifiable {
    public let id: UUID
    public let kind: ServiceJobKind
    public let status: ServiceJobStatus
    public let createdAt: Date
    public let updatedAt: Date
    public let expiresAt: Date
    public let progress: JobProgress
    public let payload: JobPayload?
    public let diagnostics: JobDiagnostics
    public let error: String?

    public init(
        id: UUID = UUID(),
        kind: ServiceJobKind,
        status: ServiceJobStatus,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        expiresAt: Date,
        progress: JobProgress = JobProgress(fractionCompleted: 0, currentStep: "Queued"),
        payload: JobPayload? = nil,
        diagnostics: JobDiagnostics = JobDiagnostics(),
        error: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.expiresAt = expiresAt
        self.progress = progress
        self.payload = payload
        self.diagnostics = diagnostics
        self.error = error
    }
}
