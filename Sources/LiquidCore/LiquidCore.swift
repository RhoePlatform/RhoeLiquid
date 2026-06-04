//
//  LiquidCore.swift
//  LiquidCore
//
//  Created as part of RhoeLiquid
//  A high-performance Swift 6.3 implementation of the Liquid template language
//

import Foundation

// MARK: - Public Module Interface

/// LiquidCore provides the fundamental types and protocols for the Liquid template engine
///
/// This module contains:
/// - Token types and tokenization structures
/// - AST node definitions and expression types
/// - Memory-optimized string storage
/// - Core error types for all phases
/// - Extension protocols for custom functionality

// MARK: - Version Information

/// Release version of the LiquidCore module.
///
/// The package is staged as the first contributor-facing Apache 2.0 foundation
/// release for `RhoePlatform/RhoeLiquid`.
public let liquidCoreVersion = "0.1.1"

/// Build information for debugging and diagnostics
public struct BuildInfo: Sendable {
    /// The Swift version used to compile this module
    public static let swiftVersion = "6.2"
    
    /// The compilation date
    public static let buildDate = Date()
    
    /// Whether this is a debug or release build
    #if DEBUG
    public static let isDebugBuild = true
    #else
    public static let isDebugBuild = false
    #endif
    
    /// Platform information
    #if os(macOS)
    public static let platform = "macOS"
    #elseif os(iOS)
    public static let platform = "iOS"
    #elseif os(watchOS)
    public static let platform = "watchOS"
    #elseif os(tvOS)
    public static let platform = "tvOS"
    #elseif os(visionOS)
    public static let platform = "visionOS"
    #elseif os(Linux)
    public static let platform = "Linux"
    #else
    public static let platform = "Unknown"
    #endif
}

// MARK: - Core Protocols

/// Protocol for legacy parser-style custom tag implementations.
///
/// New extensions should prefer `LiquidTags.CustomTag` and
/// `LiquidEngine.registerTag(_:)`. This protocol remains for compatibility with
/// older parser-driven tags and can be bridged into the active runtime with
/// `LegacyCustomTagAdapter` or `LiquidEngine.registerLegacyTag(...)`.
public protocol CustomTag: Sendable {
    /// Parse the tag and return a node that can be rendered
    ///
    /// - Parameter parser: The tag parser with utilities for parsing expressions and content
    /// - Returns: A TagNode that represents the parsed tag
    /// - Throws: ParserError if the tag syntax is invalid
    func parse(parser: TagParser) throws -> any TagNode
}

/// Protocol for legacy parser-style custom tag nodes.
///
/// TagNode represents a parsed custom tag that can be rendered during template execution.
public protocol TagNode: Sendable {
    /// Render this tag node to a string
    ///
    /// - Parameter context: The rendering context with variables and filters
    /// - Returns: The rendered string output
    /// - Throws: RenderError if rendering fails
    func render(context: borrowing RenderContext) async throws -> String
}

/// Runtime shape metadata for legacy parser-style custom tags.
///
/// `LiquidConfiguration.customTags` and compatibility registration helpers use
/// this descriptor to bridge older `LiquidCore.CustomTag` implementations into
/// the active runtime registry.
public enum LegacyCustomTagRuntimeKind: String, Sendable, CaseIterable {
    case simple
    case block
    case conditional
    case loop
    case selfClosing
}

/// Narrow compatibility contract for bootstrapping legacy parser-style tags.
///
/// The dictionary key in `LiquidConfiguration.customTags` is always the runtime
/// tag name. This descriptor only defines the runtime shape and execution
/// requirements for that legacy implementation.
public struct LegacyCustomTagRuntimeDescriptor: Sendable {
    public let kind: LegacyCustomTagRuntimeKind
    public let allowsNesting: Bool
    public let maxNestingDepth: Int?
    public let requiredContext: [String]

    public init(
        kind: LegacyCustomTagRuntimeKind,
        allowsNesting: Bool = true,
        maxNestingDepth: Int? = nil,
        requiredContext: [String] = []
    ) {
        self.kind = kind
        self.allowsNesting = allowsNesting
        self.maxNestingDepth = maxNestingDepth
        self.requiredContext = requiredContext
    }

    public static let simple = Self(kind: .simple)
}

/// Optional runtime metadata provider for legacy parser-style custom tags.
///
/// Conform to this protocol, or wrap an older tag in `ConfiguredLegacyCustomTag`,
/// when the tag needs block/loop/conditional parsing metadata or custom nesting
/// requirements.
public protocol LegacyCustomTagRuntimeDescriptorProvider: CustomTag {
    var runtimeDescriptor: LegacyCustomTagRuntimeDescriptor { get }
}

