//
//  ASTNode.swift
//  LiquidCore
//
//  Created as part of RhoeLiquid
//  A high-performance Swift 6.3 implementation of the Liquid template language
//

import Foundation

/// The main AST node type representing all possible constructs in a Liquid template
///
/// This indirect enum uses Swift's efficient pattern matching and exhaustive checking
/// to represent the complete syntax tree of a Liquid template. Each case represents
/// a different construct that can appear in a template.
public indirect enum ASTNode: Sendable {
    // MARK: - Root and Content
    
    /// The root template node containing all top-level nodes
    case template([ASTNode])
    
    /// Raw text content that should be output as-is
    case text(InlineString)
    
    /// Expression output (variables with optional filters)
    case output(Expression)
    
    // MARK: - Control Flow
    
    /// If conditional with optional elsif branches and else branch
    case `if`(
        condition: Expression,
        then: [ASTNode],
        elsif: [(Expression, [ASTNode])],
        else: [ASTNode]?
    )
    
    /// Unless conditional (inverse if) with optional else branch
    case unless(
        condition: Expression,
        then: [ASTNode],
        else: [ASTNode]?
    )
    
    /// Case/switch statement with when clauses and optional else
    case `case`(
        value: Expression,
        whens: [(Expression, [ASTNode])],
        else: [ASTNode]?
    )
    
    // MARK: - Loops
    
    /// For loop with variable, collection, body, empty clause, and parameters
    case `for`(
        variable: InlineString,
        in: Expression,
        body: [ASTNode],
        empty: [ASTNode]?,
        params: ForParams
    )
    
    /// Table row generation for HTML tables
    case tablerow(
        variable: InlineString,
        in: Expression,
        body: [ASTNode],
        params: TableRowParams
    )
    
    /// Cycle tag for alternating values
    case cycle(
        group: Expression?,
        items: [Expression]
    )
    
    // MARK: - Variable Assignment
    
    /// Variable assignment
    case assign(
        variable: InlineString,
        value: Expression
    )
    
    /// Capture rendered content into a variable
    case capture(
        variable: InlineString,
        body: [ASTNode]
    )
    
    /// Increment a counter variable
    case increment(name: InlineString)
    
    /// Decrement a counter variable
    case decrement(name: InlineString)
    
    // MARK: - Templates and Includes
    
    /// Include another template
    case include(
        template: InlineString,
        with: [String: Expression]?,
        as: InlineString?
    )

    /// Define a reusable macro with ordered parameters and optional defaults.
    case macro(
        signature: MacroSignatureNode,
        body: [ASTNode]
    )

    /// Import macros from another template file.
    case macroImport(MacroImportNode)

    /// Declare a template input contract field.
    case input(InputContractNode)
    
    /// Block definition for template inheritance
    case block(
        name: InlineString,
        body: [ASTNode]
    )
    
    /// Render a defined block with parameters
    case renderBlock(
        name: InlineString,
        params: [String: Expression]
    )
    
    /// Template inheritance - extends another template
    case extends(
        template: InlineString
    )
    
    // MARK: - Utility Constructs
    
    /// Comment (ignored during rendering)
    case comment
    
    /// Raw content (not processed for Liquid syntax)
    case raw(InlineString)
    
    /// Liquid tag for whitespace control
    case liquid(body: [ASTNode])
    
    /// Echo tag for direct expression output
    case echo(expression: Expression)
    
    /// Debug tag for development and troubleshooting
    case debug(expression: Expression?)

    /// Tag-driven macro invocation.
    case call(
        name: InlineString,
        arguments: [CallArgument],
        body: [ASTNode]?
    )

    /// Macro-side slot placeholder with fallback body content.
    case slot(
        name: InlineString,
        body: [ASTNode]
    )

    /// Call-side named fill block used by block-form macro calls.
    case fill(
        name: InlineString,
        body: [ASTNode]
    )
    
    /// Break statement for early loop exit
    case `break`
    
    /// Continue statement for next iteration
    case `continue`
    
    /// Pipeline for complex data transformations
    case pipeline(
        input: Expression,
        operations: [PipelineOp]
    )

    /// Runtime-backed custom tag resolved through the `LiquidTags` registry.
    case registeredCustomTag(
        name: InlineString,
        markup: InlineString,
        body: RuntimeCustomTagBody?
    )
    
    /// Custom tag implementation
    case custom(tag: any TagNode)
}

