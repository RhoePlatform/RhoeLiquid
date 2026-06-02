//
//  LiquidEngineAnalysis.swift
//  RhoeLiquid
//
//  Template analysis and capability metadata for the platform surface.
//

import Foundation
import LiquidCore
import LiquidExtensions
import LiquidLexer
import LiquidParser
import LiquidTags

private enum TemplateDataCapability {
    static let filterNames: Set<String> = [
        "select", "select_all", "xpath", "text", "attr", "inner_html", "strip_html",
        "tag_name", "children", "sql_query", "sql_select", "sql_join", "sql_count",
        "sql_sum", "sql_avg", "sql_min", "sql_max", "sql_distinct", "sql_schema",
        "yaml_merge", "to_yaml", "to_toml", "graphql_data", "graphql_errors",
        "graphql_has_errors"
    ]

    static let tagNames: Set<String> = ["data"]
}

private enum TemplateInputPathComponent: Equatable {
    case key(String)
    case arrayElement
}

private struct TemplateAnalysisAccumulator {
    var variables: Set<String> = []
    var variableRoots: Set<String> = []
    var referencedTemplates: Set<String> = []
    var filters: Set<String> = []
    var tags: Set<String> = []
    var dataCapabilities: Set<String> = []
    var loopCount = 0
    var usesInheritance = false
    var requiresExtendedProfile = false
    var usesDebugFeatures = false
    var declaredInputs: [TemplateInputField] = []
    var contractDefaults: Set<String> = []
    var macroDefinitions: [MacroSignature] = []
    var macroImports: [MacroImport] = []
    var macroCalls: [MacroCallSite] = []
}

// SAFETY: Immutable after init; contains [String: Any] which is not Sendable
private struct UnsafeAnalysisContext: @unchecked Sendable {
    let values: [String: Any]
}

extension LiquidEngine {
    public func validateTemplate(_ template: String) async -> (valid: Bool, errors: [String]) {
        let analysis = await analyzeTemplate(template)
        return (analysis.isValid, analysis.validationErrors)
    }

    public func analyzeTemplate(_ template: String) async -> TemplateAnalysis {
        await analyzeTemplate(template, context: nil)
    }

    public func analyzeTemplate(
        _ template: String,
        context: [String: Any]? = nil,
        templatePath: String? = nil,
        baseDirectory: URL? = nil
    ) async -> TemplateAnalysis {
        let loaderResolution = await Self.analysisTemplateLoader(
            templatePath: templatePath,
            baseDirectory: baseDirectory,
            fallback: platformTemplateLoaderForAnalysis()
        )

        switch loaderResolution {
        case .failure(let error):
            return Self.analysisFailure(for: error)
        case .success(let analysisContext):
            return await analyzeTemplate(
                template,
                context: context,
                analysisContext: analysisContext
            )
        }
    }

    public func analyzeTemplateFile(
        at path: String,
        context: [String: Any]? = nil,
        baseDirectory: URL? = nil
    ) async -> TemplateAnalysis {
        let loader = TemplateLoader(
            baseDirectory: baseDirectory,
            allowAbsolutePaths: baseDirectory != nil || TemplateLoader.isAbsolutePath(path)
        )

        do {
            let resolvedPath = try await loader.resolvedTemplatePath(for: path)
            let source = try await loader.loadTemplate(path)
            return await analyzeTemplate(
                source,
                context: context,
                analysisContext: AnalysisTemplateContext(
                    templateLoader: loader,
                    templateName: resolvedPath,
                    templatePath: resolvedPath
                )
            )
        } catch {
            return Self.analysisFailure(for: error)
        }
    }

    public func templateManifest(
        for template: String,
        templatePath: String? = nil,
        baseDirectory: URL? = nil
    ) async -> TemplateManifest {
        await analyzeTemplate(
            template,
            context: nil,
            templatePath: templatePath,
            baseDirectory: baseDirectory
        ).manifest
    }

    public func templateManifest(
        forFileAt path: String,
        baseDirectory: URL? = nil
    ) async -> TemplateManifest {
        await analyzeTemplateFile(at: path, baseDirectory: baseDirectory).manifest
    }

    private func analyzeTemplate(
        _ template: String,
        context: [String: Any]?,
        analysisContext: AnalysisTemplateContext
    ) async -> TemplateAnalysis {
        let customTagDescriptors = await currentCustomTagDescriptors()
        let unsafeContext = context.map(UnsafeAnalysisContext.init(values:))

        do {
            let ast = try Self.parseForAnalysis(template, customTagDescriptors: customTagDescriptors)
            let manifest = Self.buildManifest(from: ast, templateName: analysisContext.templateName)
            let contractValidation = await Self.validateAuthoringContracts(
                ast: ast,
                manifest: manifest,
                context: unsafeContext,
                templateLoader: analysisContext.templateLoader,
                parentTemplatePath: analysisContext.templatePath,
                customTagDescriptors: customTagDescriptors
            )
            let securityIssues = Self.analyzeSecurityIssues(in: template, manifest: manifest)
            let complexity = Self.classifyComplexity(manifest: manifest)
            let qualityScore = Self.qualityScore(
                manifest: manifest,
                securityIssues: securityIssues,
                validationErrors: contractValidation.validationErrors,
                macroDiagnostics: contractValidation.macroDiagnostics
            )
            let recommendations = Self.recommendations(
                manifest: manifest,
                securityIssues: securityIssues,
                validationErrors: contractValidation.validationErrors,
                macroDiagnostics: contractValidation.macroDiagnostics
            )

            return TemplateAnalysis(
                manifest: manifest,
                inputContract: TemplateInputContract(fields: manifest.declaredInputs),
                complexity: complexity,
                qualityScore: qualityScore,
                variableCount: manifest.requiredVariables.count,
                filterCount: manifest.activeFilters.count,
                tagCount: manifest.activeTags.count,
                loopCount: manifest.activeTags.filter { $0 == "for" || $0 == "tablerow" }.count,
                securityIssues: securityIssues,
                recommendations: recommendations,
                estimatedRenderTime: Self.estimatedRenderTime(for: manifest),
                isValid: contractValidation.validationErrors.isEmpty,
                validationErrors: contractValidation.validationErrors,
                missingRequiredInputs: contractValidation.missingRequiredInputs,
                macroDiagnostics: contractValidation.macroDiagnostics,
                warnings: Self.analysisWarnings(for: manifest) + contractValidation.warnings
            )
        } catch {
            return Self.analysisFailure(for: error)
        }
    }

    public func allFilterNames() async -> Set<String> {
        let customFilters = await getCustomFilters()
        return builtInFilterNames.union(customFilters.keys)
    }

    public func filterDocumentation() async -> [LiquidDocMetadata] {
        let customFilters = await getCustomFilters()
        var documented: [String: LiquidDocMetadata] = [:]

        for name in builtInFilterNames {
            documented[name] = LiquidDocMetadata(
                name: name,
                kind: .filter,
                summary: "Built-in Liquid filter.",
                stability: .stable,
                compatibility: .shopifyCompatible,
                capabilityIdentifiers: ["filter:\(name)"]
            )
        }

        for (name, filter) in customFilters {
            if let documentedFilter = filter as? any LiquidDocMetadataProvider {
                documented[name] = documentedFilter.liquidDocMetadata
            } else {
                let compatibility: LiquidDocCompatibility = TemplateDataCapability.filterNames.contains(name)
                    ? .extended
                    : .shopifyCompatible
                documented[name] = LiquidDocMetadata(
                    name: name,
                    kind: .filter,
                    summary: "Registry-backed custom filter.",
                    stability: .stable,
                    compatibility: compatibility,
                    capabilityIdentifiers: ["filter:\(name)"]
                )
            }
        }

        return documented.values.sorted { $0.name < $1.name }
    }

