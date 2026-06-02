//
//  Parser.swift
//  LiquidParser
//
//  Created as part of RhoeLiquid
//  A high-performance Swift 6.3 implementation of the Liquid template language
//

import Foundation
import LiquidCore
import LiquidLexer

/// A recursive descent parser for building AST from Liquid tokens
///
/// The `Parser` transforms a sequence of tokens into an Abstract Syntax Tree (AST)
/// that represents the structure and semantics of a Liquid template. It uses
/// recursive descent parsing techniques to handle nested structures efficiently.
///
/// ## Overview
///
/// The parser is the second phase of template processing in RhoeLiquid. It takes
/// the token stream produced by the lexer and builds a hierarchical tree structure
/// that captures the template's logic:
///
/// - **Template nodes**: The root container for all other nodes
/// - **Text nodes**: Literal text to be rendered
/// - **Output nodes**: Variable expressions to be evaluated
/// - **Control flow nodes**: If/else, for loops, case statements
/// - **Tag nodes**: Include, assign, capture, and custom tags
///
/// ## Usage
///
/// ```swift
/// let tokens = try lexer.tokenize()
/// let parser = Parser(consuming: tokens)
/// let ast = try parser.parse()
///
/// // AST structure for "Hello {{ name }}!":
/// // .template([
/// //     .text("Hello "),
/// //     .output(.variable("name")),
/// //     .text("!")
/// // ])
/// ```
///
/// ## Grammar
///
/// The parser implements the following simplified grammar:
///
/// ```
/// template    ::= node*
/// node        ::= text | variable | tag
/// variable    ::= "{{" expression "}}"
/// tag         ::= "{%" tagname arguments "%}" [body] ["{%" endtag "%}"]
/// expression  ::= term ("|" filter)*
/// filter      ::= identifier [":" argument ("," argument)*]
/// ```
///
/// ## Performance Characteristics
///
/// - **Time complexity**: O(n) where n is the number of tokens
/// - **Space complexity**: O(d) where d is the maximum nesting depth
/// - **Typical performance**: 50,000-200,000 ops/sec
///
/// ## Thread Safety
///
/// The `Parser` class is designed for single-threaded use. Each parser instance
/// should be used by only one thread. For concurrent parsing, create separate
/// parser instances for each thread.
///
/// ## Error Handling
///
/// The parser throws `ParserError` for syntax errors:
/// - Unexpected tokens
/// - Mismatched tags (e.g., `{% if %}...{% endfor %}`)
/// - Invalid expressions
/// - Missing end tags
public final class Parser {
    private static let eofToken = Token(
        type: .text(InlineString()),
        position: 0,
        line: 0,
        column: 0
    )

    // MARK: - Properties
    
    /// The array of tokens to parse
    private let tokens: [Token]

    /// Original template source when available, used to preserve raw custom-tag bodies.
    private let source: String?

    /// Registered runtime custom tags the parser should recognize.
    private let customTagDescriptors: [String: CustomTagDescriptor]
    
    /// Current position in the token array
    private var current: Int = 0

    /// Cached current token for hot parser paths.
    private var currentTokenStorage: Token

    /// Cached one-token lookahead for tag boundary checks.
    private var nextTokenStorage: Token

    /// Number of active macro bodies being parsed.
    private var macroBodyDepth: Int = 0

    /// Number of active block-form call bodies being parsed.
    private var callBlockDepth: Int = 0

    private struct ParserState {
        let current: Int
        let currentTokenStorage: Token
        let nextTokenStorage: Token
        let macroBodyDepth: Int
        let callBlockDepth: Int
    }
    
    // MARK: - Initialization
    
    /// Creates a new parser for the given tokens
    ///
    /// The parser consumes the token array, taking ownership to avoid
    /// unnecessary copies during parsing.
    ///
    /// - Parameter tokens: The array of tokens to parse
    ///
    /// - Note: The `consuming` parameter indicates that the parser takes
    ///   ownership of the tokens array, following Swift's ownership model.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let lexer = Lexer(template)
    /// let tokens = try lexer.tokenize()
    /// let parser = Parser(consuming: tokens)
    /// ```
    public init(
        consuming tokens: [Token],
        source: String? = nil,
        customTags: [CustomTagDescriptor] = []
    ) {
        self.tokens = tokens
        self.source = source
        if customTags.isEmpty {
            self.customTagDescriptors = [:]
        } else {
            self.customTagDescriptors = Dictionary(
                uniqueKeysWithValues: customTags.map { ($0.name, $0) }
            )
        }
        self.currentTokenStorage = tokens.first ?? Self.eofToken
        self.nextTokenStorage = tokens.count > 1 ? tokens[1] : Self.eofToken
    }
    
    // MARK: - Public Interface
    
    /// Parses the tokens into an Abstract Syntax Tree
    ///
    /// This method performs a complete syntactic analysis of the token stream,
    /// building a hierarchical tree structure that represents the template's logic
    /// and can be efficiently rendered.
    ///
    /// - Returns: The root `ASTNode` representing the entire template
    /// - Throws: `ParserError` if the tokens contain invalid syntax
    ///
    /// ## Example
    ///
    /// ```swift
    /// let parser = Parser(consuming: tokens)
    /// do {
    ///     let ast = try parser.parse()
    ///     // AST is ready for rendering
    /// } catch let error as ParserError {
    ///     print("Parsing failed: \(error)")
    /// }
    /// ```
    ///
    /// ## AST Structure
    ///
    /// The returned AST has a `.template` node as its root, containing
    /// all child nodes in order:
    ///
    /// ```swift
    /// // "Hello {{ name }}!" produces:
    /// ASTNode.template([
    ///     .text(InlineString("Hello ")),
    ///     .output(Expression.variable(InlineString("name"))),
    ///     .text(InlineString("!"))
    /// ])
    /// ```
    ///
    /// ## Error Cases
    ///
    /// Common parsing errors:
    /// - `ParserError.unexpectedToken`: Token appeared in wrong context
    /// - `ParserError.expectedEndTag`: Missing closing tag
    /// - `ParserError.unmatchedTag`: Mismatched opening/closing tags
    /// - `ParserError.invalidExpression`: Malformed expression syntax
    public func parse() throws(ParserError) ->ASTNode {
        current = 0
        refreshLookahead()
        var nodes: [ASTNode] = []
        nodes.reserveCapacity(max(4, tokens.count / 3))
        
        while !isAtEnd {
            let node = try parseNode()
            nodes.append(node)
        }
        
        return .template(nodes)
    }
    
    // MARK: - Node Parsing
    
    /// Parses the next node from the current position
    @inline(__always)
    private func parseNode() throws(ParserError) ->ASTNode {
        switch currentTokenStorage.type {
        case .text(let content):
            advance()
            return .text(content)
            
        case .variableStart:
            return try parseVariable()
            
        case .tagStart:
            return try parseTag()
            
        default:
            throw ParserError.unexpectedToken(currentToken)
        }
    }
    
    /// Parses a variable expression: {{ ... }}
    @inline(__always)
    private func parseVariable() throws(ParserError) ->ASTNode {
        advance() // consume {{
        
        let expression = try parseExpression()
        
        guard currentTokenStorage.type == .variableEnd else {
            throw ParserError.unexpectedToken(currentToken)
        }
        advance() // consume }}
        
        return .output(expression)
    }
    
    /// Parses a tag: {% ... %}
    @inline(__always)
    private func parseTag() throws(ParserError) ->ASTNode {
        advance() // consume {%

        let tagToken = currentTokenStorage
        advance()

        switch tagToken.type {
        case .if:
            return try parseIfTag()
        case .unless:
            return try parseUnlessTag()
        case .case:
            return try parseCaseTag()
        case .for:
            return try parseForTag()
        case .tablerow:
            return try parseTableRowTag()
        case .assign:
            return try parseAssignTag()
        case .capture:
            return try parseCaptureTag()
        case .macro:
            return try parseMacroTag()
        case .import:
            return try parseImportTag()
        case .from:
            return try parseFromImportTag()
        case .input:
            return try parseInputTag()
        case .call:
            return try parseCallTag()
        case .increment:
            return try parseIncrementTag()
        case .decrement:
            return try parseDecrementTag()
        case .break:
            return try parseBreakTag()
        case .continue:
            return try parseContinueTag()
        case .echo:
            return try parseEchoTag()
        case .debug:
            return try parseDebugTag()
        case .comment:
            return try parseCommentTag()
        case .raw:
            return try parseRawTag()
        case .liquid:
            return try parseLiquidTag()
        case .pipeline:
            return try parsePipelineTag()
        case .cycle:
            return try parseCycleTag()
        case .include:
            return try parseIncludeTag()
        case .render:
            return try parseRenderTag()
        case .render_block:
            return try parseRenderBlockTag()
        case .block:
            return try parseBlockTag()
        case .identifier(let name):
            return try parseIdentifierTag(named: name)
        default:
            throw ParserError.unexpectedToken(tagToken)
        }
    }

    @inline(__always)
    private func parseIdentifierTag(named name: InlineString) throws(ParserError) ->ASTNode {
        if name.equals("if") {
            return try parseIfTag()
        }
        if name.equals("unless") {
            return try parseUnlessTag()
        }
        if name.equals("case") {
            return try parseCaseTag()
        }
        if name.equals("for") {
            return try parseForTag()
        }
        if name.equals("tablerow") {
            return try parseTableRowTag()
        }
        if name.equals("assign") {
            return try parseAssignTag()
        }
        if name.equals("capture") {
            return try parseCaptureTag()
        }
        if name.equals("macro") {
            return try parseMacroTag()
        }
        if name.equals("import") {
            return try parseImportTag()
        }
        if name.equals("from") {
            return try parseFromImportTag()
        }
        if name.equals("input") {
            return try parseInputTag()
        }
        if name.equals("call") {
            return try parseCallTag()
        }
        if name.equals("slot") {
            return try parseSlotTag()
        }
        if name.equals("fill") {
            return try parseFillTag()
        }
        if name.equals("increment") {
            return try parseIncrementTag()
        }
        if name.equals("decrement") {
            return try parseDecrementTag()
        }
        if name.equals("break") {
            return try parseBreakTag()
        }
        if name.equals("continue") {
            return try parseContinueTag()
        }
        if name.equals("echo") {
            return try parseEchoTag()
        }
        if name.equals("debug") {
            return try parseDebugTag()
        }
        if name.equals("comment") {
            return try parseCommentTag()
        }
        if name.equals("raw") {
            return try parseRawTag()
        }
        if name.equals("liquid") {
            return try parseLiquidTag()
        }
        if name.equals("pipeline") {
            return try parsePipelineTag()
        }
        if name.equals("cycle") {
            return try parseCycleTag()
        }
        if name.equals("include") {
            return try parseIncludeTag()
        }
        if name.equals("render") {
            return try parseRenderTag()
        }
        if name.equals("render_block") {
            return try parseRenderBlockTag()
        }
        if name.equals("block") {
            return try parseBlockTag()
        }
        if name.equals("extends") {
            return try parseExtendsTag()
        }
        if let descriptor = customTagDescriptors[name.string] {
            return try parseCustomTag(named: name, descriptor: descriptor)
        }
        throw ParserError.unknownTag(name.string)
    }

