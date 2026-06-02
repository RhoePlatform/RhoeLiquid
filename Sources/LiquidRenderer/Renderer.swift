//
//  Renderer.swift
//  LiquidRenderer
//
//  Created as part of RhoeLiquid
//  A high-performance Swift 6.3 implementation of the Liquid template language
//

import Foundation
import LiquidCore
import LiquidExtensions
import LiquidParser
import LiquidTags
import LiquidUtilities
import OrderedCollections

internal enum LoopControlSignal: Error {
    case breakLoop
    case continueLoop
    /// Break with partial output from include (Shopify: break inside include preserves output)
    case breakLoopWithOutput(String)
}

/// Configuration options for the renderer
public struct RendererConfiguration: Sendable {
    /// Whether to auto-escape HTML in variable outputs
    public let autoEscape: Bool
    
    /// Whether to throw errors in strict mode
    public let strictMode: Bool
    
    /// Maximum nesting depth for templates
    public let maxNestingDepth: Int
    
    /// Maximum loop iterations
    public let maxLoopIterations: Int
    
    /// Debug context for debugging support (optional)
    public let debugContext: DebugContext?
    
    public init(
        autoEscape: Bool = false,
        strictMode: Bool = false,
        maxNestingDepth: Int = 100,
        maxLoopIterations: Int = 1_000_000,
        debugContext: DebugContext? = nil
    ) {
        self.autoEscape = autoEscape
        self.strictMode = strictMode
        self.maxNestingDepth = maxNestingDepth
        self.maxLoopIterations = maxLoopIterations
        self.debugContext = debugContext
    }
    
    /// Default configuration
    public static let `default` = RendererConfiguration()
    
    /// Secure configuration with auto-escaping enabled
    public static let secure = RendererConfiguration(
        autoEscape: true,
        strictMode: true,
        maxNestingDepth: 50,
        maxLoopIterations: 100_000
    )
}

/// A high-performance renderer for executing Liquid AST and producing output
///
/// The `Renderer` is the final phase of template processing in RhoeLiquid. It takes
/// an Abstract Syntax Tree (AST) and a context of variables, then executes the template
/// logic to produce the final rendered output.
///
/// ## Overview
///
/// The renderer traverses the AST depth-first, evaluating expressions, applying filters,
/// and executing control flow logic. It maintains a rendering context that tracks:
///
/// - **Variables**: Template variables and their values
/// - **Scopes**: Nested variable scopes for loops and includes
/// - **Filters**: Built-in and custom filter functions
/// - **Configuration**: Auto-escaping, strict mode, and limits
///
/// ## Usage
///
/// ```swift
/// let renderer = Renderer(configuration: .secure)
/// let output = try await renderer.render(ast, with: [
///     "user": ["name": "Alice", "role": "admin"],
///     "items": ["Apple", "Banana", "Cherry"]
/// ])
/// ```
///
/// ## Features
///
/// ### Variable Resolution
///
/// The renderer supports complex variable access patterns:
/// - Simple variables: `{{ name }}`
/// - Nested properties: `{{ user.profile.email }}`
/// - Array access: `{{ items[0] }}`
/// - Dynamic access: `{{ data[key] }}`
///
/// ### Filter Pipeline
///
/// Filters transform values through a pipeline:
/// ```liquid
/// {{ "hello world" | upcase | split: " " | first }}
/// // Output: "HELLO"
/// ```
///
/// ### Control Flow
///
/// The renderer executes all Liquid control structures:
/// - Conditionals: `if`, `elsif`, `else`, `unless`
/// - Loops: `for`, `tablerow`
/// - Case statements: `case`, `when`
/// - Iteration control: `break`, `continue`
///
/// ### Security Features
///
/// When using secure configuration:
/// - **Auto-escaping**: HTML entities are escaped by default
/// - **Loop limits**: Prevents infinite loops
/// - **Nesting limits**: Prevents stack overflow
/// - **Safe filters**: Filters cannot execute arbitrary code
///
/// ## Performance
///
/// The renderer is optimized for speed:
/// - Direct AST execution without intermediate representation
/// - Efficient variable lookup with scope management
/// - Minimal allocations during rendering
/// - Typical performance: 10,000-100,000 ops/sec
///
/// ## Thread Safety
///
/// The `Renderer` class is designed for single-threaded use. Each renderer instance
/// maintains its own context and should not be shared between threads. For concurrent
/// rendering, create separate renderer instances.
public final class Renderer {
    internal struct MacroDefinition {
        let exportedName: String
        let signature: MacroSignatureNode
        let body: [ASTNode]
        let templatePath: String?
        let declaredSlots: Set<String>