/// Protocol for custom filter implementations
///
/// Custom filters can transform values during template rendering.
public protocol CustomFilter: Sendable {
    /// The name of the filter
    var name: String { get }
    
    /// Apply the filter to a value with the given arguments
    ///
    /// - Parameters:
    ///   - value: The input value to filter
    ///   - arguments: Positional arguments passed to the filter
    ///   - namedArguments: Named arguments passed to the filter
    /// - Returns: The filtered result
    /// - Throws: RenderError if filtering fails
    func apply(
        to value: Any,
        arguments: [Any],
        namedArguments: [String: Any]
    ) async throws -> Any
}

// MARK: - Forward Declarations

/// Forward declaration for the legacy parser adapter surface.
public protocol TagParser: Sendable {
    /// Parse an expression from the current position
    func parseExpression() throws -> Expression
    
    /// Parse nodes until the specified end tag
    func parseUntilEnd(tagName: String) throws -> [ASTNode]
    
    /// Expect and consume an end tag
    func expectEndTag(_ tagName: String) throws
}

/// Forward declaration for RenderContext (implemented in LiquidRenderer module)
public protocol RenderContext: Sendable {
    /// Get a variable value from the current context
    func getValue(for key: borrowing String) throws -> Any
    
    /// Set a variable value in the current context
    func setValue(_ value: consuming Any, for key: String)
    
    /// Push a new variable scope
    func pushScope(_ scope: consuming [String: Any])
    
    /// Pop the current variable scope
    func popScope()
    
    /// Apply a filter to a value
    func applyFilter(
        name: String,
        to value: Any,
        arguments: [Any],
        namedArguments: [String: Any]
    ) async throws -> Any
}

// MARK: - Utility Types

/// Configuration options for the Liquid engine.
///
/// `LiquidConfiguration` controls various aspects of template processing,
/// including error handling, security limits, and feature enablement.
///
/// ## Usage
///
/// ```swift
/// // Default configuration
/// let config = LiquidConfiguration()
///
/// // Custom configuration
/// let config = LiquidConfiguration(
///     strictMode: true,        // Throw errors instead of ignoring them
///     maxNestingDepth: 50,     // Limit template nesting depth
///     maxLoopIterations: 1000, // Limit loop iterations
///     autoEscape: true         // Auto-escape HTML by default
/// )
///
/// // Predefined configurations
/// let strictConfig = LiquidConfiguration.strict
/// let secureConfig = LiquidConfiguration.secure
/// ```
///
/// ## Configuration Presets
///
/// - ``default``: Balanced configuration for most use cases
/// - ``strict``: Strict error handling for development
/// - ``secure``: Security-focused configuration with lower limits
public struct LiquidConfiguration: Sendable {
    /// Whether to operate in strict mode (throw errors vs. ignore them).
    ///
    /// In strict mode, template errors are thrown immediately. In non-strict mode,
    /// errors are handled gracefully with fallback values.
    ///
    /// - `true`: Throw errors immediately (recommended for development)
    /// - `false`: Handle errors gracefully with fallbacks (recommended for production)
    public let strictMode: Bool
    
    /// Maximum nesting depth for templates and includes.
    ///
    /// Limits the depth of nested template structures to prevent infinite recursion
    /// and stack overflow attacks.
    ///
    /// **Default:** 100 levels
    /// **Recommended range:** 10-200 levels
    public let maxNestingDepth: Int
    
    /// Maximum number of loop iterations.
    ///
    /// Limits the number of iterations in `for` loops to prevent infinite loops
    /// and resource exhaustion attacks.
    ///
    /// **Default:** 1,000,000 iterations
    /// **Recommended range:** 1,000-10,000,000 iterations
    public let maxLoopIterations: Int
    
    /// Whether to escape HTML by default.
    ///
    /// When enabled, all variable outputs are HTML-escaped automatically unless
    /// explicitly marked as safe.
    ///
    /// - `true`: Auto-escape HTML (recommended for web applications)
    /// - `false`: No auto-escaping (recommended for non-HTML outputs)
    public let autoEscape: Bool
    
