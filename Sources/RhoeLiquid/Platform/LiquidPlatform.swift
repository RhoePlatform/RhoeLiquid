//
//  LiquidPlatform.swift
//  RhoeLiquid
//
//  Shared platform contracts for Wave 13.
//

import Foundation
import LiquidCore
import LiquidTags

// SAFETY: Immutable after init; contains [String: Any] which is not Sendable
private struct UnsafeLiquidEnvironmentContext: @unchecked Sendable {
    let values: [String: Any]
}

private extension LiquidEngine {
    nonisolated func analyzeTemplateEnvironment(
        _ template: String,
        context: UnsafeLiquidEnvironmentContext?,
        templatePath: String? = nil,
        baseDirectory: URL? = nil
    ) async -> TemplateAnalysis {
        await analyzeTemplate(
            template,
            context: context?.values,
            templatePath: templatePath,
            baseDirectory: baseDirectory
        )
    }

    nonisolated func analyzeTemplateFileEnvironment(
        at path: String,
        context: UnsafeLiquidEnvironmentContext?,
        baseDirectory: URL? = nil
    ) async -> TemplateAnalysis {
        await analyzeTemplateFile(
            at: path,
            context: context?.values,
            baseDirectory: baseDirectory
        )
    }

    nonisolated func renderEnvironment(
        template: String,
        context: UnsafeLiquidEnvironmentContext
    ) async throws -> String {
        try await render(template: template, context: context.values)
    }

    nonisolated func renderWithMetricsEnvironment(
        template: String,
        context: UnsafeLiquidEnvironmentContext
    ) async throws -> (output: String, metrics: PerformanceMetrics) {
        try await renderWithMetrics(template: template, context: context.values)
    }
}

/// Compatibility profile that shapes how the active environment presents the
/// template runtime.
public enum CompatibilityProfile: String, Sendable, Codable, CaseIterable {
    case shopifyCompatible = "shopify_compatible"
    case extended = "extended"

    public var description: String {
        switch self {
        case .shopifyCompatible:
            return "Shopify-compatible baseline"
        case .extended:
            return "Opt-in Rhoe extension layer"
        }
    }
}

/// Structured sandbox policy for Liquid execution.
///
/// The current policy surface is intentionally small and policy-driven. The
/// environment enforces it before rendering rather than relying on one-off
/// feature checks scattered throughout the runtime.
public struct SandboxPolicy: Sendable, Codable, Equatable {
    public let name: String
    public let allowFileTemplates: Bool
    public let allowAbsoluteTemplatePaths: Bool
    public let allowDataSources: Bool
    public let allowCustomExtensions: Bool
    public let allowDebugTags: Bool
    public let allowedTags: [String]?
    public let allowedFilters: [String]?
    public let allowedDataCapabilities: [String]?
    public let maxReferencedTemplates: Int?

    public init(
        name: String,
        allowFileTemplates: Bool = true,
        allowAbsoluteTemplatePaths: Bool = false,
        allowDataSources: Bool = true,
        allowCustomExtensions: Bool = true,
        allowDebugTags: Bool = true,
        allowedTags: [String]? = nil,
        allowedFilters: [String]? = nil,
        allowedDataCapabilities: [String]? = nil,
        maxReferencedTemplates: Int? = nil
    ) {
        self.name = name
        self.allowFileTemplates = allowFileTemplates
        self.allowAbsoluteTemplatePaths = allowAbsoluteTemplatePaths
        self.allowDataSources = allowDataSources
        self.allowCustomExtensions = allowCustomExtensions
        self.allowDebugTags = allowDebugTags
        self.allowedTags = allowedTags?.sorted()
        self.allowedFilters = allowedFilters?.sorted()
        self.allowedDataCapabilities = allowedDataCapabilities?.sorted()
        self.maxReferencedTemplates = maxReferencedTemplates
    }

    public static let trustedLocal = SandboxPolicy(
        name: "trusted_local",
        allowFileTemplates: true,
        allowAbsoluteTemplatePaths: true,
        allowDataSources: true,
        allowCustomExtensions: true,
        allowDebugTags: true
    )

