//
//  RhoeLiquid.swift
//  RhoeLiquid
//
//  Created as part of RhoeLiquid
//  A high-performance Swift 6.3 implementation of the Liquid template language
//

import Foundation
import LiquidCore
import LiquidLexer
import LiquidParser
import LiquidRenderer
import LiquidFilters
import LiquidTags
import LiquidExtensions
import LiquidUtilities

/// The main Liquid template engine for high-performance template rendering.
///
/// `LiquidEngine` is the primary interface for rendering Liquid templates in Swift.
/// It orchestrates all the components (lexer, parser, renderer) to provide
/// a simple, thread-safe API for template processing.
///
/// ## Features
///
/// - **High Performance**: 5-20x faster than Ruby Liquid
/// - **Thread Safe**: Actor-based concurrency with Swift 6.3
/// - **Memory Efficient**: InlineString optimization reduces heap allocations
/// - **Extensible**: Support for custom filters and tags
/// - **Observable**: Built-in performance metrics
///
/// ## Usage
///
/// ### Basic Template Rendering
///
/// ```swift
/// let engine = LiquidEngine()
/// let template = "Hello {{ name }}!"
/// let context = ["name": "World"]
///
/// let result = try await engine.render(template: template, context: context)
/// print(result) // "Hello World!"
/// ```
///
/// ### Advanced Usage with Custom Configuration
///
/// ```swift
/// let config = LiquidConfiguration(
///     strictMode: true,
///     maxNestingDepth: 50,
///     autoEscape: true
/// )
/// let engine = LiquidEngine(configuration: config)
///
/// let (output, metrics) = try await engine.renderWithMetrics(
///     template: template,
///     context: context
/// )
/// print("Rendered in \(metrics.totalTime)ms")
/// ```
///
/// ## Performance
///
/// RhoeLiquid delivers exceptional performance:
/// - Simple templates: >50,000 ops/sec
/// - Complex templates: >1,000 ops/sec
/// - Variable interpolation: >100,000 ops/sec
/// - Memory usage: <0.03 MB for typical templates
///
/// ## Thread Safety
///
/// `LiquidEngine` is an actor, making it inherently thread-safe. You can
/// safely call its methods from multiple concurrent tasks:
///
/// ```swift
/// let engine = LiquidEngine()
///
/// await withTaskGroup(of: String.self) { group in
///     for template in templates {
///         group.addTask {
///             try await engine.render(template: template, context: context)
///         }
///     }
/// }
/// ```
public actor LiquidEngine {
    // MARK: - Configuration
    
    /// The configuration for this engine instance
    private let configuration: LiquidConfiguration
    
    /// Registry for custom filters
    private let filterRegistry: FilterRegistry
    
    /// Registry for custom tags  
    private let tagRegistry: TagRegistry
    
    /// Template loader for includes and inheritance
    private let templateLoader: TemplateLoader
    
    /// Registry for data source loaders
    private let dataLoaderRegistry: DataLoaderRegistry
    
    /// Template cache for improved performance
    private let templateCache: TemplateCache
    
    /// Shared renderer configuration for non-optimized rendering paths.
    private let rendererConfiguration: RendererConfiguration
    
    /// Legacy compiled template cache retained for compatibility with cache reset APIs.
    private var compiledTemplateCache: [String: CompiledTemplate] = [:]
    
    /// Ultra-high-performance optimized renderer (5-20x faster)
    private let optimizedRenderer: OptimizedRenderer
    
    /// Debug context for template debugging (nil when debugging disabled)
    private let debugContext: DebugContext?

    /// Observes system memory pressure so caches can be trimmed proactively.
    #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    private let memoryPressureObserver: MemoryPressureObserver?
    #endif

    /// Lazy initialization task for built-in data sources and tags.
    /// Only created when `ensureInitialized()` is first called (e.g. for {% load %} tags).
    /// NOT created during init() to avoid cooperative thread pool starvation when
    /// many LiquidEngine instances are created concurrently.
    private var initializationTask: Task<Void, Error>?

    /// Stored for deferred initialization.
    private let configuredLegacyTags: [String: any LiquidCore.CustomTag]
    
    // MARK: - Initialization
    
    /// Creates a new Liquid engine with the specified configuration.
    ///
    /// The engine is initialized with registries for custom filters and tags,
    /// and a template loader for handling includes and inheritance.
    ///
    /// - Parameter configuration: The configuration to use for this engine.
    ///   Defaults to `LiquidConfiguration.default`.
    ///
    /// ## Configuration Options
    ///
    /// ```swift
    /// // Default configuration
    /// let engine = LiquidEngine()
    ///
    /// // Custom configuration
    /// let engine = LiquidEngine(configuration: .init(
    ///     strictMode: true,
    ///     maxNestingDepth: 50,
    ///     autoEscape: true
    /// ))
    ///
    /// // Predefined configurations
    /// let strictEngine = LiquidEngine(configuration: .strict)
    /// let secureEngine = LiquidEngine(configuration: .secure)
    /// ```
    public init(configuration: LiquidConfiguration = .default) {
        let runtimeProfile = RuntimePerformanceProfile.current
        let resolvedCacheSize = configuration.maxCacheSize ?? runtimeProfile.recommendedCacheSizeBytes
        let resolvedCacheEntries = configuration.maxCacheEntries ?? runtimeProfile.recommendedCacheEntries
        let registeredFilters = Self.defaultRegisteredFilters()
            .merging(configuration.customFilters) { _, custom in custom }

        self.configuration = configuration
        self.filterRegistry = FilterRegistry(filters: registeredFilters)
        self.tagRegistry = TagRegistry()
        self.templateLoader = TemplateLoader()
        self.dataLoaderRegistry = LiquidCore.dataLoaderRegistry
        self.templateCache = TemplateCache(
            maxSize: resolvedCacheSize,
            maxEntries: resolvedCacheEntries
        )
        
        // Initialize debug context if debugging is enabled
        self.debugContext = configuration.debug.enabled ? DebugContext(configuration: configuration.debug) : nil
        
        // Initialize ultra-high-performance optimized renderer
        let rendererConfig = RendererConfiguration(
            autoEscape: configuration.autoEscape,
            strictMode: configuration.strictMode,
            maxNestingDepth: configuration.maxNestingDepth,
            maxLoopIterations: configuration.maxLoopIterations,
            debugContext: self.debugContext
        )
        self.rendererConfiguration = rendererConfig
        
        let cacheConfig = CompiledTemplateCache.CacheConfiguration.active(
            maxCacheSize: resolvedCacheEntries,
            maxMemoryUsage: resolvedCacheSize,
            compilationThreshold: 2
        )
        
        self.optimizedRenderer = OptimizedRenderer(
            configuration: rendererConfig,
            cacheConfiguration: cacheConfig,
            optimizationOptions: .aggressive
        )
        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
        if configuration.cacheEnabled {
            let templateCache = self.templateCache
            let optimizedRenderer = self.optimizedRenderer
            self.memoryPressureObserver = MemoryPressureObserver { level in
                optimizedRenderer.handleMemoryPressure(level)
                Task { [templateCache] in
                    await templateCache.handleMemoryPressure(level)
                }
            }
        } else {
            self.memoryPressureObserver = nil
        }
        #endif

        self.configuredLegacyTags = configuration.customTags
    }
    
    // MARK: - Performance Optimizations
    
    /// Get compiled template from cache
    private func getCompiledTemplate(key: String) async -> CompiledTemplate? {
        return compiledTemplateCache[key]
    }
    
    /// Store compiled template in cache
    private func setCompiledTemplate(key: String, template: CompiledTemplate) async {
        compiledTemplateCache[key] = template
    }

    /// Clear compiled template cache inside actor isolation.
    private func clearCompiledTemplateCache() {
        compiledTemplateCache.removeAll(keepingCapacity: true)
    }
    
    /// Awaits one-time initialization (installs built-in data sources and tags).
    /// The initialization runs in a background Task created during init().
    /// Only needs explicit awaiting when data source features ({% load %} tag) are used.
    /// Normal rendering can proceed without waiting — the init Task runs concurrently
    /// and completes in the background.
    private func ensureInitialized() async throws {
        if let task = initializationTask {
            try await task.value
        } else {
            let task = Task {
                await Self.installBuiltInDataSources(on: dataLoaderRegistry)
                try await tagRegistry.installBuiltIn(LoadTag())
                try await Self.installConfiguredLegacyTags(configuredLegacyTags, on: tagRegistry)
            }
            initializationTask = task
            try await task.value
        }
    }

    private static func installConfiguredLegacyTags(
        _ configuredLegacyTags: [String: any LiquidCore.CustomTag],
        on tagRegistry: TagRegistry
    ) async throws {
        guard !configuredLegacyTags.isEmpty else {
            return
        }

        for name in configuredLegacyTags.keys.sorted() {
            guard let tag = configuredLegacyTags[name] else {
                continue
            }
            try await tagRegistry.register(LegacyCustomTagAdapter(name: name, legacyTag: tag))
        }
    }

    private static func installBuiltInDataSources(on registry: DataLoaderRegistry) async {
        await registry.register(JSONDataSource())
        await registry.register(MarkdownDataSource())
        await registry.register(CSVDataSource())
        await registry.register(XMLDataSource())
        #if canImport(SQLite3)
        await registry.register(SQLiteDataSource())
        #endif
        #if !os(WASI)
        await registry.register(YAMLDataSource())
        #endif
        await registry.register(TOMLDataSource())
        await registry.register(GraphQLDataSource())
    }

    nonisolated private static func customTagDescriptors(
        from tags: [String: any LiquidTags.CustomTag]
    ) -> [CustomTagDescriptor] {
        tags.values
            .map { tag in
                CustomTagDescriptor(
                    name: tag.name,
                    requiresEndTag: tag.type.requiresEndTag
                )
            }
            .sorted { $0.name < $1.name }
    }

    nonisolated private static func tagCacheSignature(
        for tags: [String: any LiquidTags.CustomTag]
    ) -> String {
        let descriptors = customTagDescriptors(from: tags)
        guard !descriptors.isEmpty else {
            return ""
        }

        return descriptors.map { descriptor in
            descriptor.name + ":" + (descriptor.requiresEndTag ? "b" : "s")
        }.joined(separator: "|")
    }

    /// Parses template source using the standard lexer + parser pipeline.
    nonisolated private static func parseTemplateSource(
        _ template: String,
        customTagDescriptors: [CustomTagDescriptor] = []
    ) throws -> ASTNode {
        let lexer = Lexer(template)
        let tokens = try lexer.tokenize()
        let parser = Parser(
            consuming: tokens,
            source: template,
            customTags: customTagDescriptors
        )
        return try parser.parse()
    }

    nonisolated private func renderSourceWithDebugSession(
        _ source: String,
        variables: [String: Any],
        debugTemplateName: String,
        cacheTemplateName: String?,
        templateLoader: TemplateLoader?,
        templatePath: String?
    ) async throws -> String {
        let debugContext = self.debugContext
        let cacheEnabled = configuration.cacheEnabled
        let activeTemplateLoader = templateLoader ?? self.templateLoader
        let activeDataLoaderRegistry = self.dataLoaderRegistry
        let registeredFilters = await filterRegistry.getAllFilters()
        let registeredTags = await tagRegistry.getAllTags()
        let customTagDescriptors = Self.customTagDescriptors(from: registeredTags)

        if let debugContext {
            await debugContext.setCurrentTemplate(debugTemplateName)
            await debugContext.setExecutionState(.running)

            let frame = DebugFrame(
                templateName: debugTemplateName,
                functionName: "render",
                location: LiquidSourceLocation(line: 1, column: 1, position: 0, templateName: debugTemplateName),
                frameType: .template
            )
            await debugContext.pushFrame(frame)
        }

        do {
            let result: String
            if cacheEnabled {
                result = try await optimizedRenderer.render(
                    source: source,
                    with: variables,
                    templateName: cacheTemplateName,
                    customFilters: registeredFilters,
                    customTags: registeredTags,
                    templateLoader: activeTemplateLoader,
                    dataLoaderRegistry: activeDataLoaderRegistry,
                    rootTemplatePath: templatePath
                )
            } else {
                let ast = try Self.parseTemplateSource(
                    source,
                    customTagDescriptors: customTagDescriptors
                )
                let renderer = Renderer(configuration: rendererConfiguration)
                renderer.setCustomFilters(registeredFilters)
                renderer.setCustomTags(registeredTags)
                renderer.setTemplateLoader(activeTemplateLoader, rootTemplatePath: templatePath)
                renderer.setDataLoaderRegistry(activeDataLoaderRegistry)
                result = try await renderer.render(ast, with: variables)
            }

            if let debugContext {
                _ = await debugContext.popFrame()
                await debugContext.setExecutionState(.completed)
            }

            return result
        } catch {
            if let debugContext {
                await debugContext.setExecutionState(.error)
                debugContext.configuration.outputHandler?.handleDebugError(error, context: debugContext)
            }
            throw error
        }
    }

    nonisolated private func makeTemplateLoader(for path: String, baseDirectory: URL? = nil) -> TemplateLoader {
        TemplateLoader(
            baseDirectory: baseDirectory,
            allowAbsolutePaths: baseDirectory != nil || TemplateLoader.isAbsolutePath(path)
        )
    }

    nonisolated internal func platformTemplateLoaderForAnalysis() -> TemplateLoader {
        self.templateLoader
    }

    nonisolated private func renderTemplateFile(
        at path: String,
        context: [String: Any],
        baseDirectory: URL? = nil
    ) async throws -> String {
        let templateLoader = makeTemplateLoader(for: path, baseDirectory: baseDirectory)
        let resolvedPath = try await templateLoader.resolvedTemplatePath(for: path)
        let source = try await templateLoader.loadTemplate(path)

        return try await renderSourceWithDebugSession(
            source,
            variables: context,
            debugTemplateName: resolvedPath,
            cacheTemplateName: resolvedPath,
            templateLoader: templateLoader,
            templatePath: resolvedPath
        )
    }
    
    // MARK: - Template Rendering
    
    /// Renders a Liquid template with the given context.
    ///
    /// This is the main entry point for template processing. It performs
    /// lexical analysis, parsing, and rendering in sequence to produce
    /// the final output string.
    ///
    /// - Parameters:
    ///   - template: The Liquid template string to render
    ///   - context: The context variables for template evaluation. Defaults to empty.
    /// - Returns: The rendered template output
    /// - Throws: `LexerError`, `ParserError`, or `RenderError` if processing fails
    ///
    /// ## Usage Examples
    ///
    /// ### Basic Variable Interpolation
    ///
    /// ```swift
    /// let template = "Hello {{ name }}!"
    /// let context = ["name": "World"]
    /// let result = try await engine.render(template: template, context: context)
    /// // Result: "Hello World!"
    /// ```
    ///
    /// ### Control Flow
    ///
    /// ```swift
    /// let template = """
    /// {% if user.premium %}
    ///   Welcome, premium user!
    /// {% else %}
    ///   Welcome, {{ user.name }}!
    /// {% endif %}
    /// """
    /// let context = ["user": ["name": "Alice", "premium": true]]
    /// let result = try await engine.render(template: template, context: context)
    /// ```
    ///
    /// ### Loops and Filters
    ///
    /// ```swift
    /// let template = """
    /// {% for item in items %}
    ///   - {{ item | upcase }}
    /// {% endfor %}
    /// """
    /// let context = ["items": ["apple", "banana", "cherry"]]
    /// let result = try await engine.render(template: template, context: context)
    /// ```
    ///
    /// ## Performance
    ///
    /// This method is optimized for performance:
    /// - Simple templates: >50,000 ops/sec
    /// - Complex templates: >1,000 ops/sec
    /// - Memory usage: <0.03 MB for typical templates
    ///
    /// For performance monitoring, use ``renderWithMetrics(template:context:)`` instead.
    nonisolated public func render(template: String, context: [String: Any]? = nil) async throws -> String {
        try await ensureInitialized()
        let variables = context ?? [:]
        return try await renderSourceWithDebugSession(
            template,
            variables: variables,
            debugTemplateName: template,
            cacheTemplateName: "main",
            templateLoader: templateLoader,
            templatePath: nil
        )
    }
    
    /// Renders a template and produces a provenance map that traces each output
    /// character range back to the source template construct that produced it.
    ///
    /// - Parameters:
    ///   - template: The Liquid template string to render
    ///   - context: The context variables for template evaluation
    /// - Returns: A tuple of the rendered output and a provenance map
    /// - Throws: LexerError, ParserError, or RenderError if processing fails
    nonisolated public func renderWithProvenance(
        template: String,
        context: [String: Any]? = nil
    ) async throws -> (output: String, provenance: ProvenanceMap) {
        let output = try await render(template: template, context: context)
        let builder = ProvenanceBuilder()
        let provenance = builder.buildProvenanceMap(source: template, output: output)
        return (output, provenance)
    }

    /// Renders a template with performance metrics collection
    ///
    /// - Parameters:
    ///   - template: The Liquid template string to render
    ///   - context: The context variables for template evaluation
    /// - Returns: A tuple containing the rendered output and performance metrics
    /// - Throws: LexerError, ParserError, or RenderError if processing fails
    ///
    /// The returned `memoryStats` values describe observed `InlineString`-backed
    /// template storage for the source, tokens, and AST involved in the render.
    nonisolated public func renderWithMetrics(
        template: String, 
        context: [String: Any]? = nil
    ) async throws -> (output: String, metrics: PerformanceMetrics) {
        try await ensureInitialized()

        var lexingTime: Double = 0
        var parsingTime: Double = 0
        var cacheHit = false
        let ast: ASTNode
        var tokenCount = 0
        var tokensForMetrics: [Token]? = nil
        let cacheEnabled = configuration.cacheEnabled
        let activeTemplateLoader = self.templateLoader
        let activeDataLoaderRegistry = self.dataLoaderRegistry
        let registeredFilters = await filterRegistry.getAllFilters()
        let registeredTags = await tagRegistry.getAllTags()
        let customTagDescriptors = Self.customTagDescriptors(from: registeredTags)
        let tagCacheSignature = Self.tagCacheSignature(for: registeredTags)
        let cacheKeyBase = tagCacheSignature.isEmpty ? template : tagCacheSignature + "\u{1F}" + template
        
        // Check cache if enabled
        if cacheEnabled {
            let cacheKey = CacheKeyGenerator.key(for: cacheKeyBase)
            
            if let cachedAST = await templateCache.get(key: cacheKey) {
                ast = cachedAST
                cacheHit = true
                // For cached templates, lexing and parsing time are 0
            } else {
                // Lexing
                let lexingStart = Date().timeIntervalSinceReferenceDate
                let lexer = Lexer(template)
                let tokens = try lexer.tokenize()
                lexingTime = (Date().timeIntervalSinceReferenceDate - lexingStart) * 1000
                tokenCount = tokens.count
                tokensForMetrics = tokens
                
                // Parsing
                let parsingStart = Date().timeIntervalSinceReferenceDate
                let parser = Parser(
                    consuming: tokens,
                    source: template,
                    customTags: customTagDescriptors
                )
                ast = try parser.parse()
                parsingTime = (Date().timeIntervalSinceReferenceDate - parsingStart) * 1000
                
                // Cache the parsed AST
                await templateCache.set(key: cacheKey, value: ast)
            }
        } else {
            // Cache disabled - measure all phases
            // Lexing
            let lexingStart = Date().timeIntervalSinceReferenceDate
            let lexer = Lexer(template)
            let tokens = try lexer.tokenize()
            lexingTime = (Date().timeIntervalSinceReferenceDate - lexingStart) * 1000
            tokenCount = tokens.count
            tokensForMetrics = tokens
            
            // Parsing
            let parsingStart = Date().timeIntervalSinceReferenceDate
            let parser = Parser(
                consuming: tokens,
                source: template,
                customTags: customTagDescriptors
            )
            ast = try parser.parse()
            parsingTime = (Date().timeIntervalSinceReferenceDate - parsingStart) * 1000
        }
        
        // Rendering
        let renderingStart = Date().timeIntervalSinceReferenceDate
        let renderer = Renderer(configuration: rendererConfiguration)
        renderer.setCustomFilters(registeredFilters)
        renderer.setCustomTags(registeredTags)
        renderer.setTemplateLoader(activeTemplateLoader, rootTemplatePath: nil)
        renderer.setDataLoaderRegistry(activeDataLoaderRegistry)
        let output = try await renderer.render(ast, with: context ?? [:])
        let renderingTime = (Date().timeIntervalSinceReferenceDate - renderingStart) * 1000
        
        // Get cache statistics
        let cacheStats = await templateCache.statistics()
        let memoryStats = TemplateMetricsAnalyzer.memoryStats(
            source: template,
            tokens: tokensForMetrics,
            ast: ast
        )
        
        // Calculate metrics
        let metrics = PerformanceMetrics(
            lexingTime: lexingTime,
            parsingTime: parsingTime,
            renderingTime: renderingTime,
            tokenCount: tokenCount,
            nodeCount: ast.totalNodeCount(),
            memoryStats: memoryStats,
            cacheHit: cacheHit,
            cacheHitRate: cacheStats.hitRate
        )
        
        return (output, metrics)
    }
    
    // MARK: - Customization
    
    /// Registers a custom filter with the engine
    ///
    /// - Parameters:
    ///   - name: The name of the filter
    ///   - filter: The filter implementation
    public func registerFilter(name: String, filter: any CustomFilter) async {
        await filterRegistry.register(name: name, filter: filter)
    }

    /// Gets all registry-backed custom filters.
    ///
    /// Built-in renderer hot-path filters are not part of this dictionary; use
    /// `builtInFilterNames` or ``LiquidEnvironment/capabilities()`` when you
    /// need the full visible filter surface.
    public func getCustomFilters() async -> [String: any CustomFilter] {
        await filterRegistry.getAllFilters()
    }
    
    /// Registers a custom tag with the engine
    ///
    /// Registered tags are available to the active parser and renderer path,
    /// including file-backed `include` / `render` / inheritance renders.
    ///
    /// - Parameter tag: The custom tag implementation
    /// - Throws: `RegistryError` if registration fails
    ///
    /// ## Example
    ///
    /// ```swift
    /// let engine = LiquidEngine()
    /// try await engine.registerTag(MyHighlightTag())
    /// 
    /// let available = await engine.hasTag("highlight")
    /// print(available)
    /// ```
    public func registerTag(_ tag: any LiquidTags.CustomTag) async throws {
        try await ensureInitialized()
        try await tagRegistry.register(tag)
    }
    
    /// Registers multiple custom tags at once
    ///
    /// - Parameter tags: Array of custom tags to register
    /// - Throws: `RegistryError` if any registration fails
    public func registerTags(_ tags: [any LiquidTags.CustomTag]) async throws {
        try await ensureInitialized()
        try await tagRegistry.registerAll(tags)
    }

    /// Registers a legacy parser-style custom tag through the compatibility adapter.
    ///
    /// Prefer `registerTag(_:)` with `LiquidTags.CustomTag` for new extensions.
    /// This helper is for older `LiquidCore.CustomTag` implementations that still
    /// need to run through the active runtime registry. If the legacy tag conforms
    /// to `LegacyCustomTagRuntimeDescriptorProvider`, or is wrapped in
    /// `ConfiguredLegacyCustomTag`, this overload will honor that runtime shape.
    /// Otherwise the tag defaults to `.simple`.
    ///
    /// - Parameters:
    ///   - name: Template tag name.
    ///   - tag: Legacy parser-style tag implementation.
    public func registerLegacyTag(
        named name: String,
        tag: any LiquidCore.CustomTag
    ) async throws {
        try await ensureInitialized()
        try await registerTag(LegacyCustomTagAdapter(name: name, legacyTag: tag))
    }

    /// Registers a legacy parser-style custom tag through the compatibility adapter.
    ///
    /// Prefer `registerTag(_:)` with `LiquidTags.CustomTag` for new extensions.
    /// This overload is for callers that want to provide an explicit runtime tag
    /// shape without changing the legacy tag type itself.
    ///
    /// - Parameters:
    ///   - name: Template tag name.
    ///   - type: Runtime tag type controlling whether an end tag is required.
    ///   - tag: Legacy parser-style tag implementation.
    public func registerLegacyTag(
        named name: String,
        type: LiquidTags.TagType,
        tag: any LiquidCore.CustomTag
    ) async throws {
        try await ensureInitialized()
        let descriptor = LegacyCustomTagAdapter.runtimeDescriptor(for: tag)
        try await registerTag(
            LegacyCustomTagAdapter(
                name: name,
                type: type,
                legacyTag: tag,
                allowsNesting: descriptor.allowsNesting,
                maxNestingDepth: descriptor.maxNestingDepth,
                requiredContext: descriptor.requiredContext
            )
        )
    }

    /// Unregisters a custom tag
    ///
    /// - Parameter name: Name of the tag to unregister
    /// - Throws: `RegistryError` if tag cannot be unregistered
    public func unregisterTag(_ name: String) async throws {
        try await ensureInitialized()
        try await tagRegistry.unregister(name)
    }
    
    /// Checks if a tag is registered
    ///
    /// - Parameter name: The tag name to check
    /// - Returns: true if tag is available
    public func hasTag(_ name: String) async -> Bool {
        try? await ensureInitialized()
        return await tagRegistry.hasTag(name)
    }
    
    /// Gets all registered custom tags
    ///
    /// - Returns: Dictionary of tag name to tag implementation
    public func getCustomTags() async -> [String: any LiquidTags.CustomTag] {
        try? await ensureInitialized()
        return await tagRegistry.getAllTags()
    }
    
    /// Gets all available tag names (built-in and custom)
    ///
    /// - Returns: Set of all available tag names
    public func getAllTagNames() async -> Set<String> {
        try? await ensureInitialized()
        return await tagRegistry.getAllTagNames()
    }
    
    /// Gets registry statistics for monitoring
    ///
    /// - Returns: Registry statistics with usage metrics
    public func getTagRegistryStats() async -> RegistryStats {
        try? await ensureInitialized()
        return await tagRegistry.getStats()
    }
    
    /// Clears all custom tags (keeps built-in tags)
    public func clearCustomTags() async {
        try? await ensureInitialized()
        await tagRegistry.clearCustomTags()
    }
    
    // MARK: - Information
    
    /// Returns information about the engine configuration and capabilities
    public var engineInfo: EngineInfo {
        EngineInfo(
            version: liquidCoreVersion,
            configuration: configuration,
            buildInfo: BuildInfo.self
        )
    }
}