    /// Legacy custom tag bootstrap surface preserved for source compatibility.
    ///
    /// This dictionary is a narrow compatibility contract for older
    /// `LiquidCore.CustomTag` implementations. `LiquidEngine` auto-installs these
    /// entries during engine initialization by bridging them into the active
    /// registry-backed runtime with `LegacyCustomTagAdapter`.
    ///
    /// The dictionary key is always used as the runtime tag name. Tags default to
    /// the `.simple` runtime shape unless they conform to
    /// `LegacyCustomTagRuntimeDescriptorProvider` or are wrapped in
    /// `ConfiguredLegacyCustomTag` to supply block/loop/conditional metadata.
    ///
    /// New extensions should still prefer `LiquidEngine.registerTag(_:)` with
    /// `LiquidTags.CustomTag`.
    ///
    /// ```swift
    /// let engine = LiquidEngine(configuration: LiquidConfiguration(
    ///     customTags: [
    ///         "mytag": MyLegacyTag(),
    ///         "myblock": ConfiguredLegacyCustomTag(MyBlockTag(), kind: .block)
    ///     ]
    /// ))
    /// ```
    public let customTags: [String: any CustomTag]
    
    /// Custom filter registry.
    ///
    /// A dictionary of custom filters that provide additional value
    /// transformation capabilities during rendering.
    ///
    /// ```swift
    /// let customFilters = [
    ///     "myfilter": MyCustomFilter()
    /// ]
    /// ```
    public let customFilters: [String: any CustomFilter]
    
    /// Maximum size of the template cache in bytes.
    ///
    /// Controls the memory usage of the template cache. When the cache
    /// exceeds this size, least-recently-used entries are evicted.
    ///
    /// **Default:** 50MB (50 * 1024 * 1024 bytes)
    /// **Recommended range:** 10MB-500MB depending on available memory
    public let maxCacheSize: Int?
    
    /// Maximum number of templates to cache.
    ///
    /// Limits the number of parsed templates kept in memory. When this
    /// limit is exceeded, least-recently-used entries are evicted.
    ///
    /// **Default:** 1000 templates
    /// **Recommended range:** 100-10,000 templates
    public let maxCacheEntries: Int?
    
    /// Whether to enable template caching.
    ///
    /// When enabled, parsed templates are cached to improve performance
    /// for repeated renders. Disable for development or when templates
    /// change frequently.
    ///
    /// **Default:** true
    public let cacheEnabled: Bool
    
    /// Debug configuration for template debugging.
    ///
    /// Controls debugging features like breakpoints, tracing, variable watching,
    /// and interactive debugging. Disabled by default for performance.
    ///
    /// **Default:** `.disabled`
    public let debug: DebugConfiguration
    
    public init(
        strictMode: Bool = false,
        maxNestingDepth: Int = 100,
        maxLoopIterations: Int = 1_000_000,
        autoEscape: Bool = false,
        customTags: [String: any CustomTag] = [:],
        customFilters: [String: any CustomFilter] = [:],
        maxCacheSize: Int? = nil,
        maxCacheEntries: Int? = nil,
        cacheEnabled: Bool = true,
        debug: DebugConfiguration = .disabled
    ) {
        self.strictMode = strictMode
        self.maxNestingDepth = maxNestingDepth
        self.maxLoopIterations = maxLoopIterations
        self.autoEscape = autoEscape
        self.customTags = customTags
        self.customFilters = customFilters
        self.maxCacheSize = maxCacheSize
        self.maxCacheEntries = maxCacheEntries
        self.cacheEnabled = cacheEnabled
        self.debug = debug
    }
    
    /// Default configuration
    public static let `default` = LiquidConfiguration()
    
    /// Strict configuration that throws errors instead of ignoring them
    public static let strict = LiquidConfiguration(strictMode: true)
    
    /// Secure configuration with HTML auto-escaping and lower limits
    public static let secure = LiquidConfiguration(
        strictMode: true,
        maxNestingDepth: 50,
        maxLoopIterations: 100_000,
        autoEscape: true
    )
    
    /// Development configuration with debugging enabled
    public static let development = LiquidConfiguration(
        strictMode: true,
        debug: .development
    )
    
    /// Debug configuration with full debugging features
    public static let debugging = LiquidConfiguration(
        strictMode: true,
        cacheEnabled: false, // Disable cache for debugging
        debug: .full
    )
}