        init(
            exportedName: String,
            signature: MacroSignatureNode,
            body: [ASTNode],
            templatePath: String?
        ) {
            self.exportedName = exportedName
            self.signature = signature
            self.body = body
            self.templatePath = templatePath
            self.declaredSlots = Self.collectDeclaredSlots(in: body)
        }

        var identity: String {
            if let templatePath {
                return "\(templatePath)::\(exportedName)"
            }
            return exportedName
        }

        internal static func collectDeclaredSlots(in nodes: [ASTNode]) -> Set<String> {
            var names = Set<String>()
            var stack = nodes

            while let node = stack.popLast() {
                if case .slot(let name, _) = node {
                    names.insert(name.string)
                }
                stack.append(contentsOf: node.children)
            }

            return names
        }
    }

    internal struct AuthoringScope {
        let macros: [String: MacroDefinition]
        let inputContracts: [InputContractNode]
    }

    internal struct EvaluatedCallArgument {
        let label: String?
        let value: Any
    }

    internal struct MacroInvocationFrame {
        let defaultBody: [ASTNode]
        let namedFills: [String: [ASTNode]]
    }

    // MARK: - Properties
    
    /// The current rendering context with variables and state
    internal var context: RenderingContext

    /// Configuration for rendering behavior
    internal let configuration: RendererConfiguration

    /// Cached auto-escape flag so hot rendering paths don't keep re-reading configuration.
    internal let autoEscapeEnabled: Bool

    /// Registry-backed filters injected by `LiquidEngine` for this render pass.
    internal var customFilters: [String: any CustomFilter]

    /// Registry-backed custom tags injected by `LiquidEngine` for this render pass.
    internal var customTags: [String: any LiquidTags.CustomTag]

    /// Loader used for include, render, and inheritance-aware renders.
    internal var templateLoader: TemplateLoader?

    /// Data loader registry used by built-in data-loading tags.
    internal var dataLoaderRegistry: DataLoaderRegistry?

    /// Root template path for the current render pass.
    internal var rootTemplatePath: String?

    /// Active include/render stack used for relative template resolution.
    internal var templatePathStack: [String]

    /// Compiled-template hint that lets warm renders skip `forloop` body scans when provably unnecessary.
    internal var canSkipForloopObjectAnalysis: Bool

    /// Compiled-template hint that lets warm renders skip `tablerowloop` body scans when provably unnecessary.
    internal var canSkipTableRowLoopObjectAnalysis: Bool

    /// Authoring-layer macro scopes for the current render stack.
    internal var macroScopes: [[String: MacroDefinition]]

    /// Input contracts active for the current render stack.
    internal var inputContractScopes: [[InputContractNode]]

    /// Active macro call stack used to reject recursive/circular execution.
    internal var macroCallStack: [String]

    /// Active block-call frames used to resolve macro slots.
    internal var macroInvocationStack: [MacroInvocationFrame]

    /// Import path stack used to reject circular file-backed macro imports.
    internal var macroImportPathStack: [String]

    // MARK: - Initialization
    
    /// Creates a new renderer
    public init(configuration: RendererConfiguration = .default) {
        self.context = RenderingContext()
        self.configuration = configuration
        self.autoEscapeEnabled = configuration.autoEscape
        self.customFilters = [:]
        self.customTags = [:]
        self.templateLoader = nil
        self.dataLoaderRegistry = nil
        self.rootTemplatePath = nil
        self.templatePathStack = []
        self.canSkipForloopObjectAnalysis = false
        self.canSkipTableRowLoopObjectAnalysis = false
        self.macroScopes = []
        self.inputContractScopes = []
        self.macroCallStack = []
        self.macroInvocationStack = []
        self.macroImportPathStack = []
        // Set up debug context in RenderingContext
        self.context.debugContext = configuration.debugContext
    }

    /// Updates the registry-backed filters used after the core filter fast paths.
    public func setCustomFilters(_ filters: [String: any CustomFilter]) {
        self.customFilters = filters
    }

    /// Updates the registry-backed custom tags available during this render pass.
    public func setCustomTags(_ tags: [String: any LiquidTags.CustomTag]) {
        self.customTags = tags
    }