// MARK: - Engine Information

/// Information about the Liquid engine instance
public struct EngineInfo: Sendable {
    /// The version of the engine
    public let version: String
    
    /// The configuration being used
    public let configuration: LiquidConfiguration
    
    /// Build information
    public let buildInfo: BuildInfo.Type
    
    public init(version: String, configuration: LiquidConfiguration, buildInfo: BuildInfo.Type) {
        self.version = version
        self.configuration = configuration
        self.buildInfo = buildInfo
    }
}

// MARK: - Convenience Extensions

extension LiquidEngine {
    /// Renders a template from a file
    ///
    /// - Parameters:
    ///   - path: The path to the template file
    ///   - context: The context variables for template evaluation
    /// - Returns: The rendered template output
    /// - Throws: File system errors or template processing errors
    ///
    /// Nested `include`, `render`, and `extends` references are resolved relative
    /// to the file that is currently being rendered.
    nonisolated public func renderFile(at path: String, context: [String: Any] = [:]) async throws -> String {
        return try await renderTemplateFile(at: path, context: context)
    }
    
    /// Renders a template with a simple key-value context
    ///
    /// - Parameters:
    ///   - template: The Liquid template string to render
    ///   - variables: Variable name-value pairs
    /// - Returns: The rendered template output
    /// - Throws: Template processing errors
    nonisolated public func render(template: String, variables: (String, Any)...) async throws -> String {
        let context = Dictionary(uniqueKeysWithValues: variables)
        return try await render(template: template, context: context)
    }
    