/// Performance metrics for template processing.
///
/// `PerformanceMetrics` provides detailed timing and memory usage information
/// for template rendering operations, enabling performance monitoring and optimization.
///
/// ## Usage
///
/// ```swift
/// let (output, metrics) = try await engine.renderWithMetrics(
///     template: template,
///     context: context
/// )
///
/// print("Total time: \(metrics.totalTime)ms")
/// print("Lexing: \(metrics.lexingTime)ms")
/// print("Parsing: \(metrics.parsingTime)ms")
/// print("Rendering: \(metrics.renderingTime)ms")
/// print("Tokens: \(metrics.tokenCount)")
/// print("Nodes: \(metrics.nodeCount)")
/// print("Memory efficiency: \(metrics.memoryStats.inlineEfficiency * 100)%")
/// ```
///
/// ## Performance Benchmarks
///
/// Typical performance characteristics:
/// - **Lexing**: 1,000-50,000 ops/sec depending on template complexity
/// - **Parsing**: 5,000-200,000 ops/sec depending on AST complexity
/// - **Rendering**: 500-100,000 ops/sec depending on context size
/// - **Memory**: <0.03 MB for typical templates
public struct PerformanceMetrics: Sendable {
    /// Time spent in lexical analysis (milliseconds)
    public let lexingTime: Double
    
    /// Time spent in parsing (milliseconds)
    public let parsingTime: Double
    
    /// Time spent in rendering (milliseconds)
    public let renderingTime: Double
    
    /// Total processing time (milliseconds)
    public var totalTime: Double {
        return lexingTime + parsingTime + renderingTime
    }
    
    /// Number of tokens generated
    public let tokenCount: Int
    
    /// Number of AST nodes in the parsed template tree
    public let nodeCount: Int
    
    /// Development-time memory statistics for the observed `InlineString`-backed
    /// source, token, and AST string storage involved in this render.
    public let memoryStats: MemoryStats
    
    /// Whether this render used a cached template
    public let cacheHit: Bool
    
    /// Current cache hit rate (0.0 to 1.0)
    public let cacheHitRate: Double
    
    public init(
        lexingTime: Double,
        parsingTime: Double,
        renderingTime: Double,
        tokenCount: Int,
        nodeCount: Int,
        memoryStats: MemoryStats,
        cacheHit: Bool = false,
        cacheHitRate: Double = 0.0
    ) {
        self.lexingTime = lexingTime
        self.parsingTime = parsingTime
        self.renderingTime = renderingTime
        self.tokenCount = tokenCount
        self.nodeCount = nodeCount
        self.memoryStats = memoryStats
        self.cacheHit = cacheHit
        self.cacheHitRate = cacheHitRate
    }
}

// MARK: - Global Constants

/// Maximum template size that can be processed (in characters)
public let maxTemplateSize = 10_000_000 // 10MB

/// Maximum variable name length
public let maxVariableNameLength = 256

/// Maximum filter chain length
public let maxFilterChainLength = 50

/// Built-in filter names (for validation and documentation)
public let builtInFilterNames: Set<String> = [
    // String filters
    "upcase", "downcase", "capitalize", "strip", "lstrip", "rstrip",
    "size", "append", "prepend", "split", "strip_html", "strip_newlines",
    "newline_to_br", "truncate", "truncatewords", "slugify", "escape",
    "base64_encode", "base64_decode",
    
    // Array filters
    "first", "last", "join", "sort", "sort_by", "reverse", "size",
    "map", "where", "compact", "uniq", "pluck", "find", "group_by",
    
    // Math filters
    "plus", "minus", "times", "divided_by", "modulo", "round", "ceil",
    "floor", "abs", "at_least", "at_most", "clamp",
    
    // Date filters
    "date", "date_to_string", "date_to_rfc822", "date_to_iso8601", "now",
    
    // Utility filters
    "default", "json", "parse_json", "url_encode", "url_decode", "url_param"
]

/// Built-in tag names (for validation and documentation)
public let builtInTagNames: Set<String> = [
    // Control flow
    "if", "elsif", "else", "endif", "unless", "endunless",
    "case", "when", "endcase",
    
    // Loops
    "for", "endfor", "tablerow", "endtablerow", "cycle",
    "break", "continue",
    
    // Variables
    "assign", "capture", "endcapture", "increment", "decrement",
    
    // Templates
    "include", "render", "block", "endblock", "render_block",
    "macro", "endmacro", "import", "from", "input", "call", "endcall",
    "slot", "endslot", "fill", "endfill",
    
    // Utility
    "comment", "endcomment", "raw", "endraw", "liquid", "endliquid",
    "echo", "debug", "pipeline", "endpipeline"
]

// MARK: - Module Exports

// All types are defined in this module and exported automatically
// Data source types are defined in their respective files and are public,
// so they are automatically available when importing LiquidCore