    /// Configures the template loader used by file-backed template operations.
    public func setTemplateLoader(_ loader: TemplateLoader?, rootTemplatePath: String? = nil) {
        self.templateLoader = loader
        self.rootTemplatePath = rootTemplatePath
        resetTemplatePathStack()
    }

    /// Configures the data loader registry used by data-loading tags.
    public func setDataLoaderRegistry(_ registry: DataLoaderRegistry?) {
        self.dataLoaderRegistry = registry
    }

    internal var customTagDescriptors: [CustomTagDescriptor] {
        customTags.values
            .map { tag in
                CustomTagDescriptor(
                    name: tag.name,
                    requiresEndTag: tag.type.requiresEndTag
                )
            }
            .sorted { $0.name < $1.name }
    }
    
    // MARK: - Public Interface
    
    /// Renders an AST node to a string with an optional context
    ///
    /// This is the main entry point for template rendering. It sets up the rendering
    /// context with the provided variables and executes the AST to produce output.
    ///
    /// - Parameters:
    ///   - node: The AST node to render (typically a `.template` node)
    ///   - variables: Variables available during rendering
    /// - Returns: The rendered string output
    /// - Throws: `RenderError` if rendering fails
    ///
    /// ## Example
    ///
    /// ```swift
    /// let renderer = Renderer()
    /// let ast = try parser.parse()
    /// 
    /// let output = try await renderer.render(ast, with: [
    ///     "title": "Welcome",
    ///     "user": ["name": "Alice", "admin": true],
    ///     "items": [1, 2, 3, 4, 5]
    /// ])
    /// ```
    ///
    /// ## Variable Context
    ///
    /// The variables dictionary supports any valid Swift types:
    /// - Strings, numbers, booleans
    /// - Arrays and dictionaries
    /// - Custom objects (accessed via Mirror reflection)
    /// - `nil` values (treated as empty strings)
    ///
    /// ## Auto-Escaping
    ///
    /// When configured with `autoEscape: true`, all variable outputs
    /// are HTML-escaped unless explicitly marked as safe:
    ///
    /// ```liquid
    /// {{ userInput }}          <!-- Escaped -->
    /// {{ userInput | raw }}    <!-- Not escaped -->
    /// {{ userInput | escape }} <!-- Explicitly escaped -->
    /// ```
    ///
    /// ## Error Handling
    ///
    /// Common rendering errors:
    /// - `RenderError.undefinedFilter`: Unknown filter name
    /// - `RenderError.typeError`: Invalid type for operation
    /// - `RenderError.arithmeticError`: Division by zero
    /// - `RenderError.custom`: Tag-specific errors
    public func render(_ node: borrowing ASTNode, with variables: [String: Any] = [:]) async throws -> String {
        // Set up context
        canSkipForloopObjectAnalysis = false
        canSkipTableRowLoopObjectAnalysis = false
        context.setVariables(variables)
        resetTemplatePathStack()
        resetAuthoringState()

        let preparedNode = try await prepareASTForRendering(node)
        return try await withAuthoringScope(for: preparedNode, templatePath: currentTemplatePath) {
            try await renderNode(preparedNode)
        }
    }

    /// Renders a compiled template using its optimization metadata to prewarm rendering state.
    public func render(_ compiledTemplate: borrowing CompiledTemplate, with variables: [String: Any] = [:]) async throws -> String {
        resetTemplatePathStack()
        let optimizedAST = compiledTemplate.optimizedAST

        if requiresInheritanceProcessing(optimizedAST) {
            canSkipForloopObjectAnalysis = false
            canSkipTableRowLoopObjectAnalysis = false
            context.setVariables(variables)
            resetAuthoringState()
            let preparedNode = try await prepareASTForRendering(optimizedAST)
            return try await withAuthoringScope(for: preparedNode, templatePath: currentTemplatePath) {
                try await renderNode(preparedNode)
            }
        }

        canSkipForloopObjectAnalysis = compiledTemplate.performanceHints.canSkipForloopObjectAnalysis
        canSkipTableRowLoopObjectAnalysis = compiledTemplate.performanceHints.canSkipTableRowLoopObjectAnalysis

        context.setVariables(
            variables,
            prewarmingVariableAccess: compiledTemplate.variableAccess,
            performanceHints: compiledTemplate.performanceHints
        )
        resetAuthoringState()

        let authoringScope = try await buildAuthoringScope(from: optimizedAST, templatePath: currentTemplatePath)
        macroScopes.append(authoringScope.macros)
        inputContractScopes.append(authoringScope.inputContracts)
        defer {
            _ = inputContractScopes.popLast()
            _ = macroScopes.popLast()
        }
        try await applyInputDefaults(authoringScope.inputContracts)

        if case .template(let nodes) = optimizedAST {
            return try await renderCompiledTemplateNodes(
                nodes,
                staticCapacityHint: compiledTemplate.staticCapacityHint
            )
        }

        return try await renderNode(optimizedAST)
    }
    
}