    /// Renders a pre-parsed AST
    ///
    /// - Parameters:
    ///   - ast: The parsed AST to render
    ///   - context: The context variables for template evaluation
    /// - Returns: The rendered output string
    /// - Throws: RenderError if rendering fails
    nonisolated public func render(ast: ASTNode, context: [String: Any]? = nil) async throws -> String {
        try await ensureInitialized()
        let activeTemplateLoader = self.templateLoader
        let activeDataLoaderRegistry = self.dataLoaderRegistry
        let registeredFilters = await filterRegistry.getAllFilters()
        let registeredTags = await tagRegistry.getAllTags()
        let renderer = Renderer(configuration: rendererConfiguration)
        renderer.setCustomFilters(registeredFilters)
        renderer.setCustomTags(registeredTags)
        renderer.setTemplateLoader(activeTemplateLoader, rootTemplatePath: nil)
        renderer.setDataLoaderRegistry(activeDataLoaderRegistry)
        return try await renderer.render(ast, with: context ?? [:])
    }
    
    /// Renders a template with inheritance support
    ///
    /// - Parameters:
    ///   - templatePath: The path to the template file
    ///   - context: The context variables for template evaluation
    ///   - baseDirectory: The base directory for template loading (if nil, uses current directory)
    /// - Returns: The rendered output string
    /// - Throws: TemplateLoaderError, ParserError, or RenderError if processing fails
    ///
    /// This is a convenience wrapper around ``renderFile(at:context:)`` for
    /// callers that want to make inheritance explicit at the call site.
    nonisolated public func renderWithInheritance(
        templatePath: String,
        context: [String: Any] = [:],
        baseDirectory: URL? = nil
    ) async throws -> String {
        return try await renderTemplateFile(
            at: templatePath,
            context: context,
            baseDirectory: baseDirectory
        )
    }
    