/// Internal macro parameter declaration stored in the AST.
public struct MacroParameterNode: Sendable, Equatable {
    public let name: InlineString
    public let defaultValue: Expression?

    public init(name: InlineString, defaultValue: Expression? = nil) {
        self.name = name
        self.defaultValue = defaultValue
    }
}

/// Internal macro signature declaration stored in the AST.
public struct MacroSignatureNode: Sendable, Equatable {
    public let name: InlineString
    public let parameters: [MacroParameterNode]

    public init(name: InlineString, parameters: [MacroParameterNode] = []) {
        self.name = name
        self.parameters = parameters
    }
}

/// Internal macro import declaration stored in the AST.
public struct MacroImportNode: Sendable, Equatable {
    public let template: InlineString
    public let namespace: InlineString?
    public let importedMacros: [InlineString]

    public init(
        template: InlineString,
        namespace: InlineString? = nil,
        importedMacros: [InlineString] = []
    ) {
        self.template = template
        self.namespace = namespace
        self.importedMacros = importedMacros
    }
}

/// Narrow Wave 16 input type grammar stored in the AST.
public indirect enum InputTypeNode: Sendable, Equatable {
    case string
    case number
    case boolean
    case object
    case any
    case array(InputTypeNode)

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
        case .array(let element):
            return "array<\(element.description)>"
        }
    }
}

/// One component in a path-based input declaration such as `user.name` or `items[].title`.
public enum InputPathComponentNode: Sendable, Equatable {
    case key(InlineString)
    case arrayElement

    public var description: String {
        switch self {
        case .key(let name):
            return name.string
        case .arrayElement:
            return "[]"
        }
    }
}

/// Internal template input declaration stored in the AST.
public struct InputContractNode: Sendable, Equatable {
    public let path: [InputPathComponentNode]
    public let type: InputTypeNode
    public let strict: Bool
    public let defaultValue: Expression?

    public init(
        name: InlineString,
        type: InputTypeNode,
        strict: Bool = false,
        defaultValue: Expression? = nil
    ) {
        self.path = Self.parsePath(from: name)
        self.type = type
        self.strict = strict
        self.defaultValue = defaultValue
    }

    public init(
        path: [InputPathComponentNode],
        type: InputTypeNode,
        strict: Bool = false,
        defaultValue: Expression? = nil
    ) {
        self.path = path
        self.type = type
        self.strict = strict
        self.defaultValue = defaultValue
    }

    public var name: InlineString {
        Self.canonicalName(for: path)
    }

    public var required: Bool {
        defaultValue == nil
    }

    public var rootName: String? {
        guard case .key(let root)? = path.first else {
            return nil
        }
        return root.string
    }

    private static func parsePath(from name: InlineString) -> [InputPathComponentNode] {
        let string = name.string
        guard !string.isEmpty else { return [] }

        var components: [InputPathComponentNode] = []
        var current = ""
        var index = string.startIndex

        while index < string.endIndex {
            let character = string[index]
            switch character {
            case ".":
                if !current.isEmpty {
                    components.append(.key(InlineString(current)))
                    current.removeAll(keepingCapacity: true)
                }
            case "[":
                if !current.isEmpty {
                    components.append(.key(InlineString(current)))
                    current.removeAll(keepingCapacity: true)
                }
                let next = string.index(after: index)
                if next < string.endIndex, string[next] == "]" {
                    components.append(.arrayElement)
                    index = next
                }
            default:
                current.append(character)
            }

            index = string.index(after: index)
        }

        if !current.isEmpty {
            components.append(.key(InlineString(current)))
        }

        return components
    }

    private static func canonicalName(for path: [InputPathComponentNode]) -> InlineString {
        var result = ""

        for component in path {
            switch component {
            case .key(let name):
                if !result.isEmpty {
                    result.append(".")
                }
                result.append(name.string)
            case .arrayElement:
                result.append("[]")
            }
        }

        return InlineString(result)
    }
}

// MARK: - Supporting Types

/// Parameters for for loops
public struct ForParams: Sendable, Equatable {
    /// Maximum number of iterations
    public let limit: Int?

    /// Number of items to skip at the beginning
    public let offset: Int?

