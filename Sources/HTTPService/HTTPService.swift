import Foundation
import Hummingbird
import HTTPTypes
import Logging
import NIOCore
import ServiceCore

@MainActor
public class HTTPService: ObservableObject {
    @Published public private(set) var isRunning = false
    @Published public private(set) var activeConnections = 0
    @Published public private(set) var queueDepth = 0

    private let serviceManager: ServiceManager
    private let configuration: ServiceConfiguration
    private let logger = Logger(label: "http-service")

    private var connectionCount = 0
    private var serverTask: Task<Void, Error>?

    public init(serviceManager: ServiceManager, configuration: ServiceConfiguration) {
        self.serviceManager = serviceManager
        self.configuration = configuration
        self.logger.info("HTTP service initialized on port \(configuration.httpPort)")
    }

    public func start() async throws {
        guard self.serverTask == nil else {
            self.logger.warning("HTTP service already running")
            return
        }

        self.logger.info("Starting HTTP service on port \(self.configuration.httpPort)")

        let startup = StartupSignal()
        let app = self.makeApplication(startup: startup)
        let task = Task { [app] in
            do {
                try await app.runService(gracefulShutdownSignals: [])
            } catch {
                await startup.fail(error)
                throw error
            }
        }

        self.serverTask = task

        do {
            try await startup.waitUntilStarted()
            self.isRunning = true
            self.logger.info("HTTP service started on localhost:\(self.configuration.httpPort)")
        } catch {
            task.cancel()
            self.serverTask = nil
            self.logger.error("Failed to start HTTP service: \(error)")
            throw error
        }
    }

    public func stop() async {
        guard let task = self.serverTask else {
            self.logger.warning("HTTP service not running")
            return
        }

        self.logger.info("Stopping HTTP service")

        task.cancel()
        _ = await task.result

        self.serverTask = nil
        self.isRunning = false
        self.activeConnections = 0
        self.queueDepth = 0

        self.logger.info("HTTP service stopped")
    }

    public func restart() async throws {
        await self.stop()
        try await Task.sleep(for: .milliseconds(500))
        try await self.start()
    }

    internal func connectionOpened() {
        self.connectionCount += 1
        self.activeConnections = self.connectionCount
    }

    internal func connectionClosed() {
        self.connectionCount = max(0, self.connectionCount - 1)
        self.activeConnections = self.connectionCount
    }

    internal func updateQueueDepth(_ depth: Int) {
        self.queueDepth = depth
    }

    private func makeApplication(
        startup: StartupSignal
    ) -> Application<RouterResponder<BasicRequestContext>> {
        Application(
            router: self.makeRouter(),
            configuration: .init(
                address: .hostname("127.0.0.1", port: self.configuration.httpPort),
                serverName: "RhoeLiquid-Native-Service/0.1.0"
            ),
            onServerRunning: { channel in
                await startup.markStarted()
                await self.onServerStarted(channel)
            }
        )
    }

    private func makeRouter() -> Router<BasicRequestContext> {
        let router = Router()

        router.middlewares.add(CORSMiddleware(
            allowOrigin: CORSMiddleware.AllowOrigin.originBased,
            allowHeaders: [HTTPField.Name.accept, .authorization, .contentType, .origin],
            allowMethods: [HTTPRequest.Method.get, .post, .options]
        ))

        if self.configuration.logLevel == .debug {
            router.middlewares.add(LogRequestsMiddleware(.debug))
        }

        router.middlewares.add(ConnectionTrackingMiddleware(httpService: self))
        router.middlewares.add(ErrorMiddleware())

        if self.configuration.enableSecurity {
            router.middlewares.add(SecurityMiddleware(configuration: self.configuration))
            router.middlewares.add(RateLimitMiddleware(configuration: self.configuration.rateLimits))
        }

        router.middlewares.add(MetricsMiddleware(httpService: self))

        router.get("/") { _, _ in
            try await self.handleServiceInfoResponse()
        }

        router.get("/health") { _, _ in
            try await self.handleHealthCheckResponse()
        }

        router.get("/capabilities") { _, _ in
            try await self.handleCapabilitiesResponse()
        }

        router.get("/schema") { _, _ in
            try await self.handleSchemaResponse()
        }

        router.post("/render") { request, context in
            try await self.handleRender(request, context: context)
        }

        router.post("/analyze") { request, context in
            try await self.handleAnalyze(request, context: context)
        }

        router.post("/validate") { request, context in
            try await self.handleValidate(request, context: context)
        }

        router.post("/render-docx") { request, context in
            try await self.handleRenderDocx(request, context: context)
        }

        router.post("/batch") { request, context in
            try await self.handleBatch(request, context: context)
        }

        router.post("/jobs/render") { request, context in
            try await self.handleRenderJob(request, context: context)
        }

        router.post("/jobs/render-docx") { request, context in
            try await self.handleRenderDocxJob(request, context: context)
        }

        router.post("/jobs/batch") { request, context in
            try await self.handleBatchJob(request, context: context)
        }

        // Pipeline endpoints
        router.post("/pipeline") { request, context in
            try await self.handlePipeline(request, context: context)
        }

        router.post("/jobs/pipeline") { request, context in
            try await self.handlePipelineJob(request, context: context)
        }

        // Audit trail
        router.get("/audit") { request, _ in
            try await self.handleAuditQuery(request)
        }

        router.get("/jobs") { request, _ in
            try await self.handleJobLookup(request)
        }

        router.delete("/jobs") { request, _ in
            try await self.handleJobCancel(request)
        }

        router.post("/configure") { _, _ in
            try await self.handleConfigureResponse()
        }

        router.get("/metrics") { _, _ in
            try await self.handleMetricsResponse()
        }

        return router
    }