    public func tagDocumentation() async -> [LiquidDocMetadata] {
        let customTags = await getCustomTags()
        let allTagNames = await getAllTagNames()
        var documented: [String: LiquidDocMetadata] = [:]

        for name in allTagNames {
            let compatibility: LiquidDocCompatibility
            if [
                "macro", "endmacro", "import", "from", "input", "call", "endcall",
                "slot", "endslot", "fill", "endfill",
                "echo", "debug", "liquid", "pipeline"
            ].contains(name) {
                compatibility = .extended
            } else {
                compatibility = builtInTagNames.contains(name) ? .shopifyCompatible : .extended
            }
            documented[name] = LiquidDocMetadata(
                name: name,
                kind: .tag,
                summary: "Built-in or active Liquid tag.",
                stability: .stable,
                compatibility: compatibility,
                capabilityIdentifiers: ["tag:\(name)"]
            )
        }

        for (name, tag) in customTags {
            if let documentedTag = tag as? any LiquidDocMetadataProvider {
                documented[name] = documentedTag.liquidDocMetadata
            } else {
                documented[name] = LiquidDocMetadata(
                    name: name,
                    kind: .tag,
                    summary: "Registry-backed custom tag.",
                    parameters: tag.requiredContext.map {
                        LiquidDocParameter(name: $0, summary: "Required execution context key.", required: true)
                    },
                    stability: .stable,
                    compatibility: .extended,
                    capabilityIdentifiers: ["tag:\(name)"]
                )
            }
        }

        return documented.values.sorted { $0.name < $1.name }
    }

    private func currentCustomTagDescriptors() async -> [CustomTagDescriptor] {
        let customTags = await getCustomTags()
        return customTags.values
            .map { CustomTagDescriptor(name: $0.name, requiresEndTag: $0.type.requiresEndTag) }
            .sorted { $0.name < $1.name }
    }

    private static func parseForAnalysis(
        _ template: String,
        customTagDescriptors: [CustomTagDescriptor]
    ) throws -> ASTNode {
        let lexer = Lexer(template)
        let tokens = try lexer.tokenize()
        let parser = Parser(consuming: tokens, source: template, customTags: customTagDescriptors)
        return try parser.parse()
    }

    private struct AnalysisTemplateContext {
        let templateLoader: TemplateLoader?
        let templateName: String?
        let templatePath: String?
    }

    private static func analysisTemplateLoader(
        templatePath: String?,
        baseDirectory: URL?,
        fallback: TemplateLoader
    ) async -> Result<AnalysisTemplateContext, Error> {
        guard templatePath != nil || baseDirectory != nil else {
            return .success(
                AnalysisTemplateContext(
                    templateLoader: fallback,
                    templateName: nil,
                    templatePath: nil
                )
            )
        }

        let path = templatePath ?? "."
        let loader = TemplateLoader(
            baseDirectory: baseDirectory,
            allowAbsolutePaths: baseDirectory != nil || TemplateLoader.isAbsolutePath(path)
        )

        do {
            let resolvedPath = try await loader.resolvedTemplatePath(for: path)
            return .success(
                AnalysisTemplateContext(
                    templateLoader: loader,
                    templateName: resolvedPath,
                    templatePath: resolvedPath
                )
            )
        } catch {
            return .failure(error)
        }
    }

    private static func analysisFailure(for error: Error) -> TemplateAnalysis {
        let manifest = TemplateManifest(
            requiredVariables: [],
            variableRoots: [],
            referencedTemplates: [],
            activeTags: [],
            activeFilters: [],
            dataCapabilities: [],
            capabilityIdentifiers: [],
            usesInheritance: false,
            requiresExtendedProfile: false,
            usesDebugFeatures: false
        )
        return TemplateAnalysis(
            manifest: manifest,
            inputContract: TemplateInputContract(fields: []),
            complexity: .simple,
            qualityScore: 0,
            variableCount: 0,
            filterCount: 0,
            tagCount: 0,
            loopCount: 0,
            securityIssues: [],
            recommendations: ["Fix template syntax before using this template in production."],
            estimatedRenderTime: 0,
            isValid: false,
            validationErrors: [error.localizedDescription],
            missingRequiredInputs: [],
            macroDiagnostics: [],
            warnings: []
        )
    }

    private static func buildManifest(from ast: ASTNode, templateName: String?) -> TemplateManifest {
        var state = TemplateAnalysisAccumulator()
        walk(ast, into: &state)

        let requiredVariables = state.variables.sorted()
        let variableRoots = state.variableRoots.sorted()
        let referencedTemplates = state.referencedTemplates.sorted()
        let activeTags = state.tags.sorted()
        let activeFilters = state.filters.sorted()
        let dataCapabilities = state.dataCapabilities.sorted()
        let capabilityIdentifiers = activeTags.map { "tag:\($0)" } + activeFilters.map { "filter:\($0)" }

        return TemplateManifest(
            templateName: templateName,
            requiredVariables: requiredVariables,
            variableRoots: variableRoots,
            referencedTemplates: referencedTemplates,
            activeTags: activeTags,
            activeFilters: activeFilters,
            dataCapabilities: dataCapabilities,
            capabilityIdentifiers: capabilityIdentifiers.sorted(),
            usesInheritance: state.usesInheritance,
            requiresExtendedProfile: state.requiresExtendedProfile,
            usesDebugFeatures: state.usesDebugFeatures,
            declaredInputs: state.declaredInputs.sorted { $0.name < $1.name },
            contractDefaults: state.contractDefaults.sorted(),
            macroDefinitions: state.macroDefinitions.sorted { $0.name < $1.name },
            macroImports: state.macroImports.sorted {
                if $0.template == $1.template {
                    return ($0.namespace ?? "") < ($1.namespace ?? "")
                }
                return $0.template < $1.template
            },
            macroCalls: state.macroCalls.sorted { $0.name < $1.name }
        )
    }

