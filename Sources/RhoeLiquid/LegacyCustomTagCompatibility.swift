import Foundation
import LiquidCore
import LiquidLexer
import LiquidParser
import LiquidTags

/// Wraps an older `LiquidCore.CustomTag` with explicit runtime-shape metadata.
///
/// Use this when bootstrapping legacy tags through `LiquidConfiguration.customTags`
/// and the older tag type cannot itself conform to
/// `LegacyCustomTagRuntimeDescriptorProvider`.
public struct ConfiguredLegacyCustomTag: LiquidCore.CustomTag, LiquidCore.LegacyCustomTagRuntimeDescriptorProvider {
    public let runtimeDescriptor: LiquidCore.LegacyCustomTagRuntimeDescriptor

    private let baseTag: any LiquidCore.CustomTag

    public init(
        _ baseTag: any LiquidCore.CustomTag,
        runtimeDescriptor: LiquidCore.LegacyCustomTagRuntimeDescriptor
    ) {
        self.baseTag = baseTag
        self.runtimeDescriptor = runtimeDescriptor
    }

    public init(
        _ baseTag: any LiquidCore.CustomTag,
        kind: LiquidCore.LegacyCustomTagRuntimeKind,
        allowsNesting: Bool = true,
        maxNestingDepth: Int? = nil,
        requiredContext: [String] = []
    ) {
        self.init(
            baseTag,
            runtimeDescriptor: LiquidCore.LegacyCustomTagRuntimeDescriptor(
                kind: kind,
                allowsNesting: allowsNesting,
                maxNestingDepth: maxNestingDepth,
                requiredContext: requiredContext
            )
        )
    }

    public func parse(parser: any LiquidCore.TagParser) throws -> any LiquidCore.TagNode {
        try baseTag.parse(parser: parser)
    }
}

/// Compatibility adapter for older `LiquidCore.CustomTag` implementations.
///
/// Prefer native `LiquidTags.CustomTag` implementations for new work. This adapter keeps
/// older parser-style tags usable while the public extension surface finishes converging
/// on the registry-backed runtime path.
public struct LegacyCustomTagAdapter: LiquidTags.CustomTag {
    public let name: String
    public let type: TagType
    public let allowsNesting: Bool
    public let maxNestingDepth: Int?
    public let requiredContext: [String]

    private let legacyTag: any LiquidCore.CustomTag

    public init(
        name: String,
        type: TagType,
        legacyTag: any LiquidCore.CustomTag,
        allowsNesting: Bool = true,
        maxNestingDepth: Int? = nil,
        requiredContext: [String] = []
    ) {
        self.name = name
        self.type = type
        self.legacyTag = legacyTag
        self.allowsNesting = allowsNesting
        self.maxNestingDepth = maxNestingDepth
        self.requiredContext = requiredContext
    }

    public func parse(_ parameters: String, context: TagParsingContext) async throws -> TagParameters {
        TagParameters(["legacyMarkup": parameters])
    }

    public func execute(
        parameters: TagParameters,
        content: String?,
        context: TagExecutionContext
    ) async throws -> String {
        let markup = parameters.get("legacyMarkup", as: String.self) ?? ""
        let parser = LegacyTagParserAdapter(
            markup: markup,
            bodyNodes: context.bodyNodes,
            bodySource: content
        )
        let node = try legacyTag.parse(parser: parser)
        let renderContext = LegacyRenderContextAdapter(executionContext: context)
        return try await node.render(context: renderContext)
    }
}

extension LegacyCustomTagAdapter {
    init(name: String, legacyTag: any LiquidCore.CustomTag) {
        let descriptor = Self.runtimeDescriptor(for: legacyTag)
        self.init(
            name: name,
            type: descriptor.kind.runtimeTagType,
            legacyTag: legacyTag,
            allowsNesting: descriptor.allowsNesting,
            maxNestingDepth: descriptor.maxNestingDepth,
            requiredContext: descriptor.requiredContext
        )
    }

    static func runtimeDescriptor(
        for legacyTag: any LiquidCore.CustomTag
    ) -> LiquidCore.LegacyCustomTagRuntimeDescriptor {
        (legacyTag as? any LiquidCore.LegacyCustomTagRuntimeDescriptorProvider)?
            .runtimeDescriptor ?? .simple
    }
}

private extension LiquidCore.LegacyCustomTagRuntimeKind {
    var runtimeTagType: TagType {
        switch self {
        case .simple:
            return .simple
        case .block:
            return .block
        case .conditional:
            return .conditional
        case .loop:
            return .loop
        case .selfClosing:
            return .selfClosing
        }
    }
}

private struct LegacyTagParserAdapter: LiquidCore.TagParser {
    let markup: String
    let bodyNodes: [ASTNode]?
    let bodySource: String?

    func parseExpression() throws -> LiquidCore.Expression {
        let source = "{{ \(markup) }}"
        let tokens = try Lexer(source).tokenize()
        let parser = Parser(consuming: tokens, source: source)
        let ast = try parser.parse()

        guard case .template(let nodes) = ast,
              nodes.count == 1,
              case .output(let expression) = nodes[0] else {
            throw TagParsingError.invalidSyntax("Legacy tag markup did not parse as an expression")
        }

        return expression
    }

    func parseUntilEnd(tagName: String) throws -> [ASTNode] {
        guard let bodyNodes else {
            throw TagParsingError.invalidSyntax("Legacy block tag '\(tagName)' is missing its body")
        }
        return bodyNodes
    }

    func expectEndTag(_ tagName: String) throws {
        guard bodyNodes != nil || bodySource != nil else {
            throw TagParsingError.invalidSyntax("Legacy block tag '\(tagName)' is missing its end tag")
        }
    }
}

private struct LegacyRenderContextAdapter: LiquidCore.RenderContext {
    let executionContext: TagExecutionContext

    func getValue(for key: borrowing String) throws -> Any {
        try executionContext.getValue(for: key)
    }

    func setValue(_ value: consuming Any, for key: String) {
        executionContext.setVariable(value, for: key)
    }

    func pushScope(_ scope: consuming [String: Any]) {
        executionContext.pushScope(scope)
    }

    func popScope() {
        executionContext.popScope()
    }

    func applyFilter(
        name: String,
        to value: Any,
        arguments: [Any],
        namedArguments: [String: Any]
    ) async throws -> Any {
        try await executionContext.applyFilter(
            name: name,
            to: value,
            arguments: arguments,
            namedArguments: namedArguments
        )
    }
}