    // MARK: - Performance Monitoring
    
    /// Get comprehensive performance statistics for the optimized rendering system
    ///
    /// This method provides detailed insights into the performance optimizations
    /// and their effectiveness, including cache hit rates, optimization statistics,
    /// and performance multipliers achieved.
    ///
    /// ## Example Usage
    ///
    /// ```swift
    /// let engine = LiquidEngine()
    /// // ... render some templates
    /// 
    /// let stats = await engine.getPerformanceStatistics()
    /// print("Performance improvement: \(stats.performanceMultiplier)x faster")
    /// print("Cache hit rate: \(stats.cacheStats?.hitRate ?? 0)%")
    /// ```
    ///
    /// - Returns: Comprehensive rendering performance statistics
    nonisolated public func getPerformanceStatistics() async -> RenderingStatistics {
        return optimizedRenderer.statistics
    }
    
    /// Clear all performance caches and reset optimization statistics
    ///
    /// This method clears all compiled template caches, expression caches, and
    /// resets performance counters. Useful for benchmarking or memory management.
    ///
    /// **Note:** This will temporarily reduce performance until caches are rebuilt.
    ///
    /// ## Example Usage
    ///
    /// ```swift
    /// // Clear caches for benchmarking
    /// await engine.clearPerformanceCaches()
    /// 
    /// // Run benchmark
    /// let startTime = Date().timeIntervalSinceReferenceDate
    /// let result = try await engine.render(template: template, context: context)
    /// let renderTime = Date().timeIntervalSinceReferenceDate - startTime
    /// ```
    nonisolated public func clearPerformanceCaches() async {
        optimizedRenderer.clearCaches()
        await templateCache.clear()
        await self.clearCompiledTemplateCache()
    }
    