    private static func walk(_ node: ASTNode, into state: inout TemplateAnalysisAccumulator) {
        switch node {
        case .template(let nodes):
            nodes.forEach { walk($0, into: &state) }
        case .text, .comment, .raw, .break, .continue, .increment, .decrement, .custom:
            break
        case .output(let expression):
            visit(expression, into: &state)
        case .if(let condition, let thenNodes, let elsifNodes, let elseNodes):
            state.tags.insert("if")
            visit(condition, into: &state)
            thenNodes.forEach { walk($0, into: &state) }
            for (expression, branch) in elsifNodes {
                state.tags.insert("elsif")
                visit(expression, into: &state)
                branch.forEach { walk($0, into: &state) }
            }
            elseNodes?.forEach { walk($0, into: &state) }
        case .unless(let condition, let thenNodes, let elseNodes):
            state.tags.insert("unless")
            visit(condition, into: &state)
            thenNodes.forEach { walk($0, into: &state) }
            elseNodes?.forEach { walk($0, into: &state) }
        case .case(let value, let whens, let elseNodes):
            state.tags.insert("case")
            visit(value, into: &state)
            for (expression, branch) in whens {
                state.tags.insert("when")
                visit(expression, into: &state)
                branch.forEach { walk($0, into: &state) }
            }
            elseNodes?.forEach { walk($0, into: &state) }
        case .for(_, let expression, let body, let empty, let params):
            state.tags.insert("for")
            state.loopCount += 1
            visit(expression, into: &state)
            params.condition.map { visit($0, into: &state) }
            body.forEach { walk($0, into: &state) }
            empty?.forEach { walk($0, into: &state) }
        case .tablerow(_, let expression, let body, let params):
            state.tags.insert("tablerow")
            state.loopCount += 1
            visit(expression, into: &state)
            body.forEach { walk($0, into: &state) }
            if let cols = params.cols, cols > 0 {
                state.dataCapabilities.insert("tablerow:cols")
            }
        case .cycle(_, let items):
            state.tags.insert("cycle")
            items.forEach { visit($0, into: &state) }
        case .assign(_, let value):
            state.tags.insert("assign")
            visit(value, into: &state)
        case .capture(_, let body):
            state.tags.insert("capture")
            body.forEach { walk($0, into: &state) }
        case .include(let template, let withValues, _):
            state.tags.insert("include")
            state.referencedTemplates.insert(template.string)
            withValues?.values.forEach { visit($0, into: &state) }
        case .macro(let signature, let body):
            state.tags.insert("macro")
            state.requiresExtendedProfile = true
            state.macroDefinitions.append(Self.publicMacroSignature(from: signature, body: body))
            for parameter in signature.parameters {
                parameter.defaultValue.map { visit($0, into: &state) }
            }
            body.forEach { walk($0, into: &state) }
        case .macroImport(let macroImport):
            state.tags.insert(macroImport.namespace == nil ? "from" : "import")
            state.referencedTemplates.insert(macroImport.template.string)
            state.requiresExtendedProfile = true
            state.macroImports.append(Self.publicMacroImport(from: macroImport))
        case .input(let contract):
            state.tags.insert("input")
            state.requiresExtendedProfile = true
            state.declaredInputs.append(Self.publicInputField(from: contract))
            if contract.defaultValue != nil {
                state.contractDefaults.insert(contract.name.string)
            }
            contract.defaultValue.map { visit($0, into: &state) }
        case .call(let name, let arguments, let body):
            state.tags.insert("call")
            state.requiresExtendedProfile = true
            state.macroCalls.append(
                Self.publicMacroCallSite(name: name.string, arguments: arguments, body: body)
            )
            arguments.forEach { visit($0.value, into: &state) }
            body?.forEach { walk($0, into: &state) }
        case .slot(_, let body):
            state.tags.insert("slot")
            state.requiresExtendedProfile = true
            body.forEach { walk($0, into: &state) }
        case .fill(_, let body):
            state.tags.insert("fill")
            state.requiresExtendedProfile = true
            body.forEach { walk($0, into: &state) }
        case .block(let name, let body):
            state.tags.insert("block")
            state.tags.insert("block:\(name.string)")
            body.forEach { walk($0, into: &state) }
        case .renderBlock(let name, let params):
            state.tags.insert("render_block")
            state.tags.insert("render_block:\(name.string)")
            params.values.forEach { visit($0, into: &state) }
        case .extends(let template):
            state.tags.insert("extends")
            state.referencedTemplates.insert(template.string)
            state.usesInheritance = true
        case .liquid(let body):
            state.tags.insert("liquid")
            state.requiresExtendedProfile = true
            body.forEach { walk($0, into: &state) }
        case .echo(let expression):
            state.tags.insert("echo")
            state.requiresExtendedProfile = true
            visit(expression, into: &state)
        case .debug(let expression):
            state.tags.insert("debug")
            state.requiresExtendedProfile = true
            state.usesDebugFeatures = true
            expression.map { visit($0, into: &state) }
        case .pipeline(let input, let operations):
            state.tags.insert("pipeline")
            state.requiresExtendedProfile = true
            visit(input, into: &state)
            for operation in operations {
                switch operation.operation {
                case .filter(let filter):
                    state.filters.insert(filter.name.string)
                    if TemplateDataCapability.filterNames.contains(filter.name.string) {
                        state.dataCapabilities.insert("filter:\(filter.name.string)")
                    }
                    filter.arguments.forEach { visit($0, into: &state) }
                    filter.namedArguments.values.forEach { visit($0, into: &state) }
                case .assign:
                    state.tags.insert("assign")
                }
            }
        case .registeredCustomTag(let name, _, let body):
            let tagName = name.string
            state.tags.insert(tagName)
            if TemplateDataCapability.tagNames.contains(tagName) {
                state.dataCapabilities.insert("tag:\(tagName)")
            }
            body?.nodes.forEach { walk($0, into: &state) }
        }
    }

    private static func visit(_ expression: LiquidCore.Expression, into state: inout TemplateAnalysisAccumulator) {
        if let staticPath = expression.staticVariablePath {
            state.variables.insert(staticPath)
            if let root = staticPath.split(separator: ".").first {
                state.variableRoots.insert(String(root))
            }
        } else {
            let referenced = expression.referencedVariables
            state.variables.formUnion(referenced)
            for variable in referenced {
                if let root = variable.split(separator: ".").first {
                    state.variableRoots.insert(String(root))
                }
            }
        }

        switch expression {
        case .literal:
            return
        case .variable:
            return
        case .binary(let left, _, let right):
            visit(left, into: &state)
            visit(right, into: &state)
        case .unary(_, let expr):
            visit(expr, into: &state)
        case .range(let start, let end):
            visit(start, into: &state)
            visit(end, into: &state)
        case .filtered(let expr, let filters):
            visit(expr, into: &state)
            for filter in filters {
                let filterName = filter.name.string
                state.filters.insert(filterName)
                if TemplateDataCapability.filterNames.contains(filterName) {
                    state.dataCapabilities.insert("filter:\(filterName)")
                }
                filter.arguments.forEach { visit($0, into: &state) }
                filter.namedArguments.values.forEach { visit($0, into: &state) }
            }
        case .test(let expr, _):
            visit(expr, into: &state)
        case .access(let expr, let key):
            visit(expr, into: &state)
            visit(key, into: &state)
        case .call(let name, let arguments):
            state.requiresExtendedProfile = true
            state.macroCalls.append(publicMacroCallSite(name: name.string, arguments: arguments))
            arguments.forEach { visit($0.value, into: &state) }
        }
    }

    private static func publicInputField(from contract: InputContractNode) -> TemplateInputField {
        TemplateInputField(
            name: contract.name.string,
            type: publicInputType(from: contract.type),
            required: contract.required,
            strict: contract.strict,
            defaultValueDescription: contract.defaultValue?.description
        )
    }

    private static func publicInputType(from type: InputTypeNode) -> TemplateInputFieldType {
        switch type {
        case .string:
            return .string
        case .number:
            return .number
        case .boolean:
            return .boolean
        case .object:
            return .object
        case .any:
            return .any
        case .array(let elementType):
            return .array(publicInputType(from: elementType))
        }
    }

    private static func publicMacroSignature(from signature: MacroSignatureNode, body: [ASTNode]) -> MacroSignature {
        MacroSignature(
            name: signature.name.string,
            parameters: signature.parameters.map { parameter in
                MacroParameter(
                    name: parameter.name.string,
                    hasDefault: parameter.defaultValue != nil,
                    defaultValueDescription: parameter.defaultValue?.description
                )
            },
            slots: collectSlotDefinitions(from: body)
        )
    }

    private static func publicMacroImport(from macroImport: MacroImportNode) -> MacroImport {
        MacroImport(
            template: macroImport.template.string,
            namespace: macroImport.namespace?.string,
            importedMacros: macroImport.importedMacros.map(\.string)
        )
    }

    private static func publicMacroCallSite(
        name: String,
        arguments: [CallArgument],
        body: [ASTNode]? = nil
    ) -> MacroCallSite {
        MacroCallSite(
            name: name,
            positionalArgumentCount: arguments.filter { $0.label == nil }.count,
            namedArguments: arguments.compactMap { $0.label?.string },
            filledSlots: collectFilledSlots(from: body),
            hasBlockBody: body != nil
        )
    }

    private static func collectSlotDefinitions(from nodes: [ASTNode]) -> [MacroSlotDefinition] {
        var slots: [String: Bool] = [:]
        var stack = nodes

        while let node = stack.popLast() {
            if case .slot(let name, let body) = node {
                slots[name.string] = !body.isEmpty
            }
            stack.append(contentsOf: node.children)
        }

        return slots.keys.sorted().map { name in
            MacroSlotDefinition(name: name, hasFallback: slots[name] ?? false)
        }
    }