    private func parseCustomTag(named name: InlineString, descriptor: CustomTagDescriptor) throws(ParserError) ->ASTNode {
        let markupStart = current
        while currentToken.type != .tagEnd && !isAtEnd {
            advance()
        }

        let markup = InlineString(sourceString(forTokenRange: markupStart..<current).trimmingCharacters(in: .whitespacesAndNewlines))
        try consumeTagEnd()

        guard descriptor.requiresEndTag else {
            return .registeredCustomTag(name: name, markup: markup, body: nil)
        }

        let bodyStart = current
        var bodyNodes = makeNodeBuffer()
        while !isAtEnd && !currentTagMatchesIdentifier(descriptor.endTagName) {
            bodyNodes.append(try parseNode())
        }

        guard currentTagMatchesIdentifier(descriptor.endTagName) else {
            throw ParserError.unclosedTag(name.string)
        }

        let bodySource = InlineString(sourceString(forTokenRange: bodyStart..<current))
        advance() // consume {%
        try consumeTagIdentifier(descriptor.endTagName)
        try consumeTagEnd()

        return .registeredCustomTag(
            name: name,
            markup: markup,
            body: RuntimeCustomTagBody(source: bodySource, nodes: bodyNodes)
        )
    }
    
    // MARK: - Simple Tag Parsing
    
    /// Parses an assign tag: {% assign var = value %}
    private func parseAssignTag() throws(ParserError) ->ASTNode {
        let variableName: InlineString
        if case .identifier(let name) = currentToken.type {
            // Trailing '?' is not allowed in assignment targets (Shopify behavior)
            if name.string.hasSuffix("?") {
                throw ParserError.unexpectedToken(currentToken)
            }
            variableName = name
        } else if case .number(let num, _) = currentToken.type {
            // Digit-only variable names: {% assign 123 = 'hello' %}
            variableName = InlineString(String(Int(num)))
        } else {
            throw ParserError.unexpectedToken(currentToken)
        }
        advance()
        
        guard currentToken.type == .equals else {
            throw ParserError.unexpectedToken(currentToken)
        }
        advance()
        
        let value = try parseExpression()
        try consumeTagEnd()
        
        return .assign(variable: variableName, value: value)
    }
    
    /// Parses echo tag: {% echo expression %}
    private func parseEchoTag() throws(ParserError) ->ASTNode {
        // Empty echo: {% echo %} outputs nothing
        if currentToken.type == .tagEnd {
            try consumeTagEnd()
            return .echo(expression: .literal(.string(InlineString(""))))
        }
        let expression = try parseExpression()
        try consumeTagEnd()

        return .echo(expression: expression)
    }
    
    /// Parses a comment tag: {% comment %}...{% endcomment %}
    private func parseCommentTag() throws(ParserError) ->ASTNode {
        try consumeTagEnd()

        // Track nesting depth for nested comment blocks
        var depth = 1
        while !isAtEnd && depth > 0 {
            if currentTagMatches(.comment, identifier: "comment") {
                // Nested comment opening
                advance() // consume {%
                advance() // consume 'comment'
                if currentToken.type == .tagEnd { advance() } // consume %}
                depth += 1
            } else if currentTagMatches(.endcomment, identifier: "endcomment") {
                depth -= 1
                if depth == 0 {
                    break // Don't consume — let the code below do it
                }
                advance() // consume {%
                advance() // consume 'endcomment'
                if currentToken.type == .tagEnd { advance() } // consume %}
            } else {
                advance()
            }
        }

        // Consume final endcomment
        guard currentTagMatches(.endcomment, identifier: "endcomment") else {
            throw ParserError.unexpectedToken(currentToken)
        }
        advance() // consume {%
        try consumeTagKeyword(.endcomment, identifier: "endcomment")
        try consumeTagEnd()

        return .comment
    }

    /// Parses a macro definition tag: {% macro card(title, subtitle: nil) %}...{% endmacro %}
    private func parseMacroTag() throws(ParserError) ->ASTNode {
        guard case .identifier(let macroName) = currentToken.type else {
            throw ParserError.expectedIdentifier
        }
        advance()

        guard currentToken.type == .leftParen else {
            throw ParserError.expectedToken(.leftParen, got: currentToken.type)
        }
        advance()

        let parameters = try parseMacroParameters()

        guard currentToken.type == .rightParen else {
            throw ParserError.expectedToken(.rightParen, got: currentToken.type)
        }
        advance()

        try consumeTagEnd()

        macroBodyDepth += 1
        defer { macroBodyDepth -= 1 }

        var body = makeNodeBuffer()
        while !isAtEnd && !currentTagMatches(.endmacro, identifier: "endmacro") {
            body.append(try parseNode())
        }

        guard currentTagMatches(.endmacro, identifier: "endmacro") else {
            throw ParserError.unclosedTag("macro")
        }
        advance()
        try consumeTagKeyword(.endmacro, identifier: "endmacro")
        try consumeTagEnd()

        return .macro(
            signature: MacroSignatureNode(name: macroName, parameters: parameters),
            body: body
        )
    }

    /// Parses {% import "macros.liquid" as ui %}
    private func parseImportTag() throws(ParserError) ->ASTNode {
        let templateExpr = try parsePrimaryExpression()
        guard case .literal(.string(let templateName)) = templateExpr else {
            throw ParserError.expectedString
        }

        guard case .identifier(let asKeyword) = currentToken.type,
              asKeyword.equals("as") else {
            throw ParserError.missingRequiredParameter("as")
        }
        advance()

        guard case .identifier(let namespace) = currentToken.type else {
            throw ParserError.expectedIdentifier
        }
        advance()

        try consumeTagEnd()
        return .macroImport(MacroImportNode(template: templateName, namespace: namespace))
    }

    /// Parses {% from "macros.liquid" import card, badge %}
    private func parseFromImportTag() throws(ParserError) ->ASTNode {
        let templateExpr = try parsePrimaryExpression()
        guard case .literal(.string(let templateName)) = templateExpr else {
            throw ParserError.expectedString
        }

        try consumeTagKeyword(.import, identifier: "import")

        var importedMacros: [InlineString] = []
        importedMacros.reserveCapacity(2)

        while currentToken.type != .tagEnd {
            guard case .identifier(let macroName) = currentToken.type else {
                throw ParserError.expectedIdentifier
            }
            importedMacros.append(macroName)
            advance()

            guard currentToken.type == .comma || currentToken.type == .tagEnd else {
                throw ParserError.unexpectedToken(currentToken)
            }
            if currentToken.type == .comma {
                advance()
            }
        }

        try consumeTagEnd()
        return .macroImport(
            MacroImportNode(
                template: templateName,
                namespace: nil,
                importedMacros: importedMacros
            )
        )
    }

    /// Parses {% input user: object %} and {% input theme: string = "light" %}
    private func parseInputTag() throws(ParserError) ->ASTNode {
        let inputPath = try parseInputPath()

        guard currentToken.type == .colon else {
            throw ParserError.expectedToken(.colon, got: currentToken.type)
        }
        advance()

        let inputType = try parseInputType()
        let strict: Bool
        if case .identifier(let modifier) = currentToken.type,
           modifier.string == "strict" {
            guard inputType == .object else {
                throw ParserError.unsupportedFeature(
                    "strict input contracts currently require object-typed paths"
                )
            }
            strict = true
            advance()
        } else {
            strict = false
        }

        let defaultValue: LiquidCore.Expression?
        if currentToken.type == .equals {
            advance()
            defaultValue = try parseExpression()
        } else {
            defaultValue = nil
        }

        try consumeTagEnd()
        return .input(
            InputContractNode(
                path: inputPath,
                type: inputType,
                strict: strict,
                defaultValue: defaultValue
            )
        )
    }

    /// Parses tag-driven macro calls in both inline and block form.
    private func parseCallTag() throws(ParserError) ->ASTNode {
        let callName = try parseQualifiedIdentifier()

        guard currentToken.type == .leftParen else {
            throw ParserError.expectedToken(.leftParen, got: currentToken.type)
        }
        advance()

        let arguments = try parseCallArguments()

        guard currentToken.type == .rightParen else {
            throw ParserError.expectedToken(.rightParen, got: currentToken.type)
        }
        advance()

        try consumeTagEnd()
        let inlineCall = ASTNode.call(name: callName, arguments: arguments, body: nil)
        let savedState = snapshotState()

        callBlockDepth += 1
        do {
            var body = makeNodeBuffer()
            while !isAtEnd && !currentTagMatchesIdentifier("endcall") {
                body.append(try parseNode())
            }

            guard currentTagMatchesIdentifier("endcall") else {
                restoreState(savedState)
                return inlineCall
            }

            advance()
            try consumeTagIdentifier("endcall")
            try consumeTagEnd()
            callBlockDepth = savedState.callBlockDepth

            return .call(name: callName, arguments: arguments, body: body)
        } catch let error {
            if shouldFallbackToInlineCall(from: error) {
                restoreState(savedState)
                return inlineCall
            }
            callBlockDepth = savedState.callBlockDepth
            throw error
        }
    }

