//
//  CustomTag.swift
//  LiquidTags
//
//  Custom tag protocol with full lifecycle support
//

import Foundation
import LiquidCore

/// Protocol for implementing custom Liquid tags
///
/// Custom tags enable extending Liquid with new functionality beyond the built-in tags.
/// Tags can range from simple text transformations to complex logic with nested content.
///
/// The registry and protocol surface are part of the active engine runtime.
/// Register tags through `LiquidEngine.registerTag(_:)` and the default parser and
/// renderer will execute them through the `LiquidTags` registry.
///
/// ## Tag Types
///
/// - **Simple Tags**: Single-line tags that produce output directly
/// - **Block Tags**: Tags that wrap content and transform it
/// - **Conditional Tags**: Tags that control rendering based on conditions
/// - **Loop Tags**: Tags that repeat content with different contexts
///
/// ## Lifecycle
///
/// 1. **Parsing**: Tag parameters are parsed during template compilation
/// 2. **Validation**: Parameters are validated for correctness
/// 3. **Execution**: Tag logic runs during template rendering
/// 4. **Output**: Generated content is inserted into template output
///
/// ## Example Implementation
///
/// ```swift
/// public struct HighlightTag: CustomTag {
///     public let name = "highlight"
///     public let type = TagType.block
///     
///     public func parse(_ parameters: String, context: TagParsingContext) async throws -> TagParameters {
///         return try parseLanguageParameter(parameters)
///     }
///     
///     public func execute(parameters: TagParameters, content: String?, context: TagExecutionContext) async throws -> String {
///         let language = parameters["language"] as? String ?? "text"
///         return highlightCode(content ?? "", language: language)
///     }
/// }
/// ```
public protocol CustomTag: Sendable {
    /// The name of the tag (e.g., "highlight", "cache", "include_partial")
    var name: String { get }
    
    /// The type of tag (simple, block, conditional, loop)
    var type: TagType { get }
    
    /// Whether this tag can be nested within other tags
    var allowsNesting: Bool { get }
    
    /// Maximum nesting depth allowed (nil for no limit)
    var maxNestingDepth: Int? { get }
    
    /// Whether this tag requires specific context variables
    var requiredContext: [String] { get }
    
    /// Parse and validate tag parameters during template compilation
    ///
    /// This method is called once during template parsing to validate syntax
    /// and prepare optimized parameter structures.
    ///
    /// - Parameters:
    ///   - parameters: Raw parameter string from the template
    ///   - context: Parsing context with template information
    /// - Returns: Parsed and validated parameters
    /// - Throws: `TagParsingError` if parameters are invalid
    func parse(_ parameters: String, context: TagParsingContext) async throws -> TagParameters
    
    /// Execute the tag logic during template rendering
    ///
    /// This method is called during template rendering to produce the final output.
    /// It receives the parsed parameters and current execution context.
    ///
    /// - Parameters:
    ///   - parameters: Parsed parameters from the parse phase
    ///   - content: Block content for block tags (nil for simple tags)
    ///   - context: Execution context with variables and rendering state
    /// - Returns: Generated content to insert into template output
    /// - Throws: `TagExecutionError` if execution fails
    func execute(parameters: TagParameters, content: String?, context: TagExecutionContext) async throws -> String
    
    /// Optional setup hook called when tag is registered
    ///
    /// Use this to perform one-time initialization, register dependencies,
    /// or validate compatibility with the current environment.
    ///
    /// - Parameter registry: The tag registry this tag is being added to
    func setup(registry: TagRegistry) async throws
    
    /// Optional cleanup hook called when tag is unregistered
    ///
    /// Use this to clean up resources, close connections, or perform
    /// other cleanup operations.
    func teardown() async
}

/// Default implementations for optional protocol methods
public extension CustomTag {
    var allowsNesting: Bool { true }
    var maxNestingDepth: Int? { nil }
    var requiredContext: [String] { [] }
    
    func setup(registry: TagRegistry) async throws {
        // Default: no setup required
    }
    
    func teardown() async {
        // Default: no cleanup required
    }
}

/// Types of custom tags
public enum TagType: String, Sendable, CaseIterable {
    /// Simple single-line tags that produce direct output
    case simple
    
    /// Block tags that wrap and transform content
    case block
    
    /// Conditional tags that control rendering
    case conditional
    
    /// Loop tags that repeat content
    case loop
    
    /// Self-closing tags (like HTML void elements)
    case selfClosing
}

public extension TagType {
    var requiresEndTag: Bool {
        switch self {
        case .block, .conditional, .loop:
            return true
        case .simple, .selfClosing:
            return false
        }
    }
}

/// Parsed and validated tag parameters  
public struct TagParameters: Sendable {
    private let values: [String: SendableValue]
    