    private static func collectFilledSlots(from nodes: [ASTNode]?) -> [String] {
        guard let nodes else { return [] }
        return nodes.compactMap { node in
            guard case .fill(let name, _) = node else { return nil }
            return name.string
        }.sorted()
    }

    private struct StaticMacroDefinition {
        struct SlotContract {
            let hasFallback: Bool
        }

        let name: String
        let signature: MacroSignatureNode
        let slots: [String: SlotContract]
    }

    private struct MacroImportBindings {
        var directNames: Set<String> = []
        var directDefinitions: [String: StaticMacroDefinition] = [:]
        var namespaceDefinitions: [String: [String: StaticMacroDefinition]] = [:]
        var unresolvedDirectNames: Set<String> = []
        var unresolvedNamespaces: Set<String> = []
        var validationErrors: [String] = []
        var macroDiagnostics: [String] = []
    }

    private struct ImportedMacroScope {
        var definitions: [String: StaticMacroDefinition] = [:]
        var validationErrors: [String] = []
        var macroDiagnostics: [String] = []
    }

    private struct ImportedMacroResolutionError: Error {
        let diagnostic: String
    }

    // SAFETY: Single-task scoped; never shared across concurrency domains
    private final class ImportedMacroResolutionContext: @unchecked Sendable {
        let templateLoader: TemplateLoader
        let customTagDescriptors: [CustomTagDescriptor]
        var importPathStack: [String]
        var cache: [String: ImportedMacroScope] = [:]

        init(
            templateLoader: TemplateLoader,
            customTagDescriptors: [CustomTagDescriptor],
            rootTemplatePath: String?
        ) {
            self.templateLoader = templateLoader
            self.customTagDescriptors = customTagDescriptors
            self.importPathStack = rootTemplatePath.map { [$0] } ?? []
        }
    }

    private struct CallBodyContract {
        let hasDefaultBody: Bool
        let fillNames: [String]
        let duplicateFillNames: [String]
        let containsNestedFill: Bool
    }

    private struct InputContractValidation {
        let missingRequiredInputs: [String]
        let validationErrors: [String]
        let warnings: [String]
        let macroDiagnostics: [String]
    }

    private static func validateAuthoringContracts(
        ast: ASTNode,
        manifest: TemplateManifest,
        context: UnsafeAnalysisContext?,
        templateLoader: TemplateLoader?,
        parentTemplatePath: String?,
        customTagDescriptors: [CustomTagDescriptor]
    ) async -> InputContractValidation {
        var missingRequiredInputs: [String] = []
        var validationErrors: [String] = []
        var macroDiagnostics: [String] = []

        if let context {
            for field in manifest.declaredInputs {
                let path = parseInputFieldPath(field.name)
                switch validateField(
                    path: path,
                    in: context.values,
                    expected: field.type,
                    declaredPath: field.name
                ) {
                case .valid:
                    break
                case .missing(let missingPaths):
                    if field.required {
                        let reportedPaths = missingPaths.isEmpty ? [field.name] : missingPaths
                        missingRequiredInputs.append(contentsOf: reportedPaths)
                        validationErrors.append(
                            contentsOf: reportedPaths.map { "Missing required input '\($0)'." }
                        )
                    }
                case .typeMismatch(let path, let expectedType, let actualType):
                    validationErrors.append(
                        "Input '\(path)' expected \(expectedType) but received \(actualType)."
                    )
                }

                if field.strict {
                    validationErrors.append(
                        contentsOf: validateStrictField(
                            path: path,
                            in: context.values,
                            declaredPath: field.name,
                            allFields: manifest.declaredInputs
                        )
                    )
                }
            }
        }

        let localMacros = collectStaticMacroDefinitions(from: ast)
        let importBindings = await collectImportedMacroBindings(
            from: ast,
            templateLoader: templateLoader,
            parentTemplatePath: parentTemplatePath,
            customTagDescriptors: customTagDescriptors
        )
        validationErrors.append(contentsOf: importBindings.validationErrors)
        macroDiagnostics.append(contentsOf: importBindings.macroDiagnostics)
        let macroValidation = validateMacroContracts(
            in: ast,
            localMacros: localMacros,
            importBindings: importBindings
        )
        validationErrors.append(contentsOf: macroValidation.validationErrors)
        macroDiagnostics.append(contentsOf: macroValidation.macroDiagnostics)

        return InputContractValidation(
            missingRequiredInputs: missingRequiredInputs.sorted(),
            validationErrors: sortedUniqueStrings(validationErrors),
            warnings: [],
            macroDiagnostics: sortedUniqueStrings(macroDiagnostics)
        )
    }

    private static func collectStaticMacroDefinitions(from ast: ASTNode) -> [String: StaticMacroDefinition] {
        var definitions: [String: StaticMacroDefinition] = [:]
        var stack = [ast]

        while let node = stack.popLast() {
            if case .macro(let signature, let body) = node {
                definitions[signature.name.string] = StaticMacroDefinition(
                    name: signature.name.string,
                    signature: signature,
                    slots: Dictionary(
                        uniqueKeysWithValues: collectSlotDefinitions(from: body).map {
                            ($0.name, StaticMacroDefinition.SlotContract(hasFallback: $0.hasFallback))
                        }
                    )
                )
            }
            stack.append(contentsOf: node.children)
        }

        return definitions
    }

    private static func collectImportedMacroBindings(
        from ast: ASTNode,
        templateLoader: TemplateLoader?,
        parentTemplatePath: String?,
        customTagDescriptors: [CustomTagDescriptor]
    ) async -> MacroImportBindings {
        var bindings = MacroImportBindings()
        let resolutionContext = templateLoader.map {
            ImportedMacroResolutionContext(
                templateLoader: $0,
                customTagDescriptors: customTagDescriptors,
                rootTemplatePath: parentTemplatePath
            )
        }
        var stack = [ast]

        while let node = stack.popLast() {
            if case .macroImport(let macroImport) = node {
                let importedScope: ImportedMacroScope?
                var unresolvedImportDiagnostic: String?

                if let resolutionContext {
                    switch await resolveImportedMacroScope(
                        template: macroImport.template.string,
                        relativeTo: parentTemplatePath,
                        resolutionContext: resolutionContext
                    ) {
                    case .success(let scope):
                        importedScope = scope
                        bindings.validationErrors.append(contentsOf: scope.validationErrors)
                        bindings.macroDiagnostics.append(contentsOf: scope.macroDiagnostics)
                    case .failure(let error):
                        importedScope = nil
                        unresolvedImportDiagnostic = error.diagnostic
                    }
                } else {
                    importedScope = nil
                }

                if let namespace = macroImport.namespace?.string {
                    if let importedScope {
                        bindings.namespaceDefinitions[namespace] = importedScope.definitions
                    } else {
                        bindings.unresolvedNamespaces.insert(namespace)
                        bindings.macroDiagnostics.append(
                            unresolvedImportDiagnostic
                                ?? "Macro import '\(macroImport.template.string)' could not be resolved."
                        )
                    }
                } else {
                    let importedNames = Set(macroImport.importedMacros.map(\.string))
                    bindings.directNames.formUnion(importedNames)

                    if let importedScope {
                        for macroName in importedNames {
                            if let definition = importedScope.definitions[macroName] {
                                bindings.directDefinitions[macroName] = definition
                            } else {
                                bindings.validationErrors.append("Undefined imported macro: \(macroName)")
                            }
                        }
                    } else {
                        bindings.unresolvedDirectNames.formUnion(importedNames)
                        bindings.macroDiagnostics.append(
                            unresolvedImportDiagnostic
                                ?? "Macro import '\(macroImport.template.string)' could not be resolved."
                        )
                    }
                }
            }
            stack.append(contentsOf: node.children)
        }

        return bindings
    }