    /// Parses {% slot footer %}...{% endslot %} inside macro bodies.
    private func parseSlotTag() throws(ParserError) ->ASTNode {
        guard macroBodyDepth > 0 else {
            throw ParserError.unsupportedFeature("slot tags are only valid inside macro bodies")
        }

        guard case .identifier(let slotName) = currentToken.type else {
            throw ParserError.expectedIdentifier
        }
        advance()
        try consumeTagEnd()

        var body = makeNodeBuffer()
        while !isAtEnd && !currentTagMatchesIdentifier("endslot") {
            body.append(try parseNode())
        }

        guard currentTagMatchesIdentifier("endslot") else {
            throw ParserError.unclosedTag("slot")
        }
        advance()
        try consumeTagIdentifier("endslot")
        try consumeTagEnd()

        return .slot(name: slotName, body: body)
    }

    /// Parses {% fill footer %}...{% endfill %} inside block-form macro calls.
    private func parseFillTag() throws(ParserError) ->ASTNode {
        guard callBlockDepth > 0 else {
            throw ParserError.unsupportedFeature("fill tags are only valid inside block-form call bodies")
        }

        guard case .identifier(let fillName) = currentToken.type else {
            throw ParserError.expectedIdentifier
        }
        if fillName.equals("default") {
            throw ParserError.invalidParameterValue("fill name", expected: "named slot identifier other than 'default'")
        }
        advance()
        try consumeTagEnd()

        var body = makeNodeBuffer()
        while !isAtEnd && !currentTagMatchesIdentifier("endfill") {
            body.append(try parseNode())
        }

        guard currentTagMatchesIdentifier("endfill") else {
            throw ParserError.unclosedTag("fill")
        }
        advance()
        try consumeTagIdentifier("endfill")
        try consumeTagEnd()

        return .fill(name: fillName, body: body)
    }
    
    // MARK: - Control Flow Tag Parsing
    
    /// Parses an if tag with complex conditions: {% if condition %}...{% elsif %}...{% else %}...{% endif %}
    private func parseIfTag() throws(ParserError) ->ASTNode {
        let condition = try parseComplexExpression()
        try consumeTagEnd()
        
        var thenNodes = makeNodeBuffer()
        var elsifBranches: [(LiquidCore.Expression, [ASTNode])] = []
        var elseNodes: [ASTNode]? = nil
        
        // Parse then branch
        while !isAtEnd && !isElsifOrElseOrEndif() {
            thenNodes.append(try parseNode())
        }
        
        // Parse elsif branches
        while !isAtEnd && currentTagMatches(.elsif, identifier: "elsif") {
            advance() // consume {%
            try consumeTagKeyword(.elsif, identifier: "elsif")
            
            let elsifCondition = try parseComplexExpression()
            try consumeTagEnd()
            
            var elsifNodes = makeNodeBuffer()
            while !isAtEnd && !isElsifOrElseOrEndif() {
                elsifNodes.append(try parseNode())
            }
            
            elsifBranches.append((elsifCondition, elsifNodes))
        }
        
        // Parse else branch if present
        if !isAtEnd && currentTagMatches(.else, identifier: "else") {
            advance() // consume {%
            try consumeTagKeyword(.else, identifier: "else")
            // Shopify Liquid ignores expressions on else tags (e.g., {% else nonsense %})
            while currentToken.type != .tagEnd && !isAtEnd { advance() }
            try consumeTagEnd()

            var elseNodesList = makeNodeBuffer()
            while !isAtEnd && !isElsifOrElseOrEndif() {
                elseNodesList.append(try parseNode())
            }
            elseNodes = elseNodesList
        }

        // Shopify Liquid silently ignores extra elsif/else blocks after the first else
        while !isAtEnd && (currentTagMatches(.elsif, identifier: "elsif") || currentTagMatches(.else, identifier: "else")) {
            advance() // consume {%
            advance() // consume elsif/else keyword
            while currentToken.type != .tagEnd && !isAtEnd { advance() }
            try consumeTagEnd()
            // Skip body nodes until next elsif/else/endif
            while !isAtEnd && !isElsifOrElseOrEndif() {
                _ = try parseNode()
            }
        }

        // Consume endif
        guard currentTagMatches(.endif, identifier: "endif") else {
            throw ParserError.unexpectedToken(currentToken) // Missing endif
        }
        advance() // consume {%
        try consumeTagKeyword(.endif, identifier: "endif")
        try consumeTagEnd()
        
        return .if(
            condition: condition,
            then: thenNodes,
            elsif: elsifBranches,
            else: elseNodes
        )
    }
    
    /// Parses an unless tag: {% unless condition %}...{% else %}...{% endunless %}
    private func parseUnlessTag() throws(ParserError) ->ASTNode {
        let condition = try parseComplexExpression()
        try consumeTagEnd()

        var thenNodes = makeNodeBuffer()
        var elsifBranches: [(LiquidCore.Expression, [ASTNode])] = []
        var elseNodes: [ASTNode]? = nil

        // Parse then branch (unless body)
        while !isAtEnd && !isElseOrEndunless() {
            thenNodes.append(try parseNode())
        }

        // Parse elsif branches
        while !isAtEnd && currentTagMatches(.elsif, identifier: "elsif") {
            advance() // consume {%
            try consumeTagKeyword(.elsif, identifier: "elsif")
            let elsifCondition = try parseComplexExpression()
            try consumeTagEnd()

            var elsifNodes = makeNodeBuffer()
            while !isAtEnd && !isElseOrEndunless() {
                elsifNodes.append(try parseNode())
            }
            elsifBranches.append((elsifCondition, elsifNodes))
        }

        // Parse else branch if present
        if !isAtEnd && currentTagMatches(.else, identifier: "else") {
            advance() // consume {%
            try consumeTagKeyword(.else, identifier: "else")
            while currentToken.type != .tagEnd && !isAtEnd { advance() }
            try consumeTagEnd()

            var elseNodesList = makeNodeBuffer()
            while !isAtEnd && !isElseOrEndunless() {
                elseNodesList.append(try parseNode())
            }
            elseNodes = elseNodesList
        }

        // Silently ignore extra elsif/else blocks after the first else
        while !isAtEnd && (currentTagMatches(.elsif, identifier: "elsif") || currentTagMatches(.else, identifier: "else")) {
            advance()
            advance()
            while currentToken.type != .tagEnd && !isAtEnd { advance() }
            try consumeTagEnd()
            while !isAtEnd && !isElseOrEndunless() {
                _ = try parseNode()
            }
        }

        // Consume endunless
        guard currentTagMatches(.endunless, identifier: "endunless") else {
            throw ParserError.unexpectedToken(currentToken)
        }
        advance()
        try consumeTagKeyword(.endunless, identifier: "endunless")
        try consumeTagEnd()

        // If there are elsif branches, convert to if(NOT condition) structure
        if !elsifBranches.isEmpty {
            return .if(
                condition: .unary(op: .not, expr: condition),
                then: thenNodes,
                elsif: elsifBranches,
                else: elseNodes
            )
        }

        return .unless(
            condition: condition,
            then: thenNodes,
            else: elseNodes
        )
    }
    
    // MARK: - Expression Parsing
    
    /// Parses a complex expression with logical operators (and, or)
    /// Shopify Liquid: logical operators are RIGHT-associative
    /// `true and false and false or true` → `true and (false and (false or true))`
    private func parseComplexExpression() throws(ParserError) ->LiquidCore.Expression {
        var firstExpr = try parseExpression()
        firstExpr = try parseComparisonContinuation(startingWith: firstExpr)

        // Collect all expressions and operators
        var expressions: [LiquidCore.Expression] = [firstExpr]
        var operators: [BinaryOp] = []

        while currentToken.type == .and || currentToken.type == .or {
            let op: BinaryOp = currentToken.type == .and ? .and : .or
            advance()
            operators.append(op)

            var right = try parseExpression()
            right = try parseComparisonContinuation(startingWith: right)
            expressions.append(right)
        }

        // Build tree right-to-left for right-associativity
        guard !operators.isEmpty else { return firstExpr }
        var result = expressions.last!
        for i in stride(from: operators.count - 1, through: 0, by: -1) {
            result = .binary(left: expressions[i], op: operators[i], right: result)
        }

        return result
    }

    /// Parses an optional comparison continuation after a base expression.
    @inline(__always)
    private func parseComparisonContinuation(startingWith left: LiquidCore.Expression) throws(ParserError) ->LiquidCore.Expression {
        // Check for comparison operators
        let op: BinaryOp?
        switch currentToken.type {
        case .equals:
            op = .equals
        case .notEquals:
            op = .notEquals
        case .lessThan:
            op = .lessThan
        case .greaterThan:
            op = .greaterThan
        case .lessThanOrEqual:
            op = .lessThanOrEqual
        case .greaterThanOrEqual:
            op = .greaterThanOrEqual
        case .contains:
            op = .contains
        default:
            op = nil
        }
        
        if let op = op {
            advance() // consume operator
            let right = try parseExpression()
            return .binary(left: left, op: op, right: right)
        }
        
        return left
    }
    
    /// Parses an expression (with filters)
    @inline(__always)
    private func parseExpression() throws(ParserError) ->LiquidCore.Expression {
        let expr = try parsePrimaryExpression()

        guard currentTokenStorage.type == .filter else {
            return expr
        }

        advance() // consume |

        guard case .identifier(let firstFilterName) = currentTokenStorage.type else {
            throw ParserError.unexpectedToken(currentToken)
        }
        advance()

        var firstNamedArgs: [String: LiquidCore.Expression] = [:]
        let firstArguments = try parseFilterArguments(namedArguments: &firstNamedArgs)
        let firstFilter = Filter(
            name: firstFilterName,
            arguments: firstArguments,
            namedArguments: firstNamedArgs
        )

        guard currentTokenStorage.type == .filter else {
            return .filtered(expr: expr, filters: [firstFilter])
        }

        var allFilters = makeFilterBuffer()
        allFilters.append(firstFilter)

        repeat {
            advance() // consume |

            guard case .identifier(let filterName) = currentTokenStorage.type else {
                throw ParserError.unexpectedToken(currentToken)
            }
            advance()

            var namedArgs: [String: LiquidCore.Expression] = [:]
            let arguments = try parseFilterArguments(namedArguments: &namedArgs)
            allFilters.append(
                Filter(
                    name: filterName,
                    arguments: arguments,
                    namedArguments: namedArgs
                )
            )
        } while currentTokenStorage.type == .filter

        return .filtered(expr: expr, filters: allFilters)
    }

