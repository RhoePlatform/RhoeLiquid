import Foundation

public enum ServiceContractCatalog {
    public static let schemaVersion = "v1rc1"

    public static func schema() -> ServiceSchema {
        ServiceSchema(
            version: self.schemaVersion,
            endpoints: self.endpointDefinitions.map(\.endpoint),
            components: self.componentDefinitions
        )
    }

    public static func schemaData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self.schema())
    }

    public static func schemaJSON() throws -> String {
        let data = try self.schemaData()
        guard var json = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "ServiceContractCatalog", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to decode generated schema JSON."])
        }
        if !json.hasSuffix("\n") {
            json += "\n"
        }
        return json
    }

    public static func openAPIYAML(
        serviceVersion: String = "0.1.0",
        serverURL: String = "http://localhost:13480"
    ) -> String {
        var lines: [String] = [
            "openapi: 3.1.0",
            "info:",
            "  title: RhoeLiquid Native Service API",
            "  version: \(serviceVersion)",
            "  description: |",
            "    Localhost HTTP API for the active RhoeLiquid native service surface.",
            "    `/schema` is the canonical machine-readable contract and this OpenAPI file",
            "    is generated from the same v0.1.0 public release candidate contract catalog.",
            "servers:",
            "  - url: \(serverURL)",
            "    description: Default local service endpoint",
            "paths:"
        ]

        for definition in self.endpointDefinitions {
            lines.append(contentsOf: self.renderEndpoint(definition))
        }

        lines.append("components:")
        lines.append("  schemas:")
        for component in self.componentDefinitions {
            lines.append(contentsOf: self.renderComponent(component))
        }

        return lines.joined(separator: "\n") + "\n"
    }

    private static let componentDefinitions: [ServiceSchemaComponent] = [
        ServiceSchemaComponent(
            name: "PerformanceInfo",
            kind: .response,
            summary: "Aggregated runtime performance information.",
            fields: [
                "averageRenderTime": "Double",
                "cacheHitRate": "Double",
                "memoryUsage": "Int",
                "cpuUsage": "Double"
            ]
        ),
        ServiceSchemaComponent(
            name: "ServiceInfo",
            kind: .response,
            summary: "Basic service status and performance summary.",
            fields: [
                "service": "String",
                "version": "String",
                "engine": "String",
                "status": "String",
                "uptime": "Double",
                "requestsProcessed": "Int",
                "performance": "PerformanceInfo"
            ]
        ),
        ServiceSchemaComponent(
            name: "HealthResponse",
            kind: .response,
            summary: "Health-check payload.",
            fields: [
                "status": "String",
                "uptime": "Double",
                "memory_usage": "Double",
                "cpu_usage": "Double",
                "active_connections": "Int",
                "queue_depth": "Int"
            ]
        ),
        ServiceSchemaComponent(
            name: "ServiceSandboxPolicy",
            kind: .response,
            summary: "Active service sandbox policy surface.",
            fields: [
                "name": "String",
                "allowFileTemplates": "Bool",
                "allowAbsoluteTemplatePaths": "Bool",
                "allowDataSources": "Bool",
                "allowCustomExtensions": "Bool",
                "allowDebugTags": "Bool",
                "allowedTags?": "[String]",
                "allowedFilters?": "[String]",
                "allowedDataCapabilities?": "[String]",
                "maxReferencedTemplates?": "Int"
            ]
        ),
        ServiceSchemaComponent(
            name: "DOCXCoverageSummary",
            kind: .response,
            summary: "Machine-readable summary of the trusted DOCX subset.",
            fields: [
                "trustedSubsetVersion": "String",
                "structuredSupportedParts": "[String]",
                "supportedPartCount": "Int",
                "unsupportedPartCount": "Int",
                "preservesUnsupportedParts": "Bool",
                "unsupportedConstructBehavior": "String"
            ]
        ),
        ServiceSchemaComponent(
            name: "DOCXServiceCapabilities",
            kind: .response,
            summary: "DOCX coverage and preservation guarantees exposed by the service.",
            fields: [
                "supportedStructuredParts": "[String]",
                "preservesMediaRelationships": "Bool",
                "preservesNumberingAndStyles": "Bool",
                "preservesUnsupportedParts": "Bool",
                "coverageSummary": "DOCXCoverageSummary",
                "notes": "[String]"
            ]
        ),
        ServiceSchemaComponent(
            name: "ServiceSchemaEndpoint",
            kind: .response,
            summary: "One HTTP endpoint exposed by the canonical service schema.",
            fields: [
                "method": "String",
                "path": "String",
                "summary": "String",
                "requestComponent?": "String",
                "responseComponents": "Record<String, String>",
                "capabilityIdentifiers": "[String]"
            ]
        ),
        ServiceSchemaComponent(
            name: "ServiceSchemaComponent",
            kind: .response,
            summary: "One named request/response component in the canonical service schema.",
            fields: [
                "name": "String",
                "kind": "\"request\" | \"response\"",
                "summary": "String",
                "fields": "Record<String, String>"
            ]
        ),
        ServiceSchemaComponent(
            name: "ServiceCapabilities",
            kind: .response,
            summary: "Capability discovery payload for service-authoritative execution.",
            fields: [
                "serviceVersion": "String",
                "engineVersion": "String",
                "schemaVersion": "String",
                "profile": "\"shopify_compatible\" | \"extended\"",
                "sandboxPolicy": "ServiceSandboxPolicy",
                "supportedTags": "[String]",
                "supportedFilters": "[String]",
                "supportedJobKinds": "[String]",
                "preferredExecution": "\"service_authoritative\" | \"wasm_fallback\"",
                "supportsMacros": "Bool",
                "supportsInputContracts": "Bool",
                "supportsExpressionCallMacros": "Bool",
                "docx": "DOCXServiceCapabilities",
                "supportsAnalysis": "Bool",
                "supportsValidation": "Bool",
                "supportsAsyncJobs": "Bool"
            ]
        ),
        ServiceSchemaComponent(
            name: "ServiceSchema",
            kind: .response,
            summary: "Canonical machine-readable HTTP contract.",
            fields: [
                "version": "String",
                "endpoints": "[ServiceSchemaEndpoint]",
                "components": "[ServiceSchemaComponent]"
            ]
        ),
        ServiceSchemaComponent(
            name: "RenderRequest",
            kind: .request,
            summary: "Immediate template render request.",
            fields: [
                "template": "String",
                "context": "Object",
                "options": "Object?"
            ]
        ),
        ServiceSchemaComponent(
            name: "RenderResponse",
            kind: .response,
            summary: "Immediate template render response.",
            fields: [
                "success": "Bool",
                "output": "String",
                "metrics": "Object",
                "warnings": "[String]",
                "errors": "[String]"
            ]
        ),
        ServiceSchemaComponent(
            name: "AnalyzeRequest",
            kind: .request,
            summary: "Template analysis request.",
            fields: [
                "template": "String",
                "context?": "Object"
            ]
        ),
        ServiceSchemaComponent(
            name: "AnalyzeResponse",
            kind: .response,
            summary: "Template analysis response.",
            fields: [
                "success": "Bool",
                "analysis": "Object"
            ]
        ),
        ServiceSchemaComponent(
            name: "ValidateRequest",
            kind: .request,
            summary: "Template validation request.",
            fields: [
                "template": "String",
                "context?": "Object"
            ]
        ),
        ServiceSchemaComponent(
            name: "ValidateResponse",
            kind: .response,
            summary: "Template validation response.",
            fields: [
                "success": "Bool",
                "valid": "Bool",
                "errors": "[Object]",
                "warnings": "[String]"
            ]
        ),
        ServiceSchemaComponent(
            name: "DocxRenderRequest",
            kind: .request,
            summary: "DOCX render request.",
            fields: [
                "docx_data": "Base64 String",
                "context": "Object",
                "options": "Object?"
            ]
        ),
        ServiceSchemaComponent(
            name: "DocxRenderResponse",
            kind: .response,
            summary: "DOCX render response with shared diagnostics.",
            fields: [
                "success": "Bool",
                "docx_data": "Base64 String",
                "analysis": "DOCXTemplateAnalysis",
                "processing_time": "Double",
                "warnings": "[String]",
                "errors": "[String]"
            ]
        ),
        ServiceSchemaComponent(
            name: "BatchRequest",
            kind: .request,
            summary: "Async or immediate batch render request.",
            fields: [
                "templates": "[Object]",
                "options": "Object?"
            ]
        ),
        ServiceSchemaComponent(
            name: "BatchResponse",
            kind: .response,
            summary: "Immediate batch render response.",
            fields: [
                "success": "Bool",
                "results": "[Object]",
                "total_items": "Int",
                "success_count": "Int",
                "error_count": "Int",
                "processing_time": "Double"
            ]
        ),
        ServiceSchemaComponent(
            name: "DOCXPartDiagnostic",
            kind: .response,
            summary: "Per-part DOCX analysis result for the trusted subset.",
            fields: [
                "path": "String",
                "referencedVariables": "[String]",
                "referencedTemplates": "[String]",
                "warnings": "[String]",
                "unresolvedPlaceholders": "[String]",
                "unsupportedConstructs": "[String]"
            ]
        ),
        ServiceSchemaComponent(
            name: "DOCXTemplateAnalysis",
            kind: .response,
            summary: "Canonical DOCX diagnostic contract shared across service, book backend, and add-in consumers.",
            fields: [
                "referencedVariables": "[String]",
                "referencedTemplates": "[String]",
                "partDiagnostics": "[DOCXPartDiagnostic]",
                "supportedParts": "[String]",
                "unsupportedParts": "[String]",
                "warnings": "[String]",
                "coverageSummary": "DOCXCoverageSummary"
            ]
        ),
        ServiceSchemaComponent(
            name: "JobProgress",
            kind: .response,
            summary: "Progress metadata for a durable job.",
            fields: [
                "fractionCompleted": "Double",
                "currentStep": "String",
                "completedSteps?": "Int",
                "totalSteps?": "Int"
            ]
        ),
        ServiceSchemaComponent(
            name: "JobDiagnostics",
            kind: .response,
            summary: "Warnings, errors, and analysis attached to a durable job.",
            fields: [
                "warnings": "[String]",
                "errors": "[String]",
                "templateAnalysis?": "Object",
                "docxAnalysis?": "DOCXTemplateAnalysis"
            ]
        ),
        ServiceSchemaComponent(
            name: "JobPayload",
            kind: .response,
            summary: "Completed payload attached to a durable job.",
            fields: [
                "output?": "String",
                "docxData?": "Base64 String",
                "batchResult?": "Object",
                "processingTime?": "Double"
            ]
        ),
        ServiceSchemaComponent(
            name: "JobHandle",
            kind: .response,
            summary: "Durable async job handle.",
            fields: [
                "id": "String",
                "kind": "String",
                "status": "\"queued\" | \"running\" | \"completed\" | \"failed\" | \"cancelled\"",
                "createdAt": "String",
                "updatedAt": "String",
                "expiresAt": "String",
                "progress": "JobProgress",
                "payload?": "JobPayload",
                "diagnostics": "JobDiagnostics",
                "error?": "String"
            ]
        ),
        ServiceSchemaComponent(
            name: "MetricsResponse",
            kind: .response,
            summary: "Service metrics snapshot.",
            fields: [
                "active_connections": "Int",
                "average_render_time": "Double",
                "cache_hit_rate": "Double",
                "cpu_usage": "Double",
                "error_rate": "Double",
                "memory_usage": "Int",
                "queue_depth": "Int",
                "recent_activity": "[Object]",
                "requests_today": "Int",
                "total_requests": "Int",
                "uptime": "Double"
            ]
        ),
        ServiceSchemaComponent(
            name: "ErrorResponse",
            kind: .response,
            summary: "Standard error response.",
            fields: [
                "success": "Bool",
                "error": "String"
            ]
        )
    ]

    private static let endpointDefinitions: [EndpointDefinition] = [
        EndpointDefinition(
            method: "GET",
            path: "/",
            summary: "Get basic service information.",
            responses: ["200": "ServiceInfo"]
        ),
        EndpointDefinition(
            method: "GET",
            path: "/health",
            summary: "Health check for the local service.",
            responses: ["200": "HealthResponse"]
        ),
        EndpointDefinition(
            method: "GET",
            path: "/capabilities",
            summary: "Discover engine, DOCX, sandbox, and async-job capabilities.",
            responses: ["200": "ServiceCapabilities"]
        ),
        EndpointDefinition(
            method: "GET",
            path: "/schema",
            summary: "Fetch the canonical machine-readable HTTP contract.",
            responses: ["200": "ServiceSchema"]
        ),
        EndpointDefinition(
            method: "POST",
            path: "/render",
            summary: "Render a Liquid template immediately.",
            requestComponent: "RenderRequest",
            responses: ["200": "RenderResponse", "400": "ErrorResponse"],
            capabilityIdentifiers: ["render.sync"]
        ),
        EndpointDefinition(
            method: "POST",
            path: "/analyze",
            summary: "Analyze a Liquid template without rendering output.",
            requestComponent: "AnalyzeRequest",
            responses: ["200": "AnalyzeResponse", "400": "ErrorResponse"],
            capabilityIdentifiers: ["analysis.template"]
        ),
        EndpointDefinition(
            method: "POST",
            path: "/validate",
            summary: "Validate Liquid template syntax.",
            requestComponent: "ValidateRequest",
            responses: ["200": "ValidateResponse", "400": "ErrorResponse"],
            capabilityIdentifiers: ["validation.template"]
        ),
        EndpointDefinition(
            method: "POST",
            path: "/render-docx",
            summary: "Render the trusted DOCX subset and return shared diagnostics.",
            requestComponent: "DocxRenderRequest",
            responses: ["200": "DocxRenderResponse", "400": "ErrorResponse"],
            capabilityIdentifiers: ["render.docx"]
        ),
        EndpointDefinition(
            method: "POST",
            path: "/batch",
            summary: "Process a synchronous batch of template renders.",
            requestComponent: "BatchRequest",
            responses: ["200": "BatchResponse", "400": "ErrorResponse"],
            capabilityIdentifiers: ["render.batch.sync"]
        ),
        EndpointDefinition(
            method: "POST",
            path: "/jobs/render",
            summary: "Submit an async template render job.",
            requestComponent: "RenderRequest",
            responses: ["200": "JobHandle", "400": "ErrorResponse"],
            capabilityIdentifiers: ["jobs.render"]
        ),
        EndpointDefinition(
            method: "POST",
            path: "/jobs/render-docx",
            summary: "Submit an async DOCX render job.",
            requestComponent: "DocxRenderRequest",
            responses: ["200": "JobHandle", "400": "ErrorResponse"],
            capabilityIdentifiers: ["jobs.render_docx"]
        ),
        EndpointDefinition(
            method: "POST",
            path: "/jobs/batch",
            summary: "Submit an async batch render job.",
            requestComponent: "BatchRequest",
            responses: ["200": "JobHandle", "400": "ErrorResponse"],
            capabilityIdentifiers: ["jobs.batch"]
        ),
        EndpointDefinition(
            method: "GET",
            path: "/jobs",
            summary: "Look up a durable async job by id.",
            responses: ["200": "JobHandle", "404": "ErrorResponse"],
            capabilityIdentifiers: ["jobs.lookup"]
        ),
        EndpointDefinition(
            method: "DELETE",
            path: "/jobs",
            summary: "Cancel a queued or running async job by id.",
            responses: ["200": "JobHandle", "404": "ErrorResponse"],
            capabilityIdentifiers: ["jobs.cancel"]
        ),
        EndpointDefinition(
            method: "GET",
            path: "/metrics",
            summary: "Get the current service metrics snapshot.",
            responses: ["200": "MetricsResponse"]
        )
    ]

    private struct EndpointDefinition {
        let method: String
        let path: String
        let summary: String
        let requestComponent: String?
        let responses: [String: String]
        let capabilityIdentifiers: [String]

        init(
            method: String,
            path: String,
            summary: String,
            requestComponent: String? = nil,
            responses: [String: String],
            capabilityIdentifiers: [String] = []
        ) {
            self.method = method
            self.path = path
            self.summary = summary
            self.requestComponent = requestComponent
            self.responses = responses
            self.capabilityIdentifiers = capabilityIdentifiers
        }

        var endpoint: ServiceSchemaEndpoint {
            ServiceSchemaEndpoint(
                method: self.method,
                path: self.path,
                summary: self.summary,
                requestComponent: self.requestComponent,
                responseComponents: self.responses,
                capabilityIdentifiers: self.capabilityIdentifiers
            )
        }
    }

    private static func renderEndpoint(_ definition: EndpointDefinition) -> [String] {
        var lines: [String] = [
            "  \(definition.path):",
            "    \(definition.method.lowercased()):",
            "      summary: \(self.yamlScalar(definition.summary))"
        ]

        if let requestComponent = definition.requestComponent {
            lines.append("      requestBody:")
            lines.append("        required: true")
            lines.append("        content:")
            lines.append("          application/json:")
            lines.append("            schema:")
            lines.append("              $ref: '#/components/schemas/\(requestComponent)'")
        }

        lines.append("      responses:")
        for status in definition.responses.keys.sorted() {
            guard let component = definition.responses[status] else { continue }
            lines.append("        '\(status)':")
            lines.append("          description: \(self.yamlScalar(component))")
            lines.append("          content:")
            lines.append("            application/json:")
            lines.append("              schema:")
            lines.append("                $ref: '#/components/schemas/\(component)'")
        }

        return lines
    }

    private static func renderComponent(_ component: ServiceSchemaComponent) -> [String] {
        var lines: [String] = [
            "    \(component.name):",
            "      type: object",
            "      description: \(self.yamlScalar(component.summary))",
            "      properties:"
        ]

        for field in component.fields.keys.sorted() {
            guard let typeName = component.fields[field] else { continue }
            let fieldName = field.hasSuffix("?") ? String(field.dropLast()) : field
            lines.append("        \(fieldName):")
            lines.append(contentsOf: self.renderSchemaType(typeName, indent: "          "))
        }

        return lines
    }

    private static func renderSchemaType(_ typeName: String, indent: String) -> [String] {
        let normalized = typeName.replacingOccurrences(of: "?", with: "")

        if normalized.hasPrefix("[") && normalized.hasSuffix("]") {
            let itemType = String(normalized.dropFirst().dropLast())
            return [
                "\(indent)type: array",
                "\(indent)items:",
            ] + self.renderSchemaType(itemType, indent: indent + "  ")
        }

        if normalized.hasSuffix("[]") {
            let itemType = String(normalized.dropLast(2))
            return [
                "\(indent)type: array",
                "\(indent)items:",
            ] + self.renderSchemaType(itemType, indent: indent + "  ")
        }

        if self.componentDefinitions.contains(where: { $0.name == normalized }) {
            return ["\(indent)$ref: '#/components/schemas/\(normalized)'"]
        }

        if normalized.hasPrefix("Record<") {
            return [
                "\(indent)type: object",
                "\(indent)additionalProperties:",
                "\(indent)  type: string"
            ]
        }

        let unionOptions = normalized
            .split(separator: "|")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        if unionOptions.count > 1,
           unionOptions.allSatisfy({ $0.hasPrefix("\"") && $0.hasSuffix("\"") }) {
            return [
                "\(indent)type: string",
                "\(indent)enum:",
            ] + unionOptions.map { "\(indent)  \($0)" }
        }

        let lowercased = normalized.lowercased()
        switch lowercased {
        case "string", "base64 string":
            return ["\(indent)type: string"]
        case "bool":
            return ["\(indent)type: boolean"]
        case "int":
            return ["\(indent)type: integer"]
        case "double":
            return ["\(indent)type: number"]
        default:
            return [
                "\(indent)type: object",
                "\(indent)description: \(self.yamlScalar(typeName))"
            ]
        }
    }

    private static func yamlScalar(_ value: String) -> String {
        if value.rangeOfCharacter(from: CharacterSet(charactersIn: ":#'\"")) != nil {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\\\""))\""
        }
        return value
    }
}