// MARK: - Rendering Context

/// Manages variables and state during template rendering
/// 
/// This is a class used internally by Renderer during a single render operation.
/// It doesn't need to be Sendable because each Renderer instance is used within
/// a single task and is not shared across concurrent contexts.
internal final class RenderingContext {
    internal struct VariableSnapshot {
        let name: String
        let storedValue: Any?
        let existed: Bool
        let usedLocalScope: Bool
    }

    private enum PathComponent {
        case size
        case first
        case last
        case index(Int)
        case key(String)
    }

    private struct CachedVariablePath {
        let baseName: String
        let components: [PathComponent]
    }

    private var variables: [String: Any] = [:]
    private var scopes: [[String: Any]] = []
    private var currentScope: [String: Any]?
    private var blockDefinitions: [String: [ASTNode]] = [:]
    private var variablePathCache: [String: CachedVariablePath] = [:]
    private var loopDepth: Int = 0
    /// Separate namespace for increment/decrement counters (Shopify Liquid behavior)
    private var counters: [String: Int] = [:]
    
    /// Debug context for variable access tracking (weak reference to avoid cycles)
    weak var debugContext: DebugContext?
    
    func setVariables(
        _ vars: [String: Any],
        prewarmingVariableAccess: [String: AccessPattern] = [:],
        performanceHints: PerformanceHints? = nil
    ) {
        variables = vars
        if !scopes.isEmpty {
            scopes.removeAll(keepingCapacity: true)
        }
        currentScope = nil
        loopDepth = 0
        if !counters.isEmpty {
            counters.removeAll(keepingCapacity: true)
        }
        if !blockDefinitions.isEmpty {
            blockDefinitions.removeAll(keepingCapacity: true)
        }
        if let performanceHints {
            if performanceHints.maxLoopDepth > 0 {
                scopes.reserveCapacity(performanceHints.maxLoopDepth)
            }
            if performanceHints.estimatedVariableCount > 0 {
                variablePathCache.reserveCapacity(performanceHints.estimatedVariableCount)
            }
        }
        if !prewarmingVariableAccess.isEmpty {
            variablePathCache.reserveCapacity(max(variablePathCache.count, prewarmingVariableAccess.count))
            prewarmVariablePaths(prewarmingVariableAccess)
        }
    }
    