    @inline(__always)
    private func parseFilterArguments(namedArguments: inout [String: LiquidCore.Expression]) throws(ParserError) ->[LiquidCore.Expression] {
        guard currentToken.type == .colon else {
            return []
        }

        advance() // consume :

        // Check if this is a named argument: identifier followed by colon
        if case .identifier(let argName) = currentToken.type,
           nextTokenStorage.type == .colon {
            // Named argument
            advance() // consume identifier
            advance() // consume :
            namedArguments[argName.string] = try parsePrimaryExpression()

            var positionalArgs: [LiquidCore.Expression] = []
            while currentToken.type == .comma {
                advance() // consume ,
                if case .identifier(let nextArgName) = currentToken.type,
                   nextTokenStorage.type == .colon {
                    advance() // consume identifier
                    advance() // consume :
                    namedArguments[nextArgName.string] = try parsePrimaryExpression()
                } else {
                    // Positional argument after named arguments
                    positionalArgs.append(try parsePrimaryExpression())
                }
            }
            return positionalArgs
        }

        let firstArgument = try parsePrimaryExpression()

        guard currentToken.type == .comma else {
            return [firstArgument]
        }

        var arguments = makeExpressionBuffer()
        arguments.append(firstArgument)

        repeat {
            advance() // consume ,
            // Check for named arguments after positional ones
            if case .identifier(let argName) = currentToken.type,
               nextTokenStorage.type == .colon {
                advance() // consume identifier
                advance() // consume :
                namedArguments[argName.string] = try parsePrimaryExpression()
                // Continue to consume more named args
                while currentToken.type == .comma {
                    advance()
                    if case .identifier(let nextArgName) = currentToken.type,
                       nextTokenStorage.type == .colon {
                        advance()
                        advance()
                        namedArguments[nextArgName.string] = try parsePrimaryExpression()
                    } else {
                        arguments.append(try parsePrimaryExpression())
                        break
                    }
                }
                break
            }
            arguments.append(try parsePrimaryExpression())
        } while currentToken.type == .comma

        return arguments
    }
    
    /// Parses a primary expression (no filters)
    @inline(__always)
    private func parsePrimaryExpression() throws(ParserError) ->LiquidCore.Expression {
        switch currentToken.type {
        case .empty:
            // Shopify Liquid: 'empty' evaluates to "" in expression context
            advance()
            return .literal(.string(InlineString("")))

        case .identifier(let name):
            advance()

            if let literal = literalExpression(for: name) {
                return literal
            }

            let components = try collectQualifiedIdentifierComponents(startingWith: name)

            if currentTokenStorage.type == .leftParen {
                advance()
                let arguments = try parseCallArguments()
                guard currentToken.type == .rightParen else {
                    throw ParserError.expectedToken(.rightParen, got: currentToken.type)
                }
                advance()
                return .call(
                    name: InlineString(components.map(\.string).joined(separator: ".")),
                    arguments: arguments
                )
            }

            var expr: LiquidCore.Expression = .variable(name)
            for property in components.dropFirst() {
                expr = .access(expr: expr, key: .literal(.string(property)))
            }

            // Handle bracket and dot access chains: items[0], items["key"].prop, items[0][1]
            var hasMoreAccess = true
            while hasMoreAccess {
                hasMoreAccess = false
                while currentTokenStorage.type == .leftBracket {
                    advance() // consume [
                    let keyExpr = try parsePrimaryExpression()
                    guard currentToken.type == .rightBracket else {
                        throw ParserError.expectedToken(.rightBracket, got: currentToken.type)
                    }
                    advance() // consume ]
                    expr = .access(expr: expr, key: keyExpr)
                    hasMoreAccess = true
                }
                // Handle dot access after brackets: items[0].title
                while currentTokenStorage.type == .dot {
                    guard case .identifier(let prop) = nextTokenStorage.type else { break }
                    advance() // consume .
                    advance() // consume identifier
                    expr = .access(expr: expr, key: .literal(.string(prop)))
                    hasMoreAccess = true
                }
            }

            return expr
            
        case .string(let value):
            advance()
            return .literal(.string(value))
            
        case .number(let value, let isFloat):
            advance()

            // Check for range operator
            if currentToken.type == .range {
                advance() // consume ..

                guard case .number(let endValue, let endIsFloat) = currentToken.type else {
                    throw ParserError.unexpectedToken(currentToken)
                }
                advance()

                return .range(start: .literal(.number(value, isFloat: isFloat)), end: .literal(.number(endValue, isFloat: endIsFloat)))
            }

            return .literal(.number(value, isFloat: isFloat))
            
        case .leftParen:
            advance() // consume (

            // Parse range inside parentheses: (expr..expr)
            // Start can be a number, identifier, or negative number
            let startExpr: LiquidCore.Expression
            if case .number(let startValue, let startIsFloat) = currentToken.type {
                advance()
                startExpr = .literal(.number(startValue, isFloat: startIsFloat))
            } else if case .identifier(let name) = currentToken.type {
                advance()
                var expr: LiquidCore.Expression = .variable(name)
                // Handle dotted access like product.count
                while currentToken.type == .dot {
                    advance() // consume .
                    guard case .identifier(let prop) = currentToken.type else {
                        throw ParserError.unexpectedToken(currentToken)
                    }
                    advance()
                    expr = .access(expr: expr, key: .literal(.string(prop)))
                }
                startExpr = expr
            } else {
                throw ParserError.unexpectedToken(currentToken)
            }

            guard currentToken.type == .range else {
                throw ParserError.unexpectedToken(currentToken)
            }
            advance() // consume ..

            let endExpr: LiquidCore.Expression
            if case .number(let endValue, let endIsFloat) = currentToken.type {
                advance()
                endExpr = .literal(.number(endValue, isFloat: endIsFloat))
            } else if case .identifier(let name) = currentToken.type {
                advance()
                var expr: LiquidCore.Expression = .variable(name)
                while currentToken.type == .dot {
                    advance()
                    guard case .identifier(let prop) = currentToken.type else {
                        throw ParserError.unexpectedToken(currentToken)
                    }
                    advance()
                    expr = .access(expr: expr, key: .literal(.string(prop)))
                }
                endExpr = expr
            } else {
                throw ParserError.unexpectedToken(currentToken)
            }

            guard currentToken.type == .rightParen else {
                throw ParserError.unexpectedToken(currentToken)
            }
            advance() // consume )

            return .range(start: startExpr, end: endExpr)
            
        case .leftBracket:
            // Top-level bracket access: {{ [something] }} or {{ ["key"] }}
            // This is an indirect variable lookup: look up the bracket contents,
            // then use the result to look up in the root context
            advance() // consume [
            let keyExpr = try parsePrimaryExpression()
            guard currentToken.type == .rightBracket else {
                throw ParserError.expectedToken(.rightBracket, got: currentToken.type)
            }
            advance() // consume ]

            // Build as access on a special "root" sentinel,
            // but since Liquid treats [x] as context[context[x]],
            // we model it as a variable access with the key expression
            var expr: LiquidCore.Expression = .access(expr: .variable(InlineString("")), key: keyExpr)

            // Handle chained bracket/dot access after: [x][0], [x].prop
            while currentTokenStorage.type == .leftBracket {
                advance()
                let nextKey = try parsePrimaryExpression()
                guard currentToken.type == .rightBracket else {
                    throw ParserError.expectedToken(.rightBracket, got: currentToken.type)
                }
                advance()
                expr = .access(expr: expr, key: nextKey)
            }
            while currentTokenStorage.type == .dot {
                advance()
                guard case .identifier(let prop) = currentToken.type else {
                    throw ParserError.unexpectedToken(currentToken)
                }
                advance()
                expr = .access(expr: expr, key: .literal(.string(prop)))
            }
            return expr

        // Allow reserved words as variable names in expression context
        case .include, .for, .if, .elsif, .else, .unless, .case, .when,
             .comment, .raw, .capture, .tablerow, .cycle:
            let name = InlineString(currentToken.type.keywordString ?? "")
            advance()
            var expr: LiquidCore.Expression = .variable(name)
            // Handle dot access chains: include.menu
            var hasMoreAccess = true
            while hasMoreAccess {
                hasMoreAccess = false
                while currentTokenStorage.type == .leftBracket {
                    advance()
                    let keyExpr = try parsePrimaryExpression()
                    guard currentToken.type == .rightBracket else {
                        throw ParserError.expectedToken(.rightBracket, got: currentToken.type)
                    }
                    advance()
                    expr = .access(expr: expr, key: keyExpr)
                    hasMoreAccess = true
                }
                while currentTokenStorage.type == .dot {
                    advance()
                    guard case .identifier(let prop) = currentToken.type else {
                        throw ParserError.unexpectedToken(currentToken)
                    }
                    advance()
                    expr = .access(expr: expr, key: .literal(.string(prop)))
                    hasMoreAccess = true
                }
            }
            return expr

        default:
            throw ParserError.unexpectedToken(currentToken)
        }
    }

    private func collectQualifiedIdentifierComponents(
        startingWith first: InlineString
    ) throws(ParserError) ->[InlineString] {
        var components = [first]
        components.reserveCapacity(2)

        while currentTokenStorage.type == .dot {
            guard case .identifier(let property) = nextTokenStorage.type else {
                throw ParserError.unexpectedToken(nextTokenStorage)
            }
            advance()
            advance()
            components.append(property)
        }

        return components
    }

    private func parseQualifiedIdentifier() throws(ParserError) ->InlineString {
        guard case .identifier(let first) = currentToken.type else {
            throw ParserError.expectedIdentifier
        }
        advance()
        let components = try collectQualifiedIdentifierComponents(startingWith: first)
        return InlineString(components.map(\.string).joined(separator: "."))
    }

    private func parseCallArguments() throws(ParserError) ->[CallArgument] {
        guard currentToken.type != .rightParen else {
            return []
        }

        var arguments: [CallArgument] = []
        arguments.reserveCapacity(2)
        var seenLabels = Set<String>()

        while currentToken.type != .rightParen {
            if case .identifier(let label) = currentToken.type,
               nextTokenStorage.type == .colon {
                if !seenLabels.insert(label.string).inserted {
                    throw ParserError.duplicateParameter(label.string)
                }
                advance()
                advance()
                arguments.append(CallArgument(label: label, value: try parseExpression()))
            } else {
                arguments.append(CallArgument(value: try parseExpression()))
            }

            guard currentToken.type == .comma || currentToken.type == .rightParen else {
                throw ParserError.unexpectedToken(currentToken)
            }

            if currentToken.type == .comma {
                advance()
            }
        }

        return arguments
    }