    /// Wrapper for making values Sendable-compatible
    public enum SendableValue: Sendable {
        case string(String)
        case int(Int)
        case double(Double)
        case bool(Bool)
        case array([SendableValue])
        case dictionary([String: SendableValue])
        case null
        
        public var anyValue: Any {
            switch self {
            case .string(let value): return value
            case .int(let value): return value
            case .double(let value): return value
            case .bool(let value): return value
            case .array(let values): return values.map(\.anyValue)
            case .dictionary(let dict): return dict.mapValues(\.anyValue)
            case .null: return NSNull()
            }
        }
    }
    
    public init(_ values: [String: Any] = [:]) {
        var sendableValues: [String: SendableValue] = [:]
        for (key, value) in values {
            sendableValues[key] = Self.makeSendableValue(value)
        }
        self.values = sendableValues
    }
    
    /// Get a parameter value
    public func get<T>(_ key: String, as type: T.Type = T.self) -> T? {
        return values[key]?.anyValue as? T
    }
    
    /// Get a required parameter value
    public func require<T>(_ key: String, as type: T.Type = T.self) throws -> T {
        guard let value = values[key]?.anyValue as? T else {
            throw TagExecutionError.missingParameter(key)
        }
        return value
    }
    
    /// Get parameter with default value
    public func get<T>(_ key: String, default defaultValue: T) -> T {
        return (values[key]?.anyValue as? T) ?? defaultValue
    }
    
    /// Check if parameter exists
    public func has(_ key: String) -> Bool {
        return values[key] != nil
    }
    
    /// Get all parameter keys
    public var keys: [String] {
        return Array(values.keys)
    }
    
    private static func makeSendableValue(_ value: Any) -> SendableValue {
        switch value {
        case let str as String:
            return .string(str)
        case let int as Int:
            return .int(int)
        case let double as Double:
            return .double(double)
        case let bool as Bool:
            return .bool(bool)
        case let array as [Any]:
            return .array(array.map(makeSendableValue))
        case let dict as [String: Any]:
            return .dictionary(dict.mapValues(makeSendableValue))
        case is NSNull:
            return .null
        default:
            return .string(String(describing: value))
        }
    }
}

/// Context provided during tag parsing
// SAFETY: Immutable after init; contains [String: Any] which is not Sendable
public struct TagParsingContext: @unchecked Sendable {
    /// The template being parsed
    public let templateName: String?
    
    /// Current line number in template
    public let lineNumber: Int
    
    /// Available context variables at parse time
    public let staticContext: [String: Any]
    
    /// Parser configuration
    public let configuration: LiquidConfiguration
    
    public init(
        templateName: String? = nil,
        lineNumber: Int = 0,
        staticContext: [String: Any] = [:],
        configuration: LiquidConfiguration
    ) {
        self.templateName = templateName
        self.lineNumber = lineNumber
        self.staticContext = staticContext
        self.configuration = configuration
    }
}

/// Context provided during tag execution
// SAFETY: Immutable after init; contains [String: Any] which is not Sendable
public struct TagExecutionContext: @unchecked Sendable {
    /// Current variable context
    public let variables: [String: Any]
    
    /// Template rendering context
    public let renderContext: RenderContext
    
    /// Current loop context (if inside a loop)
    public let loopContext: LoopContext?
    
    /// Scoped variables for this tag execution
    public let scopedVariables: [String: Any]

    /// Parsed block body nodes when the current tag is a block tag.
    public let bodyNodes: [ASTNode]?

    private let variableSetter: ((String, Any) -> Void)?
    private let valueGetter: ((String) throws -> Any)?
    private let scopePusher: (([String: Any]) -> Void)?
    private let scopePopper: (() -> Void)?
    private let filterApplier: ((String, Any, [Any], [String: Any]) async throws -> Any)?
    private let activeDataLoaderRegistry: DataLoaderRegistry?
    
    public init(
        variables: [String: Any],
        renderContext: RenderContext,
        loopContext: LoopContext? = nil,
        scopedVariables: [String: Any] = [:],
        bodyNodes: [ASTNode]? = nil,
        variableSetter: ((String, Any) -> Void)? = nil,
        valueGetter: ((String) throws -> Any)? = nil,
        scopePusher: (([String: Any]) -> Void)? = nil,
        scopePopper: (() -> Void)? = nil,
        filterApplier: ((String, Any, [Any], [String: Any]) async throws -> Any)? = nil,
        dataLoaderRegistry: DataLoaderRegistry? = nil
    ) {
        self.variables = variables
        self.renderContext = renderContext
        self.loopContext = loopContext
        self.scopedVariables = scopedVariables
        self.bodyNodes = bodyNodes
        self.variableSetter = variableSetter
        self.valueGetter = valueGetter
        self.scopePusher = scopePusher
        self.scopePopper = scopePopper
        self.filterApplier = filterApplier
        self.activeDataLoaderRegistry = dataLoaderRegistry
    }

