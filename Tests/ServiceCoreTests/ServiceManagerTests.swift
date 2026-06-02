import XCTest
@testable import ServiceCore
import RhoeDOCX

@MainActor
final class ServiceManagerTests: XCTestCase {
    func testLifecycleAndRendering() async throws {
        let manager = ServiceManager(configuration: self.makeConfiguration())

        try await manager.startService()
        defer { Task { await manager.stopService() } }

        XCTAssertEqual(manager.status, .active)

        let result = try await manager.processTemplate(
            "Hello {{ name }}!",
            context: ["name": "World"]
        )

        XCTAssertEqual(result.output, "Hello World!")
        XCTAssertGreaterThan(result.metrics.renderTime, 0)

        await manager.stopService()
        XCTAssertEqual(manager.status, .stopped)
    }

    func testValidationAndAnalysis() async throws {
        let manager = ServiceManager(configuration: self.makeConfiguration())

        try await manager.startService()
        defer { Task { await manager.stopService() } }

        let analysis = try await manager.analyzeTemplate("{{ name | upcase }}")
        XCTAssertGreaterThanOrEqual(analysis.variableCount, 1)

        let validation = try await manager.validateTemplate("{{ name }}")
        XCTAssertTrue(validation.isValid)
        XCTAssertTrue(validation.errors.isEmpty)
    }

    func testProcessingUpdatesMetricsAndActivity() async throws {
        let manager = ServiceManager(configuration: self.makeConfiguration())

        try await manager.startService()
        defer { Task { await manager.stopService() } }

        _ = try await manager.processTemplate(
            "{% for item in items %}{{ item }}{% endfor %}",
            context: ["items": ["A", "B", "C"]]
        )

        XCTAssertFalse(manager.recentActivity.isEmpty)
        XCTAssertEqual(manager.recentActivity.last?.status, .success)
    }

    func testServiceCapabilitiesAndSchema() async throws {
        let manager = ServiceManager(configuration: self.makeConfiguration())

        try await manager.startService()
        defer { Task { await manager.stopService() } }

        let capabilities = try await manager.serviceCapabilities()
        XCTAssertEqual(capabilities.serviceVersion, "0.1.0")
        XCTAssertEqual(capabilities.engineVersion, "0.1.0")
        XCTAssertEqual(capabilities.schemaVersion, "v1rc1")
        XCTAssertEqual(capabilities.profile, .extended)
        XCTAssertEqual(capabilities.sandboxPolicy.name, "service_safe")
        XCTAssertTrue(capabilities.supportsAnalysis)
        XCTAssertTrue(capabilities.supportsValidation)
        XCTAssertTrue(capabilities.supportsAsyncJobs)
        XCTAssertEqual(capabilities.preferredExecution, .serviceAuthoritative)
        XCTAssertTrue(capabilities.supportsMacros)
        XCTAssertTrue(capabilities.supportsInputContracts)
        XCTAssertTrue(capabilities.supportsExpressionCallMacros)
        XCTAssertTrue(capabilities.supportedJobKinds.contains(.renderDocx))
        XCTAssertTrue(capabilities.docx.supportedStructuredParts.contains("word/document.xml"))
        XCTAssertTrue(capabilities.docx.supportedStructuredParts.contains("word/comments.xml"))
        XCTAssertTrue(capabilities.docx.preservesUnsupportedParts)
        XCTAssertEqual(capabilities.docx.coverageSummary.trustedSubsetVersion, "trusted-docx-v1")

        let schema = manager.serviceSchema()
        XCTAssertEqual(schema.version, "v1rc1")
        XCTAssertTrue(schema.endpoints.contains { $0.path == "/capabilities" && $0.method == "GET" })
        XCTAssertTrue(schema.endpoints.contains { $0.path == "/schema" && $0.method == "GET" })
        XCTAssertTrue(schema.endpoints.contains { $0.path == "/jobs/render-docx" && $0.method == "POST" })
        XCTAssertTrue(schema.components.contains { $0.name == "ServiceCapabilities" && $0.kind == .response })
    }

    func testAnalysisAndValidationSurfacePathBasedInputContractsWithContext() async throws {
        let manager = ServiceManager(configuration: self.makeConfiguration())

        try await manager.startService()
        defer { Task { await manager.stopService() } }

        let template = """
        {% input user.name: string %}
        {% input items[].title: string = "Untitled" %}
        {% macro greeting(name) %}Hello {{ name }}{% endmacro %}
        {{ greeting(name: user.name) }}
        """

        let analysisWithoutContext = try await manager.analyzeTemplate(template)
        XCTAssertTrue(analysisWithoutContext.manifest.requiresExtendedProfile)
        XCTAssertEqual(
            analysisWithoutContext.inputContract.fields.map(\.name),
            ["items[].title", "user.name"]
        )
        XCTAssertEqual(analysisWithoutContext.manifest.contractDefaults, ["items[].title"])
        XCTAssertTrue(analysisWithoutContext.manifest.macroDefinitions.contains { $0.name == "greeting" })
        XCTAssertTrue(analysisWithoutContext.manifest.macroCalls.contains { $0.name == "greeting" })
        XCTAssertTrue(analysisWithoutContext.missingRequiredInputs.isEmpty)

        let analysisWithMissingInput = try await manager.analyzeTemplate(template, context: [:])
        XCTAssertEqual(analysisWithMissingInput.missingRequiredInputs, ["user.name"])

        let validationWithMissingInput = try await manager.validateTemplate(template, context: [:])
        XCTAssertFalse(validationWithMissingInput.isValid)
        XCTAssertTrue(validationWithMissingInput.errors.contains { $0.message.contains("Missing required input 'user.name'") })
    }