    /// Pre-warm performance caches with commonly used templates
    ///
    /// This method pre-compiles and caches frequently used templates to ensure
    /// maximum performance from the first render. Ideal for production deployments.
    ///
    /// - Parameter templates: Dictionary of template names to template source code
    ///
    /// ## Example Usage
    ///
    /// ```swift
    /// let commonTemplates = [
    ///     "user-profile": "Hello {{ user.name }}!",
    ///     "email-template": "{{ content | strip_html }}",
    ///     "product-list": "{% for product in products %}{{ product.name }}{% endfor %}"
    /// ]
    /// 
    /// try await engine.warmupPerformanceCaches(templates: commonTemplates)
    /// // Templates are now pre-compiled and cached for maximum speed
    /// ```
    ///
    /// - Throws: Template compilation errors
    nonisolated public func warmupPerformanceCaches(templates: [String: String]) async throws {
        try await optimizedRenderer.warmupCaches(templates: templates)
    }
}

extension LiquidEngine {
    private static func defaultRegisteredFilters() -> [String: any CustomFilter] {
        var filters: [String: any CustomFilter] = [
            "where": WhereFilter(),
            "map": MapFilter(),
            "group_by": GroupByFilter(),
            "sort_by": SortByFilter(),
            "find": FindFilter(),
            "sum": SumFilter(),
            "pluck": PluckFilter(),
            "limit": LimitFilter(),
            "offset": OffsetFilter(),
            "select": SelectFilter(),
            "select_all": SelectAllFilter(),
            "xpath": XPathFilter(),
            "text": TextContentFilter(),
            "attr": AttributeFilter(),
            "inner_html": InnerHTMLFilter(),
            "strip_html": StripHTMLFilter(),
            "tag_name": TagNameFilter(),
            "children": ChildrenFilter(),
            "sql_query": SQLQueryFilter(),
            "sql_select": SQLSelectFilter(),
            "sql_join": SQLJoinFilter(),
            "sql_count": SQLCountFilter(),
            "sql_sum": SQLSumFilter(),
            "sql_avg": SQLAverageFilter(),
            "sql_min": SQLMinFilter(),
            "sql_max": SQLMaxFilter(),
            "sql_distinct": SQLDistinctFilter(),
            "sql_schema": SQLSchemaFilter(),
            "to_toml": ToTOMLFilter(),
            "graphql_data": GraphQLDataFilter(),
            "graphql_errors": GraphQLErrorsFilter(),
            "graphql_has_errors": GraphQLHasErrorsFilter(),
            // Shopify-compatible filters
            "remove_last": RemoveLastFilter(),
            "replace_last": ReplaceLastFilter(),
            "slice": SliceFilter(),
            "modulo": ModuloFilter(),
            "sort_natural": SortNaturalFilter(),
        ]

        #if !os(WASI)
        filters["yaml_merge"] = YAMLMergeFilter()
        filters["to_yaml"] = ToYAMLFilter()
        #endif

        return filters
    }
}

private extension LiquidEngine {
    func logCriticalError(_ message: String, error: Error, context: [String: String]) async {
        let metadata = context
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: ", ")
        let line = metadata.isEmpty
            ? "[RhoeLiquid] \(message): \(error.localizedDescription)\n"
            : "[RhoeLiquid] \(message): \(error.localizedDescription) (\(metadata))\n"
        FileHandle.standardError.write(Data(line.utf8))
    }
}

// MARK: - Public Re-exports

/// Re-export core types for convenience
public typealias LiquidConfiguration = LiquidCore.LiquidConfiguration
public typealias PerformanceMetrics = LiquidCore.PerformanceMetrics
public typealias BuildInfo = LiquidCore.BuildInfo