    /// Whether to use offset: continue (continue from where previous loop ended)
    public let offsetContinue: Bool

    /// Whether to iterate in reverse order
    public let reversed: Bool

    /// Condition for filtering items
    public let condition: Expression?

    /// Whether the loop is recursive
    public let recursive: Bool

    /// Expression for limit (when it's a variable, needs runtime evaluation)
    public let limitExpression: Expression?

    /// Expression for offset (when it's a variable, needs runtime evaluation)
    public let offsetExpression: Expression?

    /// Pre-rendered static loop body captured during compilation for hot-path reuse.
    package let staticBodySegment: InlineString?

    /// Compiler-proved dynamic loop body plan for static text surrounding one or two outputs.
    package let renderPlan: LoopBodyRenderPlan?

    public init(
        limit: Int? = nil,
        offset: Int? = nil,
        offsetContinue: Bool = false,
        reversed: Bool = false,
        condition: Expression? = nil,
        recursive: Bool = false,
        limitExpression: Expression? = nil,
        offsetExpression: Expression? = nil
    ) {
        self.limit = limit
        self.offset = offset
        self.offsetContinue = offsetContinue
        self.reversed = reversed
        self.condition = condition
        self.recursive = recursive
        self.limitExpression = limitExpression
        self.offsetExpression = offsetExpression
        self.staticBodySegment = nil
        self.renderPlan = nil
    }

    package init(
        limit: Int? = nil,
        offset: Int? = nil,
        offsetContinue: Bool = false,
        reversed: Bool = false,
        condition: Expression? = nil,
        recursive: Bool = false,
        limitExpression: Expression? = nil,
        offsetExpression: Expression? = nil,
        staticBodySegment: InlineString? = nil,
        renderPlan: LoopBodyRenderPlan? = nil
    ) {
        self.limit = limit
        self.offset = offset
        self.offsetContinue = offsetContinue
        self.reversed = reversed
        self.condition = condition
        self.recursive = recursive
        self.limitExpression = limitExpression
        self.offsetExpression = offsetExpression
        self.staticBodySegment = staticBodySegment
        self.renderPlan = renderPlan
    }
}

/// Parameters for table row generation
public struct TableRowParams: Sendable, Equatable {
    /// Number of columns per row
    public let cols: Int?
    
    /// Maximum number of items to process
    public let limit: Int?
    
    /// Number of items to skip at the beginning
    public let offset: Int?

    /// Pre-rendered static cell body captured during compilation for hot-path reuse.
    package let staticBodySegment: InlineString?

    /// Compiler-proved dynamic cell body plan for static text surrounding one or two outputs.
    package let renderPlan: LoopBodyRenderPlan?

    public init(cols: Int? = nil, limit: Int? = nil, offset: Int? = nil) {
        self.cols = cols
        self.limit = limit
        self.offset = offset
        self.staticBodySegment = nil
        self.renderPlan = nil
    }

    package init(
        cols: Int? = nil,
        limit: Int? = nil,
        offset: Int? = nil,
        staticBodySegment: InlineString? = nil,
        renderPlan: LoopBodyRenderPlan? = nil
    ) {
        self.cols = cols
        self.limit = limit
        self.offset = offset
        self.staticBodySegment = staticBodySegment
        self.renderPlan = renderPlan
    }
}

package enum LoopBodyRenderPlan: Sendable, Equatable {
    case single(
        prefix: InlineString,
        expression: Expression,
        suffix: InlineString
    )
    case double(
        prefix: InlineString,
        first: Expression,
        middle: InlineString,
        second: Expression,
        suffix: InlineString
    )

    package var staticUTF8Count: Int {
        switch self {
        case .single(let prefix, _, let suffix):
            return prefix.utf8Count + suffix.utf8Count
        case .double(let prefix, _, let middle, _, let suffix):
            return prefix.utf8Count + middle.utf8Count + suffix.utf8Count
        }
    }
}

/// Pipeline operation for data transformation
public struct PipelineOp: Sendable, Equatable {
    /// The type of pipeline operation
    public enum Operation: Sendable, Equatable {
        /// Apply a filter to the data
        case filter(Filter)
        
        /// Assign the result to a variable
        case assign(InlineString)
    }
    
    /// The operation to perform
    public let operation: Operation
    
    public init(operation: Operation) {
        self.operation = operation
    }
}