    func testAnalysisAndValidationSurfaceIndexedMissingArrayContractPaths() async throws {
        let manager = ServiceManager(configuration: self.makeConfiguration())

        try await manager.startService()
        defer { Task { await manager.stopService() } }

        let template = """
        {% input items[].title: string %}
        """
        let context: [String: Any] = [
            "items": [
                ["title": "Ready"],
                [:]
            ]
        ]

        let analysis = try await manager.analyzeTemplate(template, context: context)
        XCTAssertEqual(analysis.missingRequiredInputs, ["items[1].title"])

        let validation = try await manager.validateTemplate(template, context: context)
        XCTAssertFalse(validation.isValid)
        XCTAssertTrue(validation.errors.contains { $0.message.contains("Missing required input 'items[1].title'") })
    }

    func testAnalysisAndValidationSurfaceIndexedTypeMismatchPaths() async throws {
        let manager = ServiceManager(configuration: self.makeConfiguration())

        try await manager.startService()
        defer { Task { await manager.stopService() } }

        let template = """
        {% input items[].title: string %}
        """
        let context: [String: Any] = [
            "items": [
                ["title": "Ready"],
                ["title": 7]
            ]
        ]

        let analysis = try await manager.analyzeTemplate(template, context: context)
        XCTAssertTrue(analysis.missingRequiredInputs.isEmpty)
        XCTAssertTrue(analysis.validationErrors.contains("Input 'items[1].title' expected string but received number."))

        let validation = try await manager.validateTemplate(template, context: context)
        XCTAssertFalse(validation.isValid)
        XCTAssertTrue(validation.errors.contains { $0.message.contains("Input 'items[1].title' expected string but received number.") })
    }

    func testAnalysisAndValidationSurfaceStrictObjectContracts() async throws {
        let manager = ServiceManager(configuration: self.makeConfiguration())

        try await manager.startService()
        defer { Task { await manager.stopService() } }

        let template = """
        {% input user: object strict %}
        {% input user.name: string %}
        """
        let context: [String: Any] = [
            "user": [
                "name": "Ada",
                "role": "admin"
            ]
        ]

        let analysis = try await manager.analyzeTemplate(template, context: context)
        XCTAssertTrue(analysis.inputContract.fields.contains { $0.name == "user" && $0.strict })
        XCTAssertTrue(analysis.validationErrors.contains("Input 'user.role' is not declared by strict contract 'user'."))

        let validation = try await manager.validateTemplate(template, context: context)
        XCTAssertFalse(validation.isValid)
        XCTAssertTrue(validation.errors.contains { $0.message.contains("Input 'user.role' is not declared by strict contract 'user'.") })
    }

    func testAnalysisSurfacesWave17MacroDiagnostics() async throws {
        let manager = ServiceManager(configuration: self.makeConfiguration())

        try await manager.startService()
        defer { Task { await manager.stopService() } }

        let template = """
        {% input user.name: string = "Guest" %}
        {% macro card(title) %}
        <article>
          <h1>{{ title }}</h1>
          {% slot default %}Fallback{% endslot %}
          {% slot footer %}{% endslot %}
        </article>
        {% endmacro %}
        {% call card(title: user.name) %}Body{% endcall %}
        {{ card(title: user.name) }}
        """

        let analysis = try await manager.analyzeTemplate(template)
        XCTAssertTrue(analysis.manifest.macroDefinitions.contains { $0.name == "card" && $0.slots.map(\.name) == ["default", "footer"] })
        XCTAssertTrue(analysis.manifest.macroCalls.contains { $0.name == "card" && $0.hasBlockBody })
        XCTAssertTrue(analysis.macroDiagnostics.contains("Macro call 'card' leaves required slot 'footer' unresolved."))
        XCTAssertTrue(analysis.macroDiagnostics.contains("Expression-call macro 'card' cannot satisfy required slot 'footer'."))
    }