    private static func resolveImportedMacroScope(
        template: String,
        relativeTo parentTemplatePath: String?,
        resolutionContext: ImportedMacroResolutionContext
    ) async -> Result<ImportedMacroScope, ImportedMacroResolutionError> {
        let resolvedPath: String

        do {
            resolvedPath = try await resolutionContext.templateLoader.resolvedTemplatePath(
                for: template,
                relativeTo: parentTemplatePath
            )
        } catch {
            return .failure(
                ImportedMacroResolutionError(
                    diagnostic: "Macro import '\(template)' could not be resolved."
                )
            )
        }

        if let cached = resolutionContext.cache[resolvedPath] {
            return .success(cached)
        }

        if resolutionContext.importPathStack.contains(resolvedPath) {
            return .failure(
                ImportedMacroResolutionError(
                    diagnostic: "Macro import '\(template)' could not be resolved due to circular imports."
                )
            )
        }

        resolutionContext.importPathStack.append(resolvedPath)
        defer { _ = resolutionContext.importPathStack.popLast() }

        do {
            let importedAST = try await resolutionContext.templateLoader.loadTemplateAST(
                template,
                relativeTo: parentTemplatePath,
                customTagDescriptors: resolutionContext.customTagDescriptors
            )
            let scope = await collectAvailableImportedMacros(
                from: importedAST,
                templatePath: resolvedPath,
                resolutionContext: resolutionContext
            )
            resolutionContext.cache[resolvedPath] = scope
            return .success(scope)
        } catch {
            return .failure(
                ImportedMacroResolutionError(
                    diagnostic: "Macro import '\(template)' could not be resolved."
                )
            )
        }
    }

    private static func collectAvailableImportedMacros(
        from ast: ASTNode,
        templatePath: String,
        resolutionContext: ImportedMacroResolutionContext
    ) async -> ImportedMacroScope {
        var definitions: [String: StaticMacroDefinition] = [:]
        var validationErrors: [String] = []
        var macroDiagnostics: [String] = []

        await collectAvailableImportedMacros(
            from: ast,
            templatePath: templatePath,
            resolutionContext: resolutionContext,
            definitions: &definitions,
            validationErrors: &validationErrors,
            macroDiagnostics: &macroDiagnostics
        )

        return ImportedMacroScope(
            definitions: definitions,
            validationErrors: sortedUniqueStrings(validationErrors),
            macroDiagnostics: sortedUniqueStrings(macroDiagnostics)
        )
    }

    private static func collectAvailableImportedMacros(
        from node: ASTNode,
        templatePath: String,
        resolutionContext: ImportedMacroResolutionContext,
        definitions: inout [String: StaticMacroDefinition],
        validationErrors: inout [String],
        macroDiagnostics: inout [String]
    ) async {
        switch node {
        case .template(let nodes):
            for child in nodes {
                await collectAvailableImportedMacros(
                    from: child,
                    templatePath: templatePath,
                    resolutionContext: resolutionContext,
                    definitions: &definitions,
                    validationErrors: &validationErrors,
                    macroDiagnostics: &macroDiagnostics
                )
            }

        case .macro(let signature, let body):
            let macroName = signature.name.string
            if definitions[macroName] == nil {
                definitions[macroName] = StaticMacroDefinition(
                    name: macroName,
                    signature: signature,
                    slots: Dictionary(
                        uniqueKeysWithValues: collectSlotDefinitions(from: body).map {
                            ($0.name, StaticMacroDefinition.SlotContract(hasFallback: $0.hasFallback))
                        }
                    )
                )
            } else {
                validationErrors.append("Duplicate macro definition: \(macroName)")
            }

        case .macroImport(let macroImport):
            switch await resolveImportedMacroScope(
                template: macroImport.template.string,
                relativeTo: templatePath,
                resolutionContext: resolutionContext
            ) {
            case .success(let importedScope):
                validationErrors.append(contentsOf: importedScope.validationErrors)
                macroDiagnostics.append(contentsOf: importedScope.macroDiagnostics)

                if let namespace = macroImport.namespace?.string {
                    for (name, definition) in importedScope.definitions {
                        let exportedName = "\(namespace).\(name)"
                        if definitions[exportedName] == nil {
                            definitions[exportedName] = definition
                        }
                    }
                } else {
                    for importedName in macroImport.importedMacros.map(\.string) {
                        if let definition = importedScope.definitions[importedName] {
                            if definitions[importedName] == nil {
                                definitions[importedName] = definition
                            }
                        } else {
                            validationErrors.append("Undefined imported macro: \(importedName)")
                        }
                    }
                }

            case .failure(let error):
                macroDiagnostics.append(error.diagnostic)
            }

        case .text, .output, .assign, .include, .input, .comment, .raw,
             .if, .unless, .case, .for, .tablerow, .capture, .increment,
             .decrement, .break, .continue, .cycle, .call, .slot, .fill,
             .block, .renderBlock, .extends, .liquid, .echo, .debug,
             .pipeline, .custom, .registeredCustomTag:
            for child in node.children {
                await collectAvailableImportedMacros(
                    from: child,
                    templatePath: templatePath,
                    resolutionContext: resolutionContext,
                    definitions: &definitions,
                    validationErrors: &validationErrors,
                    macroDiagnostics: &macroDiagnostics
                )
            }
        }
    }

    private static func validateMacroContracts(
        in ast: ASTNode,
        localMacros: [String: StaticMacroDefinition],
        importBindings: MacroImportBindings
    ) -> (validationErrors: [String], macroDiagnostics: [String]) {
        var validationErrors: [String] = []
        var macroDiagnostics: [String] = []
        var duplicateMacroNames = Set<String>()
        var seenMacroNames = Set<String>()
        var stack = [ast]

        while let node = stack.popLast() {
            switch node {
            case .macro(let signature, _):
                let macroName = signature.name.string
                if !seenMacroNames.insert(macroName).inserted {
                    duplicateMacroNames.insert(macroName)
                }
            case .call(let name, let arguments, let body):
                let result = validateTagMacroCall(
                    name: name.string,
                    arguments: arguments,
                    body: body,
                    localMacros: localMacros,
                    importBindings: importBindings
                )
                validationErrors.append(contentsOf: result.validationErrors)
                macroDiagnostics.append(contentsOf: result.macroDiagnostics)
            default:
                break
            }

            for expression in node.expressions {
                let result = validateExpressionMacroCalls(
                    in: expression,
                    localMacros: localMacros,
                    importBindings: importBindings
                )
                validationErrors.append(contentsOf: result.validationErrors)
                macroDiagnostics.append(contentsOf: result.macroDiagnostics)
            }

            stack.append(contentsOf: node.children)
        }

        for name in duplicateMacroNames {
            validationErrors.append("Duplicate macro definition: \(name)")
        }

        return (sortedUniqueStrings(validationErrors), sortedUniqueStrings(macroDiagnostics))
    }