    public static let serviceSafe = SandboxPolicy(
        name: "service_safe",
        allowFileTemplates: true,
        allowAbsoluteTemplatePaths: false,
        allowDataSources: true,
        allowCustomExtensions: true,
        allowDebugTags: false,
        maxReferencedTemplates: 128
    )

    public static let compatibilityStrict = SandboxPolicy(
        name: "compatibility_strict",
        allowFileTemplates: true,
        allowAbsoluteTemplatePaths: false,
        allowDataSources: false,
        allowCustomExtensions: false,
        allowDebugTags: false,
        allowedTags: builtInTagNames.sorted(),
        allowedFilters: builtInFilterNames.sorted(),
        allowedDataCapabilities: [],
        maxReferencedTemplates: 64
    )

    public func allows(tag: String) -> Bool {
        guard let allowedTags else {
            return true
        }
        return allowedTags.contains(tag)
    }

    public func allows(filter: String) -> Bool {
        guard let allowedFilters else {
            return true
        }
        return allowedFilters.contains(filter)
    }

    public func allowsDataCapability(_ capability: String) -> Bool {
        guard allowDataSources else {
            return false
        }
        guard let allowedDataCapabilities else {
            return true
        }
        return allowedDataCapabilities.contains(capability)
    }
}

/// Stability labels for capability metadata.
public enum LiquidDocStability: String, Sendable, Codable, CaseIterable {
    case stable
    case compatibility
    case experimental
}

/// Compatibility labels for capability metadata.
public enum LiquidDocCompatibility: String, Sendable, Codable, CaseIterable {
    case shopifyCompatible = "shopify_compatible"
    case extended = "extended"
    case compatibilityOnly = "compatibility_only"
}

/// Metadata kind supported by the active platform layer.
public enum LiquidDocKind: String, Sendable, Codable, CaseIterable {
    case filter
    case tag
}

/// Machine-readable parameter metadata for tags and filters.
public struct LiquidDocParameter: Sendable, Codable, Equatable {
    public let name: String
    public let summary: String
    public let required: Bool

    public init(name: String, summary: String, required: Bool = false) {
        self.name = name
        self.summary = summary
        self.required = required
    }
}

/// Metadata used for documentation and capability discovery.
public struct LiquidDocMetadata: Sendable, Codable, Equatable {
    public let name: String
    public let kind: LiquidDocKind
    public let summary: String
    public let parameters: [LiquidDocParameter]
    public let stability: LiquidDocStability
    public let compatibility: LiquidDocCompatibility
    public let capabilityIdentifiers: [String]

    public init(
        name: String,
        kind: LiquidDocKind,
        summary: String,
        parameters: [LiquidDocParameter] = [],
        stability: LiquidDocStability = .stable,
        compatibility: LiquidDocCompatibility = .shopifyCompatible,
        capabilityIdentifiers: [String] = []
    ) {
        self.name = name
        self.kind = kind
        self.summary = summary
        self.parameters = parameters
        self.stability = stability
        self.compatibility = compatibility
        self.capabilityIdentifiers = capabilityIdentifiers
    }
}

/// Optional metadata provider for tags and filters that want richer docs output.
public protocol LiquidDocMetadataProvider: Sendable {
    var liquidDocMetadata: LiquidDocMetadata { get }
}

/// Narrow Wave 16 input field type surface exposed by template analysis.
public indirect enum TemplateInputFieldType: Sendable, Codable, Equatable {
    case string
    case number
    case boolean
    case object
    case any
    case array(TemplateInputFieldType)

    public var description: String {
        switch self {
        case .string:
            return "string"
        case .number:
            return "number"
        case .boolean:
            return "boolean"
        case .object:
            return "object"
        case .any:
            return "any"
        case .array(let elementType):
            return "array<\(elementType.description)>"
        }
    }
}

/// One declared template input field in the public analysis surface.
public struct TemplateInputField: Sendable, Codable, Equatable {
    public let name: String
    public let type: TemplateInputFieldType
    public let required: Bool
    public let strict: Bool
    public let defaultValueDescription: String?

    public init(
        name: String,
        type: TemplateInputFieldType,
        required: Bool,
        strict: Bool = false,
        defaultValueDescription: String? = nil
    ) {
        self.name = name
        self.type = type
        self.required = required
        self.strict = strict
        self.defaultValueDescription = defaultValueDescription
    }
}