    private func onServerStarted(_ channel: any Channel) {
        let address = channel.localAddress?.description ?? "unknown"
        self.logger.info("Server listening on \(address)")
    }
}

extension HTTPService {
    private func handleServiceInfoResponse() throws -> Response {
        try self.encode(self.buildServiceInfo())
    }

    private func buildServiceInfo() -> ServiceInfo {
        let metrics = self.serviceManager.metrics
        let status = self.serviceManager.status

        return ServiceInfo(
            status: status,
            uptime: metrics.uptime,
            requestsProcessed: metrics.totalRequests,
            performance: PerformanceInfo(
                averageRenderTime: metrics.averageRenderTime,
                cacheHitRate: metrics.cacheHitRate,
                memoryUsage: metrics.memoryUsage,
                cpuUsage: metrics.cpuUsage
            )
        )
    }

    private func handleHealthCheckResponse() throws -> Response {
        try self.jsonResponse(self.buildHealthCheckPayload())
    }

    private func handleCapabilitiesResponse() async throws -> Response {
        try self.encode(try await self.serviceManager.serviceCapabilities())
    }

    private func handleSchemaResponse() throws -> Response {
        try self.encode(self.serviceManager.serviceSchema())
    }

    private func buildHealthCheckPayload() -> [String: Any] {
        let metrics = self.serviceManager.metrics
        let status = self.serviceManager.status

        return [
            "active_connections": self.activeConnections,
            "cpu_usage": metrics.cpuUsage,
            "memory_usage": Double(metrics.memoryUsage) / 1024 / 1024,
            "queue_depth": self.queueDepth,
            "status": status == .active ? "healthy" : "unhealthy",
            "uptime": metrics.uptime,
        ]
    }

    private func handleRender(
        _ request: Request,
        context: BasicRequestContext
    ) async throws -> Response {
        let requestBody = try await request.decode(as: RenderRequest.self, context: context)

        do {
            let result = try await self.serviceManager.processTemplate(
                requestBody.template,
                context: requestBody.context,
                options: ProcessingOptions(
                    clientIP: self.getClientIP(request),
                    timeout: requestBody.options?.timeout ?? 30.0,
                    includeMetrics: requestBody.options?.includeMetrics ?? true
                )
            )

            let payload = RenderSuccessResponse(
                success: true,
                output: result.output,
                metrics: ResponseMetrics(
                    renderTime: result.metrics.renderTime,
                    parseTime: 0.001,
                    memoryUsed: result.metrics.memoryUsed,
                    variablesProcessed: result.metrics.variableCount,
                    filtersApplied: result.metrics.filterCount,
                    cacheHit: result.metrics.cacheHit
                ),
                warnings: result.warnings,
                errors: result.errors
            )

            return try self.encode(payload)
        } catch {
            self.logger.error("Render request failed: \(error)")
            return try self.encode(RenderErrorResponse(success: false, error: error.localizedDescription))
        }
    }