/// Preserves both the raw body source and parsed body nodes for block custom tags.
public struct RuntimeCustomTagBody: Sendable {
    /// The original template source inside the custom block boundaries.
    public let source: InlineString

    /// The parsed AST nodes for the body.
    public let nodes: [ASTNode]

    public init(source: InlineString, nodes: [ASTNode]) {
        self.source = source
        self.nodes = nodes
    }
}

// MARK: - ASTNode Analysis and Utilities

extension ASTNode {
    /// Returns true if this node can contain child nodes
    public var isContainer: Bool {
        switch self {
        case .template, .if, .unless, .case, .for, .tablerow, .capture,
             .macro,
             .block, .liquid, .pipeline:
            return true
        case .registeredCustomTag(name: _, markup: _, body: let body):
            return body != nil
        case .text, .output, .assign, .include, .macroImport, .input, .comment, .raw,
             .echo, .debug, .cycle, .increment, .decrement, .renderBlock, .custom,
             .break, .continue, .extends:
            return false
        case .call(name: _, arguments: _, body: let body):
            return body != nil
        case .slot, .fill:
            return true
        }
    }
    
    /// Returns all immediate child nodes
    public var children: [ASTNode] {
        switch self {
        case .template(let nodes):
            return nodes
        case .if(condition: _, then: let then, elsif: let elsif, else: let elseBranch):
            var children = then
            for (_, nodes) in elsif {
                children.append(contentsOf: nodes)
            }
            if let elseNodes = elseBranch {
                children.append(contentsOf: elseNodes)
            }
            return children
        case .unless(condition: _, then: let then, else: let elseBranch):
            var children = then
            if let elseNodes = elseBranch {
                children.append(contentsOf: elseNodes)
            }
            return children
        case .case(value: _, whens: let whens, else: let elseBranch):
            var children: [ASTNode] = []
            for (_, nodes) in whens {
                children.append(contentsOf: nodes)
            }
            if let elseNodes = elseBranch {
                children.append(contentsOf: elseNodes)
            }
            return children
        case .for(variable: _, in: _, body: let body, empty: let empty, params: _):
            var children = body
            if let emptyNodes = empty {
                children.append(contentsOf: emptyNodes)
            }
            return children
        case .tablerow(variable: _, in: _, body: let body, params: _):
            return body
        case .capture(variable: _, body: let body),
             .macro(signature: _, body: let body),
             .block(name: _, body: let body),
             .slot(name: _, body: let body),
             .fill(name: _, body: let body),
             .liquid(body: let body):
            return body
        case .call(name: _, arguments: _, body: let body):
            return body ?? []
        case .registeredCustomTag(name: _, markup: _, body: let body):
            return body?.nodes ?? []
        case .text, .output, .assign, .include, .macroImport, .input, .comment, .raw,
             .echo, .debug, .cycle, .increment, .decrement, .renderBlock, .custom,
             .break, .continue, .pipeline, .extends:
            return []
        }
    }
    
    /// Returns all expressions contained in this node
    public var expressions: [Expression] {
        switch self {
        case .output(let expr):
            return [expr]
        case .if(condition: let condition, then: _, elsif: let elsif, else: _):
            var exprs = [condition]
            for (cond, _) in elsif {
                exprs.append(cond)
            }
            return exprs
        case .unless(condition: let condition, then: _, else: _):
            return [condition]
        case .case(value: let value, whens: let whens, else: _):
            var exprs = [value]
            for (expr, _) in whens {
                exprs.append(expr)
            }
            return exprs
        case .for(variable: _, in: let collection, body: _, empty: _, params: let params):
            var exprs = [collection]
            if let condition = params.condition {
                exprs.append(condition)
            }
            return exprs
        case .tablerow(variable: _, in: let collection, body: _, params: _):
            return [collection]
        case .assign(variable: _, value: let value):
            return [value]
        case .input(let contract):
            return contract.defaultValue.map { [$0] } ?? []
        case .cycle(group: _, items: let items):
            return items
        case .echo(expression: let expr):
            return [expr]
        case .debug(expression: let expr):
            return expr.map { [$0] } ?? []
        case .call(name: _, arguments: let arguments, body: _):
            return arguments.map(\.value)
        case .pipeline(input: let input, operations: let operations):
            var exprs = [input]
            for op in operations {
                if case .filter(let filter) = op.operation {
                    exprs.append(contentsOf: filter.arguments)
                }
            }
            return exprs
        case .include(template: _, with: let with, as: _):
            return with?.values.map { $0 } ?? []
        case .renderBlock(name: _, params: let params):
            return Array(params.values)
        case .registeredCustomTag:
            return []
        case .template, .text, .comment, .raw, .liquid, .break, .continue, .custom,
             .capture, .increment, .decrement, .block, .extends, .slot, .fill:
            return []
        case .macro(signature: let signature, body: _):
            return signature.parameters.compactMap(\.defaultValue)
        case .macroImport:
            return []
        }
    }
    