/// Public template input contract surface used by services, publishing, and tooling.
public struct TemplateInputContract: Sendable, Codable, Equatable {
    public let fields: [TemplateInputField]

    public init(fields: [TemplateInputField]) {
        self.fields = fields
    }
}

/// One public macro parameter in the Wave 16 authoring layer.
public struct MacroParameter: Sendable, Codable, Equatable {
    public let name: String
    public let hasDefault: Bool
    public let defaultValueDescription: String?

    public init(name: String, hasDefault: Bool, defaultValueDescription: String? = nil) {
        self.name = name
        self.hasDefault = hasDefault
        self.defaultValueDescription = defaultValueDescription
    }
}

/// One public macro slot definition exposed through analysis and tooling.
public struct MacroSlotDefinition: Sendable, Codable, Equatable {
    public let name: String
    public let hasFallback: Bool

    public init(name: String, hasFallback: Bool) {
        self.name = name
        self.hasFallback = hasFallback
    }
}

/// Public macro signature exposed through analysis and capabilities.
public struct MacroSignature: Sendable, Codable, Equatable {
    public let name: String
    public let parameters: [MacroParameter]
    public let slots: [MacroSlotDefinition]

    public init(
        name: String,
        parameters: [MacroParameter],
        slots: [MacroSlotDefinition] = []
    ) {
        self.name = name
        self.parameters = parameters
        self.slots = slots
    }
}

/// Public macro import descriptor exposed through analysis and tooling surfaces.
public struct MacroImport: Sendable, Codable, Equatable {
    public let template: String
    public let namespace: String?
    public let importedMacros: [String]

    public init(template: String, namespace: String? = nil, importedMacros: [String] = []) {
        self.template = template
        self.namespace = namespace
        self.importedMacros = importedMacros
    }
}

/// Public macro call-site descriptor exposed through analysis.
public struct MacroCallSite: Sendable, Codable, Equatable {
    public let name: String
    public let positionalArgumentCount: Int
    public let namedArguments: [String]
    public let filledSlots: [String]
    public let hasBlockBody: Bool

    public init(
        name: String,
        positionalArgumentCount: Int,
        namedArguments: [String],
        filledSlots: [String] = [],
        hasBlockBody: Bool = false
    ) {
        self.name = name
        self.positionalArgumentCount = positionalArgumentCount
        self.namedArguments = namedArguments.sorted()
        self.filledSlots = filledSlots.sorted()
        self.hasBlockBody = hasBlockBody
    }
}

/// Manifest of the capabilities and dependencies used by a template.
public struct TemplateManifest: Sendable, Codable, Equatable {
    public let templateName: String?
    public let requiredVariables: [String]
    public let variableRoots: [String]
    public let referencedTemplates: [String]
    public let activeTags: [String]
    public let activeFilters: [String]
    public let dataCapabilities: [String]
    public let capabilityIdentifiers: [String]
    public let usesInheritance: Bool
    public let requiresExtendedProfile: Bool
    public let usesDebugFeatures: Bool
    public let declaredInputs: [TemplateInputField]
    public let contractDefaults: [String]
    public let macroDefinitions: [MacroSignature]
    public let macroImports: [MacroImport]
    public let macroCalls: [MacroCallSite]

    public init(
        templateName: String? = nil,
        requiredVariables: [String],
        variableRoots: [String],
        referencedTemplates: [String],
        activeTags: [String],
        activeFilters: [String],
        dataCapabilities: [String],
        capabilityIdentifiers: [String],
        usesInheritance: Bool,
        requiresExtendedProfile: Bool,
        usesDebugFeatures: Bool,
        declaredInputs: [TemplateInputField] = [],
        contractDefaults: [String] = [],
        macroDefinitions: [MacroSignature] = [],
        macroImports: [MacroImport] = [],
        macroCalls: [MacroCallSite] = []
    ) {
        self.templateName = templateName
        self.requiredVariables = requiredVariables
        self.variableRoots = variableRoots
        self.referencedTemplates = referencedTemplates
        self.activeTags = activeTags
        self.activeFilters = activeFilters
        self.dataCapabilities = dataCapabilities
        self.capabilityIdentifiers = capabilityIdentifiers
        self.usesInheritance = usesInheritance
        self.requiresExtendedProfile = requiresExtendedProfile
        self.usesDebugFeatures = usesDebugFeatures
        self.declaredInputs = declaredInputs
        self.contractDefaults = contractDefaults
        self.macroDefinitions = macroDefinitions
        self.macroImports = macroImports
        self.macroCalls = macroCalls
    }
}