    private func parseMacroParameters() throws(ParserError) ->[MacroParameterNode] {
        guard currentToken.type != .rightParen else {
            return []
        }

        var parameters: [MacroParameterNode] = []
        parameters.reserveCapacity(2)
        var seenNames = Set<String>()

        while currentToken.type != .rightParen {
            guard case .identifier(let parameterName) = currentToken.type else {
                throw ParserError.expectedIdentifier
            }
            if !seenNames.insert(parameterName.string).inserted {
                throw ParserError.duplicateParameter(parameterName.string)
            }
            advance()

            let defaultValue: LiquidCore.Expression?
            if currentToken.type == .colon {
                advance()
                defaultValue = try parseExpression()
            } else {
                defaultValue = nil
            }

            parameters.append(MacroParameterNode(name: parameterName, defaultValue: defaultValue))

            guard currentToken.type == .comma || currentToken.type == .rightParen else {
                throw ParserError.unexpectedToken(currentToken)
            }
            if currentToken.type == .comma {
                advance()
            }
        }

        return parameters
    }

    private func parseInputType() throws(ParserError) ->InputTypeNode {
        guard case .identifier(let typeName) = currentToken.type else {
            throw ParserError.expectedIdentifier
        }
        advance()

        if typeName.equals("array") {
            guard currentToken.type == .lessThan else {
                throw ParserError.invalidParameterValue("input type", expected: "array<element_type>")
            }
            advance()
            let elementType = try parseInputType()
            guard currentToken.type == .greaterThan else {
                throw ParserError.expectedToken(.greaterThan, got: currentToken.type)
            }
            advance()
            return .array(elementType)
        }

        if typeName.equals("string") { return .string }
        if typeName.equals("number") { return .number }
        if typeName.equals("boolean") { return .boolean }
        if typeName.equals("object") { return .object }
        if typeName.equals("any") { return .any }

        throw ParserError.invalidParameterValue(
            "input type",
            expected: "string, number, boolean, object, any, or array<...>"
        )
    }

    private func parseInputPath() throws(ParserError) ->[InputPathComponentNode] {
        guard case .identifier(let rootName) = currentToken.type else {
            throw ParserError.expectedIdentifier
        }
        advance()

        var path: [InputPathComponentNode] = [.key(rootName)]

        while true {
            if currentToken.type == .dot {
                advance()
                guard case .identifier(let segmentName) = currentToken.type else {
                    throw ParserError.expectedIdentifier
                }
                path.append(.key(segmentName))
                advance()
                continue
            }

            if currentToken.type == .leftBracket {
                advance()
                guard currentToken.type == .rightBracket else {
                    throw ParserError.expectedToken(.rightBracket, got: currentToken.type)
                }
                advance()
                path.append(.arrayElement)
                continue
            }

            break
        }

        return path
    }

    @inline(__always)
    private func literalExpression(for identifier: InlineString) -> LiquidCore.Expression? {
        switch identifier.utf8Count {
        case 3:
            if identifier.equals("nil") {
                return .literal(.null)
            }

        case 4:
            if identifier.equals("null") {
                return .literal(.null)
            }
            if identifier.equals("true") {
                return .literal(.boolean(true))
            }

        case 5:
            if identifier.equals("false") {
                return .literal(.boolean(false))
            }
            // Shopify Liquid: 'empty' evaluates to "" in expression context
            if identifier.equals("empty") {
                return .literal(.string(InlineString("")))
            }

        default:
            break
        }

        return nil
    }
    
    // MARK: - Utility Methods
    
    /// Current token
    @inline(__always)
    private var currentToken: Token {
        currentTokenStorage
    }
    
    /// Whether we've reached the end of tokens
    @inline(__always)
    private var isAtEnd: Bool {
        return current >= tokens.count
    }
    
    /// Advances to next token
    @discardableResult
    @inline(__always)
    private func advance() -> Token {
        let previous = currentTokenStorage
        if !isAtEnd {
            current += 1
            refreshLookahead()
        }
        return previous
    }

    @inline(__always)
    private func makeNodeBuffer() -> [ASTNode] {
        var nodes: [ASTNode] = []
        nodes.reserveCapacity(min(max(4, max(1, tokens.count - current) / 4), 64))
        return nodes
    }

    @inline(__always)
    private func makeExpressionBuffer(initialCapacity: Int = 2) -> [LiquidCore.Expression] {
        var expressions: [LiquidCore.Expression] = []
        expressions.reserveCapacity(initialCapacity)
        return expressions
    }

    @inline(__always)
    private func makeFilterBuffer(initialCapacity: Int = 2) -> [Filter] {
        var filters: [Filter] = []
        filters.reserveCapacity(initialCapacity)
        return filters
    }

    @inline(__always)
    private func currentTagMatches(_ keyword: TokenType, identifier: StaticString) -> Bool {
        guard currentTokenStorage.type == .tagStart else { return false }
        return tagTokenMatches(nextTokenStorage.type, keyword: keyword, identifier: identifier)
    }

    @inline(__always)
    private func currentTagMatchesAny(
        _ first: (TokenType, StaticString),
        _ second: (TokenType, StaticString)
    ) -> Bool {
        guard currentTokenStorage.type == .tagStart else { return false }
        let tokenType = nextTokenStorage.type
        return tagTokenMatches(tokenType, keyword: first.0, identifier: first.1)
            || tagTokenMatches(tokenType, keyword: second.0, identifier: second.1)
    }

    @inline(__always)
    private func currentTagMatchesAny(
        _ first: (TokenType, StaticString),
        _ second: (TokenType, StaticString),
        _ third: (TokenType, StaticString)
    ) -> Bool {
        guard currentTokenStorage.type == .tagStart else { return false }
        let tokenType = nextTokenStorage.type
        return tagTokenMatches(tokenType, keyword: first.0, identifier: first.1)
            || tagTokenMatches(tokenType, keyword: second.0, identifier: second.1)
            || tagTokenMatches(tokenType, keyword: third.0, identifier: third.1)
    }

    @inline(__always)
    private func currentTagMatchesIdentifier(_ identifier: String) -> Bool {
        guard currentTokenStorage.type == .tagStart else { return false }
        guard case .identifier(let name) = nextTokenStorage.type else { return false }
        return name.string == identifier
    }

    @inline(__always)
    private func tagTokenMatches(_ tokenType: TokenType, keyword: TokenType, identifier: StaticString) -> Bool {
        if tokenType == keyword {
            return true
        }

        if case .identifier(let name) = tokenType {
            return name.equals(identifier)
        }

        return false
    }

    @inline(__always)
    private func consumeTagKeyword(_ keyword: TokenType, identifier: StaticString) throws(ParserError) {
        if currentToken.type == keyword {
            advance()
            return
        }

        if case .identifier(let name) = currentToken.type,
           name.equals(identifier) {
            advance()
            return
        }

        throw ParserError.unexpectedToken(currentToken)
    }

    private func consumeTagIdentifier(_ identifier: String) throws(ParserError) {
        guard case .identifier(let name) = currentToken.type,
              name.string == identifier else {
            throw ParserError.unexpectedToken(currentToken)
        }
        advance()
    }

    private func snapshotState() -> ParserState {
        ParserState(
            current: current,
            currentTokenStorage: currentTokenStorage,
            nextTokenStorage: nextTokenStorage,
            macroBodyDepth: macroBodyDepth,
            callBlockDepth: callBlockDepth
        )
    }

    private func restoreState(_ state: ParserState) {
        current = state.current
        currentTokenStorage = state.currentTokenStorage
        nextTokenStorage = state.nextTokenStorage
        macroBodyDepth = state.macroBodyDepth
        callBlockDepth = state.callBlockDepth
    }

    private func shouldFallbackToInlineCall(from error: ParserError) -> Bool {
        guard case .unexpectedToken(let token) = error else {
            return false
        }

        if token.type == .tagStart {
            return true
        }

        switch token.type {
        case .else, .elsif, .endif, .endunless, .when, .endcase, .empty,
             .endfor, .endtablerow, .endcapture, .endraw, .endblock,
             .endmacro, .endcomment, .endliquid, .endpipeline:
            return true
        case .identifier(let name):
            return name.string == "endcall"
                || name.string == "endslot"
                || name.string == "endfill"
                || name.string == "else"
                || name.string == "elsif"
                || name.string == "when"
                || name.string == "empty"
                || name.string.hasPrefix("end")
        default:
            return false
        }
    }

    /// Peeks at current identifier name
    private func peekIdentifierName() -> InlineString? {
        guard case .identifier(let name) = currentTokenStorage.type else { return nil }
        return name
    }

    @inline(__always)
    private func refreshLookahead() {
        currentTokenStorage = current < tokens.count ? tokens[current] : Self.eofToken
        nextTokenStorage = (current + 1) < tokens.count ? tokens[current + 1] : Self.eofToken
    }
    
    /// Consumes tag end token
    @inline(__always)
    private func consumeTagEnd() throws(ParserError) {
        guard currentTokenStorage.type == .tagEnd else {
            throw ParserError.unexpectedToken(currentToken)
        }
        advance()
    }

    private func sourceString(forTokenRange range: Range<Int>) -> String {
        guard !range.isEmpty else {
            return ""
        }

        if let exactSource = exactSourceString(forTokenRange: range) {
            return exactSource
        }

        return reconstructSource(forTokenRange: range)
    }

    private func liquidBodySource(forTokenRange range: Range<Int>) -> String {
        guard !range.isEmpty else {
            return ""
        }

        if let exactSource = exactSourceString(forTokenRange: range) {
            return exactSource
        }

        var output = ""
        var previousToken: Token?

        for token in tokens[range] {
            if let previousToken {
                if token.line > previousToken.line {
                    output.append("\n")
                } else if shouldInsertSpace(between: previousToken.type, and: token.type) {
                    output.append(" ")
                }
            }

            output.append(tokenSourceLexeme(token))
            previousToken = token
        }

        return output
    }