    /// Returns true if this node requires an end tag
    public var requiresEndTag: Bool {
        switch self {
        case .if, .unless, .case, .for, .tablerow, .capture, .macro, .block, .liquid, .pipeline,
             .slot, .fill:
            return true
        case .registeredCustomTag(name: _, markup: _, body: let body):
            return body != nil
        case .template, .text, .output, .assign, .include, .macroImport, .input, .comment, .raw,
             .echo, .debug, .cycle, .increment, .decrement, .renderBlock, .custom,
             .break, .continue, .extends:
            return false
        case .call(name: _, arguments: _, body: let body):
            return body != nil
        }
    }
    
    /// Returns the depth of nesting for this node
    public func nestingDepth() -> Int {
        let childDepths = children.map { $0.nestingDepth() }
        return (childDepths.max() ?? 0) + 1
    }

    /// Returns the total number of AST nodes in this subtree.
    public func totalNodeCount() -> Int {
        1 + children.reduce(0) { partial, child in
            partial + child.totalNodeCount()
        }
    }
    
    /// Visits all nodes in the tree with a closure
    public func visit(_ visitor: (ASTNode) throws -> Void) rethrows {
        try visitor(self)
        for child in children {
            try child.visit(visitor)
        }
    }
    
    /// Transforms the AST by applying a transformation to each node
    public func transform(_ transformer: (ASTNode) throws -> ASTNode) rethrows -> ASTNode {
        let transformedChildren = try children.map { try $0.transform(transformer) }
        
        let nodeWithTransformedChildren = updateChildren(transformedChildren)
        return try transformer(nodeWithTransformedChildren)
    }
    
    /// Updates this node with new children (used internally by transform)
    private func updateChildren(_ newChildren: [ASTNode]) -> ASTNode {
        switch self {
        case .template:
            return .template(newChildren)
        case .if(condition: let condition, then: _, elsif: let elsif, else: let elseBranch):
            // This is simplified - full implementation would need to handle elsif properly
            return .if(condition: condition, then: newChildren, elsif: elsif, else: elseBranch)
        case .unless(condition: let condition, then: _, else: let elseBranch):
            return .unless(condition: condition, then: newChildren, else: elseBranch)
        case .for(variable: let variable, in: let collection, body: _, empty: let empty, params: let params):
            return .for(variable: variable, in: collection, body: newChildren, empty: empty, params: params)
        case .capture(variable: let variable, body: _):
            return .capture(variable: variable, body: newChildren)
        case .macro(signature: let signature, body: _):
            return .macro(signature: signature, body: newChildren)
        case .block(name: let name, body: _):
            return .block(name: name, body: newChildren)
        case .slot(name: let name, body: _):
            return .slot(name: name, body: newChildren)
        case .fill(name: let name, body: _):
            return .fill(name: name, body: newChildren)
        case .call(name: let name, arguments: let arguments, body: let body):
            guard body != nil else { return self }
            return .call(name: name, arguments: arguments, body: newChildren)
        case .registeredCustomTag(name: let name, markup: let markup, body: let body):
            guard let body else {
                return self
            }
            return .registeredCustomTag(
                name: name,
                markup: markup,
                body: RuntimeCustomTagBody(source: body.source, nodes: newChildren)
            )
        case .liquid:
            return .liquid(body: newChildren)
        case .text, .output, .assign, .include, .macroImport, .input, .comment, .raw,
             .echo, .debug, .cycle, .increment, .decrement, .renderBlock, .custom,
             .break, .continue, .case, .tablerow, .pipeline, .extends:
            return self // Non-container nodes return unchanged
        }
    }
}

// MARK: - CustomStringConvertible