    func getVariable(_ name: String) -> Any? {
        let value: Any?

        if let path = cachedVariablePath(for: name) {
            switch path.components.count {
            case 0:
                value = lookupValue(named: path.baseName)
            case 1:
                if let baseValue = lookupValue(named: path.baseName) {
                    switch path.components[0] {
                    case .size:
                        if let dict = baseValue as? [String: Any], let v = dict["size"] ?? dict["length"] {
                            value = v
                        } else if let ordered = baseValue as? OrderedDictionary<String, Any>, let v = ordered["size"] ?? ordered["length"] {
                            value = v
                        } else if let array = baseValue as? [Any] {
                            value = array.count
                        } else if let string = baseValue as? String {
                            value = string.count
                        } else {
                            value = 0
                        }
                    case .first:
                        if let dict = baseValue as? [String: Any], let v = dict["first"] {
                            value = v
                        } else if let ordered = baseValue as? OrderedDictionary<String, Any> {
                            if let v = ordered["first"] {
                                value = v
                            } else if !ordered.isEmpty {
                                let first = ordered.elements[0]
                                value = [first.key, first.value] as [Any]
                            } else {
                                value = nil
                            }
                        } else if let array = baseValue as? [Any], !array.isEmpty {
                            value = array[0]
                        } else {
                            value = nil
                        }
                    case .last:
                        if let dict = baseValue as? [String: Any], let v = dict["last"] {
                            value = v
                        } else if let ordered = baseValue as? OrderedDictionary<String, Any>, let v = ordered["last"] {
                            value = v
                        } else if let array = baseValue as? [Any], !array.isEmpty {
                            value = array[array.count - 1]
                        } else {
                            value = nil
                        }
                    case .index(let index):
                        if let array = baseValue as? [Any], index >= 0 && index < array.count {
                            value = array[index]
                        } else {
                            value = nil
                        }
                    case .key(let key):
                        if let dictionary = baseValue as? [String: Any] {
                            value = dictionary[key]
                        } else if let ordered = baseValue as? OrderedDictionary<String, Any> {
                            // Check for special properties first, then dict key
                            if let v = ordered[key] {
                                value = v
                            } else if key == "first", !ordered.isEmpty {
                                let first = ordered.elements[0]
                                value = [first.key, first.value] as [Any]
                            } else if key == "last", !ordered.isEmpty {
                                let lastPair = ordered.elements[ordered.count - 1]
                                value = [lastPair.key, lastPair.value] as [Any]
                            } else if key == "size" || key == "length" {
                                value = ordered.count
                            } else {
                                value = nil
                            }
                        } else if let dataValue = baseValue as? DataValue {
                            value = dataValue[key].liquidValue
                        } else {
                            value = resolve(path.components[0], from: baseValue)
                        }
                    }
                } else {
                    value = nil
                }
            default:
                var currentValue = lookupValue(named: path.baseName)
                for component in path.components {
                    guard let resolved = currentValue else {
                        currentValue = nil
                        break
                    }
                    currentValue = resolve(component, from: resolved)
                }
                value = currentValue
            }
        } else {
            value = lookupValue(named: name)
        }

        recordVariableAccess(name, type: .read, value: value)
        return value
    }
    
    func setVariable(_ name: String, value: Any) {
        if currentScope != nil {
            currentScope?[name] = value
        } else {
            variables[name] = value
        }

        recordVariableAccess(name, type: .write, value: value)
    }

    /// Sets a variable at root scope so it persists after loops and blocks.
    /// Used by `assign` tag (Shopify behavior: assign leaks to outer scope).
    func setRootVariable(_ name: String, value: Any) {
        variables[name] = value
        recordVariableAccess(name, type: .write, value: value)
    }

    /// Get/set counters in the separate increment/decrement namespace
    func getCounter(_ name: String) -> Int? {
        return counters[name]
    }

    func setCounter(_ name: String, value: Int) {
        counters[name] = value
    }

    
    func pushScope(_ scope: [String: Any] = [:]) {
        if let currentScope {
            scopes.append(currentScope)
        }
        currentScope = scope
    }
    
    func popScope() {
        currentScope = scopes.popLast()
    }

    var isInsideLoop: Bool {
        loopDepth > 0
    }

    func enterLoop() {
        loopDepth += 1
    }

    func leaveLoop() {
        if loopDepth > 0 {
            loopDepth -= 1
        }
    }

    internal func snapshotVariables(named names: [String]) -> [VariableSnapshot] {
        let useLocalScope = currentScope != nil

        return names.map { name in
            if useLocalScope {
                let storedValue = currentScope?[name]
                return VariableSnapshot(
                    name: name,
                    storedValue: storedValue,
                    existed: storedValue != nil,
                    usedLocalScope: true
                )
            }

            let storedValue = variables[name]
            return VariableSnapshot(
                name: name,
                storedValue: storedValue,
                existed: storedValue != nil,
                usedLocalScope: false
            )
        }
    }

    internal func restoreVariables(_ snapshots: [VariableSnapshot]) {
        for snapshot in snapshots {
            if snapshot.usedLocalScope, currentScope != nil {
                if snapshot.existed {
                    currentScope?[snapshot.name] = snapshot.storedValue
                } else {
                    currentScope?.removeValue(forKey: snapshot.name)
                }
            } else if snapshot.existed {
                variables[snapshot.name] = snapshot.storedValue
            } else {
                variables.removeValue(forKey: snapshot.name)
            }
        }
    }
    
    /// Defines a block for later use
    func defineBlock(_ name: String, body: [ASTNode]) {
        blockDefinitions[name] = body
    }
    