    private func handleAnalyze(
        _ request: Request,
        context: BasicRequestContext
    ) async throws -> Response {
        let requestBody = try await request.decode(as: TemplateRequest.self, context: context)
        let analysis = try await self.serviceManager.analyzeTemplate(
            requestBody.template,
            context: requestBody.context
        )

        return try self.encode(
            AnalyzeSuccessResponse(
                success: true,
                analysis: AnalyzeResponsePayload(
                    complexity: analysis.complexity.rawValue,
                    estimatedRenderTime: analysis.estimatedRenderTime,
                    filterCount: analysis.filterCount,
                    manifest: AnalyzeManifestPayload(
                        activeFilters: analysis.manifest.activeFilters,
                        activeTags: analysis.manifest.activeTags,
                        contractDefaults: analysis.manifest.contractDefaults,
                        dataCapabilities: analysis.manifest.dataCapabilities,
                        declaredInputs: analysis.manifest.declaredInputs.map {
                            AnalyzeInputFieldPayload(
                                name: $0.name,
                                type: $0.type.description,
                                required: $0.required,
                                strict: $0.strict,
                                defaultValueDescription: $0.defaultValueDescription
                            )
                        },
                        macroCalls: analysis.manifest.macroCalls.map {
                            AnalyzeMacroCallPayload(
                                name: $0.name,
                                positionalArgumentCount: $0.positionalArgumentCount,
                                namedArguments: $0.namedArguments,
                                filledSlots: $0.filledSlots,
                                hasBlockBody: $0.hasBlockBody
                            )
                        },
                        macroDefinitions: analysis.manifest.macroDefinitions.map {
                            AnalyzeMacroSignaturePayload(
                                name: $0.name,
                                parameters: $0.parameters.map {
                                    AnalyzeMacroParameterPayload(
                                        name: $0.name,
                                        hasDefault: $0.hasDefault,
                                        defaultValueDescription: $0.defaultValueDescription
                                    )
                                },
                                slots: $0.slots.map {
                                    AnalyzeMacroSlotPayload(
                                        name: $0.name,
                                        hasFallback: $0.hasFallback
                                    )
                                }
                            )
                        },
                        macroImports: analysis.manifest.macroImports.map {
                            AnalyzeMacroImportPayload(
                                template: $0.template,
                                namespace: $0.namespace,
                                importedMacros: $0.importedMacros
                            )
                        },
                        referencedTemplates: analysis.manifest.referencedTemplates,
                        requiredVariables: analysis.manifest.requiredVariables,
                        requiresExtendedProfile: analysis.manifest.requiresExtendedProfile,
                        usesInheritance: analysis.manifest.usesInheritance
                    ),
                    missingRequiredInputs: analysis.missingRequiredInputs,
                    macroDiagnostics: analysis.macroDiagnostics,
                    qualityScore: analysis.qualityScore,
                    recommendations: analysis.recommendations,
                    securityIssues: analysis.securityIssues.map {
                        AnalyzeSecurityIssuePayload(
                            type: $0.type,
                            severity: $0.severity,
                            description: $0.description,
                            location: $0.location
                        )
                    },
                    tagCount: analysis.tagCount,
                    validationErrors: analysis.validationErrors,
                    variableCount: analysis.variableCount,
                    warnings: analysis.warnings
                )
            )
        )
    }

    private func handleValidate(
        _ request: Request,
        context: BasicRequestContext
    ) async throws -> Response {
        let requestBody = try await request.decode(as: TemplateRequest.self, context: context)
        let validation = try await self.serviceManager.validateTemplate(
            requestBody.template,
            context: requestBody.context
        )

        let errors = validation.errors.map { error in
            [
                "column": error.column,
                "line": error.line,
                "message": error.message,
                "severity": error.severity.rawValue,
            ] as [String: Any]
        }

        return try self.jsonResponse([
            "errors": errors,
            "success": true,
            "valid": validation.isValid,
            "warnings": validation.warnings.map(\.message),
        ])
    }