    func testAsyncRenderJobCompletesWithTemplateAnalysis() async throws {
        let manager = ServiceManager(configuration: self.makeConfiguration())

        try await manager.startService()
        defer { Task { await manager.stopService() } }

        let handle = try await manager.submitRenderJob(
            template: "Hello {{ name | upcase }}!",
            context: ["name": "World"]
        )

        XCTAssertEqual(handle.kind, .render)
        XCTAssertEqual(handle.status, .queued)

        let completed = try await self.awaitJob(handle.id, using: manager)
        XCTAssertEqual(completed.status, .completed)
        XCTAssertEqual(completed.payload?.output, "Hello WORLD!")
        XCTAssertTrue(completed.diagnostics.templateAnalysis?.manifest.requiredVariables.contains("name") ?? false)
        XCTAssertTrue(completed.diagnostics.templateAnalysis?.manifest.activeFilters.contains("upcase") ?? false)
        XCTAssertGreaterThan(completed.expiresAt, completed.createdAt)
        XCTAssertEqual(completed.progress.currentStep, "Completed")
    }

    func testAsyncRenderJobRetainsWave17ValidationDiagnostics() async throws {
        let manager = ServiceManager(configuration: self.makeConfiguration())

        try await manager.startService()
        defer { Task { await manager.stopService() } }

        let handle = try await manager.submitRenderJob(
            template: "{% input user.name: string %}Hello {{ user.name }}",
            context: [:]
        )

        let completed = try await self.awaitJob(handle.id, using: manager)
        XCTAssertEqual(completed.status, .failed)
        XCTAssertEqual(completed.diagnostics.templateAnalysis?.missingRequiredInputs, ["user.name"])
        XCTAssertTrue(completed.diagnostics.errors.contains { $0.contains("Missing required input 'user.name'") })
    }

    func testDocxProcessingReturnsRenderedArchiveAndAnalysis() async throws {
        let manager = ServiceManager(configuration: self.makeConfiguration())

        try await manager.startService()
        defer { Task { await manager.stopService() } }

        let fixture = try await Self.makeMinimalDOCX(templateText: "Hello {{ name }}")
        let result = try await manager.processDocxTemplate(
            fixture,
            context: ["name": "Wave13"]
        )

        XCTAssertTrue(result.analysis.supportedParts.contains("word/document.xml"))
        XCTAssertTrue(result.analysis.referencedVariables.contains("name"))
        XCTAssertEqual(result.analysis.coverageSummary.trustedSubsetVersion, "trusted-docx-v1")
        XCTAssertTrue(result.errors.isEmpty)

        let xml = try await Self.extractDocumentXML(from: result.docxData)
        XCTAssertTrue(xml.contains("Hello Wave13"))
        XCTAssertFalse(xml.contains("{{ name }}"))
    }

    func testDurableJobStoreRecoversRunningJobAfterRestart() async throws {
        let storageDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = ServiceJobStore(storageDirectory: storageDirectory, retentionInterval: 3600)

        let created = await store.create(kind: .render)
        _ = await store.markRunning(
            id: created.id,
            progress: JobProgress(fractionCompleted: 0.5, currentStep: "Rendering", completedSteps: 0, totalSteps: 1)
        )

        let recoveredStore = ServiceJobStore(storageDirectory: storageDirectory, retentionInterval: 3600)
        let recovered = await recoveredStore.job(id: created.id)

        XCTAssertEqual(recovered?.status, .failed)
        XCTAssertEqual(recovered?.progress.currentStep, "Interrupted by service restart")
        XCTAssertEqual(recovered?.error, "Service restarted before the async job completed.")

        try? FileManager.default.removeItem(at: storageDirectory)
    }

    private func awaitJob(_ id: UUID, using manager: ServiceManager) async throws -> JobHandle {
        let timeout = Date().addingTimeInterval(2.0)

        while Date() < timeout {
            if let handle = await manager.job(id: id), handle.status.isTerminal {
                return handle
            }
            try await Task.sleep(nanoseconds: 20_000_000)
        }

        XCTFail("Timed out waiting for job \(id)")
        throw CancellationError()
    }

    private func makeConfiguration() -> ServiceConfiguration {
        ServiceConfiguration(
            httpPort: 13481,
            enableSecurity: false,
            performanceMode: .development,
            storageDirectory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString),
            logLevel: .debug
        )
    }

    private static func makeMinimalDOCX(templateText: String) async throws -> Data {
        let builder = ZIPBuilder()

        await builder.addFile(
            path: "[Content_Types].xml",
            data: Data(
                """
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
                  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
                  <Default Extension="xml" ContentType="application/xml"/>
                  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
                </Types>
                """.utf8
            ),
            compressionMethod: .stored
        )

        await builder.addFile(
            path: "_rels/.rels",
            data: Data(
                """
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
                  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
                </Relationships>
                """.utf8
            ),
            compressionMethod: .stored
        )

        await builder.addFile(
            path: "word/document.xml",
            data: Data(
                """
                <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
                <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
                  <w:body>
                    <w:p>
                      <w:r><w:t>\(templateText)</w:t></w:r>
                    </w:p>
                  </w:body>
                </w:document>
                """.utf8
            ),
            compressionMethod: .stored
        )

        return try await builder.build()
    }

    private static func extractDocumentXML(from docxData: Data) async throws -> String {
        let archive = ZIPArchive(data: docxData)
        let package = try await archive.open()
        let xmlData = try await package.extractData(for: "word/document.xml")
        return try XCTUnwrap(String(data: xmlData, encoding: .utf8))
    }
}