extension ASTNode: CustomStringConvertible {
    public var description: String {
        switch self {
        case .template(let nodes):
            return "template(\(nodes.count) nodes)"
        case .text(let content):
            return "text(\(content))"
        case .output(let expr):
            return "output(\(expr))"
        case .if(condition: let condition, then: let then, elsif: let elsif, else: let elseBranch):
            let elsifInfo = elsif.isEmpty ? "" : ", \(elsif.count) elsif"
            let elseInfo = elseBranch != nil ? ", else" : ""
            return "if(\(condition), \(then.count) then\(elsifInfo)\(elseInfo))"
        case .unless(condition: let condition, then: let then, else: let elseBranch):
            let elseInfo = elseBranch != nil ? ", else" : ""
            return "unless(\(condition), \(then.count) then\(elseInfo))"
        case .case(value: let value, whens: let whens, else: let elseBranch):
            let elseInfo = elseBranch != nil ? ", else" : ""
            return "case(\(value), \(whens.count) whens\(elseInfo))"
        case .for(variable: let variable, in: let collection, body: let body, empty: let empty, params: _):
            let emptyInfo = empty != nil ? ", empty: \(empty!.count)" : ""
            return "for(\(variable) in \(collection), \(body.count) nodes\(emptyInfo))"
        case .tablerow(variable: let variable, in: let collection, body: let body, params: _):
            return "tablerow(\(variable) in \(collection), \(body.count) nodes)"
        case .cycle(group: let group, items: let items):
            let groupInfo = group.map { "group: \($0), " } ?? ""
            return "cycle(\(groupInfo)\(items.count) items)"
        case .assign(variable: let variable, value: let value):
            return "assign(\(variable) = \(value))"
        case .capture(variable: let variable, body: let body):
            return "capture(\(variable), \(body.count) nodes)"
        case .increment(let name):
            return "increment(\(name))"
        case .decrement(let name):
            return "decrement(\(name))"
        case .include(template: let template, with: let with, as: let asVar):
            let withInfo = with != nil ? ", with params" : ""
            let asInfo = asVar.map { ", as \($0)" } ?? ""
            return "include(\(template)\(withInfo)\(asInfo))"
        case .macro(signature: let signature, body: let body):
            return "macro(\(signature.name), \(signature.parameters.count) params, \(body.count) nodes)"
        case .macroImport(let macroImport):
            if let namespace = macroImport.namespace {
                return "import(\(macroImport.template) as \(namespace))"
            }
            return "from(\(macroImport.template) import \(macroImport.importedMacros.count) macros)"
        case .input(let contract):
            if let defaultValue = contract.defaultValue {
                return "input(\(contract.name): \(contract.type.description) = \(defaultValue))"
            }
            return "input(\(contract.name): \(contract.type.description))"
        case .block(name: let name, body: let body):
            return "block(\(name), \(body.count) nodes)"
        case .renderBlock(name: let name, params: let params):
            return "renderBlock(\(name), \(params.count) params)"
        case .comment:
            return "comment"
        case .raw(let content):
            return "raw(\(content))"
        case .liquid(body: let body):
            return "liquid(\(body.count) nodes)"
        case .echo(expression: let expr):
            return "echo(\(expr))"
        case .debug(expression: let expr):
            return "debug(\(expr?.description ?? "all"))"
        case .call(name: let name, arguments: let arguments, body: let body):
            if let body {
                return "call(\(name), \(arguments.count) args, \(body.count) body nodes)"
            }
            return "call(\(name), \(arguments.count) args)"
        case .slot(name: let name, body: let body):
            return "slot(\(name), \(body.count) nodes)"
        case .fill(name: let name, body: let body):
            return "fill(\(name), \(body.count) nodes)"
        case .pipeline(input: let input, operations: let operations):
            return "pipeline(\(input), \(operations.count) ops)"
        case .registeredCustomTag(name: let name, markup: let markup, body: let body):
            if let body {
                return "registeredCustomTag(\(name), markup: \(markup), body: \(body.nodes.count) nodes)"
            }
            return "registeredCustomTag(\(name), markup: \(markup))"
        case .custom(let tag):
            return "custom(\(type(of: tag)))"
        case .break:
            return "break"
        case .continue:
            return "continue"
        case .extends(template: let template):
            return "extends(\(template))"
        }
    }
}