    static func isStaticallyBlankBlock(_ nodes: [ASTNode]) -> Bool {
        for node in nodes {
            switch node {
            case .text(let text):
                if !text.string.allSatisfy(\.isWhitespace) { return false }
            case .assign, .comment, .increment, .decrement, .capture:
                continue
            case .if(_, let thenNodes, let elsifBranches, let elseNodes):
                if !isStaticallyBlankBlock(thenNodes) { return false }
                for (_, branchNodes) in elsifBranches {
                    if !isStaticallyBlankBlock(branchNodes) { return false }
                }
                if let elseNodes, !isStaticallyBlankBlock(elseNodes) { return false }
            case .unless(_, let thenNodes, let elseNodes):
                if !isStaticallyBlankBlock(thenNodes) { return false }
                if let elseNodes, !isStaticallyBlankBlock(elseNodes) { return false }
            case .case(_, let whens, let elseBranch):
                for (_, whenNodes) in whens { if !isStaticallyBlankBlock(whenNodes) { return false } }
                if let elseBranch, !isStaticallyBlankBlock(elseBranch) { return false }
            case .for(_, _, let body, let empty, _):
                if !isStaticallyBlankBlock(body) { return false }
                if let empty, !isStaticallyBlankBlock(empty) { return false }
            case .liquid(let body):
                if !isStaticallyBlankBlock(body) { return false }
            case .output, .echo, .raw:
                return false
            default:
                return false
            }
        }
        return true
    }

    /// Gets a block definition by name
    func getBlockDefinition(_ name: String) -> [ASTNode]? {
        return blockDefinitions[name]
    }
    
    /// Checks if a block is defined
    func hasBlock(_ name: String) -> Bool {
        return blockDefinitions[name] != nil
    }

    struct SavedState {
        let variables: [String: Any]
        let scopes: [[String: Any]]
        let currentScope: [String: Any]?
        let counters: [String: Int]
    }

    func saveState() -> SavedState {
        SavedState(
            variables: variables,
            scopes: scopes,
            currentScope: currentScope,
            counters: counters
        )
    }

    func restoreState(_ state: SavedState) {
        variables = state.variables
        scopes = state.scopes
        currentScope = state.currentScope
        counters = state.counters
    }

    func isolateScope(with bindings: [String: Any]) {
        variables = [:]
        scopes.removeAll(keepingCapacity: true)
        currentScope = nil
        counters.removeAll(keepingCapacity: true)
        for (key, value) in bindings {
            variables[key] = value
        }
    }

    func currentScopeVariables() -> [String: Any] {
        currentScope ?? [:]
    }

    func hasCompleteInputContractValue(at path: [InputPathComponentNode]) -> Bool {
        guard !path.isEmpty else {
            return false
        }

        return hasInputContractValue(
            lookupValueForInputPathComponent(path[0]),
            remaining: Array(path.dropFirst())
        )
    }

    func applyInputContractDefault(_ value: Any, at path: [InputPathComponentNode]) {
        guard case .key(let rootName)? = path.first else {
            return
        }

        let existingValue = lookupValue(named: rootName.string)
        let (updatedValue, changed) = applyingInputContractDefault(
            existingValue,
            remaining: Array(path.dropFirst()),
            defaultValue: value
        )

        guard changed else {
            return
        }

        if currentScope != nil {
            currentScope?[rootName.string] = updatedValue
        } else {
            variables[rootName.string] = updatedValue
        }

        recordVariableAccess(InputContractNode(path: path, type: .any).name.string, type: .write, value: updatedValue)
    }

    func visibleVariables() -> [String: Any] {
        var merged = variables
        for scope in scopes {
            for (key, value) in scope {
                merged[key] = value
            }
        }
        if let currentScope {
            for (key, value) in currentScope {
                merged[key] = value
            }
        }
        return merged
    }

    func currentLoopContext() -> LoopContext? {
        let forloopRaw = getVariable("forloop")
        let forloop: [String: Any]
        if let dict = forloopRaw as? [String: Any] {
            forloop = dict
        } else if let ordered = forloopRaw as? OrderedDictionary<String, Any> {
            forloop = Dictionary(uniqueKeysWithValues: ordered.map { ($0.key, $0.value) })
        } else {
            return nil
        }

        let index0 = integerValue(forloop["index0"]) ?? 0
        let length = integerValue(forloop["length"]) ?? 0
        guard length > 0 else {
            return nil
        }

        return LoopContext(index: index0, length: length)
    }

