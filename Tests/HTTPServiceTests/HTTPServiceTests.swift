import Foundation
import XCTest
@testable import HTTPService
@testable import ServiceCore
import RhoeDOCX

@MainActor
final class HTTPServiceTests: XCTestCase {
    private var serviceManager: ServiceManager!
    private var httpService: HTTPService!
    private var configuration: ServiceConfiguration!

    override func setUp() async throws {
        self.configuration = ServiceConfiguration(
            httpPort: 15480,
            performanceMode: .development,
            storageDirectory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString),
            logLevel: .debug
        )
        self.serviceManager = ServiceManager(configuration: self.configuration)
        self.httpService = HTTPService(
            serviceManager: self.serviceManager,
            configuration: self.configuration
        )

        try await self.serviceManager.startService()
        try await self.httpService.start()
    }

    override func tearDown() async throws {
        await self.httpService.stop()
        await self.serviceManager.stopService()
        self.httpService = nil
        self.serviceManager = nil
        self.configuration = nil
    }

    func testHealthEndpoint() async throws {
        let response = try await self.request(path: "/health")

        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(response.json["status"] as? String, "healthy")
    }

    func testRenderEndpoint() async throws {
        let body = try JSONEncoder().encode(
            RenderRequest(
                template: "Hello {{ name }}!",
                context: ["name": "World"],
                options: RenderOptions(includeMetrics: true)
            )
        )

        let response = try await self.request(
            path: "/render",
            method: "POST",
            body: body
        )

        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(response.json["success"] as? Bool, true)
        XCTAssertEqual(response.json["output"] as? String, "Hello World!")
    }

    func testCapabilitiesAndSchemaEndpoints() async throws {
        let capabilities = try await self.request(path: "/capabilities")
        XCTAssertEqual(capabilities.statusCode, 200)
        XCTAssertEqual(capabilities.json["serviceVersion"] as? String, "0.1.0")
        XCTAssertEqual(capabilities.json["engineVersion"] as? String, "0.1.0")
        XCTAssertEqual(capabilities.json["schemaVersion"] as? String, "v1rc1")
        XCTAssertEqual(capabilities.json["profile"] as? String, "extended")
        XCTAssertEqual(capabilities.json["supportsAsyncJobs"] as? Bool, true)
        XCTAssertEqual(capabilities.json["supportsMacros"] as? Bool, true)
        XCTAssertEqual(capabilities.json["supportsInputContracts"] as? Bool, true)
        XCTAssertEqual(capabilities.json["supportsExpressionCallMacros"] as? Bool, true)
        XCTAssertEqual(capabilities.json["preferredExecution"] as? String, "service_authoritative")
        let jobKinds = try XCTUnwrap(capabilities.json["supportedJobKinds"] as? [String])
        XCTAssertTrue(jobKinds.contains("render_docx"))
        let docx = try XCTUnwrap(capabilities.json["docx"] as? [String: Any])
        let structuredParts = try XCTUnwrap(docx["supportedStructuredParts"] as? [String])
        XCTAssertTrue(structuredParts.contains("word/document.xml"))
        XCTAssertTrue(structuredParts.contains("word/comments.xml"))
        let coverageSummary = try XCTUnwrap(docx["coverageSummary"] as? [String: Any])
        XCTAssertEqual(coverageSummary["trustedSubsetVersion"] as? String, "trusted-docx-v1")

        let schema = try await self.request(path: "/schema")
        XCTAssertEqual(schema.statusCode, 200)
        let endpoints = try XCTUnwrap(schema.json["endpoints"] as? [[String: Any]])
        let components = try XCTUnwrap(schema.json["components"] as? [[String: Any]])
        XCTAssertTrue(endpoints.contains { ($0["path"] as? String) == "/capabilities" })
        XCTAssertTrue(endpoints.contains { ($0["path"] as? String) == "/jobs/render-docx" })
        XCTAssertTrue(components.contains { ($0["name"] as? String) == "ServiceCapabilities" })
    }

    func testAnalyzeEndpointIncludesWave17StructuralInputMetadata() async throws {
        let body = try JSONSerialization.data(withJSONObject: [
            "template": "{% input user.name: string %}{% input items[].title: string = \"Untitled\" %}{% macro greeting(name) %}Hello {{ name }}{% endmacro %}{{ greeting(name: user.name) }}",
            "context": [:]
        ])

        let response = try await self.request(
            path: "/analyze",
            method: "POST",
            body: body
        )

        XCTAssertEqual(response.statusCode, 200)
        let analysis = try XCTUnwrap(response.json["analysis"] as? [String: Any])
        let manifest = try XCTUnwrap(analysis["manifest"] as? [String: Any])
        let declaredInputs = try XCTUnwrap(manifest["declared_inputs"] as? [[String: Any]])
        XCTAssertEqual(
            declaredInputs.compactMap { $0["name"] as? String }.sorted(),
            ["items[].title", "user.name"]
        )
        XCTAssertEqual(manifest["contract_defaults"] as? [String], ["items[].title"])
        let macroDefinitions = try XCTUnwrap(manifest["macro_definitions"] as? [[String: Any]])
        XCTAssertEqual(macroDefinitions.first?["name"] as? String, "greeting")
        let macroCalls = try XCTUnwrap(manifest["macro_calls"] as? [[String: Any]])
        XCTAssertEqual(macroCalls.first?["name"] as? String, "greeting")
        XCTAssertEqual(analysis["missing_required_inputs"] as? [String], ["user.name"])
    }

    func testAnalyzeEndpointReportsIndexedMissingArrayPaths() async throws {
        let body = try JSONSerialization.data(withJSONObject: [
            "template": "{% input items[].title: string %}",
            "context": [
                "items": [
                    ["title": "Ready"],
                    [:]
                ]
            ]
        ])

        let response = try await self.request(
            path: "/analyze",
            method: "POST",
            body: body
        )

        XCTAssertEqual(response.statusCode, 200)
        let analysis = try XCTUnwrap(response.json["analysis"] as? [String: Any])
        XCTAssertEqual(analysis["missing_required_inputs"] as? [String], ["items[1].title"])
    }

    func testAnalyzeEndpointReportsIndexedTypeMismatchPaths() async throws {
        let body = try JSONSerialization.data(withJSONObject: [
            "template": "{% input items[].title: string %}",
            "context": [
                "items": [
                    ["title": "Ready"],
                    ["title": 7]
                ]
            ]
        ])

        let response = try await self.request(
            path: "/analyze",
            method: "POST",
            body: body
        )

        XCTAssertEqual(response.statusCode, 200)
        let analysis = try XCTUnwrap(response.json["analysis"] as? [String: Any])
        let validationErrors = try XCTUnwrap(analysis["validation_errors"] as? [String])
        XCTAssertTrue(validationErrors.contains("Input 'items[1].title' expected string but received number."))
    }

    func testAnalyzeEndpointIncludesStrictInputMetadataAndErrors() async throws {
        let body = try JSONSerialization.data(withJSONObject: [
            "template": "{% input user: object strict %}{% input user.name: string %}",
            "context": [
                "user": [
                    "name": "Ada",
                    "role": "admin"
                ]
            ]
        ])

        let response = try await self.request(
            path: "/analyze",
            method: "POST",
            body: body
        )

        XCTAssertEqual(response.statusCode, 200)
        let analysis = try XCTUnwrap(response.json["analysis"] as? [String: Any])
        let manifest = try XCTUnwrap(analysis["manifest"] as? [String: Any])
        let declaredInputs = try XCTUnwrap(manifest["declared_inputs"] as? [[String: Any]])
        XCTAssertTrue(declaredInputs.contains {
            ($0["name"] as? String) == "user" && ($0["strict"] as? Bool) == true
        })
        let validationErrors = try XCTUnwrap(analysis["validation_errors"] as? [String])
        XCTAssertTrue(validationErrors.contains("Input 'user.role' is not declared by strict contract 'user'."))
    }

    func testValidateEndpointReportsStrictObjectContractErrors() async throws {
        let body = try JSONSerialization.data(withJSONObject: [
            "template": "{% input user: object strict %}{% input user.name: string %}",
            "context": [
                "user": [
                    "name": "Ada",
                    "role": "admin"
                ]
            ]
        ])

        let response = try await self.request(
            path: "/validate",
            method: "POST",
            body: body
        )

        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(response.json["valid"] as? Bool, false)
        let errors = try XCTUnwrap(response.json["errors"] as? [[String: Any]])
        XCTAssertTrue(errors.contains { ($0["message"] as? String)?.contains("Input 'user.role' is not declared by strict contract 'user'.") == true })
    }

    func testAnalyzeEndpointIncludesWave17MacroSlotDiagnostics() async throws {
        let body = try JSONSerialization.data(withJSONObject: [
            "template": """
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
        ])

        let response = try await self.request(
            path: "/analyze",
            method: "POST",
            body: body
        )

        XCTAssertEqual(response.statusCode, 200)
        let analysis = try XCTUnwrap(response.json["analysis"] as? [String: Any])
        let manifest = try XCTUnwrap(analysis["manifest"] as? [String: Any])
        let macroDefinitions = try XCTUnwrap(manifest["macro_definitions"] as? [[String: Any]])
        let slots = try XCTUnwrap(macroDefinitions.first?["slots"] as? [[String: Any]])
        XCTAssertEqual(slots.compactMap { $0["name"] as? String }.sorted(), ["default", "footer"])
        XCTAssertTrue(slots.contains { ($0["name"] as? String) == "footer" && ($0["has_fallback"] as? Bool) == false })

        let macroCalls = try XCTUnwrap(manifest["macro_calls"] as? [[String: Any]])
        XCTAssertTrue(macroCalls.contains {
            ($0["name"] as? String) == "card"
                && ($0["has_block_body"] as? Bool) == true
                && (($0["filled_slots"] as? [String]) ?? []).isEmpty
        })
        XCTAssertTrue(macroCalls.contains {
            ($0["name"] as? String) == "card"
                && ($0["has_block_body"] as? Bool) == false
        })

        let macroDiagnostics = try XCTUnwrap(analysis["macro_diagnostics"] as? [String])
        XCTAssertTrue(macroDiagnostics.contains("Macro call 'card' leaves required slot 'footer' unresolved."))
        XCTAssertTrue(macroDiagnostics.contains("Expression-call macro 'card' cannot satisfy required slot 'footer'."))
    }

    func testValidateEndpointUsesContextForWave17PathBasedInputContracts() async throws {
        let body = try JSONSerialization.data(withJSONObject: [
            "template": "{% input user.name: string %}Hello {{ user.name }}",
            "context": ["user": [:]]
        ])

        let response = try await self.request(
            path: "/validate",
            method: "POST",
            body: body
        )

        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(response.json["valid"] as? Bool, false)
        let errors = try XCTUnwrap(response.json["errors"] as? [[String: Any]])
        XCTAssertTrue(errors.contains { ($0["message"] as? String)?.contains("Missing required input 'user.name'") == true })
    }

    func testValidateEndpointReportsIndexedMissingArrayPaths() async throws {
        let body = try JSONSerialization.data(withJSONObject: [
            "template": "{% input items[].title: string %}",
            "context": [
                "items": [
                    ["title": "Ready"],
                    [:]
                ]
            ]
        ])

        let response = try await self.request(
            path: "/validate",
            method: "POST",
            body: body
        )

        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(response.json["valid"] as? Bool, false)
        let errors = try XCTUnwrap(response.json["errors"] as? [[String: Any]])
        XCTAssertTrue(errors.contains { ($0["message"] as? String)?.contains("Missing required input 'items[1].title'") == true })
    }

    func testValidateEndpointReportsIndexedTypeMismatchPaths() async throws {
        let body = try JSONSerialization.data(withJSONObject: [
            "template": "{% input items[].title: string %}",
            "context": [
                "items": [
                    ["title": "Ready"],
                    ["title": 7]
                ]
            ]
        ])

        let response = try await self.request(
            path: "/validate",
            method: "POST",
            body: body
        )

        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(response.json["valid"] as? Bool, false)
        let errors = try XCTUnwrap(response.json["errors"] as? [[String: Any]])
        XCTAssertTrue(errors.contains { ($0["message"] as? String)?.contains("Input 'items[1].title' expected string but received number.") == true })
    }

    func testValidateEndpointReportsStaticWave17BlockCallErrors() async throws {
        let body = try JSONSerialization.data(withJSONObject: [
            "template": """
            {% macro card(title) %}
            <article>
              <h1>{{ title }}</h1>
              {% slot footer %}Footer{% endslot %}
            </article>
            {% endmacro %}
            {% call card(title: "Wave 17") %}
            Body
            {% fill aside %}Oops{% endfill %}
            {% endcall %}
            """
        ])

        let response = try await self.request(
            path: "/validate",
            method: "POST",
            body: body
        )

        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(response.json["valid"] as? Bool, false)
        let errors = try XCTUnwrap(response.json["errors"] as? [[String: Any]])
        XCTAssertTrue(errors.contains { ($0["message"] as? String)?.contains("Macro card does not declare a default slot") == true })
        XCTAssertTrue(errors.contains { ($0["message"] as? String)?.contains("Unknown fill 'aside' for macro card") == true })
    }

    func testAsyncRenderJobEndpointCompletes() async throws {
        let body = try JSONSerialization.data(withJSONObject: [
            "template": "Hello {{ name | upcase }}!",
            "context": ["name": "word"]
        ])

        let response = try await self.request(
            path: "/jobs/render",
            method: "POST",
            body: body
        )

        XCTAssertEqual(response.statusCode, 200)
        let id = try XCTUnwrap(response.json["id"] as? String)

        let completed = try await self.awaitJob(id: id)
        XCTAssertEqual(completed["status"] as? String, "completed")
        XCTAssertNotNil(completed["expiresAt"])
        XCTAssertNotNil(completed["progress"])
        let payload = try XCTUnwrap(completed["payload"] as? [String: Any])
        XCTAssertEqual(payload["output"] as? String, "Hello WORD!")
    }

    func testRenderDocxEndpointReturnsAnalysis() async throws {
        let fixture = try await Self.makeMinimalDOCX(templateText: "Hello {{ name }}")
        let body = try JSONSerialization.data(withJSONObject: [
            "docx_data": fixture.base64EncodedString(),
            "context": ["name": "Service"]
        ])

        let response = try await self.request(
            path: "/render-docx",
            method: "POST",
            body: body
        )

        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(response.json["success"] as? Bool, true)

        let analysis = try XCTUnwrap(response.json["analysis"] as? [String: Any])
        let variables = try XCTUnwrap(analysis["referenced_variables"] as? [String])
        XCTAssertTrue(variables.contains("name"))
        let coverage = try XCTUnwrap(analysis["coverage_summary"] as? [String: Any])
        XCTAssertEqual(coverage["trusted_subset_version"] as? String, "trusted-docx-v1")
        let partDiagnostics = try XCTUnwrap(analysis["part_diagnostics"] as? [[String: Any]])
        let documentDiagnostic = try XCTUnwrap(partDiagnostics.first { ($0["path"] as? String) == "word/document.xml" })
        XCTAssertEqual(documentDiagnostic["unsupported_constructs"] as? [String], [])

        let encodedDOCX = try XCTUnwrap(response.json["docx_data"] as? String)
        let renderedData = try XCTUnwrap(Data(base64Encoded: encodedDOCX))
        let xml = try await Self.extractDocumentXML(from: renderedData)
        XCTAssertTrue(xml.contains("Hello Service"))
        XCTAssertFalse(xml.contains("{{ name }}"))
    }

    private func request(
        path: String,
        method: String = "GET",
        body: Data? = nil
    ) async throws -> (statusCode: Int, json: [String: Any]) {
        var request = URLRequest(url: URL(string: "http://127.0.0.1:\(self.configuration.httpPort)\(path)")!)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = try XCTUnwrap(response as? HTTPURLResponse)
        let json = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        return (httpResponse.statusCode, json)
    }

    private func awaitJob(id: String) async throws -> [String: Any] {
        let timeout = Date().addingTimeInterval(2.0)

        while Date() < timeout {
            let response = try await self.request(path: "/jobs?id=\(id)")
            if let status = response.json["status"] as? String,
               ["completed", "failed", "cancelled"].contains(status) {
                return response.json
            }
            try await Task.sleep(nanoseconds: 20_000_000)
        }

        XCTFail("Timed out waiting for job \(id)")
        throw CancellationError()
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
