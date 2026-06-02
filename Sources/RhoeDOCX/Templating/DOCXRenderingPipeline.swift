import Foundation
@preconcurrency import RhoeLiquid

// SAFETY: Immutable after init; contains [String: Any] which is not Sendable
private struct UnsafePipelineRenderContext: @unchecked Sendable {
    let values: [String: Any]
}

private extension DOCXTemplateEngine {
    func renderUnsafe(
        document: WMLDocument,
        context: UnsafePipelineRenderContext
    ) async throws -> WMLDocument {
        try await render(document: document, context: context.values)
    }
}

private extension LiquidEnvironment {
    func renderUnsafe(
        template: String,
        context: UnsafePipelineRenderContext
    ) async throws -> String {
        try await render(template: template, context: context.values)
    }
}

public struct DOCXPartDiagnostic: Sendable, Codable, Equatable {
    public let path: String
    public let referencedVariables: [String]
    public let referencedTemplates: [String]
    public let warnings: [String]
    public let unresolvedPlaceholders: [String]
    public let unsupportedConstructs: [String]

    public init(
        path: String,
        referencedVariables: [String],
        referencedTemplates: [String],
        warnings: [String] = [],
        unresolvedPlaceholders: [String] = [],
        unsupportedConstructs: [String] = []
    ) {
        self.path = path
        self.referencedVariables = referencedVariables
        self.referencedTemplates = referencedTemplates
        self.warnings = warnings
        self.unresolvedPlaceholders = unresolvedPlaceholders
        self.unsupportedConstructs = unsupportedConstructs
    }
}

public struct DOCXTemplateCoverageSummary: Sendable, Codable, Equatable {
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

public struct DOCXTemplateAnalysis: Sendable, Codable, Equatable {
    public let referencedVariables: [String]
    public let referencedTemplates: [String]
    public let partDiagnostics: [DOCXPartDiagnostic]
    public let supportedParts: [String]
    public let unsupportedParts: [String]
    public let warnings: [String]
    public let coverageSummary: DOCXTemplateCoverageSummary

    public init(
        referencedVariables: [String],
        referencedTemplates: [String],
        partDiagnostics: [DOCXPartDiagnostic],
        supportedParts: [String],
        unsupportedParts: [String],
        warnings: [String],
        coverageSummary: DOCXTemplateCoverageSummary
    ) {
        self.referencedVariables = referencedVariables
        self.referencedTemplates = referencedTemplates
        self.partDiagnostics = partDiagnostics
        self.supportedParts = supportedParts
        self.unsupportedParts = unsupportedParts
        self.warnings = warnings
        self.coverageSummary = coverageSummary
    }
}

public struct DOCXRenderOutput: Sendable {
    public let data: Data
    public let analysis: DOCXTemplateAnalysis

