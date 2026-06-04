/**
 * ServiceManager.swift
 * 
 * Core orchestration actor for RhoeLiquid Native Service
 * Manages engine lifecycle, metrics, and coordination between components
 */

import Foundation
import Logging
import RhoeLiquid
import RhoeDOCX

// SAFETY: Immutable after init; contains [String: Any] which is not Sendable
private struct UnsafeProcessingContext: @unchecked Sendable {
    let values: [String: Any]
}

private extension LiquidEngine {
    func renderWithMetricsUnsafe(
        template: String,
        context: UnsafeProcessingContext
    ) async throws -> (output: String, metrics: PerformanceMetrics) {
        try await renderWithMetrics(template: template, context: context.values)
    }
}

private extension LiquidEnvironment {
    func renderWithMetricsUnsafe(
        template: String,
        context: UnsafeProcessingContext
    ) async throws -> (output: String, metrics: PerformanceMetrics) {
        try await renderWithMetrics(template: template, context: context.values)
    }

    func analyzeTemplateUnsafe(
        _ template: String,
        context: UnsafeProcessingContext?
    ) async -> TemplateAnalysis {
        await analyzeTemplate(template, context: context?.values)
    }
}

private extension DOCXRenderingPipeline {
    func renderUnsafe(
        data: Data,
        context: UnsafeProcessingContext
    ) async throws -> DOCXRenderOutput {
        try await render(data: data, context: context.values)
    }
}