    private func handleRenderDocx(
        _ request: Request,
        context: BasicRequestContext
    ) async throws -> Response {
        let requestBody = try await request.decode(as: DocxRenderRequest.self, context: context)

        guard let docxData = Data(base64Encoded: requestBody.docxData) else {
            throw HTTPError(.badRequest, message: "Invalid base64 encoded DOCX data")
        }

        do {
            let result = try await self.serviceManager.processDocxTemplate(
                docxData,
                context: requestBody.context,
                options: ProcessingOptions(
                    clientIP: self.getClientIP(request),
                    timeout: requestBody.options?.timeout ?? 30.0
                )
            )

            return try self.encode(
                DocxRenderSuccessResponse(
                    success: true,
                    docxData: result.docxData.base64EncodedString(),
                    analysis: DocxAnalysisPayload(
                        partDiagnostics: result.analysis.partDiagnostics.map {
                            DocxPartDiagnosticPayload(
                                path: $0.path,
                                referencedVariables: $0.referencedVariables,
                                referencedTemplates: $0.referencedTemplates,
                                warnings: $0.warnings,
                                unresolvedPlaceholders: $0.unresolvedPlaceholders,
                                unsupportedConstructs: $0.unsupportedConstructs
                            )
                        },
                        referencedTemplates: result.analysis.referencedTemplates,
                        referencedVariables: result.analysis.referencedVariables,
                        supportedParts: result.analysis.supportedParts,
                        unsupportedParts: result.analysis.unsupportedParts,
                        coverageSummary: DocxCoverageSummaryPayload(
                            trustedSubsetVersion: result.analysis.coverageSummary.trustedSubsetVersion,
                            structuredSupportedParts: result.analysis.coverageSummary.structuredSupportedParts,
                            supportedPartCount: result.analysis.coverageSummary.supportedPartCount,
                            unsupportedPartCount: result.analysis.coverageSummary.unsupportedPartCount,
                            preservesUnsupportedParts: result.analysis.coverageSummary.preservesUnsupportedParts,
                            unsupportedConstructBehavior: result.analysis.coverageSummary.unsupportedConstructBehavior
                        )
                    ),
                    processingTime: result.processingTime,
                    warnings: result.warnings,
                    errors: result.errors
                )
            )
        } catch {
            self.logger.error("DOCX processing failed: \(error)")
            return try self.jsonResponse([
                "error": "DOCX processing failed: \(error.localizedDescription)",
                "success": false,
            ])
        }
    }

    private func handleBatch(
        _ request: Request,
        context: BasicRequestContext
    ) async throws -> Response {
        let requestBody = try await request.decode(as: BatchRequest.self, context: context)

        let requests = requestBody.templates.map { template in
            BatchProcessingRequest(
                template: template.template,
                context: template.context,
                timeout: template.timeout
            )
        }

        do {
            let result = try await self.serviceManager.batchProcess(
                requests,
                options: BatchProcessingOptions(
                    concurrent: requestBody.options?.concurrent ?? true,
                    maxConcurrency: requestBody.options?.maxConcurrency ?? 4,
                    clientIP: self.getClientIP(request)
                )
            )

            return try self.jsonResponse([
                "error_count": result.errorCount,
                "processing_time": result.processingTime,
                "results": result.results.map { item in
                    [
                        "error": item.error.map { $0 as Any } ?? NSNull(),
                        "index": item.index,
                        "output": item.output.map { $0 as Any } ?? NSNull(),
                        "success": item.success,
                    ]
                },
                "success": true,
                "success_count": result.successCount,
                "total_items": result.totalItems,
            ])
        } catch {
            self.logger.error("Batch processing failed: \(error)")
            return try self.jsonResponse([
                "error": "Batch processing failed: \(error.localizedDescription)",
                "success": false,
            ])
        }
    }

    private func handleRenderJob(
        _ request: Request,
        context: BasicRequestContext
    ) async throws -> Response {
        let requestBody = try await request.decode(as: RenderRequest.self, context: context)
        let handle = try await self.serviceManager.submitRenderJob(
            template: requestBody.template,
            context: requestBody.context,
            options: ProcessingOptions(
                clientIP: self.getClientIP(request),
                timeout: requestBody.options?.timeout ?? 30.0,
                includeMetrics: requestBody.options?.includeMetrics ?? true
            )
        )
        return try self.encode(handle)
    }

    private func handleRenderDocxJob(
        _ request: Request,
        context: BasicRequestContext
    ) async throws -> Response {
        let requestBody = try await request.decode(as: DocxRenderRequest.self, context: context)

        guard let docxData = Data(base64Encoded: requestBody.docxData) else {
            throw HTTPError(.badRequest, message: "Invalid base64 encoded DOCX data")
        }

        let handle = try await self.serviceManager.submitDocxRenderJob(
            docxData: docxData,
            context: requestBody.context,
            options: ProcessingOptions(
                clientIP: self.getClientIP(request),
                timeout: requestBody.options?.timeout ?? 30.0
            )
        )
        return try self.encode(handle)
    }