    public init(data: Data, analysis: DOCXTemplateAnalysis) {
        self.data = data
        self.analysis = analysis
    }
}

public actor DOCXRenderingPipeline: Sendable {
    public static let trustedStructuredPartPatterns = [
        "word/document.xml",
        "word/header*.xml",
        "word/footer*.xml",
        "word/comments.xml",
        "word/footnotes.xml",
        "word/endnotes.xml",
    ]

    private enum RenderingMode {
        case structuredDocument
        case xmlTextNodes
    }

    private struct PartProcessingResult {
        let diagnostic: DOCXPartDiagnostic
        let outputData: Data
        let supported: Bool
    }

    private let environment: LiquidEnvironment
    private let templateEngine: DOCXTemplateEngine

    public init(environment: LiquidEnvironment = LiquidEnvironment()) {
        self.environment = environment
        self.templateEngine = DOCXTemplateEngine(environment: environment)
    }

    public func analyze(data: Data) async throws -> DOCXTemplateAnalysis {
        let archive = ZIPArchive(data: data)
        let package = try await archive.open()
        return try await self.process(package: package, context: nil).analysis
    }

    public func render(data: Data, context: [String: Any]) async throws -> DOCXRenderOutput {
        let archive = ZIPArchive(data: data)
        let package = try await archive.open()
        return try await self.process(package: package, context: context)
    }

    private func process(
        package: ZIPPackage,
        context: [String: Any]?
    ) async throws -> DOCXRenderOutput {
        let builder = ZIPBuilder()
        let sortedEntries = package.files.values.sorted { $0.path < $1.path }

        var referencedVariables: Set<String> = []
        var referencedTemplates: Set<String> = []
        var partDiagnostics: [DOCXPartDiagnostic] = []
        var supportedParts: [String] = []
        var unsupportedParts: [String] = []
        var warnings: [String] = []

        for entry in sortedEntries {
            let originalData = try await package.extractData(for: entry.path)
            let outputData: Data

            if let mode = self.renderingMode(for: entry.path) {
                do {
                    let result = try await self.processRenderablePart(
                        data: originalData,
                        path: entry.path,
                        mode: mode,
                        context: context
                    )
                    outputData = result.outputData
                    partDiagnostics.append(result.diagnostic)
                    referencedVariables.formUnion(result.diagnostic.referencedVariables)
                    referencedTemplates.formUnion(result.diagnostic.referencedTemplates)
                    warnings.append(contentsOf: result.diagnostic.warnings)

                    if result.supported {
                        supportedParts.append(entry.path)
                    } else {
                        unsupportedParts.append(entry.path)
                    }
                } catch {
                    outputData = originalData
                    unsupportedParts.append(entry.path)
                    let warning = "Skipped trusted DOCX handling for \(entry.path): \(error.localizedDescription)"
                    warnings.append(warning)
                    partDiagnostics.append(
                        DOCXPartDiagnostic(
                            path: entry.path,
                            referencedVariables: [],
                            referencedTemplates: [],
                            warnings: [warning],
                            unresolvedPlaceholders: [],
                            unsupportedConstructs: ["Failed to process trusted DOCX part safely."]
                        )
                    )
                }
            } else {
                outputData = originalData
                unsupportedParts.append(entry.path)
            }

            await builder.addFile(
                path: entry.path,
                data: outputData,
                date: entry.lastModified,
                compressionMethod: entry.compressionMethod
            )
        }

        let coverageSummary = DOCXTemplateCoverageSummary(
            trustedSubsetVersion: "trusted-docx-v1",
            structuredSupportedParts: Self.trustedStructuredPartPatterns,
            supportedPartCount: supportedParts.count,
            unsupportedPartCount: unsupportedParts.count,
            preservesUnsupportedParts: true,
            unsupportedConstructBehavior: "Unsupported or untrusted package parts are preserved byte-for-byte and reported in diagnostics."
        )

        let analysis = DOCXTemplateAnalysis(
            referencedVariables: referencedVariables.sorted(),
            referencedTemplates: referencedTemplates.sorted(),
            partDiagnostics: partDiagnostics.sorted { $0.path < $1.path },
            supportedParts: supportedParts.sorted(),
            unsupportedParts: unsupportedParts.sorted(),
            warnings: Array(Set(warnings)).sorted(),
            coverageSummary: coverageSummary
        )

        return DOCXRenderOutput(
            data: try await builder.build(),
            analysis: analysis
        )
    }

    private func processRenderablePart(
        data: Data,
        path: String,
        mode: RenderingMode,
        context: [String: Any]?
    ) async throws -> PartProcessingResult {
        switch mode {
        case .structuredDocument:
            return try await self.processStructuredDocumentPart(
                data: data,
                path: path,
                context: context
            )
        case .xmlTextNodes:
            return try await self.processXMLTextNodePart(
                data: data,
                path: path,
                context: context
            )
        }
    }

    private func processStructuredDocumentPart(
        data: Data,
        path: String,
        context: [String: Any]?
    ) async throws -> PartProcessingResult {
        let parser = WordprocessingMLParser()
        let parseResult = try await parser.parse(data: data)
        let templateSnippets = self.collectTemplateSnippets(from: parseResult.document)

        let summary = await self.analyzeSnippets(templateSnippets)
        let renderedData: Data
        let unresolvedPlaceholders: [String]

        if let context {
            let renderedDocument = try await self.templateEngine.renderUnsafe(
                document: parseResult.document,
                context: UnsafePipelineRenderContext(values: context)
            )
            let serializer = XMLSerializer()
            let xml = try await serializer.serializeDocument(renderedDocument, namespaces: parseResult.namespaces)
            renderedData = Data(xml.utf8)
            unresolvedPlaceholders = self.collectTemplateSnippets(from: renderedDocument)
        } else {
            renderedData = data
            unresolvedPlaceholders = []
        }

        return PartProcessingResult(
            diagnostic: DOCXPartDiagnostic(
                path: path,
                referencedVariables: summary.referencedVariables,
                referencedTemplates: summary.referencedTemplates,
                warnings: summary.warnings,
                unresolvedPlaceholders: unresolvedPlaceholders,
                unsupportedConstructs: []
            ),
            outputData: renderedData,
            supported: true
        )
    }

    private func processXMLTextNodePart(
        data: Data,
        path: String,
        context: [String: Any]?
    ) async throws -> PartProcessingResult {
        guard var xml = String(data: data, encoding: .utf8) else {
            throw DOCXError.encodingError("Could not decode XML for \(path)")
        }

        let matches = self.textNodeMatches(in: xml)
        let unsupportedConstructs = self.detectUnsupportedConstructs(in: xml, using: matches)
        let snippets = matches.map {
            self.decodeXML($0.content)
        }.filter { self.containsLiquidMarkup($0) }
        let summary = await self.analyzeSnippets(snippets)

        var unresolvedPlaceholders: Set<String> = []
        if let context, unsupportedConstructs.isEmpty {
            let unsafeContext = UnsafePipelineRenderContext(values: context)
            for match in matches.reversed() where self.containsLiquidMarkup(self.decodeXML(match.content)) {
                let decoded = self.decodeXML(match.content)
                let rendered = try await self.environment.renderUnsafe(template: decoded, context: unsafeContext)
                unresolvedPlaceholders.formUnion(self.extractLiquidPlaceholders(from: rendered))
                let escaped = self.escapeXML(rendered)
                xml = self.replacingCharacters(
                    in: xml,
                    range: match.contentRange,
                    with: escaped
                )
            }
        }

        return PartProcessingResult(
            diagnostic: DOCXPartDiagnostic(
                path: path,
                referencedVariables: summary.referencedVariables,
                referencedTemplates: summary.referencedTemplates,
                warnings: summary.warnings,
                unresolvedPlaceholders: unresolvedPlaceholders.sorted(),
                unsupportedConstructs: unsupportedConstructs
            ),
            outputData: unsupportedConstructs.isEmpty && context != nil ? Data(xml.utf8) : data,
            supported: unsupportedConstructs.isEmpty
        )
    }

    private func renderingMode(for path: String) -> RenderingMode? {
        switch path {
        case "word/document.xml":
            return .structuredDocument
        case let path where path.hasPrefix("word/header"):
            return .structuredDocument
        case let path where path.hasPrefix("word/footer"):
            return .structuredDocument
        case "word/comments.xml", "word/footnotes.xml", "word/endnotes.xml":
            return .xmlTextNodes
        default:
            return nil
        }
    }

    private func analyzeSnippets(_ snippets: [String]) async -> SnippetSummary {
        var referencedVariables = Set<String>()
        var referencedTemplates = Set<String>()
        var warnings: [String] = []

        for snippet in snippets {
            let analysis = await self.environment.analyzeTemplate(snippet)
            referencedVariables.formUnion(analysis.manifest.requiredVariables)
            referencedTemplates.formUnion(analysis.manifest.referencedTemplates)
            warnings.append(contentsOf: analysis.warnings)
            warnings.append(contentsOf: analysis.validationErrors)
        }

        return SnippetSummary(
            referencedVariables: referencedVariables.sorted(),
            referencedTemplates: referencedTemplates.sorted(),
            warnings: Array(Set(warnings)).sorted()
        )
    }

    private struct SnippetSummary {
        let referencedVariables: [String]
        let referencedTemplates: [String]
        let warnings: [String]
    }

    private struct XMLTextNodeMatch {
        let contentRange: NSRange
        let content: String
    }

    private func textNodeMatches(in xml: String) -> [XMLTextNodeMatch] {
        let pattern = #"<w:t\b[^>]*>(.*?)</w:t>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            return []
        }

        let nsXML = xml as NSString
        return regex.matches(in: xml, range: NSRange(location: 0, length: nsXML.length)).compactMap { match in
            guard match.numberOfRanges > 1 else { return nil }
            let contentRange = match.range(at: 1)
            return XMLTextNodeMatch(
                contentRange: contentRange,
                content: nsXML.substring(with: contentRange)
            )
        }
    }