    private func lookupValue(named name: String) -> Any? {
        // Check current scope first
        if let currentScope,
           let value = currentScope[name] {
            return value
        }
        // Check parent scopes (for nested loop variables like forloop/parentloop)
        for scope in scopes.reversed() {
            if let value = scope[name] {
                return value
            }
        }
        // Check normal variables first, then fall back to counter namespace
        if let value = variables[name] {
            return value
        }
        // Fall back to increment/decrement counter namespace
        if let counter = counters[name] {
            return counter
        }
        return nil
    }

    private func lookupValueForInputPathComponent(_ component: InputPathComponentNode) -> Any? {
        guard case .key(let name) = component else {
            return nil
        }
        return lookupValue(named: name.string)
    }

    private func hasInputContractValue(_ value: Any?, remaining: [InputPathComponentNode]) -> Bool {
        if remaining.isEmpty {
            return value != nil
        }

        guard let value else {
            return false
        }

        switch remaining[0] {
        case .key(let key):
            return hasInputContractValue(
                nestedInputContractValue(forKey: key.string, in: value),
                remaining: Array(remaining.dropFirst())
            )
        case .arrayElement:
            let array: [Any]
            if let values = value as? [Any] {
                array = values
            } else if let dataValue = value as? DataValue,
                      case .array(let values) = dataValue {
                array = values.map(\.liquidValue)
            } else {
                return false
            }

            guard !array.isEmpty else {
                return false
            }

            let rest = Array(remaining.dropFirst())
            return array.allSatisfy { hasInputContractValue($0, remaining: rest) }
        }
    }

    private func nestedInputContractValue(forKey key: String, in value: Any) -> Any? {
        if let dictionary = value as? [String: Any] {
            return dictionary[key]
        }
        if let ordered = value as? OrderedDictionary<String, Any> {
            return ordered[key]
        }
        if let dataValue = value as? DataValue {
            return dataValue[key].liquidValue
        }
        return nil
    }

    private func applyingInputContractDefault(
        _ value: Any?,
        remaining: [InputPathComponentNode],
        defaultValue: Any
    ) -> (Any, Bool) {
        if remaining.isEmpty {
            if let value {
                return (value, false)
            }
            return (defaultValue, true)
        }

        switch remaining[0] {
        case .key(let key):
            var dictionary: [String: Any]
            if let existing = value as? [String: Any] {
                dictionary = existing
            } else if let ordered = value as? OrderedDictionary<String, Any> {
                // Convert OrderedDictionary to regular dict for mutation
                dictionary = Dictionary(uniqueKeysWithValues: ordered.map { ($0.key, $0.value) })
            } else if let dataValue = value as? DataValue,
                      case .object(let object) = dataValue {
                dictionary = object.mapValues(\.liquidValue)
            } else {
                dictionary = [:]
            }

            let existingChild = dictionary[key.string]
            let (updatedChild, changed) = applyingInputContractDefault(
                existingChild,
                remaining: Array(remaining.dropFirst()),
                defaultValue: defaultValue
            )

            guard changed else {
                return (dictionary, false)
            }

            dictionary[key.string] = updatedChild
            return (dictionary, true)

        case .arrayElement:
            var array: [Any]
            if let existing = value as? [Any] {
                array = existing
            } else if let dataValue = value as? DataValue,
                      case .array(let values) = dataValue {
                array = values.map(\.liquidValue)
            } else {
                return (value as Any, false)
            }

            let rest = Array(remaining.dropFirst())
            var changed = false
            for index in array.indices {
                let (updatedElement, elementChanged) = applyingInputContractDefault(
                    array[index],
                    remaining: rest,
                    defaultValue: defaultValue
                )
                if elementChanged {
                    array[index] = updatedElement
                    changed = true
                }
            }

            return (array, changed)
        }
    }

    private func cachedVariablePath(for name: String) -> CachedVariablePath? {
        if let cached = variablePathCache[name] {
            return cached
        }

        guard name.contains(".") else {
            return nil
        }

        let rawComponents = name.split(separator: ".")
        guard let first = rawComponents.first else {
            return nil
        }

        let cached = makeCachedVariablePath(
            baseName: String(first),
            components: rawComponents.dropFirst()
        )
        if variablePathCache.count > 512 {
            variablePathCache.removeAll(keepingCapacity: true)
        }
        variablePathCache[name] = cached
        return cached
    }