    private func handleBatchJob(
        _ request: Request,
        context: BasicRequestContext
    ) async throws -> Response {
        let requestBody = try await request.decode(as: BatchRequest.self, context: context)

        let requests = requestBody.templates.map { template in
            BatchProcessingRequest(
                template: template.template,
                context: template.context,
                timeout: template.timeout
            )
        }

        let handle = try await self.serviceManager.submitBatchJob(
            requests,
            options: BatchProcessingOptions(
                concurrent: requestBody.options?.concurrent ?? true,
                maxConcurrency: requestBody.options?.maxConcurrency ?? 4,
                clientIP: self.getClientIP(request)
            )
        )

        return try self.encode(handle)
    }

    private func handleJobLookup(_ request: Request) async throws -> Response {
        guard let jobID = self.jobID(from: request) else {
            throw HTTPError(.badRequest, message: "Missing or invalid 'id' query parameter")
        }

        guard let handle = await self.serviceManager.job(id: jobID) else {
            throw HTTPError(.notFound, message: "Job not found")
        }

        return try self.encode(handle)
    }

    private func handleJobCancel(_ request: Request) async throws -> Response {
        guard let jobID = self.jobID(from: request) else {
            throw HTTPError(.badRequest, message: "Missing or invalid 'id' query parameter")
        }

        guard let handle = await self.serviceManager.cancelJob(id: jobID) else {
            throw HTTPError(.notFound, message: "Job not found")
        }

        return try self.encode(handle)
    }

    private func jobID(from request: Request) -> UUID? {
        guard let query = request.uri.query else {
            return nil
        }

        let components = query.split(separator: "&")
        for component in components {
            let pieces = component.split(separator: "=", maxSplits: 1)
            guard pieces.count == 2 else {
                continue
            }
            if pieces[0] == "id" {
                return UUID(uuidString: String(pieces[1]))
            }
        }

        return nil
    }

    // MARK: - Pipeline Handlers

    private func handlePipeline(_ request: Request, context: some RequestContext) async throws -> Response {
        let definition = try await self.decodePipelineDefinition(request)
        let result = try await self.serviceManager.executePipeline(definition)
        return try self.jsonResponse([
            "success": true,
            "pipeline_id": result.pipelineId,
            "stage_results": result.stageResults.map { stage in
                [
                    "stage_id": stage.stageId,
                    "success": stage.success,
                    "output": stage.output as Any,
                    "error": stage.error as Any,
                    "processing_time": stage.processingTime,
                    "skipped": stage.skipped,
                ] as [String: Any]
            },
            "total_processing_time": result.totalProcessingTime,
            "audit_trail_count": result.auditTrail.count,
        ])
    }

    private func handlePipelineJob(_ request: Request, context: some RequestContext) async throws -> Response {
        let definition = try await self.decodePipelineDefinition(request)
        let handle = await self.serviceManager.submitPipelineJob(definition)
        return try self.encode(handle)
    }

    private func decodePipelineDefinition(_ request: Request) async throws -> PipelineDefinition {
        let body = try await request.body.collect(upTo: 10 * 1024 * 1024)
        let decoder = JSONDecoder()
        return try decoder.decode(PipelineDefinition.self, from: body)
    }

    // MARK: - Audit Handlers

    private func handleAuditQuery(_ request: Request) async throws -> Response {
        let entries = await self.serviceManager.auditStore.recentEntries(limit: 100)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(entries)
        let jsonString = String(data: data, encoding: .utf8) ?? "[]"
        return try self.jsonResponse(["success": true, "entries_count": entries.count, "entries_json": jsonString])
    }

    private func handleConfigureResponse() throws -> Response {
        try self.jsonResponse([
            "message": "Configuration updated successfully",
            "success": true,
        ])
    }

    private func handleMetricsResponse() throws -> Response {
        try self.jsonResponse(self.buildMetricsPayload())
    }

    private func buildMetricsPayload() -> [String: Any] {
        let metrics = self.serviceManager.metrics
        let recentActivity = self.serviceManager.recentActivity

        return [
            "active_connections": self.activeConnections,
            "average_render_time": metrics.averageRenderTime,
            "cache_hit_rate": metrics.cacheHitRate,
            "cpu_usage": metrics.cpuUsage,
            "error_rate": metrics.errorRate,
            "memory_usage": metrics.memoryUsage,
            "queue_depth": self.queueDepth,
            "recent_activity": recentActivity.prefix(10).map { activity in
                [
                    "client_ip": activity.clientIP ?? "unknown",
                    "render_time": activity.renderTime,
                    "status": activity.status.rawValue,
                    "timestamp": activity.timestamp.timeIntervalSince1970,
                ] as [String: Any]
            },
            "requests_today": metrics.requestsToday,
            "total_requests": metrics.totalRequests,
            "uptime": metrics.uptime,
        ]
    }