/// Template complexity levels used by the analysis surface.
public enum TemplateComplexity: String, Sendable, Codable, CaseIterable {
    case simple
    case moderate
    case complex
    case veryComplex = "very_complex"
}

/// Security issue discovered during template analysis.
public struct SecurityIssue: Sendable, Codable, Equatable {
    public let type: String
    public let severity: String
    public let description: String
    public let location: String?

    public init(type: String, severity: String, description: String, location: String? = nil) {
        self.type = type
        self.severity = severity
        self.description = description
        self.location = location
    }
}

/// High-level template analysis used by services, tooling, and publication builds.
public struct TemplateAnalysis: Sendable, Codable, Equatable {
    public let manifest: TemplateManifest
    public let inputContract: TemplateInputContract
    public let complexity: TemplateComplexity
    public let qualityScore: Double
    public let variableCount: Int
    public let filterCount: Int
    public let tagCount: Int
    public let loopCount: Int
    public let securityIssues: [SecurityIssue]
    public let recommendations: [String]
    public let estimatedRenderTime: TimeInterval
    public let isValid: Bool
    public let validationErrors: [String]
    public let missingRequiredInputs: [String]
    public let macroDiagnostics: [String]
    public let warnings: [String]

    public init(
        manifest: TemplateManifest,
        inputContract: TemplateInputContract,
        complexity: TemplateComplexity,
        qualityScore: Double,
        variableCount: Int,
        filterCount: Int,
        tagCount: Int,
        loopCount: Int,
        securityIssues: [SecurityIssue],
        recommendations: [String],
        estimatedRenderTime: TimeInterval,
        isValid: Bool,
        validationErrors: [String],
        missingRequiredInputs: [String],
        macroDiagnostics: [String],
        warnings: [String]
    ) {
        self.manifest = manifest
        self.inputContract = inputContract
        self.complexity = complexity
        self.qualityScore = qualityScore
        self.variableCount = variableCount
        self.filterCount = filterCount
        self.tagCount = tagCount
        self.loopCount = loopCount
        self.securityIssues = securityIssues
        self.recommendations = recommendations
        self.estimatedRenderTime = estimatedRenderTime
        self.isValid = isValid
        self.validationErrors = validationErrors
        self.missingRequiredInputs = missingRequiredInputs
        self.macroDiagnostics = macroDiagnostics
        self.warnings = warnings
    }
}

/// Capability snapshot exported by the active environment.
public struct LiquidEnvironmentCapabilities: Sendable, Codable, Equatable {
    public let version: String
    public let profile: CompatibilityProfile
    public let sandboxPolicy: SandboxPolicy
    public let supportedTags: [String]
    public let supportedFilters: [String]
    public let supportsMacros: Bool
    public let supportsInputContracts: Bool
    public let supportsExpressionCallMacros: Bool
    public let documentedTags: [LiquidDocMetadata]
    public let documentedFilters: [LiquidDocMetadata]

    public init(
        version: String,
        profile: CompatibilityProfile,
        sandboxPolicy: SandboxPolicy,
        supportedTags: [String],
        supportedFilters: [String],
        supportsMacros: Bool,
        supportsInputContracts: Bool,
        supportsExpressionCallMacros: Bool,
        documentedTags: [LiquidDocMetadata],
        documentedFilters: [LiquidDocMetadata]
    ) {
        self.version = version
        self.profile = profile
        self.sandboxPolicy = sandboxPolicy
        self.supportedTags = supportedTags
        self.supportedFilters = supportedFilters
        self.supportsMacros = supportsMacros
        self.supportsInputContracts = supportsInputContracts
        self.supportsExpressionCallMacros = supportsExpressionCallMacros
        self.documentedTags = documentedTags
        self.documentedFilters = documentedFilters
    }
}