    private func exactSourceString(forTokenRange range: Range<Int>) -> String? {
        guard let source,
              range.lowerBound >= 0,
              range.upperBound <= tokens.count,
              range.lowerBound < range.upperBound else {
            return nil
        }

        let startOffset = tokens[range.lowerBound].position
        let endOffset: Int
        if range.upperBound < tokens.count {
            endOffset = tokens[range.upperBound].position
        } else {
            endOffset = source.utf8.count
        }

        guard let startIndex = stringIndex(in: source, utf8Offset: startOffset),
              let endIndex = stringIndex(in: source, utf8Offset: endOffset),
              startIndex <= endIndex else {
            return nil
        }

        return String(source[startIndex..<endIndex])
    }

    private func stringIndex(in source: String, utf8Offset: Int) -> String.Index? {
        guard utf8Offset >= 0 else {
            return nil
        }

        let utf8View = source.utf8
        guard let utf8Index = utf8View.index(utf8View.startIndex, offsetBy: utf8Offset, limitedBy: utf8View.endIndex),
              let index = String.Index(utf8Index, within: source) else {
            return nil
        }

        return index
    }

    private func reconstructSource(forTokenRange range: Range<Int>) -> String {
        var output = ""
        var previous: TokenType?

        for token in tokens[range] {
            let tokenType = token.type
            let lexeme = tokenSourceLexeme(token)

            if !output.isEmpty && shouldInsertSpace(between: previous, and: tokenType) {
                output.append(" ")
            }

            output.append(lexeme)
            previous = tokenType
        }

        return output
    }

    private func tokenSourceLexeme(_ token: Token) -> String {
        switch token.type {
        case .tagStart:
            return token.trimLeft ? "{%-" : "{%"
        case .tagEnd:
            return token.trimRight ? "-%}" : "%}"
        case .variableStart:
            return token.trimLeft ? "{{-" : "{{"
        case .variableEnd:
            return token.trimRight ? "-}}" : "}}"
        default:
            return token.type.sourceLexeme
        }
    }

    private func shouldInsertSpace(between previous: TokenType?, and current: TokenType) -> Bool {
        guard let previous else {
            return false
        }

        if case .text = previous {
            return false
        }
        if case .text = current {
            return false
        }

        switch current {
        case .dot, .comma, .colon, .rightParen, .tagEnd, .variableEnd:
            return false
        default:
            break
        }

        switch previous {
        case .leftParen, .tagStart, .variableStart, .dot:
            return false
        default:
            return true
        }
    }
    
    // MARK: - Helper Methods for Control Flow
    
    /// Checks if current position is at elsif, else, or endif tag
    @inline(__always)
    private func isElsifOrElseOrEndif() -> Bool {
        currentTagMatchesAny(
            (.elsif, "elsif"),
            (.else, "else"),
            (.endif, "endif")
        )
    }
    
    /// Checks if current position is at endif tag
    @inline(__always)
    private func isEndif() -> Bool {
        currentTagMatches(.endif, identifier: "endif")
    }
    
    /// Checks if current position is at elsif, else, or endunless tag
    @inline(__always)
    private func isElseOrEndunless() -> Bool {
        currentTagMatchesAny(
            (.elsif, "elsif"),
            (.else, "else"),
            (.endunless, "endunless")
        )
    }
    
    /// Checks if current position is at endunless tag
    @inline(__always)
    private func isEndunless() -> Bool {
        currentTagMatches(.endunless, identifier: "endunless")
    }
    
    // MARK: - Complex Tag Parsing (Stubs)
    
    /// Parses a case tag: {% case expr %}...{% when val %}...{% endcase %}
    private func parseCaseTag() throws(ParserError) ->ASTNode {
        let expression = try parseExpression()
        try consumeTagEnd()
        
        var branches: [(LiquidCore.Expression?, [ASTNode])] = []
        branches.reserveCapacity(4)
        var defaultBranch: [ASTNode]? = nil
        
        // Parse all branches: when, else, and mixed when/else blocks
        // Skip whitespace before first branch
        while !isAtEnd && currentToken.type != .tagStart {
            advance()
        }

        while !isAtEnd && !currentTagMatches(.endcase, identifier: "endcase") {
            if currentTagMatches(.when, identifier: "when") {
                try parseCaseWhenBranch(into: &branches)
            } else if currentTagMatches(.else, identifier: "else") {
                advance() // consume {%
                try consumeTagKeyword(.else, identifier: "else")
                try consumeTagEnd()

                var elseNodes = makeNodeBuffer()
                while !isAtEnd && !isWhenOrElseOrEndcase() {
                    elseNodes.append(try parseNode())
                }
                // Store else as nil-expression branch
                branches.append((nil, elseNodes))
                if defaultBranch == nil {
                    defaultBranch = elseNodes
                }
            } else {
                // Skip whitespace/text between branches
                advance()
            }
        }

        guard currentTagMatches(.endcase, identifier: "endcase") else {
            throw ParserError.unexpectedToken(currentToken)
        }
        advance() // consume {%
        try consumeTagKeyword(.endcase, identifier: "endcase")
        try consumeTagEnd()

        // Convert branches to AST format
        // Else branches use .literal(.null) as sentinel expression
        let allBranches: [(LiquidCore.Expression, [ASTNode])] = branches.map { (value, nodes) in
            if let value { return (value, nodes) }
            return (.literal(.null), nodes) // sentinel for else
        }

        // If we have sentinel else branches in allBranches, don't also pass defaultBranch
        // to avoid double-rendering
        let hasSentinelElse = branches.contains { $0.0 == nil }
        return .case(value: expression, whens: allBranches, else: hasSentinelElse ? nil : defaultBranch)
    }
    
    /// Parses a single `when` branch in a case statement, appending to branches array.
    /// Handles comma, `or`, and `and` separated values. `and` invalidates the entire when clause.
    private func parseCaseWhenBranch(into branches: inout [(LiquidCore.Expression?, [ASTNode])]) throws(ParserError) {
        advance() // consume {%
        try consumeTagKeyword(.when, identifier: "when")

        var whenValues = makeExpressionBuffer()
        whenValues.append(try parseExpression())

        // Parse comma/or/and separated values
        // 'and' in when expressions invalidates the entire when clause (Shopify behavior)
        var hasInvalidAnd = false
        while currentToken.type == .comma || currentToken.type == .or || currentToken.type == .and {
            if currentToken.type == .and { hasInvalidAnd = true }
            advance()
            whenValues.append(try parseExpression())
        }
        if hasInvalidAnd { whenValues.removeAll() }

        try consumeTagEnd()

        var whenNodes = makeNodeBuffer()
        while !isAtEnd && !isWhenOrElseOrEndcase() {
            whenNodes.append(try parseNode())
        }
        for value in whenValues {
            branches.append((value, whenNodes))
        }
    }

    /// Checks if current position is at when, else, or endcase tag
    @inline(__always)
    private func isWhenOrElseOrEndcase() -> Bool {
        currentTagMatchesAny(
            (.when, "when"),
            (.else, "else"),
            (.endcase, "endcase")
        )
    }
    
    /// Checks if current position is at endcase tag
    @inline(__always)
    private func isEndcase() -> Bool {
        currentTagMatches(.endcase, identifier: "endcase")
    }
    
    /// Parses a for loop tag: {% for item in collection %}...{% endfor %}
    private func parseForTag() throws(ParserError) ->ASTNode {
        guard case .identifier(let variable) = currentToken.type else {
            throw ParserError.unexpectedToken(currentToken)
        }
        advance()
        
        guard currentToken.type == .in else {
            throw ParserError.unexpectedToken(currentToken)
        }
        advance()
        
        let collection = try parseExpression()
        
        // Parse optional parameters
        var limit: Int? = nil
        var offset: Int? = nil
        var offsetContinue = false
        var reversed = false
        var limitExpression: LiquidCore.Expression? = nil
        var offsetExpression: LiquidCore.Expression? = nil
        
        // Skip optional comma before first parameter (Shopify allows commas between params)
        if currentToken.type == .comma { advance() }
        while let paramName = peekIdentifierName() {
            guard paramName.equals("limit")
                    || paramName.equals("offset")
                    || paramName.equals("reversed") else {
                break
            }

            advance() // consume parameter name
            
            if paramName.equals("reversed") {
                reversed = true
                continue
            }

            guard currentToken.type == .colon else {
                throw ParserError.unexpectedToken(currentToken)
            }
            advance()
            
            // Check for offset: continue (special keyword)
            if paramName.equals("offset"),
               (currentToken.type == .continue ||
                (currentToken.type == .identifier(InlineString("continue")))) {
                advance() // consume 'continue'
                offsetContinue = true
            } else {
                let value = try parsePrimaryExpression()

                if case .literal(.number(let num, _)) = value {
                    if paramName.equals("limit") {
                        limit = Int(num)
                    } else if paramName.equals("offset") {
                        offset = Int(num)
                    }
                } else if case .literal(.string(let str)) = value {
                    // String coercion: "2" → 2 (Shopify behavior)
                    if let intVal = Int(str.string) {
                        if paramName.equals("limit") { limit = intVal }
                        else if paramName.equals("offset") { offset = intVal }
                    } else {
                        // Non-numeric string like 'foo' → error
                        throw ParserError.unexpectedToken(currentToken)
                    }
                } else if case .variable = value {
                    // Variable reference — store expression for runtime evaluation
                    if paramName.equals("limit") { limitExpression = value }
                    else if paramName.equals("offset") { offsetExpression = value }
                } else {
                    // Boolean, nil, or other non-numeric type → error
                    throw ParserError.unexpectedToken(currentToken)
                }
            }
            // Skip optional trailing comma after parameter value
            if currentToken.type == .comma { advance() }
        }

        let params = ForParams(limit: limit, offset: offset, offsetContinue: offsetContinue, reversed: reversed, limitExpression: limitExpression, offsetExpression: offsetExpression)
        
        try consumeTagEnd()
        
        // Parse loop body
        var body = makeNodeBuffer()
        
        while !isAtEnd && !isEmptyOrEndfor() {
            body.append(try parseNode())
        }
        
        // Parse empty/else branch if present (for empty collections)
        // Supports both {% empty %} and {% else %} (Shopify-compatible)
        var emptyBranch: [ASTNode]? = nil
        if !isAtEnd && (currentTagMatches(.empty, identifier: "empty") || currentTagMatches(.else, identifier: "else")) {
            let isElseForm = currentTagMatches(.else, identifier: "else")
            advance() // consume {%
            if isElseForm {
                try consumeTagKeyword(.else, identifier: "else")
            } else {
                try consumeTagKeyword(.empty, identifier: "empty")
            }
            try consumeTagEnd()
            
            var emptyNodes = makeNodeBuffer()
            while !isAtEnd && !isEndfor() {
                emptyNodes.append(try parseNode())
            }
            emptyBranch = emptyNodes
        }
        
        // Consume endfor
        guard currentTagMatches(.endfor, identifier: "endfor") else {
            throw ParserError.unexpectedToken(currentToken)
        }
        advance() // consume {%
        try consumeTagKeyword(.endfor, identifier: "endfor")
        try consumeTagEnd()
        
        return .for(variable: variable, in: collection, body: body, empty: emptyBranch, params: params)
    }
    