    private func encode<T: Encodable>(_ value: T) throws -> Response {
        let data = try JSONEncoder().encode(value)
        return self.response(with: data)
    }

    private func jsonResponse(
        _ payload: [String: Any],
        status: HTTPResponse.Status = .ok
    ) throws -> Response {
        let data = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
        return self.response(with: data, status: status)
    }

    private func response(
        with data: Data,
        status: HTTPResponse.Status = .ok
    ) -> Response {
        var buffer = ByteBufferAllocator().buffer(capacity: data.count)
        buffer.writeBytes(data)

        return Response(
            status: status,
            headers: [
                .contentLength: "\(data.count)",
                .contentType: "application/json; charset=utf-8",
            ],
            body: .init(byteBuffer: buffer)
        )
    }

    private func getClientIP(_ request: Request) -> String? {
        request.headers[.xForwardedFor]
            ?? request.headers[.xRealIP]
            ?? "127.0.0.1"
    }
}

struct TemplateRequest: Codable {
    let template: String
    let context: [String: Any]?

    init(template: String, context: [String: Any]? = nil) {
        self.template = template
        self.context = context
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.template = try container.decode(String.self, forKey: .template)
        if let values = try container.decodeIfPresent([String: JSONValue].self, forKey: .context) {
            self.context = JSONValue.decodeDictionary(values)
        } else {
            self.context = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.template, forKey: .template)
        if let context {
            try container.encode(JSONValue.encodeDictionary(context), forKey: .context)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case template
        case context
    }
}

struct RenderRequest: Codable {
    let template: String
    var context: [String: Any]
    let options: RenderOptions?

    init(template: String, context: [String: Any], options: RenderOptions?) {
        self.template = template
        self.context = context
        self.options = options
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.template = try container.decode(String.self, forKey: .template)
        self.options = try container.decodeIfPresent(RenderOptions.self, forKey: .options)
        let values = try container.decode([String: JSONValue].self, forKey: .context)
        self.context = JSONValue.decodeDictionary(values)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.template, forKey: .template)
        try container.encode(JSONValue.encodeDictionary(self.context), forKey: .context)
        try container.encodeIfPresent(self.options, forKey: .options)
    }

    private enum CodingKeys: String, CodingKey {
        case context
        case options
        case template
    }
}

struct RenderOptions: Codable {
    let strictMode: Bool?
    let autoEscape: Bool?
    let includeMetrics: Bool?
    let timeout: Double?

    init(
        strictMode: Bool? = nil,
        autoEscape: Bool? = nil,
        includeMetrics: Bool? = nil,
        timeout: Double? = nil
    ) {
        self.strictMode = strictMode
        self.autoEscape = autoEscape
        self.includeMetrics = includeMetrics
        self.timeout = timeout
    }
}

struct RenderSuccessResponse: Codable {
    let success: Bool
    let output: String
    let metrics: ResponseMetrics
    let warnings: [String]
    let errors: [String]
}

struct RenderErrorResponse: Codable {
    let success: Bool
    let error: String
}

struct AnalyzeSuccessResponse: Codable {
    let success: Bool
    let analysis: AnalyzeResponsePayload
}

struct AnalyzeResponsePayload: Codable {
    let complexity: String
    let estimatedRenderTime: TimeInterval
    let filterCount: Int
    let manifest: AnalyzeManifestPayload
    let missingRequiredInputs: [String]
    let macroDiagnostics: [String]
    let qualityScore: Double
    let recommendations: [String]
    let securityIssues: [AnalyzeSecurityIssuePayload]
    let tagCount: Int
    let validationErrors: [String]
    let variableCount: Int
    let warnings: [String]

    private enum CodingKeys: String, CodingKey {
        case complexity
        case estimatedRenderTime = "estimated_render_time"
        case filterCount = "filter_count"
        case manifest
        case missingRequiredInputs = "missing_required_inputs"
        case macroDiagnostics = "macro_diagnostics"
        case qualityScore = "quality_score"
        case recommendations
        case securityIssues = "security_issues"
        case tagCount = "tag_count"
        case validationErrors = "validation_errors"
        case variableCount = "variable_count"
        case warnings
    }
}