/// Errors emitted by the platform-oriented environment layer.
public enum LiquidEnvironmentError: LocalizedError, Sendable {
    case sandboxViolation(String)
    case unsupportedProfileFeature(String)
    case validationFailure(String)

    public var errorDescription: String? {
        switch self {
        case .sandboxViolation(let message):
            return "Sandbox policy blocked template execution: \(message)"
        case .unsupportedProfileFeature(let message):
            return "Template requires an opt-in compatibility profile: \(message)"
        case .validationFailure(let message):
            return "Template input or authoring validation failed: \(message)"
        }
    }
}

/// Canonical platform surface layered above `LiquidEngine`.
///
/// `LiquidEnvironment` owns the runtime profile, sandbox policy, capability
/// metadata, and a backing engine instance. `LiquidEngine` remains the
/// convenience render façade, while this environment becomes the richer
/// integration entry point for services, build systems, and tooling.
public actor LiquidEnvironment {
    public nonisolated let engine: LiquidEngine
    public let profile: CompatibilityProfile
    public let sandboxPolicy: SandboxPolicy

    public init(
        configuration: LiquidConfiguration = .default,
        profile: CompatibilityProfile = .extended,
        sandboxPolicy: SandboxPolicy = .trustedLocal
    ) {
        self.engine = LiquidEngine(configuration: configuration)
        self.profile = profile
        self.sandboxPolicy = sandboxPolicy
    }

    public func render(template: String, context: [String: Any] = [:]) async throws -> String {
        let unsafeContext = UnsafeLiquidEnvironmentContext(values: context)
        let analysis = await engine.analyzeTemplateEnvironment(template, context: unsafeContext)
        try enforce(analysis)
        return try await engine.renderEnvironment(
            template: template,
            context: unsafeContext
        )
    }

    public func renderWithMetrics(
        template: String,
        context: [String: Any] = [:]
    ) async throws -> (output: String, metrics: PerformanceMetrics) {
        let unsafeContext = UnsafeLiquidEnvironmentContext(values: context)
        let analysis = await engine.analyzeTemplateEnvironment(template, context: unsafeContext)
        try enforce(analysis)
        return try await engine.renderWithMetricsEnvironment(
            template: template,
            context: unsafeContext
        )
    }

    public func analyzeTemplate(
        _ template: String,
        context: [String: Any]? = nil,
        templatePath: String? = nil,
        baseDirectory: URL? = nil
    ) async -> TemplateAnalysis {
        let unsafeContext = context.map(UnsafeLiquidEnvironmentContext.init(values:))
        let analysis = await engine.analyzeTemplateEnvironment(
            template,
            context: unsafeContext,
            templatePath: templatePath,
            baseDirectory: baseDirectory
        )
        return applyPolicyWarnings(to: analysis)
    }

    public func analyzeTemplateFile(
        at path: String,
        context: [String: Any]? = nil,
        baseDirectory: URL? = nil
    ) async -> TemplateAnalysis {
        let unsafeContext = context.map(UnsafeLiquidEnvironmentContext.init(values:))
        let analysis = await engine.analyzeTemplateFileEnvironment(
            at: path,
            context: unsafeContext,
            baseDirectory: baseDirectory
        )
        return applyPolicyWarnings(to: analysis)
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

    public func capabilities() async -> LiquidEnvironmentCapabilities {
        let tags = await engine.getAllTagNames().sorted()
        let filters = await engine.allFilterNames()
        let supportsMacros = builtInTagNames.contains("macro") && builtInTagNames.contains("call")
        let supportsInputContracts = builtInTagNames.contains("input")
        return LiquidEnvironmentCapabilities(
            version: liquidCoreVersion,
            profile: profile,
            sandboxPolicy: sandboxPolicy,
            supportedTags: tags,
            supportedFilters: filters.sorted(),
            supportsMacros: supportsMacros,
            supportsInputContracts: supportsInputContracts,
            supportsExpressionCallMacros: supportsMacros,
            documentedTags: await engine.tagDocumentation(),
            documentedFilters: await engine.filterDocumentation()
        )
    }

    public func registerFilter(name: String, filter: any CustomFilter) async {
        await engine.registerFilter(name: name, filter: filter)
    }

    public func registerTag(_ tag: any LiquidTags.CustomTag) async throws {
        try await engine.registerTag(tag)
    }

    public func registerLegacyTag(
        named name: String,
        tag: any LiquidCore.CustomTag
    ) async throws {
        try await engine.registerLegacyTag(named: name, tag: tag)
    }

    private func enforce(_ analysis: TemplateAnalysis) throws {
        if analysis.manifest.requiresExtendedProfile && profile == .shopifyCompatible {
            throw LiquidEnvironmentError.unsupportedProfileFeature(
                "Template uses Rhoe-only or opt-in syntax while the environment is running in shopifyCompatible mode."
            )
        }

        if !analysis.validationErrors.isEmpty {
            throw LiquidEnvironmentError.validationFailure(analysis.validationErrors.joined(separator: " "))
        }

        if let maxReferencedTemplates = sandboxPolicy.maxReferencedTemplates,
           analysis.manifest.referencedTemplates.count > maxReferencedTemplates {
            throw LiquidEnvironmentError.sandboxViolation(
                "Template references \(analysis.manifest.referencedTemplates.count) other templates, exceeding the limit of \(maxReferencedTemplates)."
            )
        }

        if !sandboxPolicy.allowFileTemplates && !analysis.manifest.referencedTemplates.isEmpty {
            throw LiquidEnvironmentError.sandboxViolation(
                "Template references other template files, but file template loading is disabled."
            )
        }

        if !sandboxPolicy.allowDataSources && !analysis.manifest.dataCapabilities.isEmpty {
            throw LiquidEnvironmentError.sandboxViolation(
                "Template uses data-source capabilities, but data-source access is disabled."
            )
        }

        for tag in analysis.manifest.activeTags where !sandboxPolicy.allows(tag: tag) {
            throw LiquidEnvironmentError.sandboxViolation("Tag '\(tag)' is not allowed by the active sandbox policy.")
        }

        for filter in analysis.manifest.activeFilters where !sandboxPolicy.allows(filter: filter) {
            throw LiquidEnvironmentError.sandboxViolation("Filter '\(filter)' is not allowed by the active sandbox policy.")
        }

        if !sandboxPolicy.allowDebugTags && analysis.manifest.usesDebugFeatures {
            throw LiquidEnvironmentError.sandboxViolation("Debug-oriented tags are disabled by the active sandbox policy.")
        }

        for capability in analysis.manifest.dataCapabilities where !sandboxPolicy.allowsDataCapability(capability) {
            throw LiquidEnvironmentError.sandboxViolation(
                "Data capability '\(capability)' is not allowed by the active sandbox policy."
            )
        }
    }

    private func applyPolicyWarnings(to analysis: TemplateAnalysis) -> TemplateAnalysis {
        var warnings = analysis.warnings

        if profile == .shopifyCompatible && analysis.manifest.requiresExtendedProfile {
            warnings.append("Template uses features that require the extended profile.")
        }

        if !sandboxPolicy.allowDataSources && !analysis.manifest.dataCapabilities.isEmpty {
            warnings.append("Template uses data-source capabilities that the active sandbox policy would block during rendering.")
        }

        if !sandboxPolicy.allowDebugTags && analysis.manifest.usesDebugFeatures {
            warnings.append("Template uses debug-oriented tags that the active sandbox policy would block during rendering.")
        }

        return TemplateAnalysis(
            manifest: analysis.manifest,
            inputContract: analysis.inputContract,
            complexity: analysis.complexity,
            qualityScore: analysis.qualityScore,
            variableCount: analysis.variableCount,
            filterCount: analysis.filterCount,
            tagCount: analysis.tagCount,
            loopCount: analysis.loopCount,
            securityIssues: analysis.securityIssues,
            recommendations: analysis.recommendations,
            estimatedRenderTime: analysis.estimatedRenderTime,
            isValid: analysis.isValid,
            validationErrors: analysis.validationErrors,
            missingRequiredInputs: analysis.missingRequiredInputs,
            macroDiagnostics: analysis.macroDiagnostics,
            warnings: warnings
        )
    }
}