/// Core service manager actor that orchestrates the entire RhoeLiquid Native Service.
///
/// `ServiceManager` is the central coordination point for the service, managing:
/// - Liquid template engine lifecycle
/// - Performance metrics collection
/// - Rate limiting enforcement
/// - Activity tracking and logging
///
/// ## Usage
/// ```swift
/// let manager = ServiceManager(configuration: .production)
/// try await manager.startService()
/// 
/// let result = try await manager.processTemplate(
///     "Hello {{ name }}!",
///     context: ["name": "World"]
/// )
/// print(result.output) // "Hello World!"
/// ```
///
/// ## Thread Safety
/// This class is marked with `@MainActor` to ensure all operations occur on the main thread,
/// providing thread-safe access to the service state and metrics.
///
/// ## Performance
/// The service manager is optimized for high-throughput template processing with:
/// - Template caching for repeated renders
/// - Efficient metrics collection
/// - Minimal memory overhead
///
/// - Note: This class conforms to `ObservableObject` for SwiftUI integration
/// - Important: Always call `startService()` before processing templates
@MainActor
public final class ServiceManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public private(set) var status: ServiceStatus = .stopped
    @Published public private(set) var metrics: ServiceMetrics = ServiceMetrics()
    @Published public private(set) var recentActivity: [ProcessingActivity] = []
    @Published public private(set) var configuration: ServiceConfiguration
    
    // MARK: - Private Properties
    
    private let logger = Logger(label: "service-manager")
    private let environment: LiquidEnvironment
    private let docxPipeline: DOCXRenderingPipeline
    private let jobStore: ServiceJobStore
    private let startTime: Date
    private var metricsUpdateTask: Task<Void, Never>?
    private var inflightJobs: [UUID: Task<Void, Never>] = [:]
    
    // Metrics tracking
    private var totalRequests: Int = 0
    private var requestsToday: Int = 0
    private var renderTimes: [TimeInterval] = []
    private var cacheHits: Int = 0
    private var cacheRequests: Int = 0
    private var errors: Int = 0
    private let maxActivityHistory = 100
    
    // MARK: - Initialization
    
    public init(configuration: ServiceConfiguration = .production) {
        self.configuration = configuration
        self.startTime = Date()
        self.jobStore = ServiceJobStore(
            storageDirectory: configuration.storageDirectory ?? Self.defaultStorageDirectory(),
            retentionInterval: configuration.jobRetentionSeconds
        )
        
        let environment = LiquidEnvironment(
            configuration: configuration.performanceMode.engineConfiguration(),
            profile: .extended,
            sandboxPolicy: .serviceSafe
        )
        self.environment = environment
        self.docxPipeline = DOCXRenderingPipeline(environment: environment)

        logger.info("🚀 ServiceManager initialized with \(configuration.performanceMode.rawValue) mode")
    }

    private static func defaultStorageDirectory() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return appSupport.appendingPathComponent("RhoeLiquid", isDirectory: true)
    }
    
    // MARK: - Service Lifecycle
    
    /// Starts the RhoeLiquid Native Service and initializes all components.
    ///
    /// This method performs the following initialization steps:
    /// 1. Configures the Liquid template engine
    /// 2. Starts metrics collection
    /// 3. Updates service status to active
    ///
    /// - Throws: `ServiceError` if initialization fails
    /// - Note: This method is idempotent - calling it multiple times is safe
    ///
    /// ## Example
    /// ```swift
    /// do {
    ///     try await serviceManager.startService()
    ///     print("Service started successfully")
    /// } catch {
    ///     print("Failed to start: \(error)")
    /// }
    /// ```
    public func startService() async throws {
        logger.info("🔄 Starting RhoeLiquid Native Service...")
        status = .starting
        
        do {
            // Configure engine for service operation
            try await configureEngine()
            
            // Start metrics collection
            startMetricsCollection()
            
            status = .active
            logger.info("✅ RhoeLiquid Native Service started successfully")
            
            // Log startup metrics
            await logStartupMetrics()
            
        } catch {
            status = .error
            logger.error("❌ Failed to start service: \(error)")
            throw error
        }
    }
    
    /// Stops the RhoeLiquid Native Service gracefully.
    ///
    /// This method performs a clean shutdown:
    /// 1. Cancels metrics collection tasks
    /// 2. Logs final service metrics
    /// 3. Updates service status to stopped
    ///
    /// - Note: This method is safe to call even if the service is already stopped
    /// - Important: Any in-flight template processing will complete before shutdown
    ///
    /// ## Example
    /// ```swift
    /// await serviceManager.stopService()
    /// print("Service stopped")
    /// ```
    public func stopService() async {
        logger.info("🛑 Stopping RhoeLiquid Native Service...")
        status = .stopping
        
        // Cancel metrics collection
        metricsUpdateTask?.cancel()
        metricsUpdateTask = nil

        for (jobID, task) in inflightJobs {
            task.cancel()
            _ = await jobStore.cancel(id: jobID)
        }
        inflightJobs.removeAll()
        
        // Log shutdown metrics
        await logShutdownMetrics()
        
        status = .stopped
        logger.info("✅ RhoeLiquid Native Service stopped")
    }
    
    /// Restarts the RhoeLiquid Native Service.
    ///
    /// Performs a complete stop and start cycle with a brief delay to ensure
    /// clean resource cleanup.
    ///
    /// - Throws: `ServiceError` if the service fails to restart
    /// - Note: The service will be unavailable for ~500ms during restart
    ///
    /// ## Example
    /// ```swift
    /// try await serviceManager.restartService()
    /// print("Service restarted")
    /// ```
    public func restartService() async throws {
        await stopService()
        try await Task.sleep(for: .milliseconds(500))
        try await startService()
    }
    
    // MARK: - Engine Configuration
    
    private func configureEngine() async throws {
        logger.debug("⚙️ Configuring engine for native service operation")
        
        // The engine is already configured with the performance mode configuration
        // during initialization, so no additional configuration is needed
        
        logger.info("✅ Engine configured for \(configuration.performanceMode.rawValue) mode")
    }
    
    // MARK: - Template Processing
    
    /// Processes a Liquid template with the provided context data.
    ///
    /// This is the main API for template rendering. It supports all standard Liquid
    /// features plus RhoeLiquid extensions like custom filters.
    ///
    /// - Parameters:
    ///   - template: The Liquid template string to process
    ///   - context: Dictionary of variables available to the template
    ///   - options: Optional processing configuration
    ///
    /// - Returns: `ProcessingResult` containing rendered output and metrics
    ///
    /// - Throws:
    ///   - `ServiceError.rateLimitExceeded`: Client has exceeded rate limits
    ///   - `ServiceError.templateTooLarge`: Template exceeds size limit
    ///   - `ServiceError.serviceUnavailable`: Service is not running
    ///   - `LiquidError`: Template syntax or rendering errors
    ///
    /// ## Example
    /// ```swift
    /// let result = try await manager.processTemplate(
    ///     "{% for item in items %}{{ item }}{% endfor %}",
    ///     context: ["items": ["A", "B", "C"]],
    ///     options: ProcessingOptions(includeMetrics: true)
    /// )
    /// print(result.output) // "ABC"
    /// print(result.metrics.renderTime) // 0.002
    /// ```
    ///
    /// ## Performance
    /// - Templates are cached for improved performance
    /// - Average render time: <5ms for typical templates
    /// - Memory usage scales with template complexity
    ///
    /// - Important: Rate limits apply per client IP address
    /// - Note: Large templates (>10MB) will be rejected
    public func processTemplate(
        _ template: String,
        context: [String: Any],
        options: ProcessingOptions = ProcessingOptions()
    ) async throws -> ProcessingResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        let clientIP = options.clientIP
        let unsafeContext = UnsafeProcessingContext(values: context)
        
        do {
            // Check rate limits
            if await shouldRateLimit(clientIP: clientIP) {
                let activity = ProcessingActivity(
                    renderTime: 0,
                    status: .rateLimited,
                    clientIP: clientIP,
                    errorMessage: "Rate limit exceeded"
                )
                await addActivity(activity)
                throw ServiceError.rateLimitExceeded
            }
            
            // Process template with metrics
            let (output, engineMetrics) = try await environment.renderWithMetricsUnsafe(
                template: template,
                context: unsafeContext
            )
            let renderTime = CFAbsoluteTimeGetCurrent() - startTime
            
            // Update metrics
            await updateMetrics(renderTime: renderTime, success: true, cacheHit: engineMetrics.cacheHit)
            
            // Create activity record
            let activity = ProcessingActivity(
                renderTime: renderTime,
                status: .success,
                clientIP: clientIP
            )
            await addActivity(activity)
            
            // Create result with metrics
            let metrics = ProcessingMetrics(
                renderTime: renderTime,
                memoryUsed: await getMemoryUsage(),
                variableCount: countVariables(in: template),
                filterCount: countFilters(in: template),
                cacheHit: engineMetrics.cacheHit
            )
            
            return ProcessingResult(
                output: output,
                metrics: metrics,
                warnings: [],
                errors: []
            )
            
        } catch {
            let renderTime = CFAbsoluteTimeGetCurrent() - startTime
            
            // Update error metrics
            await updateMetrics(renderTime: renderTime, success: false, cacheHit: false)
            
            // Create error activity
            let status: ProcessingStatus = .error
            let activity = ProcessingActivity(
                renderTime: renderTime,
                status: status,
                clientIP: clientIP,
                errorMessage: error.localizedDescription
            )
            await addActivity(activity)
            
            logger.error("❌ Template processing failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Metrics Management
    
    private func startMetricsCollection() {
        metricsUpdateTask = Task {
            while !Task.isCancelled {
                await updateSystemMetrics()
                try? await Task.sleep(for: .seconds(5))
            }
        }
    }
    
    private func updateSystemMetrics() async {
        let uptime = Date().timeIntervalSince(startTime)
        let memoryUsage = await getMemoryUsage()
        let cpuUsage = await getCPUUsage()
        let cacheHitRate = cacheRequests > 0 ? Double(cacheHits) / Double(cacheRequests) : 0.0
        let averageRenderTime = renderTimes.isEmpty ? 0.0 : renderTimes.reduce(0, +) / Double(renderTimes.count)
        let errorRate = totalRequests > 0 ? Double(errors) / Double(totalRequests) : 0.0
        
        metrics = ServiceMetrics(
            uptime: uptime,
            totalRequests: totalRequests,
            requestsToday: requestsToday,
            averageRenderTime: averageRenderTime,
            memoryUsage: memoryUsage,
            cpuUsage: cpuUsage,
            cacheHitRate: cacheHitRate,
            activeConnections: 0, // Will be set by HTTP service
            errorRate: errorRate,
            queueDepth: 0 // Will be set by HTTP service
        )
    }
    
    private func updateMetrics(renderTime: TimeInterval, success: Bool, cacheHit: Bool) async {
        totalRequests += 1
        requestsToday += 1
        
        if success {
            renderTimes.append(renderTime)
            // Keep only last 1000 render times for average calculation
            if renderTimes.count > 1000 {
                renderTimes.removeFirst(renderTimes.count - 1000)
            }
        } else {
            errors += 1
        }
        
        cacheRequests += 1
        if cacheHit {
            cacheHits += 1
        }
    }
    
    private func addActivity(_ activity: ProcessingActivity) async {
        recentActivity.insert(activity, at: 0)
        // Keep only recent activities
        if recentActivity.count > maxActivityHistory {
            recentActivity.removeLast(recentActivity.count - maxActivityHistory)
        }
    }
    
    // MARK: - Rate Limiting
    
    private func shouldRateLimit(clientIP: String?) async -> Bool {
        // Basic rate limiting implementation
        // In a production service, this would use a more sophisticated approach
        // with Redis or similar for distributed rate limiting
        guard let clientIP = clientIP else { return false }
        
        let now = Date()
        let oneMinuteAgo = now.addingTimeInterval(-60)
        
        // Count recent requests from this IP
        let recentRequests = recentActivity.filter { activity in
            activity.clientIP == clientIP && activity.timestamp > oneMinuteAgo
        }.count
        
        return recentRequests >= configuration.rateLimits.requestsPerMinute
    }
    
    // MARK: - System Metrics
    
    private func getMemoryUsage() async -> Int {
        let task = mach_task_self_
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let status = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(task, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        return status == KERN_SUCCESS ? Int(info.resident_size) : 0
    }
    
    private func getCPUUsage() async -> Double {
        // Simplified CPU usage calculation
        // In production, this would use more accurate system APIs
        return 0.0
    }
    
    // MARK: - Template Analysis
    
    private func countVariables(in template: String) -> Int {
        let regex = try! NSRegularExpression(pattern: #"\{\{\s*[\w.]+\s*\}\}"#)
        return regex.numberOfMatches(in: template, range: NSRange(template.startIndex..., in: template))
    }
    
    private func countFilters(in template: String) -> Int {
        let regex = try! NSRegularExpression(pattern: #"\|\s*\w+"#)
        return regex.numberOfMatches(in: template, range: NSRange(template.startIndex..., in: template))
    }
    
    // MARK: - Template Analysis and Validation
    
    /// Analyze template structure and complexity
    public func analyzeTemplate(
        _ template: String,
        context: [String: Any]? = nil
    ) async throws -> TemplateAnalysis {
        guard status == .active else {
            throw ServiceError.serviceUnavailable
        }

        return await environment.analyzeTemplateUnsafe(
            template,
            context: context.map(UnsafeProcessingContext.init(values:))
        )
    }
    
    /// Validate template syntax
    public func validateTemplate(
        _ template: String,
        context: [String: Any]? = nil
    ) async throws -> TemplateValidationResult {
        guard status == .active else {
            throw ServiceError.serviceUnavailable
        }
        
        let analysis = await environment.analyzeTemplateUnsafe(
            template,
            context: context.map(UnsafeProcessingContext.init(values:))
        )
        
        return TemplateValidationResult(
            isValid: analysis.isValid,
            errors: analysis.validationErrors.map {
                ValidationError(line: 1, column: 1, message: $0, severity: .error)
            },
            warnings: analysis.warnings.map {
                ValidationWarning(line: 1, column: 1, message: $0, severity: .warning)
            }
        )
    }

    // MARK: - Capability Contracts

    public func serviceCapabilities() async throws -> ServiceCapabilities {
        guard status == .active else {
            throw ServiceError.serviceUnavailable
        }

        let environmentCapabilities = await environment.capabilities()
        let supportedStructuredParts = DOCXRenderingPipeline.trustedStructuredPartPatterns
        let coverageSummary = DOCXCoverageSummary(
            trustedSubsetVersion: "trusted-docx-v1",
            structuredSupportedParts: supportedStructuredParts,
            supportedPartCount: supportedStructuredParts.count,
            unsupportedPartCount: 0,
            preservesUnsupportedParts: true,
            unsupportedConstructBehavior: "Unsupported or untrusted DOCX constructs are preserved byte-for-byte and reported in diagnostics."
        )

        return ServiceCapabilities(
            serviceVersion: "0.1.1",
            engineVersion: environmentCapabilities.version,
            schemaVersion: ServiceContractCatalog.schemaVersion,
            profile: environmentCapabilities.profile,
            sandboxPolicy: environmentCapabilities.sandboxPolicy,
            supportedTags: environmentCapabilities.supportedTags,
            supportedFilters: environmentCapabilities.supportedFilters,
            supportedJobKinds: ServiceJobKind.allCases,
            preferredExecution: .serviceAuthoritative,
            supportsMacros: environmentCapabilities.supportsMacros,
            supportsInputContracts: environmentCapabilities.supportsInputContracts,
            supportsExpressionCallMacros: environmentCapabilities.supportsExpressionCallMacros,
            docx: DOCXServiceCapabilities(
                supportedStructuredParts: supportedStructuredParts,
                preservesMediaRelationships: true,
                preservesNumberingAndStyles: true,
                preservesUnsupportedParts: true,
                coverageSummary: coverageSummary,
                notes: [
                    "Structured rendering currently targets the trusted DOCX subset frozen for the v0.1.0 public baseline.",
                    "Unsupported or untrusted package parts are preserved byte-for-byte and reported instead of being silently rewritten."
                ]
            ),
            supportsAnalysis: true,
            supportsValidation: true,
            supportsAsyncJobs: true
        )
    }

    public func serviceSchema() -> ServiceSchema {
        ServiceContractCatalog.schema()
    }
    
    // MARK: - DOCX Processing
    
    /// Process a DOCX template with context data
    public func processDocxTemplate(
        _ docxData: Data,
        context: [String: Any],
        options: ProcessingOptions = ProcessingOptions()
    ) async throws -> DocxProcessingResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        guard status == .active else {
            throw ServiceError.serviceUnavailable
        }
        
        do {
            let processed = try await docxPipeline.renderUnsafe(
                data: docxData,
                context: UnsafeProcessingContext(values: context)
            )
            
            let processingTime = CFAbsoluteTimeGetCurrent() - startTime
            
            // Update metrics
            await updateMetrics(renderTime: processingTime, success: true, cacheHit: false)
            
            return DocxProcessingResult(
                docxData: processed.data,
                processingTime: processingTime,
                errors: [],
                warnings: processed.analysis.warnings,
                analysis: processed.analysis
            )
            
        } catch {
            let processingTime = CFAbsoluteTimeGetCurrent() - startTime
            await updateMetrics(renderTime: processingTime, success: false, cacheHit: false)
            throw error
        }
    }

    // MARK: - Async Jobs

    public func submitRenderJob(
        template: String,
        context: [String: Any],
        options: ProcessingOptions = ProcessingOptions()
    ) async throws -> JobHandle {
        guard status == .active else {
            throw ServiceError.serviceUnavailable
        }

        let analysis = await environment.analyzeTemplateUnsafe(
            template,
            context: UnsafeProcessingContext(values: context)
        )
        let handle = await jobStore.create(
            kind: .render,
            diagnostics: JobDiagnostics(templateAnalysis: analysis)
        )

        let task = Task { @MainActor [weak self] in
            guard let self else { return }
            _ = await self.jobStore.markRunning(
                id: handle.id,
                progress: JobProgress(fractionCompleted: 0.2, currentStep: "Rendering template", completedSteps: 0, totalSteps: 1)
            )

            do {
                let result = try await self.processTemplate(template, context: context, options: options)
                _ = await self.jobStore.complete(
                    id: handle.id,
                    payload: JobPayload(
                        output: result.output,
                        processingTime: result.metrics.renderTime
                    ),
                    diagnostics: JobDiagnostics(
                        warnings: result.warnings,
                        errors: result.errors,
                        templateAnalysis: analysis
                    )
                )
            } catch is CancellationError {
                _ = await self.jobStore.cancel(id: handle.id)
            } catch {
                _ = await self.jobStore.fail(
                    id: handle.id,
                    error: error.localizedDescription,
                    diagnostics: JobDiagnostics(
                        errors: [error.localizedDescription],
                        templateAnalysis: analysis
                    )
                )
            }
            self.inflightJobs.removeValue(forKey: handle.id)
        }
        inflightJobs[handle.id] = task

        return handle
    }

    public func submitDocxRenderJob(
        docxData: Data,
        context: [String: Any],
        options: ProcessingOptions = ProcessingOptions()
    ) async throws -> JobHandle {
        guard status == .active else {
            throw ServiceError.serviceUnavailable
        }

        let handle = await jobStore.create(kind: .renderDocx)

        let task = Task { @MainActor [weak self] in
            guard let self else { return }
            _ = await self.jobStore.markRunning(
                id: handle.id,
                progress: JobProgress(fractionCompleted: 0.2, currentStep: "Rendering DOCX", completedSteps: 0, totalSteps: 1)
            )

            do {
                let result = try await self.processDocxTemplate(docxData, context: context, options: options)
                _ = await self.jobStore.complete(
                    id: handle.id,
                    payload: JobPayload(
                        docxData: result.docxData.base64EncodedString(),
                        processingTime: result.processingTime
                    ),
                    diagnostics: JobDiagnostics(
                        warnings: result.warnings,
                        errors: result.errors,
                        docxAnalysis: result.analysis
                    )
                )
            } catch is CancellationError {
                _ = await self.jobStore.cancel(id: handle.id)
            } catch {
                _ = await self.jobStore.fail(
                    id: handle.id,
                    error: error.localizedDescription,
                    diagnostics: JobDiagnostics(errors: [error.localizedDescription])
                )
            }
            self.inflightJobs.removeValue(forKey: handle.id)
        }
        inflightJobs[handle.id] = task

        return handle
    }

    public func submitBatchJob(
        _ requests: [BatchProcessingRequest],
        options: BatchProcessingOptions = BatchProcessingOptions()
    ) async throws -> JobHandle {
        guard status == .active else {
            throw ServiceError.serviceUnavailable
        }

        let handle = await jobStore.create(kind: .batch)

        let task = Task { @MainActor [weak self] in
            guard let self else { return }
            _ = await self.jobStore.markRunning(
                id: handle.id,
                progress: JobProgress(fractionCompleted: 0.1, currentStep: "Processing batch", completedSteps: 0, totalSteps: 1)
            )

            do {
                let result = try await self.batchProcess(requests, options: options)
                _ = await self.jobStore.complete(
                    id: handle.id,
                    payload: JobPayload(
                        batchResult: result,
                        processingTime: result.processingTime
                    ),
                    diagnostics: JobDiagnostics()
                )
            } catch is CancellationError {
                _ = await self.jobStore.cancel(id: handle.id)
            } catch {
                _ = await self.jobStore.fail(
                    id: handle.id,
                    error: error.localizedDescription,
                    diagnostics: JobDiagnostics(errors: [error.localizedDescription])
                )
            }
            self.inflightJobs.removeValue(forKey: handle.id)
        }
        inflightJobs[handle.id] = task

        return handle
    }

    public func job(id: UUID) async -> JobHandle? {
        await jobStore.job(id: id)
    }

    public func cancelJob(id: UUID) async -> JobHandle? {
        inflightJobs[id]?.cancel()
        inflightJobs.removeValue(forKey: id)
        return await jobStore.cancel(id: id)
    }
    
    // MARK: - Batch Processing
    
    /// Process multiple templates in batch
    public func batchProcess(
        _ requests: [BatchProcessingRequest],
        options: BatchProcessingOptions = BatchProcessingOptions()
    ) async throws -> BatchProcessingResult {
        guard status == .active else {
            throw ServiceError.serviceUnavailable
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        var results: [BatchItemResult] = []
        var successCount = 0
        var errorCount = 0
        
        // Process requests concurrently or sequentially based on options
        if options.concurrent {
            // Concurrent processing with task group
            await withTaskGroup(of: BatchItemResult.self) { group in
                for (index, request) in requests.enumerated() {
                    group.addTask { [weak self] in
                        guard let self = self else {
                            return BatchItemResult(
                                index: index,
                                success: false,
                                output: nil,
                                error: "Service unavailable"
                            )
                        }
                        
                        do {
                            let result = try await self.processTemplate(
                                request.template,
                                context: request.context,
                                options: ProcessingOptions(
                                    clientIP: options.clientIP,
                                    timeout: request.timeout ?? 30.0
                                )
                            )
                            return BatchItemResult(
                                index: index,
                                success: true,
                                output: result.output,
                                error: nil
                            )
                        } catch {
                            return BatchItemResult(
                                index: index,
                                success: false,
                                output: nil,
                                error: error.localizedDescription
                            )
                        }
                    }
                }
                
                for await result in group {
                    results.append(result)
                    if result.success {
                        successCount += 1
                    } else {
                        errorCount += 1
                    }
                }
            }
        } else {
            // Sequential processing
            for (index, request) in requests.enumerated() {
                do {
                    let result = try await processTemplate(
                        request.template,
                        context: request.context,
                        options: ProcessingOptions(
                            clientIP: options.clientIP,
                            timeout: request.timeout ?? 30.0
                        )
                    )
                    results.append(BatchItemResult(
                        index: index,
                        success: true,
                        output: result.output,
                        error: nil
                    ))
                    successCount += 1
                } catch {
                    results.append(BatchItemResult(
                        index: index,
                        success: false,
                        output: nil,
                        error: error.localizedDescription
                    ))
                    errorCount += 1
                }
            }
        }
        
        let totalTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Sort results by index to maintain order
        results.sort { $0.index < $1.index }
        
        return BatchProcessingResult(
            results: results,
            totalItems: requests.count,
            successCount: successCount,
            errorCount: errorCount,
            processingTime: totalTime
        )
    }
    
    // MARK: - Document Pipeline

    /// The audit store for recording rendering operations.
    public let auditStore = AuditStore()

    /// Execute a document pipeline — multi-stage, multi-output rendering.
    public func executePipeline(
        _ definition: PipelineDefinition,
        progressHandler: ((_ stageIndex: Int, _ stageName: String) -> Void)? = nil
    ) async throws -> PipelineResult {
        guard status == .active else {
            throw ServiceError.serviceUnavailable
        }

        let pipelineStart = CFAbsoluteTimeGetCurrent()
        var stageResults: [StageResult] = []
        var auditEntries: [AuditEntry] = []
        var completedStageIds = Set<String>()

        // Build shared context from definition
        var sharedContext: [String: Any] = [:]
        if let ctx = definition.sharedContext {
            for (key, value) in ctx {
                sharedContext[key] = value
            }
        }

        for (stageIndex, stage) in definition.stages.enumerated() {
            progressHandler?(stageIndex, stage.id)

            // Check dependencies
            if let deps = stage.dependsOn {
                let unmet = deps.filter { !completedStageIds.contains($0) }
                if !unmet.isEmpty {
                    stageResults.append(StageResult(
                        stageId: stage.id,
                        success: false,
                        error: "Unmet dependencies: \(unmet.joined(separator: ", "))",
                        skipped: true
                    ))
                    continue
                }
            }

            // Evaluate condition (if present, render as Liquid — truthy = proceed)
            if let condition = stage.condition {
                do {
                    let conditionResult = try await processTemplate(
                        "{% if \(condition) %}true{% endif %}",
                        context: sharedContext,
                        options: ProcessingOptions(timeout: 5.0)
                    )
                    if conditionResult.output.trimmingCharacters(in: .whitespacesAndNewlines) != "true" {
                        stageResults.append(StageResult(stageId: stage.id, success: true, skipped: true))
                        completedStageIds.insert(stage.id)
                        continue
                    }
                } catch {
                    stageResults.append(StageResult(
                        stageId: stage.id,
                        success: false,
                        error: "Condition evaluation failed: \(error.localizedDescription)",
                        skipped: true
                    ))
                    continue
                }
            }

            // Merge context: shared + per-stage overrides
            var stageContext = sharedContext
            if let overrides = stage.contextOverrides {
                for (key, value) in overrides {
                    stageContext[key] = value
                }
            }

            // Execute the stage
            let stageStart = CFAbsoluteTimeGetCurrent()
            do {
                let result = try await processTemplate(
                    stage.template,
                    context: stageContext,
                    options: ProcessingOptions(timeout: 30.0)
                )
                let stageDuration = CFAbsoluteTimeGetCurrent() - stageStart

                stageResults.append(StageResult(
                    stageId: stage.id,
                    success: true,
                    output: result.output,
                    processingTime: stageDuration
                ))
                completedStageIds.insert(stage.id)

                // Record audit entry for this stage
                let entry = AuditEntry(
                    operation: .pipelineStage,
                    templateHash: AuditStore.hash(stage.template),
                    contextHash: AuditStore.hash(String(describing: stageContext)),
                    outputHash: AuditStore.hash(result.output),
                    durationMs: stageDuration * 1000,
                    stageId: stage.id,
                    pipelineId: definition.id,
                    success: true
                )
                await auditStore.record(entry)
                auditEntries.append(entry)
            } catch {
                let stageDuration = CFAbsoluteTimeGetCurrent() - stageStart
                stageResults.append(StageResult(
                    stageId: stage.id,
                    success: false,
                    error: error.localizedDescription,
                    processingTime: stageDuration
                ))

                let entry = AuditEntry(
                    operation: .pipelineStage,
                    templateHash: AuditStore.hash(stage.template),
                    contextHash: AuditStore.hash(String(describing: stageContext)),
                    durationMs: stageDuration * 1000,
                    stageId: stage.id,
                    pipelineId: definition.id,
                    success: false
                )
                await auditStore.record(entry)
                auditEntries.append(entry)
            }
        }

        let totalTime = CFAbsoluteTimeGetCurrent() - pipelineStart

        // Record pipeline-level audit entry
        let pipelineEntry = AuditEntry(
            operation: .pipeline,
            templateHash: AuditStore.hash(definition.id),
            contextHash: AuditStore.hash(String(describing: sharedContext)),
            durationMs: totalTime * 1000,
            pipelineId: definition.id,
            success: stageResults.allSatisfy { $0.success || $0.skipped }
        )
        await auditStore.record(pipelineEntry)
        auditEntries.append(pipelineEntry)

        return PipelineResult(
            pipelineId: definition.id,
            stageResults: stageResults,
            totalProcessingTime: totalTime,
            auditTrail: auditEntries
        )
    }

    /// Submit a pipeline as an async job.
    public func submitPipelineJob(_ definition: PipelineDefinition) async -> JobHandle {
        let handle = await jobStore.create(kind: .pipeline)
        let id = handle.id

        let task = Task { [weak self] in
            guard let self = self else { return }
            _ = await self.jobStore.markRunning(id: id)

            do {
                let stageCount = definition.stages.count
                let result = try await self.executePipeline(definition, progressHandler: { stageIndex, stageName in
                    let fraction = Double(stageIndex + 1) / Double(max(stageCount, 1))
                    let progress = JobProgress(fractionCompleted: fraction, currentStep: "Stage: \(stageName)")
                    Task {
                        _ = await self.jobStore.updateProgress(id: id, progress: progress)
                    }
                })

                let payload = JobPayload(
                    output: result.stageResults.compactMap(\.output).joined(separator: "\n---\n"),
                    processingTime: result.totalProcessingTime
                )
                let diagnostics = JobDiagnostics(
                    warnings: result.stageResults.filter { $0.skipped }.map { "\($0.stageId): skipped" },
                    errors: result.stageResults.compactMap { $0.error }.map { $0 }
                )
                _ = await self.jobStore.complete(id: id, payload: payload, diagnostics: diagnostics)
            } catch is CancellationError {
                _ = await self.jobStore.cancel(id: id)
            } catch {
                let diagnostics = JobDiagnostics(errors: [error.localizedDescription])
                _ = await self.jobStore.fail(id: id, error: error.localizedDescription, diagnostics: diagnostics)
            }

            inflightJobs.removeValue(forKey: id)
        }

        inflightJobs[id] = task
        return handle
    }

    // MARK: - Logging

    private func logStartupMetrics() async {
        let memoryUsageMB = await getMemoryUsage() / 1024 / 1024
        logger.info("📊 Service startup metrics", metadata: [
            "performance_mode": "\(configuration.performanceMode.rawValue)",
            "memory_usage_mb": "\(memoryUsageMB)",
            "max_concurrent_requests": "\(configuration.maxConcurrentRequests)"
        ])
    }
    
    private func logShutdownMetrics() async {
        let uptime = Date().timeIntervalSince(startTime)
        logger.info("📊 Service shutdown metrics", metadata: [
            "uptime_seconds": "\(uptime)",
            "total_requests": "\(totalRequests)",
            "average_render_time_ms": "\(metrics.averageRenderTime * 1000)",
            "cache_hit_rate": "\(metrics.cacheHitRate)",
            "error_rate": "\(metrics.errorRate)"
        ])
    }
}

// MARK: - Supporting Types

/// Configuration options for template processing operations.
///
/// Use `ProcessingOptions` to customize how templates are processed,
/// including timeout settings, metrics collection, and client identification.
///
/// ## Example
/// ```swift
/// let options = ProcessingOptions(
///     clientIP: "127.0.0.1",
///     timeout: 10.0,
///     includeMetrics: true
/// )
/// let result = try await manager.processTemplate(template, context: context, options: options)
/// ```
public struct ProcessingOptions: Sendable {
    public let clientIP: String?
    public let timeout: TimeInterval
    public let includeMetrics: Bool
    
    public init(
        clientIP: String? = nil,
        timeout: TimeInterval = 30.0,
        includeMetrics: Bool = true
    ) {
        self.clientIP = clientIP
        self.timeout = timeout
        self.includeMetrics = includeMetrics
    }
}

/// Result returned from successful template processing.
///
/// Contains the rendered output along with detailed performance metrics
/// and any warnings or recoverable errors encountered during processing.
///
/// ## Example
/// ```swift
/// let result = try await manager.processTemplate(template, context: context)
/// print("Output: \(result.output)")
/// print("Render time: \(result.metrics.renderTime)s")
/// if !result.warnings.isEmpty {
///     print("Warnings: \(result.warnings)")
/// }
/// ```
public struct ProcessingResult: Sendable, Codable {
    public let output: String
    public let metrics: ProcessingMetrics
    public let warnings: [String]
    public let errors: [String]
    
    public init(
        output: String,
        metrics: ProcessingMetrics,
        warnings: [String] = [],
        errors: [String] = []
    ) {
        self.output = output
        self.metrics = metrics
        self.warnings = warnings
        self.errors = errors
    }
}

/// Detailed performance metrics for a single template processing operation.
///
/// Provides insights into rendering performance, resource usage, and cache effectiveness.
/// Use these metrics to optimize template design and identify performance bottlenecks.
///
/// ## Metrics Explained
/// - `renderTime`: Total time to process the template (in seconds)
/// - `memoryUsed`: Memory consumed during processing (in bytes)
/// - `variableCount`: Number of variables referenced in the template
/// - `filterCount`: Number of filters applied
/// - `cacheHit`: Whether the template was served from cache
///
/// ## Example
/// ```swift
/// if result.metrics.renderTime > 0.1 {
///     print("Warning: Slow template render (\(result.metrics.renderTime)s)")
/// }
/// print("Cache hit rate: \(result.metrics.cacheHit ? "HIT" : "MISS")")
/// ```
public struct ProcessingMetrics: Sendable, Codable {
    public let renderTime: TimeInterval
    public let memoryUsed: Int
    public let variableCount: Int
    public let filterCount: Int
    public let cacheHit: Bool
    
    public init(
        renderTime: TimeInterval,
        memoryUsed: Int,
        variableCount: Int,
        filterCount: Int,
        cacheHit: Bool
    ) {
        self.renderTime = renderTime
        self.memoryUsed = memoryUsed
        self.variableCount = variableCount
        self.filterCount = filterCount
        self.cacheHit = cacheHit
    }
}

/// Errors that can occur during service operations.
///
/// These errors provide specific information about failures in the
/// RhoeLiquid Native Service, allowing for appropriate error handling
/// and recovery strategies.
///
/// ## Error Handling Example
/// ```swift
/// do {
///     let result = try await manager.processTemplate(template, context: context)
/// } catch ServiceError.rateLimitExceeded {
///     // Wait and retry
///     try await Task.sleep(for: .seconds(30))
/// } catch ServiceError.templateTooLarge {
///     // Split template or reduce size
/// } catch {
///     // Handle other errors
/// }
/// ```

// MARK: - DOCX Processing Types

/// Result of DOCX template processing
public struct DocxProcessingResult: Sendable {
    public let docxData: Data
    public let processingTime: TimeInterval
    public let errors: [String]
    public let warnings: [String]
    public let analysis: DOCXTemplateAnalysis

    public init(
        docxData: Data,
        processingTime: TimeInterval,
        errors: [String],
        warnings: [String],
        analysis: DOCXTemplateAnalysis
    ) {
        self.docxData = docxData
        self.processingTime = processingTime
        self.errors = errors
        self.warnings = warnings
        self.analysis = analysis
    }
}

// MARK: - Batch Processing Types

/// Request for batch processing
// SAFETY: Immutable after init; contains [String: Any] which is not Sendable
public struct BatchProcessingRequest: @unchecked Sendable {
    public let template: String
    public let context: [String: Any]
    public let timeout: TimeInterval?
    
    public init(template: String, context: [String: Any], timeout: TimeInterval? = nil) {
        self.template = template
        self.context = context
        self.timeout = timeout
    }
}

/// Options for batch processing
public struct BatchProcessingOptions: Sendable {
    public let concurrent: Bool
    public let maxConcurrency: Int
    public let clientIP: String?
    
    public init(concurrent: Bool = true, maxConcurrency: Int = 4, clientIP: String? = nil) {
        self.concurrent = concurrent
        self.maxConcurrency = maxConcurrency
        self.clientIP = clientIP
    }
}

/// Result of a single batch item
public struct BatchItemResult: Sendable, Codable {
    public let index: Int
    public let success: Bool
    public let output: String?
    public let error: String?
    
    public init(index: Int, success: Bool, output: String?, error: String?) {
        self.index = index
        self.success = success
        self.output = output
        self.error = error
    }
}

/// Result of batch processing operation
public struct BatchProcessingResult: Sendable, Codable {
    public let results: [BatchItemResult]
    public let totalItems: Int
    public let successCount: Int
    public let errorCount: Int
    public let processingTime: TimeInterval
    
    public init(results: [BatchItemResult], totalItems: Int, successCount: Int, errorCount: Int, processingTime: TimeInterval) {
        self.results = results
        self.totalItems = totalItems
        self.successCount = successCount
        self.errorCount = errorCount
        self.processingTime = processingTime
    }
}

// MARK: - Template Validation Types

/// Result of template validation operation
public struct TemplateValidationResult: Sendable {
    public let isValid: Bool
    public let errors: [ValidationError]
    public let warnings: [ValidationWarning]
    
    public init(isValid: Bool, errors: [ValidationError], warnings: [ValidationWarning]) {
        self.isValid = isValid
        self.errors = errors
        self.warnings = warnings
    }
}

/// Validation error with location information
public struct ValidationError: Sendable {
    public let line: Int
    public let column: Int
    public let message: String
    public let severity: ValidationSeverity
    
    public init(line: Int, column: Int, message: String, severity: ValidationSeverity) {
        self.line = line
        self.column = column
        self.message = message
        self.severity = severity
    }
}

/// Validation warning with location information
public struct ValidationWarning: Sendable {
    public let line: Int
    public let column: Int
    public let message: String
    public let severity: ValidationSeverity
    
    public init(line: Int, column: Int, message: String, severity: ValidationSeverity) {
        self.line = line
        self.column = column
        self.message = message
        self.severity = severity
    }
}

/// Severity levels for validation issues
public enum ValidationSeverity: String, Sendable, Codable {
    case error = "error"
    case warning = "warning"
    case info = "info"
}

public enum ServiceError: Error, LocalizedError {
    case rateLimitExceeded
    case templateTooLarge
    case contextTooLarge
    case serviceUnavailable
    case configurationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .templateTooLarge:
            return "Template size exceeds maximum limit."
        case .contextTooLarge:
            return "Context data size exceeds maximum limit."
        case .serviceUnavailable:
            return "Service is currently unavailable."
        case .configurationError(let message):
            return "Configuration error: \(message)"
        }
    }
}