    private static func validateTagMacroCall(
        name: String,
        arguments: [CallArgument],
        body: [ASTNode]?,
        localMacros: [String: StaticMacroDefinition],
        importBindings: MacroImportBindings
    ) -> (validationErrors: [String], macroDiagnostics: [String]) {
        guard let resolution = resolveMacro(name, localMacros: localMacros, importBindings: importBindings) else {
            return (["Undefined macro: \(name)"], [])
        }

        let macro: StaticMacroDefinition
        switch resolution {
        case .local(let definition), .imported(let definition):
            macro = definition
        case .unresolvedImport:
            return ([], [])
        case .missingImportedMacro:
            return (["Undefined imported macro: \(name)"], [])
        }

        var validationErrors = validateMacroArguments(
            signature: macro.signature,
            arguments: arguments,
            macroName: name
        )
        var macroDiagnostics: [String] = []

        let callBody = analyzeCallBody(body)
        if callBody.containsNestedFill {
            validationErrors.append("fill blocks must be top-level children of a block-form call: \(name)")
        }
        for fillName in callBody.duplicateFillNames {
            validationErrors.append("Duplicate fill '\(fillName)' for macro \(name)")
        }
        if callBody.hasDefaultBody && macro.slots["default"] == nil {
            validationErrors.append("Macro \(name) does not declare a default slot")
        }
        for fillName in callBody.fillNames where macro.slots[fillName] == nil {
            validationErrors.append("Unknown fill '\(fillName)' for macro \(name)")
        }

        for (slotName, slotContract) in macro.slots where !slotContract.hasFallback {
            if slotName == "default" {
                if !callBody.hasDefaultBody {
                    macroDiagnostics.append("Macro call '\(name)' leaves required slot 'default' unresolved.")
                }
            } else if !callBody.fillNames.contains(slotName) {
                macroDiagnostics.append("Macro call '\(name)' leaves required slot '\(slotName)' unresolved.")
            }
        }

        return (sortedUniqueStrings(validationErrors), sortedUniqueStrings(macroDiagnostics))
    }

    private static func validateExpressionMacroCalls(
        in expression: LiquidCore.Expression,
        localMacros: [String: StaticMacroDefinition],
        importBindings: MacroImportBindings
    ) -> (validationErrors: [String], macroDiagnostics: [String]) {
        switch expression {
        case .call(let name, let arguments):
            guard let resolution = resolveMacro(name.string, localMacros: localMacros, importBindings: importBindings) else {
                return (["Undefined macro: \(name.string)"], [])
            }

            let macro: StaticMacroDefinition
            switch resolution {
            case .local(let definition), .imported(let definition):
                macro = definition
            case .unresolvedImport:
                return ([], [])
            case .missingImportedMacro:
                return (["Undefined imported macro: \(name.string)"], [])
            }

            var macroDiagnostics: [String] = []
            for (slotName, slotContract) in macro.slots where !slotContract.hasFallback {
                macroDiagnostics.append(
                    "Expression-call macro '\(name.string)' cannot satisfy required slot '\(slotName)'."
                )
            }
            return (
                sortedUniqueStrings(
                    validateMacroArguments(
                        signature: macro.signature,
                        arguments: arguments,
                        macroName: name.string
                    )
                ),
                sortedUniqueStrings(macroDiagnostics)
            )
        case .binary(let left, _, let right):
            return mergeMacroValidationResults(
                validateExpressionMacroCalls(in: left, localMacros: localMacros, importBindings: importBindings),
                validateExpressionMacroCalls(in: right, localMacros: localMacros, importBindings: importBindings)
            )
        case .unary(_, let expr), .test(let expr, _):
            return validateExpressionMacroCalls(in: expr, localMacros: localMacros, importBindings: importBindings)
        case .range(let start, let end):
            return mergeMacroValidationResults(
                validateExpressionMacroCalls(in: start, localMacros: localMacros, importBindings: importBindings),
                validateExpressionMacroCalls(in: end, localMacros: localMacros, importBindings: importBindings)
            )
        case .filtered(let base, let filters):
            var result = validateExpressionMacroCalls(
                in: base,
                localMacros: localMacros,
                importBindings: importBindings
            )

            for filter in filters {
                for argument in filter.arguments {
                    result = mergeMacroValidationResults(
                        result,
                        validateExpressionMacroCalls(
                            in: argument,
                            localMacros: localMacros,
                            importBindings: importBindings
                        )
                    )
                }
                for argument in filter.namedArguments.values {
                    result = mergeMacroValidationResults(
                        result,
                        validateExpressionMacroCalls(
                            in: argument,
                            localMacros: localMacros,
                            importBindings: importBindings
                        )
                    )
                }
            }

            return result
        case .access(let base, let key):
            return mergeMacroValidationResults(
                validateExpressionMacroCalls(in: base, localMacros: localMacros, importBindings: importBindings),
                validateExpressionMacroCalls(in: key, localMacros: localMacros, importBindings: importBindings)
            )
        case .literal, .variable:
            return ([], [])
        }
    }

    private static func validateMacroArguments(
        signature: MacroSignatureNode,
        arguments: [CallArgument],
        macroName: String
    ) -> [String] {
        var bindings = Set<String>()
        var validationErrors: [String] = []
        var nextPositionalIndex = 0
        let parameterOrder = signature.parameters.map { $0.name.string }
        let validNames = Set(parameterOrder)

        for argument in arguments {
            if let label = argument.label?.string {
                guard validNames.contains(label) else {
                    validationErrors.append("Unknown macro parameter '\(label)' for \(macroName)")
                    continue
                }
                bindings.insert(label)
                continue
            }

            while nextPositionalIndex < parameterOrder.count,
                  bindings.contains(parameterOrder[nextPositionalIndex]) {
                nextPositionalIndex += 1
            }

            guard nextPositionalIndex < parameterOrder.count else {
                validationErrors.append("Too many positional arguments for macro \(macroName)")
                continue
            }

            bindings.insert(parameterOrder[nextPositionalIndex])
            nextPositionalIndex += 1
        }

        for parameter in signature.parameters {
            let parameterName = parameter.name.string
            if bindings.contains(parameterName) {
                continue
            }
            if parameter.defaultValue == nil {
                validationErrors.append("Missing required macro parameter '\(parameterName)' for \(macroName)")
            }
        }

        return validationErrors
    }

    private static func analyzeCallBody(_ body: [ASTNode]?) -> CallBodyContract {
        guard let body else {
            return CallBodyContract(
                hasDefaultBody: false,
                fillNames: [],
                duplicateFillNames: [],
                containsNestedFill: false
            )
        }

        var hasDefaultBody = false
        var fillNames: [String] = []
        var duplicateFillNames = Set<String>()
        var seenFillNames = Set<String>()
        var containsNestedFill = false

        for node in body {
            if case .fill(let fillName, _) = node {
                let name = fillName.string
                if !seenFillNames.insert(name).inserted {
                    duplicateFillNames.insert(name)
                }
                fillNames.append(name)
                continue
            }

            if containsNestedFillNode(node) {
                containsNestedFill = true
            }
            hasDefaultBody = true
        }

        return CallBodyContract(
            hasDefaultBody: hasDefaultBody,
            fillNames: fillNames.sorted(),
            duplicateFillNames: Array(duplicateFillNames).sorted(),
            containsNestedFill: containsNestedFill
        )
    }

    private static func containsNestedFillNode(_ node: ASTNode) -> Bool {
        var stack = node.children

        while let current = stack.popLast() {
            if case .fill = current {
                return true
            }
            stack.append(contentsOf: current.children)
        }

        return false
    }

    private enum MacroResolution {
        case local(StaticMacroDefinition)
        case imported(StaticMacroDefinition)
        case unresolvedImport
        case missingImportedMacro
    }

    private static func resolveMacro(
        _ name: String,
        localMacros: [String: StaticMacroDefinition],
        importBindings: MacroImportBindings
    ) -> MacroResolution? {
        if let macro = localMacros[name] {
            return .local(macro)
        }
        if let macro = importBindings.directDefinitions[name] {
            return .imported(macro)
        }
        if importBindings.unresolvedDirectNames.contains(name) {
            return .unresolvedImport
        }
        if importBindings.directNames.contains(name) {
            return .missingImportedMacro
        }
        if let dotIndex = name.firstIndex(of: ".") {
            let namespace = String(name[..<dotIndex])
            let macroName = String(name[name.index(after: dotIndex)...])
            if let definitions = importBindings.namespaceDefinitions[namespace] {
                if let macro = definitions[macroName] {
                    return .imported(macro)
                }
                return .missingImportedMacro
            }
            if importBindings.unresolvedNamespaces.contains(namespace) {
                return .unresolvedImport
            }
        }
        return nil
    }