    /// Checks if current position is at empty, else, or endfor tag
    @inline(__always)
    private func isEmptyOrEndfor() -> Bool {
        currentTagMatchesAny(
            (.empty, "empty"),
            (.else, "else"),
            (.endfor, "endfor")
        )
    }
    
    /// Checks if current position is at else or endfor tag
    @inline(__always)
    private func isElseOrEndfor() -> Bool {
        currentTagMatchesAny(
            (.else, "else"),
            (.endfor, "endfor")
        )
    }
    
    /// Checks if current position is at endfor tag
    @inline(__always)
    private func isEndfor() -> Bool {
        currentTagMatches(.endfor, identifier: "endfor")
    }
    
    /// Checks if current position is at endtablerow tag
    @inline(__always)
    private func isEndtablerow() -> Bool {
        currentTagMatches(.endtablerow, identifier: "endtablerow")
    }
    
    /// Parses a tablerow tag: {% tablerow item in collection cols:2 %}...{% endtablerow %}
    private func parseTableRowTag() throws(ParserError) ->ASTNode {
        guard case .identifier(let variable) = currentToken.type else {
            throw ParserError.unexpectedToken(currentToken)
        }
        advance()
        
        guard currentToken.type == .in else {
            throw ParserError.unexpectedToken(currentToken)
        }
        advance()
        
        let collection = try parseExpression()
        
        // Parse optional parameters
        var cols: Int? = nil
        var limit: Int? = nil
        var offset: Int? = nil
        
        while let paramName = peekIdentifierName() {
            guard paramName.equals("cols")
                    || paramName.equals("limit")
                    || paramName.equals("offset") else {
                break
            }

            advance() // consume parameter name
            
            guard currentToken.type == .colon else {
                throw ParserError.unexpectedToken(currentToken)
            }
            advance()
            
            let value = try parsePrimaryExpression()

            if case .literal(.number(let num, _)) = value {
                if paramName.equals("cols") {
                    cols = Int(num)
                } else if paramName.equals("limit") {
                    limit = Int(num)
                } else if paramName.equals("offset") {
                    offset = Int(num)
                }
            } else if case .literal(.string(let str)) = value {
                if let intVal = Int(str.string) {
                    if paramName.equals("cols") { cols = intVal }
                    else if paramName.equals("limit") { limit = intVal }
                    else if paramName.equals("offset") { offset = intVal }
                }
            }
        }

        let params = TableRowParams(cols: cols, limit: limit, offset: offset)
        try consumeTagEnd()
        
        // Parse tablerow body
        var body = makeNodeBuffer()
        while !isAtEnd && !isEndtablerow() {
            body.append(try parseNode())
        }
        
        // Consume endtablerow
        guard currentTagMatches(.endtablerow, identifier: "endtablerow") else {
            throw ParserError.unexpectedToken(currentToken)
        }
        advance() // consume {%
        try consumeTagKeyword(.endtablerow, identifier: "endtablerow")
        try consumeTagEnd()
        
        return .tablerow(variable: variable, in: collection, body: body, params: params)
    }
    
    /// Parses a capture tag: {% capture var %}...{% endcapture %}
    private func parseCaptureTag() throws(ParserError) ->ASTNode {
        let variable: InlineString
        if case .identifier(let name) = currentToken.type {
            variable = name
        } else if case .number(let num, _) = currentToken.type {
            // Digit-only variable names: {% capture 123 %}
            variable = InlineString(String(Int(num)))
        } else {
            throw ParserError.unexpectedToken(currentToken)
        }
        advance()
        try consumeTagEnd()
        
        var body = makeNodeBuffer()
        while !isAtEnd && !currentTagMatches(.endcapture, identifier: "endcapture") {
            body.append(try parseNode())
        }
        
        // Consume endcapture
        guard currentTagMatches(.endcapture, identifier: "endcapture") else {
            throw ParserError.unexpectedToken(currentToken)
        }
        advance() // consume {%
        try consumeTagKeyword(.endcapture, identifier: "endcapture")
        try consumeTagEnd()
        
        return .capture(variable: variable, body: body)
    }
    
    /// Parses increment tag: {% increment counter %}
    private func parseIncrementTag() throws(ParserError) ->ASTNode {
        guard case .identifier(let counter) = currentToken.type else {
            throw ParserError.unexpectedToken(currentToken)
        }
        advance()
        try consumeTagEnd()
        
        return .increment(name: counter)
    }
    
    /// Parses decrement tag: {% decrement counter %}
    private func parseDecrementTag() throws(ParserError) ->ASTNode {
        guard case .identifier(let counter) = currentToken.type else {
            throw ParserError.unexpectedToken(currentToken)
        }
        advance()
        try consumeTagEnd()
        
        return .decrement(name: counter)
    }

    /// Parses break tag: {% break %}
    private func parseBreakTag() throws(ParserError) ->ASTNode {
        try consumeTagEnd()
        return .break
    }

    /// Parses continue tag: {% continue %}
    private func parseContinueTag() throws(ParserError) ->ASTNode {
        try consumeTagEnd()
        return .continue
    }

    /// Parses debug tag: {% debug %} or {% debug expression %}
    private func parseDebugTag() throws(ParserError) ->ASTNode {
        let expression: LiquidCore.Expression?
        if currentToken.type == .tagEnd {
            expression = nil
        } else {
            expression = try parseExpression()
        }

        try consumeTagEnd()
        return .debug(expression: expression)
    }
    
    /// Parses raw tag: {% raw %}...{% endraw %}
    private func parseRawTag() throws(ParserError) ->ASTNode {
        // Record position right after {% raw %} tag end
        let tagEndToken = currentToken
        try consumeTagEnd()

        // If we have the original source, extract raw content verbatim
        if let source {
            let rawStartPosition = tagEndToken.position + 2 // after %} (position is already past any trim marker)

            // Skip tokens until we find {% endraw %}
            while !isAtEnd && !currentTagMatches(.endraw, identifier: "endraw") {
                advance()
            }

            guard currentTagMatches(.endraw, identifier: "endraw") else {
                throw ParserError.unexpectedToken(currentToken)
            }

            // The endraw tag start token position is the end of raw content
            let rawEndPosition = currentToken.position

            // Extract verbatim content from source
            let startIndex = source.utf8.index(source.startIndex, offsetBy: rawStartPosition, limitedBy: source.endIndex) ?? source.endIndex
            let endIndex = source.utf8.index(source.startIndex, offsetBy: rawEndPosition, limitedBy: source.endIndex) ?? source.endIndex
            let content = String(source[startIndex ..< endIndex])

            advance() // consume {%
            try consumeTagKeyword(.endraw, identifier: "endraw")
            try consumeTagEnd()

            return .raw(InlineString(content))
        }

        // Fallback: reconstruct from tokens (lossy)
        var content = ""
        while !isAtEnd && !currentTagMatches(.endraw, identifier: "endraw") {
            switch currentToken.type {
            case .text(let text):
                content.append(text.string)
            case .variableStart:
                content.append(currentToken.trimLeft ? "{{-" : "{{")
            case .variableEnd:
                content.append(currentToken.trimRight ? "-}}" : "}}")
            case .tagStart:
                content.append(currentToken.trimLeft ? "{%-" : "{%")
            case .tagEnd:
                content.append(currentToken.trimRight ? "-%}" : "%}")
            default:
                content.append(" ")
            }
            advance()
        }

        guard currentTagMatches(.endraw, identifier: "endraw") else {
            throw ParserError.unexpectedToken(currentToken)
        }
        advance()
        try consumeTagKeyword(.endraw, identifier: "endraw")
        try consumeTagEnd()

        return .raw(InlineString(content))
    }
    
    /// Parses liquid tag: {% liquid ... %}
    private func parseLiquidTag() throws(ParserError) ->ASTNode {
        let markupStart = current
        while currentToken.type != .tagEnd && !isAtEnd {
            advance()
        }

        var bodySource = liquidBodySource(forTokenRange: markupStart..<current)
        // Strip trailing `-` that may be captured from `-%}` trim marker
        if bodySource.hasSuffix("-") {
            bodySource = String(bodySource.dropLast())
        }
        try consumeTagEnd()

        let rewrittenTemplate = rewriteLiquidBodyAsTemplate(bodySource)
        guard !rewrittenTemplate.isEmpty else {
            return .liquid(body: [])
        }

        let nestedTokens: [Token]
        do {
            nestedTokens = try Lexer(rewrittenTemplate).tokenize()
        } catch {
            throw ParserError.unsupportedFeature("Lexer error in liquid tag body: \(error)")
        }
        let nestedParser = Parser(
            consuming: nestedTokens,
            source: rewrittenTemplate,
            customTags: Array(customTagDescriptors.values)
        )
        let nestedAST = try nestedParser.parse()

        guard case .template(let nodes) = nestedAST else {
            return .liquid(body: [])
        }

        return .liquid(body: normalizeLiquidBodyNodes(nodes))
    }

    /// Parses pipeline tag: {% pipeline ... %}
    private func parsePipelineTag() throws(ParserError) ->ASTNode {
        throw ParserError.unsupportedFeature(
            "The pipeline tag is archived and not part of the active RhoeLiquid 1.x runtime."
        )
    }

    private func rewriteLiquidBodyAsTemplate(_ bodySource: String) -> String {
        // Shopify Liquid: only \n is a valid line separator in liquid tags, not \r
        if bodySource.contains("\r") && !bodySource.contains("\n") {
            // Pure \r line endings are not supported
            return "{% invalid_liquid_cr %}"
        }
        // Normalize \r\n to \n
        let normalizedSource = bodySource.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
        let lines = normalizedSource
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }

        var result: [String] = []
        var inComment = false
        for line in lines {
            if line.isEmpty { continue }

            if inComment {
                // Inside comment block, check for endcomment
                if line == "endcomment" {
                    result.append("{% endcomment %}")
                    inComment = false
                }
                // Skip comment content lines
                continue
            }

            if line.hasPrefix("comment") {
                result.append("{% comment %}")
                inComment = true
                continue
            }

            // Handle # inline comments — skip them
            if line.hasPrefix("#") {
                continue
            }

            // Handle echo — convert to output: {% echo expr %} → {{ expr }}
            if line.hasPrefix("echo ") {
                let expr = String(line.dropFirst(5)).trimmingCharacters(in: .whitespacesAndNewlines)
                result.append("{{ \(expr) }}")
                continue
            }

            result.append("{% \(line) %}")
        }

        return result.joined(separator: "\n")
    }

    private func normalizeLiquidBodyNodes(_ nodes: [ASTNode]) -> [ASTNode] {
        nodes.compactMap(normalizeLiquidBodyNode)
    }

    private func normalizeLiquidBodyNode(_ node: ASTNode) -> ASTNode? {
        switch node {
        case .text(let text):
            let trimmed = text.string.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : node
        case .template(let nodes):
            return .template(normalizeLiquidBodyNodes(nodes))
        case .if(let condition, let thenNodes, let elsifBranches, let elseNodes):
            return .if(
                condition: condition,
                then: normalizeLiquidBodyNodes(thenNodes),
                elsif: elsifBranches.map { condition, branch in
                    (condition, normalizeLiquidBodyNodes(branch))
                },
                else: elseNodes.map(normalizeLiquidBodyNodes)
            )
        case .unless(let condition, let thenNodes, let elseNodes):
            return .unless(
                condition: condition,
                then: normalizeLiquidBodyNodes(thenNodes),
                else: elseNodes.map(normalizeLiquidBodyNodes)
            )
        case .case(let value, let whens, let elseBranch):
            return .case(
                value: value,
                whens: whens.map { value, branch in
                    (value, normalizeLiquidBodyNodes(branch))
                },
                else: elseBranch.map(normalizeLiquidBodyNodes)
            )
        case .for(let variable, let collection, let body, let empty, let params):
            return .for(
                variable: variable,
                in: collection,
                body: normalizeLiquidBodyNodes(body),
                empty: empty.map(normalizeLiquidBodyNodes),
                params: params
            )
        case .tablerow(let variable, let collection, let body, let params):
            return .tablerow(
                variable: variable,
                in: collection,
                body: normalizeLiquidBodyNodes(body),
                params: params
            )
        case .capture(let variable, let body):
            return .capture(variable: variable, body: normalizeLiquidBodyNodes(body))
        case .block(let name, let body):
            return .block(name: name, body: normalizeLiquidBodyNodes(body))
        case .liquid(let body):
            return .liquid(body: normalizeLiquidBodyNodes(body))
        case .registeredCustomTag(let name, let markup, let body):
            guard let body else {
                return node
            }
            return .registeredCustomTag(
                name: name,
                markup: markup,
                body: RuntimeCustomTagBody(
                    source: body.source,
                    nodes: normalizeLiquidBodyNodes(body.nodes)
                )
            )
        default:
            return node
        }
    }
    
    /// Parses cycle tag: {% cycle 'one', 'two', 'three' %}
    private func parseCycleTag() throws(ParserError) ->ASTNode {
        var values = makeExpressionBuffer(initialCapacity: 4)

        // Parse first value — might be a group name followed by ':'
        let firstExpr = try parsePrimaryExpression()

        // Check for named cycle: {% cycle name: val1, val2 %}
        var group: LiquidCore.Expression? = nil
        if currentToken.type == .colon {
            advance() // consume ':'
            group = firstExpr
            // Parse actual cycle values
            values.append(try parsePrimaryExpression())
        } else {
            values.append(firstExpr)
        }

        // Parse remaining values
        while currentToken.type == .comma {
            advance() // consume comma
            values.append(try parsePrimaryExpression())
        }

        try consumeTagEnd()
        return .cycle(group: group, items: values)
    }
    
    /// Parses include tag: {% include 'template' %}
    private func parseIncludeTag() throws(ParserError) ->ASTNode {
        let templateName = try parsePrimaryExpression()
        let templateStr: InlineString
        if case .literal(.string(let name)) = templateName {
            templateStr = name
        } else if case .variable(let name) = templateName {
            // Support include with variable name: {% include my_template %}
            templateStr = name
        } else {
            throw ParserError.expectedString
        }

        var variables: [String: LiquidCore.Expression] = [:]
        variables.reserveCapacity(4)
        var alias: InlineString? = nil

        // Skip optional comma after template name
        if currentToken.type == .comma { advance() }

        // Parse optional variable assignments
        while currentToken.type != .tagEnd {
            if currentToken.type == .for {
                // {% include 'template' for collection %} — iterate over collection
                advance() // consume 'for'
                let expr = try parseExpression()
                variables["_for"] = expr
                // Skip optional comma
                if currentToken.type == .comma { advance() }
            } else if case .identifier(let varName) = currentToken.type {
                advance()

                guard currentToken.type == .colon else {
                    throw ParserError.unexpectedToken(currentToken)
                }
                advance()

                let value = try parsePrimaryExpression()
                variables[varName.string] = value

                // Skip optional comma
                if currentToken.type == .comma {
                    advance()
                }
            } else if currentToken.type == .with {
                advance() // consume 'with'
                // Parse the object to merge
                let expr = try parsePrimaryExpression()
                variables["_with"] = expr
                if case .identifier(let keyword) = currentToken.type, keyword.equals("as") {
                    advance()
                    guard case .identifier(let aliasName) = currentToken.type else {
                        throw ParserError.unexpectedToken(currentToken)
                    }
                    alias = aliasName
                    advance()
                }
            } else {
                throw ParserError.unexpectedToken(currentToken)
            }
        }

        try consumeTagEnd()
        return .include(template: templateStr, with: variables.isEmpty ? nil : variables, as: alias)
    }
    
    /// Parses render tag: {% render 'template' %}
    private func parseRenderTag() throws(ParserError) ->ASTNode {
        // Similar to include but with isolated scope
        let templateName = try parsePrimaryExpression()
        let templateStr: InlineString
        if case .literal(.string(let name)) = templateName {
            templateStr = name
        } else {
            throw ParserError.expectedString
        }

        var variables: [String: LiquidCore.Expression] = [:]
        variables.reserveCapacity(4)
        var alias: InlineString? = nil

        // Skip optional comma after template name
        if currentToken.type == .comma { advance() }

        // Parse optional variable assignments
        while currentToken.type != .tagEnd {
            if case .identifier(let varName) = currentToken.type {
                advance()
                
                guard currentToken.type == .colon else {
                    throw ParserError.unexpectedToken(currentToken)
                }
                advance()
                
                let value = try parsePrimaryExpression()
                variables[varName.string] = value
                
                // Skip optional comma
                if currentToken.type == .comma {
                    advance()
                }
            } else if currentToken.type == .with {
                advance()
                let expr = try parsePrimaryExpression()
                variables["_with"] = expr
                if case .identifier(let keyword) = currentToken.type, keyword.equals("as") {
                    advance()
                    guard case .identifier(let aliasName) = currentToken.type else {
                        throw ParserError.unexpectedToken(currentToken)
                    }
                    alias = aliasName
                    advance()
                }
            } else if currentToken.type == .for {
                advance()
                let expr = try parsePrimaryExpression()
                variables["_for"] = expr
                if case .identifier(let keyword) = currentToken.type, keyword.equals("as") {
                    advance()
                    guard case .identifier(let aliasName) = currentToken.type else {
                        throw ParserError.unexpectedToken(currentToken)
                    }
                    alias = aliasName
                    advance()
                }
            } else {
                throw ParserError.unexpectedToken(currentToken)
            }
        }
        
        try consumeTagEnd()
        // The render tag doesn't exist in the current AST, use include with isolated scope marker.
        var renderVars = variables
        renderVars["__render_isolated__"] = .literal(.boolean(true))
        
        return .include(template: templateStr, with: renderVars, as: alias)
    }
    
    /// Parses block tag: {% block name %}...{% endblock %}
    private func parseBlockTag() throws(ParserError) ->ASTNode {
        guard case .identifier(let blockName) = currentToken.type else {
            throw ParserError.unexpectedToken(currentToken)
        }
        advance()
        try consumeTagEnd()
        
        var body = makeNodeBuffer()
        while !isAtEnd && !currentTagMatches(.endblock, identifier: "endblock") {
            body.append(try parseNode())
        }
        
        // Consume endblock
        guard currentTagMatches(.endblock, identifier: "endblock") else {
            throw ParserError.unexpectedToken(currentToken)
        }
        advance() // consume {%
        try consumeTagKeyword(.endblock, identifier: "endblock")
        try consumeTagEnd()
        
        return .block(name: blockName, body: body)
    }
    
    /// Parses an extends tag: {% extends "parent_template.liquid" %}
    private func parseExtendsTag() throws(ParserError) ->ASTNode {
        // Expect a string literal for the template name
        let templateExpr = try parsePrimaryExpression()
        
        guard case .literal(.string(let templateName)) = templateExpr else {
            throw ParserError.expectedString
        }
        
        try consumeTagEnd()
        
        return .extends(template: templateName)
    }
    
    /// Parses render_block tag: {% render_block name param1:value1 param2:value2 %}
    private func parseRenderBlockTag() throws(ParserError) ->ASTNode {
        guard case .identifier(let blockName) = currentToken.type else {
            throw ParserError.unexpectedToken(currentToken)
        }
        advance()
        
        var params: [String: LiquidCore.Expression] = [:]
        params.reserveCapacity(4)
        
        // Parse optional parameters
        while currentToken.type != .tagEnd {
            if case .identifier(let paramName) = currentToken.type {
                advance()
                
                guard currentToken.type == .colon else {
                    throw ParserError.unexpectedToken(currentToken)
                }
                advance()
                
                let value = try parsePrimaryExpression()
                params[paramName.string] = value
                
                // Skip optional comma
                if currentToken.type == .comma {
                    advance()
                }
            } else {
                throw ParserError.unexpectedToken(currentToken)
            }
        }
        
        try consumeTagEnd()
        return .renderBlock(name: blockName, params: params)
    }
}