    private func detectUnsupportedConstructs(in xml: String, using matches: [XMLTextNodeMatch]) -> [String] {
        let mutable = NSMutableString(string: xml)
        for match in matches.reversed() {
            mutable.replaceCharacters(in: match.contentRange, with: "")
        }

        let outsideTextNodes = mutable as String
        if self.containsLiquidMarkup(outsideTextNodes) {
            return ["Liquid markup outside supported <w:t> text nodes is preserved instead of being rewritten."]
        }
        return []
    }

    private func replacingCharacters(in value: String, range: NSRange, with replacement: String) -> String {
        let mutable = NSMutableString(string: value)
        mutable.replaceCharacters(in: range, with: replacement)
        return mutable as String
    }

    private func extractLiquidPlaceholders(from value: String) -> [String] {
        let pattern = #"\{\{.*?\}\}|\{%.*?%\}"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            return []
        }

        let nsValue = value as NSString
        return regex.matches(in: value, range: NSRange(location: 0, length: nsValue.length)).map {
            nsValue.substring(with: $0.range)
        }
    }

    private func decodeXML(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&apos;", with: "'")
            .replacingOccurrences(of: "&amp;", with: "&")
    }

    private func escapeXML(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }

    private func collectTemplateSnippets(from document: WMLDocument) -> [String] {
        self.collectTemplateSnippets(from: document.body)
    }

    private func collectTemplateSnippets(from body: WMLBody) -> [String] {
        var snippets: [String] = []
        for item in body.content {
            snippets.append(contentsOf: self.collectTemplateSnippets(from: item))
        }
        return snippets
    }

    private func collectTemplateSnippets(from content: WMLBodyContent) -> [String] {
        switch content {
        case .paragraph(let paragraph):
            return self.collectTemplateSnippets(from: paragraph)
        case .table(let table):
            return self.collectTemplateSnippets(from: table)
        case .structuredDocumentTag(let sdt):
            return sdt.content.flatMap { self.collectTemplateSnippets(from: $0) }
        case .altChunk, .sectionProperties:
            return []
        }
    }

    private func collectTemplateSnippets(from paragraph: WMLParagraph) -> [String] {
        var snippets: [String] = []
        for item in paragraph.content {
            snippets.append(contentsOf: self.collectTemplateSnippets(from: item))
        }
        return snippets
    }

    private func collectTemplateSnippets(from table: WMLTable) -> [String] {
        var snippets: [String] = []
        for row in table.rows {
            snippets.append(contentsOf: self.collectTemplateSnippets(from: row))
        }
        return snippets
    }

    private func collectTemplateSnippets(from row: WMLTableRow) -> [String] {
        var snippets: [String] = []
        for cell in row.cells {
            snippets.append(contentsOf: self.collectTemplateSnippets(from: cell))
        }
        return snippets
    }

    private func collectTemplateSnippets(from cell: WMLTableCell) -> [String] {
        var snippets: [String] = []
        for item in cell.content {
            switch item {
            case .paragraph(let paragraph):
                snippets.append(contentsOf: self.collectTemplateSnippets(from: paragraph))
            case .table(let nestedTable):
                snippets.append(contentsOf: self.collectTemplateSnippets(from: nestedTable))
            default:
                continue
            }
        }
        return snippets
    }

    private func collectTemplateSnippets(from content: WMLParagraphContent) -> [String] {
        switch content {
        case .run(let run):
            return self.collectTemplateSnippets(from: run)
        case .hyperlink(let hyperlink):
            return hyperlink.content.flatMap { self.collectTemplateSnippets(from: $0) }
        default:
            return []
        }
    }

    private func collectTemplateSnippets(from run: WMLRun) -> [String] {
        var snippets: [String] = []
        for content in run.content {
            switch content {
            case .text(let text):
                if self.containsLiquidMarkup(text.content) {
                    snippets.append(text.content)
                }
            default:
                continue
            }
        }
        return snippets
    }

    private func containsLiquidMarkup(_ value: String) -> Bool {
        value.contains("{{") || value.contains("{%")
    }
}