    /// Set or overwrite a variable in the active render scope.
    public func setVariable(_ value: Any, for key: String) {
        variableSetter?(key, value)
    }

    /// Read a value from the active render context.
    public func getValue(for key: String) throws -> Any {
        guard let valueGetter else {
            throw TagExecutionError.invalidContext("Variable reads are not available in this render context")
        }
        return try valueGetter(key)
    }

    /// Push a new variable scope into the active render context.
    public func pushScope(_ scope: [String: Any] = [:]) {
        scopePusher?(scope)
    }

    /// Pop the current variable scope from the active render context.
    public func popScope() {
        scopePopper?()
    }

    /// Apply a registered Liquid filter inside the active render context.
    public func applyFilter(
        name: String,
        to value: Any,
        arguments: [Any] = [],
        namedArguments: [String: Any] = [:]
    ) async throws -> Any {
        guard let filterApplier else {
            throw TagExecutionError.invalidContext("Filter application is not available in this render context")
        }
        return try await filterApplier(name, value, arguments, namedArguments)
    }

    /// Load structured data through the engine's active data loader registry.
    public func loadData(from path: String, options: LoadOptions = LoadOptions()) async throws -> DataValue {
        guard let activeDataLoaderRegistry else {
            throw TagExecutionError.invalidContext("Data loading is not available in this render context")
        }
        return try await activeDataLoaderRegistry.load(from: path, options: options)
    }
}

/// Render context information
public struct RenderContext: Sendable {
    /// Template name being rendered
    public let templateName: String?
    
    /// Rendering configuration
    public let configuration: LiquidConfiguration
    
    /// Current nesting depth
    public let nestingDepth: Int
    
    /// Whether we're in strict mode
    public let strictMode: Bool
    
    public init(
        templateName: String? = nil,
        configuration: LiquidConfiguration,
        nestingDepth: Int = 0,
        strictMode: Bool = false
    ) {
        self.templateName = templateName
        self.configuration = configuration
        self.nestingDepth = nestingDepth
        self.strictMode = strictMode
    }
}

/// Loop context information
public struct LoopContext: Sendable {
    /// Current iteration index (0-based)
    public let index: Int
    
    /// Current iteration index (1-based)  
    public let index1: Int
    
    /// Whether this is the first iteration
    public let first: Bool
    
    /// Whether this is the last iteration
    public let last: Bool
    
    /// Total number of iterations
    public let length: Int
    
    /// Remaining iterations
    public let rindex: Int
    
    /// Remaining iterations (1-based)
    public let rindex1: Int
    
    public init(index: Int, length: Int) {
        self.index = index
        self.index1 = index + 1
        self.first = index == 0
        self.last = index == length - 1
        self.length = length
        self.rindex = length - index
        self.rindex1 = length - index - 1
    }
}

/// Errors that can occur during tag parsing
public enum TagParsingError: Error, Sendable {
    case invalidSyntax(String)
    case missingRequiredParameter(String)
    case invalidParameterValue(String, expected: String)
    case unsupportedFeature(String)
    case nestingTooDeep(Int, maximum: Int)
    
    public var localizedDescription: String {
        switch self {
        case .invalidSyntax(let message):
            return "Tag parsing error: \(message)"
        case .missingRequiredParameter(let param):
            return "Missing required parameter: \(param)"
        case .invalidParameterValue(let param, let expected):
            return "Invalid value for parameter '\(param)': expected \(expected)"
        case .unsupportedFeature(let feature):
            return "Unsupported feature: \(feature)"
        case .nestingTooDeep(let depth, let maximum):
            return "Nesting too deep: \(depth) (maximum: \(maximum))"
        }
    }
}

/// Errors that can occur during tag execution
public enum TagExecutionError: Error, Sendable {
    case missingParameter(String)
    case invalidContext(String)
    case executionFailed(String)
    case resourceNotFound(String)
    case permissionDenied(String)
    case timeout
    
    public var localizedDescription: String {
        switch self {
        case .missingParameter(let param):
            return "Missing required parameter: \(param)"
        case .invalidContext(let message):
            return "Invalid execution context: \(message)"
        case .executionFailed(let message):
            return "Tag execution failed: \(message)"
        case .resourceNotFound(let resource):
            return "Resource not found: \(resource)"
        case .permissionDenied(let message):
            return "Permission denied: \(message)"
        case .timeout:
            return "Tag execution timeout"
        }
    }
}