    private func prewarmVariablePaths(_ accessPatterns: [String: AccessPattern]) {
        for (name, accessPattern) in accessPatterns {
            guard accessPattern.path.count > 1, variablePathCache[name] == nil else {
                continue
            }

            let cached = makeCachedVariablePath(
                baseName: accessPattern.path[0],
                components: accessPattern.path.dropFirst()
            )
            variablePathCache[name] = cached
        }
    }

    @inline(__always)
    private func makeCachedVariablePath<S: Sequence>(
        baseName: String,
        components: S
    ) -> CachedVariablePath where S.Element: StringProtocol {
        var parsedComponents: [PathComponent] = []
        let rawComponents = Array(components)
        parsedComponents.reserveCapacity(rawComponents.count)

        for rawComponent in rawComponents {
            switch rawComponent {
            case "size", "length":
                parsedComponents.append(.size)
            case "first":
                parsedComponents.append(.first)
            case "last":
                parsedComponents.append(.last)
            default:
                if let index = Int(rawComponent) {
                    parsedComponents.append(.index(index))
                } else {
                    parsedComponents.append(.key(String(rawComponent)))
                }
            }
        }

        return CachedVariablePath(
            baseName: baseName,
            components: parsedComponents
        )
    }

    private func resolve(_ component: PathComponent, from value: Any) -> Any? {
        switch component {
        case .size:
            // Dictionary key "size" or "length" takes priority (e.g., forloop.length)
            if let dict = value as? [String: Any] {
                if let val = dict["size"] { return val }
                if let val = dict["length"] { return val }
            }
            if let ordered = value as? OrderedDictionary<String, Any> {
                if let val = ordered["size"] { return val }
                if let val = ordered["length"] { return val }
            }
            if let array = value as? [Any] {
                return array.count
            } else if let string = value as? String {
                return string.count
            }
            return 0

        case .first:
            // Dictionary key "first" takes priority (e.g., forloop.first)
            if let dict = value as? [String: Any], let val = dict["first"] {
                return val
            }
            if let ordered = value as? OrderedDictionary<String, Any>, let val = ordered["first"] {
                return val
            }
            if let array = value as? [Any], !array.isEmpty {
                return array[0]
            }
            return nil

        case .last:
            // Dictionary key "last" takes priority (e.g., forloop.last)
            if let dict = value as? [String: Any], let val = dict["last"] {
                return val
            }
            if let ordered = value as? OrderedDictionary<String, Any>, let val = ordered["last"] {
                return val
            }
            if let array = value as? [Any], !array.isEmpty {
                return array[array.count - 1]
            }
            return nil

        case .index(let index):
            if let array = value as? [Any], index >= 0 && index < array.count {
                return array[index]
            }
            return nil

        case .key(let key):
            if let dictionary = value as? [String: Any] {
                return dictionary[key]
            }
            if let ordered = value as? OrderedDictionary<String, Any> {
                return ordered[key]
            }
            if let dataValue = value as? DataValue {
                return dataValue[key].liquidValue
            }

            let mirror = Mirror(reflecting: value)
            for child in mirror.children where child.label == key {
                return child.value
            }
            return nil
        }
    }

    private func recordVariableAccess(_ name: String, type: DebugVariableAccessType, value: Any?) {
        guard let debugContext else {
            return
        }

        let config = debugContext.configuration
        let capturedName = name
        let capturedValue = value.map(SendableAnyValue.init)
        Task {
            let access = DebugVariableAccess(
                variableName: capturedName,
                accessType: type,
                value: capturedValue,
                location: LiquidSourceLocation(line: 0, column: 0, position: 0, templateName: nil)
            )
            await debugContext.recordVariableAccess(access)

            if config.trackVariables {
                config.outputHandler?.handleDebugOutput(.variableAccess(access))
            }
        }
    }

    private func integerValue(_ value: Any?) -> Int? {
        switch value {
        case let int as Int:
            return int
        case let double as Double:
            return Int(double)
        case let number as NSNumber:
            return number.intValue
        case let string as String:
            return Int(string)
        default:
            return nil
        }
    }
}

// MARK: - Async Extensions

extension Sequence {
    func asyncMap<T>(_ transform: (Element) async throws -> T) async rethrows -> [T] {
        var results: [T] = []
        for element in self {
            results.append(try await transform(element))
        }
        return results
    }
}