    private static func mergeMacroValidationResults(
        _ lhs: (validationErrors: [String], macroDiagnostics: [String]),
        _ rhs: (validationErrors: [String], macroDiagnostics: [String])
    ) -> (validationErrors: [String], macroDiagnostics: [String]) {
        (
            sortedUniqueStrings(lhs.validationErrors + rhs.validationErrors),
            sortedUniqueStrings(lhs.macroDiagnostics + rhs.macroDiagnostics)
        )
    }

    private static func sortedUniqueStrings(_ values: [String]) -> [String] {
        Array(Set(values)).sorted()
    }

    private static func valueMatchesType(_ value: Any, expected type: TemplateInputFieldType) -> Bool {
        switch type {
        case .any:
            return true
        case .string:
            return value is String || value is InlineString
        case .number:
            return value is Int || value is Double || value is Float || value is NSNumber
        case .boolean:
            return value is Bool
        case .object:
            if value is [String: Any] {
                return true
            }
            if let dataValue = value as? DataValue,
               case .object = dataValue {
                return true
            }
            return false
        case .array(let elementType):
            let array: [Any]
            if let values = value as? [Any] {
                array = values
            } else if let dataValue = value as? DataValue,
                      case .array(let values) = dataValue {
                array = values.map(\.liquidValue)
            } else {
                return false
            }
            return array.allSatisfy { valueMatchesType($0, expected: elementType) }
        }
    }

    private static func typeDescription(for value: Any) -> String {
        switch value {
        case is String, is InlineString:
            return "string"
        case is Bool:
            return "boolean"
        case is Int, is Double, is Float, is NSNumber:
            return "number"
        case is [Any]:
            return "array"
        case let dataValue as DataValue:
            switch dataValue {
            case .array:
                return "array"
            case .object:
                return "object"
            case .string:
                return "string"
            case .bool:
                return "boolean"
            case .int, .double:
                return "number"
            case .null:
                return "null"
            case .date:
                return "date"
            case .data:
                return "data"
            }
        case is [String: Any]:
            return "object"
        default:
            return String(describing: type(of: value))
        }
    }

    private enum FieldValidationResult {
        case valid
        case missing([String])
        case typeMismatch(path: String, expectedType: String, actualType: String)
    }

    private struct ResolvedStrictObject {
        let path: String
        let keys: [String]
    }

    private static func parseInputFieldPath(_ path: String) -> [TemplateInputPathComponent] {
        guard !path.isEmpty else {
            return []
        }

        var components: [TemplateInputPathComponent] = []
        var current = ""
        var index = path.startIndex

        while index < path.endIndex {
            let character = path[index]
            switch character {
            case ".":
                if !current.isEmpty {
                    components.append(.key(current))
                    current.removeAll(keepingCapacity: true)
                }
            case "[":
                if !current.isEmpty {
                    components.append(.key(current))
                    current.removeAll(keepingCapacity: true)
                }
                let next = path.index(after: index)
                if next < path.endIndex, path[next] == "]" {
                    components.append(.arrayElement)
                    index = next
                }
            default:
                current.append(character)
            }
            index = path.index(after: index)
        }

        if !current.isEmpty {
            components.append(.key(current))
        }

        return components
    }

    private static func validateField(
        path: [TemplateInputPathComponent],
        in context: [String: Any],
        expected type: TemplateInputFieldType,
        declaredPath: String
    ) -> FieldValidationResult {
        validateField(
            path: path,
            currentValue: context,
            expected: type,
            currentPath: "",
            declaredPath: declaredPath
        )
    }

    private static func validateField(
        path: [TemplateInputPathComponent],
        currentValue: Any?,
        expected type: TemplateInputFieldType,
        currentPath: String,
        declaredPath: String
    ) -> FieldValidationResult {
        guard !path.isEmpty else {
            guard let currentValue else {
                return .missing([currentPath.isEmpty ? declaredPath : currentPath])
            }
            return valueMatchesType(currentValue, expected: type)
                ? .valid
                : .typeMismatch(
                    path: reportedInputPath(currentPath, fallback: declaredPath),
                    expectedType: type.description,
                    actualType: typeDescription(for: currentValue)
                )
        }

        guard let currentValue else {
            return .missing([
                materializeInputPath(
                    currentPath: currentPath,
                    remainingPath: path,
                    fallback: declaredPath
                )
            ])
        }

        switch path[0] {
        case .key(let key):
            if let dictionary = currentValue as? [String: Any] {
                return validateField(
                    path: Array(path.dropFirst()),
                    currentValue: dictionary[key],
                    expected: type,
                    currentPath: appendInputPathKey(currentPath, key: key),
                    declaredPath: declaredPath
                )
            }

            if let dataValue = currentValue as? DataValue {
                let child = dataValue[key]
                if case .null = child {
                    return .missing([
                        materializeInputPath(
                            currentPath: appendInputPathKey(currentPath, key: key),
                            remainingPath: Array(path.dropFirst()),
                            fallback: declaredPath
                        )
                    ])
                }
                return validateField(
                    path: Array(path.dropFirst()),
                    currentValue: child.liquidValue,
                    expected: type,
                    currentPath: appendInputPathKey(currentPath, key: key),
                    declaredPath: declaredPath
                )
            }

            return .typeMismatch(
                path: reportedInputPath(currentPath, fallback: declaredPath),
                expectedType: "object",
                actualType: typeDescription(for: currentValue)
            )

        case .arrayElement:
            let array: [Any]
            if let values = currentValue as? [Any] {
                array = values
            } else if let dataValue = currentValue as? DataValue,
                      case .array(let values) = dataValue {
                array = values.map(\.liquidValue)
            } else {
                return .typeMismatch(
                    path: reportedInputPath(currentPath, fallback: declaredPath),
                    expectedType: "array",
                    actualType: typeDescription(for: currentValue)
                )
            }

            guard !array.isEmpty else {
                return .missing([
                    materializeInputPath(
                        currentPath: currentPath,
                        remainingPath: path,
                        fallback: declaredPath
                    )
                ])
            }

            var missingPaths: [String] = []

            for (index, element) in array.enumerated() {
                let result = validateField(
                    path: Array(path.dropFirst()),
                    currentValue: element,
                    expected: type,
                    currentPath: appendInputPathIndex(currentPath, index: index),
                    declaredPath: declaredPath
                )
                switch result {
                case .valid:
                    continue
                case .typeMismatch:
                    return result
                case .missing(let indexedPaths):
                    missingPaths.append(contentsOf: indexedPaths)
                }
            }

            return missingPaths.isEmpty ? .valid : .missing(sortedUniqueStrings(missingPaths))
        }
    }

    private static func validateStrictField(
        path: [TemplateInputPathComponent],
        in context: [String: Any],
        declaredPath: String,
        allFields: [TemplateInputField]
    ) -> [String] {
        let allowedKeys = allowedDirectChildKeys(for: path, across: allFields)
        let resolvedObjects = resolveStrictObjects(
            path: path,
            currentValue: context,
            currentPath: ""
        )

        guard !resolvedObjects.isEmpty else {
            return []
        }

        var errors: [String] = []
        for resolved in resolvedObjects {
            for key in resolved.keys where !allowedKeys.contains(key) {
                errors.append(
                    "Input '\(appendInputPathKey(resolved.path, key: key))' is not declared by strict contract '\(declaredPath)'."
                )
            }
        }

        return sortedUniqueStrings(errors)
    }

    private static func allowedDirectChildKeys(
        for strictPath: [TemplateInputPathComponent],
        across fields: [TemplateInputField]
    ) -> Set<String> {
        var keys = Set<String>()

        for field in fields {
            let fieldPath = parseInputFieldPath(field.name)
            guard fieldPath.count > strictPath.count else {
                continue
            }
            guard Array(fieldPath.prefix(strictPath.count)) == strictPath else {
                continue
            }
            guard case .key(let key) = fieldPath[strictPath.count] else {
                continue
            }
            keys.insert(key)
        }

        return keys
    }