struct AnalyzeManifestPayload: Codable {
    let activeFilters: [String]
    let activeTags: [String]
    let contractDefaults: [String]
    let dataCapabilities: [String]
    let declaredInputs: [AnalyzeInputFieldPayload]
    let macroCalls: [AnalyzeMacroCallPayload]
    let macroDefinitions: [AnalyzeMacroSignaturePayload]
    let macroImports: [AnalyzeMacroImportPayload]
    let referencedTemplates: [String]
    let requiredVariables: [String]
    let requiresExtendedProfile: Bool
    let usesInheritance: Bool

    private enum CodingKeys: String, CodingKey {
        case activeFilters = "active_filters"
        case activeTags = "active_tags"
        case contractDefaults = "contract_defaults"
        case dataCapabilities = "data_capabilities"
        case declaredInputs = "declared_inputs"
        case macroCalls = "macro_calls"
        case macroDefinitions = "macro_definitions"
        case macroImports = "macro_imports"
        case referencedTemplates = "referenced_templates"
        case requiredVariables = "required_variables"
        case requiresExtendedProfile = "requires_extended_profile"
        case usesInheritance = "uses_inheritance"
    }
}

struct AnalyzeInputFieldPayload: Codable {
    let name: String
    let type: String
    let required: Bool
    let strict: Bool
    let defaultValueDescription: String?

    private enum CodingKeys: String, CodingKey {
        case name
        case type
        case required
        case strict
        case defaultValueDescription = "default_value_description"
    }
}

struct AnalyzeMacroSignaturePayload: Codable {
    let name: String
    let parameters: [AnalyzeMacroParameterPayload]
    let slots: [AnalyzeMacroSlotPayload]
}

struct AnalyzeMacroParameterPayload: Codable {
    let name: String
    let hasDefault: Bool
    let defaultValueDescription: String?

    private enum CodingKeys: String, CodingKey {
        case name
        case hasDefault = "has_default"
        case defaultValueDescription = "default_value_description"
    }
}

struct AnalyzeMacroSlotPayload: Codable {
    let name: String
    let hasFallback: Bool

    private enum CodingKeys: String, CodingKey {
        case name
        case hasFallback = "has_fallback"
    }
}

struct AnalyzeMacroImportPayload: Codable {
    let template: String
    let namespace: String?
    let importedMacros: [String]

    private enum CodingKeys: String, CodingKey {
        case template
        case namespace
        case importedMacros = "imported_macros"
    }
}

struct AnalyzeMacroCallPayload: Codable {
    let name: String
    let positionalArgumentCount: Int
    let namedArguments: [String]
    let filledSlots: [String]
    let hasBlockBody: Bool

    private enum CodingKeys: String, CodingKey {
        case name
        case positionalArgumentCount = "positional_argument_count"
        case namedArguments = "named_arguments"
        case filledSlots = "filled_slots"
        case hasBlockBody = "has_block_body"
    }
}

struct AnalyzeSecurityIssuePayload: Codable {
    let type: String
    let severity: String
    let description: String
    let location: String?
}

struct ResponseMetrics: Codable {
    let renderTime: TimeInterval
    let parseTime: TimeInterval
    let memoryUsed: Int
    let variablesProcessed: Int
    let filtersApplied: Int
    let cacheHit: Bool
}

struct DocxRenderSuccessResponse: Codable {
    let success: Bool
    let docxData: String
    let analysis: DocxAnalysisPayload
    let processingTime: TimeInterval
    let warnings: [String]
    let errors: [String]

    private enum CodingKeys: String, CodingKey {
        case success
        case docxData = "docx_data"
        case analysis
        case processingTime = "processing_time"
        case warnings
        case errors
    }
}

struct DocxAnalysisPayload: Codable {
    let partDiagnostics: [DocxPartDiagnosticPayload]
    let referencedTemplates: [String]
    let referencedVariables: [String]
    let supportedParts: [String]
    let unsupportedParts: [String]
    let coverageSummary: DocxCoverageSummaryPayload

    private enum CodingKeys: String, CodingKey {
        case partDiagnostics = "part_diagnostics"
        case referencedTemplates = "referenced_templates"
        case referencedVariables = "referenced_variables"
        case supportedParts = "supported_parts"
        case unsupportedParts = "unsupported_parts"
        case coverageSummary = "coverage_summary"
    }
}