    private static func resolveStrictObjects(
        path: [TemplateInputPathComponent],
        currentValue: Any?,
        currentPath: String
    ) -> [ResolvedStrictObject] {
        guard let currentValue else {
            return []
        }

        guard !path.isEmpty else {
            guard let keys = directObjectKeys(from: currentValue) else {
                return []
            }
            return [
                ResolvedStrictObject(
                    path: currentPath,
                    keys: keys
                )
            ]
        }

        switch path[0] {
        case .key(let key):
            if let dictionary = currentValue as? [String: Any] {
                return resolveStrictObjects(
                    path: Array(path.dropFirst()),
                    currentValue: dictionary[key],
                    currentPath: appendInputPathKey(currentPath, key: key)
                )
            }

            if let dataValue = currentValue as? DataValue {
                let child = dataValue[key]
                if case .null = child {
                    return []
                }
                return resolveStrictObjects(
                    path: Array(path.dropFirst()),
                    currentValue: child.liquidValue,
                    currentPath: appendInputPathKey(currentPath, key: key)
                )
            }

            return []

        case .arrayElement:
            let array: [Any]
            if let values = currentValue as? [Any] {
                array = values
            } else if let dataValue = currentValue as? DataValue,
                      case .array(let values) = dataValue {
                array = values.map(\.liquidValue)
            } else {
                return []
            }

            return array.enumerated().flatMap { index, element in
                resolveStrictObjects(
                    path: Array(path.dropFirst()),
                    currentValue: element,
                    currentPath: appendInputPathIndex(currentPath, index: index)
                )
            }
        }
    }

    private static func directObjectKeys(from value: Any) -> [String]? {
        if let dictionary = value as? [String: Any] {
            return dictionary.keys.sorted()
        }

        if let dataValue = value as? DataValue,
           case .object(let dictionary) = dataValue {
            return dictionary.keys.sorted()
        }

        return nil
    }

    private static func appendInputPathKey(_ currentPath: String, key: String) -> String {
        if currentPath.isEmpty {
            return key
        }

        return "\(currentPath).\(key)"
    }

    private static func appendInputPathIndex(_ currentPath: String, index: Int) -> String {
        "\(currentPath)[\(index)]"
    }

    private static func reportedInputPath(_ currentPath: String, fallback: String) -> String {
        currentPath.isEmpty ? fallback : currentPath
    }

    private static func materializeInputPath(
        currentPath: String,
        remainingPath: [TemplateInputPathComponent],
        fallback: String
    ) -> String {
        var resolvedPath = currentPath

        for component in remainingPath {
            switch component {
            case .key(let key):
                resolvedPath = appendInputPathKey(resolvedPath, key: key)
            case .arrayElement:
                if resolvedPath.isEmpty {
                    resolvedPath = fallback
                } else {
                    resolvedPath += "[]"
                }
            }
        }

        return resolvedPath.isEmpty ? fallback : resolvedPath
    }

    private static func classifyComplexity(manifest: TemplateManifest) -> TemplateComplexity {
        let score = manifest.requiredVariables.count
            + manifest.activeFilters.count * 2
            + manifest.activeTags.count * 3
            + manifest.referencedTemplates.count * 4
            + manifest.dataCapabilities.count * 2
            + manifest.macroDefinitions.count * 2
            + manifest.declaredInputs.count

        switch score {
        case ..<10:
            return .simple
        case ..<30:
            return .moderate
        case ..<60:
            return .complex
        default:
            return .veryComplex
        }
    }

    private static func qualityScore(
        manifest: TemplateManifest,
        securityIssues: [SecurityIssue],
        validationErrors: [String],
        macroDiagnostics: [String]
    ) -> Double {
        var score = 10.0
        score -= Double(validationErrors.count) * 2.5
        score -= Double(macroDiagnostics.count) * 0.25
        score -= Double(securityIssues.count) * 0.75
        if manifest.requiresExtendedProfile {
            score -= 0.5
        }
        if manifest.referencedTemplates.count > 32 {
            score -= 0.5
        }
        return max(0, min(score, 10))
    }

    private static func recommendations(
        manifest: TemplateManifest,
        securityIssues: [SecurityIssue],
        validationErrors: [String],
        macroDiagnostics: [String]
    ) -> [String] {
        var recommendations: [String] = []

        if !validationErrors.isEmpty {
            recommendations.append("Fix template syntax errors before using this template in service or publishing workflows.")
        }
        if !macroDiagnostics.isEmpty {
            recommendations.append("Review macro and slot diagnostics before promoting this template into shared authoring flows.")
        }
        if manifest.requiresExtendedProfile {
            recommendations.append("Run this template under the extended profile or remove opt-in features.")
        }
        if !manifest.dataCapabilities.isEmpty {
            recommendations.append("Review sandbox policy coverage for the data-source capabilities used by this template.")
        }
        if manifest.referencedTemplates.count > 16 {
            recommendations.append("Consider flattening deeply composed template graphs to reduce operational complexity.")
        }
        if !securityIssues.isEmpty {
            recommendations.append("Review the reported security issues before exposing this template through the native service.")
        }

        return recommendations
    }

    private static func estimatedRenderTime(for manifest: TemplateManifest) -> TimeInterval {
        let score = manifest.requiredVariables.count
            + manifest.activeFilters.count * 2
            + manifest.activeTags.count * 3
            + manifest.referencedTemplates.count * 4
            + manifest.dataCapabilities.count * 2
        return TimeInterval(score) * 0.001 + 0.001
    }

    private static func analysisWarnings(for manifest: TemplateManifest) -> [String] {
        var warnings: [String] = []
        if manifest.requiresExtendedProfile {
            warnings.append("Template uses opt-in extended features.")
        }
        if manifest.usesDebugFeatures {
            warnings.append("Template uses debug-oriented tags.")
        }
        if !manifest.dataCapabilities.isEmpty {
            warnings.append("Template uses data-source capabilities: \(manifest.dataCapabilities.joined(separator: ", ")).")
        }
        return warnings
    }

    private static func analyzeSecurityIssues(
        in template: String,
        manifest: TemplateManifest
    ) -> [SecurityIssue] {
        var issues: [SecurityIssue] = []

        let rawLikeFilters = ["raw", "strip_html"]
        for filter in manifest.activeFilters where rawLikeFilters.contains(filter) {
            issues.append(
                SecurityIssue(
                    type: "unsafe_filter",
                    severity: filter == "raw" ? "high" : "medium",
                    description: "Filter '\(filter)' can bypass or weaken output safety controls.",
                    location: "filter:\(filter)"
                )
            )
        }

        if template.localizedCaseInsensitiveContains("script")
            || template.localizedCaseInsensitiveContains("javascript:")
            || template.localizedCaseInsensitiveContains("onclick")
            || template.localizedCaseInsensitiveContains("onerror") {
            issues.append(
                SecurityIssue(
                    type: "potential_xss",
                    severity: "high",
                    description: "Template output appears to reference script-like or event-handler content.",
                    location: "template"
                )
            )
        }

        if manifest.referencedTemplates.count > 32 {
            issues.append(
                SecurityIssue(
                    type: "resource_exhaustion",
                    severity: "medium",
                    description: "Large template reference graph may create operational complexity or higher render cost.",
                    location: "template_graph"
                )
            )
        }

        let sensitiveRoots = ["password", "token", "secret", "apiKey", "privateKey"]
        for variable in manifest.variableRoots where sensitiveRoots.contains(variable) {
            issues.append(
                SecurityIssue(
                    type: "unauthorized_access",
                    severity: "high",
                    description: "Template references a potentially sensitive root variable '\(variable)'.",
                    location: variable
                )
            )
        }

        return issues
    }
}