struct DocxPartDiagnosticPayload: Codable {
    let path: String
    let referencedVariables: [String]
    let referencedTemplates: [String]
    let warnings: [String]
    let unresolvedPlaceholders: [String]
    let unsupportedConstructs: [String]

    private enum CodingKeys: String, CodingKey {
        case path
        case referencedVariables = "referenced_variables"
        case referencedTemplates = "referenced_templates"
        case warnings
        case unresolvedPlaceholders = "unresolved_placeholders"
        case unsupportedConstructs = "unsupported_constructs"
    }
}

struct DocxCoverageSummaryPayload: Codable {
    let trustedSubsetVersion: String
    let structuredSupportedParts: [String]
    let supportedPartCount: Int
    let unsupportedPartCount: Int
    let preservesUnsupportedParts: Bool
    let unsupportedConstructBehavior: String

    private enum CodingKeys: String, CodingKey {
        case trustedSubsetVersion = "trusted_subset_version"
        case structuredSupportedParts = "structured_supported_parts"
        case supportedPartCount = "supported_part_count"
        case unsupportedPartCount = "unsupported_part_count"
        case preservesUnsupportedParts = "preserves_unsupported_parts"
        case unsupportedConstructBehavior = "unsupported_construct_behavior"
    }
}

struct DocxRenderRequest: Codable {
    let docxData: String
    let context: [String: Any]
    let options: RenderOptions?

    init(docxData: String, context: [String: Any], options: RenderOptions?) {
        self.docxData = docxData
        self.context = context
        self.options = options
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.docxData = try container.decode(String.self, forKey: .docxData)
        self.options = try container.decodeIfPresent(RenderOptions.self, forKey: .options)
        let values = try container.decode([String: JSONValue].self, forKey: .context)
        self.context = JSONValue.decodeDictionary(values)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.docxData, forKey: .docxData)
        try container.encode(JSONValue.encodeDictionary(self.context), forKey: .context)
        try container.encodeIfPresent(self.options, forKey: .options)
    }

    private enum CodingKeys: String, CodingKey {
        case context
        case docxData = "docx_data"
        case options
    }
}

struct BatchRequest: Codable {
    let templates: [BatchTemplateRequest]
    let options: BatchRequestOptions?
}

struct BatchTemplateRequest: Codable {
    let template: String
    let context: [String: Any]
    let timeout: TimeInterval?

    init(template: String, context: [String: Any], timeout: TimeInterval?) {
        self.template = template
        self.context = context
        self.timeout = timeout
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.template = try container.decode(String.self, forKey: .template)
        self.timeout = try container.decodeIfPresent(TimeInterval.self, forKey: .timeout)
        let values = try container.decode([String: JSONValue].self, forKey: .context)
        self.context = JSONValue.decodeDictionary(values)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.template, forKey: .template)
        try container.encode(JSONValue.encodeDictionary(self.context), forKey: .context)
        try container.encodeIfPresent(self.timeout, forKey: .timeout)
    }

    private enum CodingKeys: String, CodingKey {
        case context
        case template
        case timeout
    }
}

struct BatchRequestOptions: Codable {
    let concurrent: Bool?
    let maxConcurrency: Int?

    init(concurrent: Bool? = nil, maxConcurrency: Int? = nil) {
        self.concurrent = concurrent
        self.maxConcurrency = maxConcurrency
    }
}

enum HTTPServiceError: Error, LocalizedError {
    case serverStartFailed(String)

    var errorDescription: String? {
        switch self {
        case .serverStartFailed(let reason):
            return "Server failed to start: \(reason)"
        }
    }
}

private actor StartupSignal {
    private enum State {
        case failure(Error)
        case pending(CheckedContinuation<Void, Error>?)
        case success
    }

    private var state: State = .pending(nil)

    func waitUntilStarted() async throws {
        switch self.state {
        case .success:
            return
        case .failure(let error):
            throw error
        case .pending:
            try await withCheckedThrowingContinuation { continuation in
                self.state = .pending(continuation)
            }
        }
    }

    func markStarted() {
        switch self.state {
        case .success, .failure:
            return
        case .pending(let continuation):
            self.state = .success
            continuation?.resume()
        }
    }

    func fail(_ error: Error) {
        switch self.state {
        case .success, .failure:
            return
        case .pending(let continuation):
            self.state = .failure(error)
            continuation?.resume(throwing: error)
        }
    }
}
