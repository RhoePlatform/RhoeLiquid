//
//  RenderSpan.swift
//  LiquidCore
//
//  Created as part of RhoeLiquid
//  A high-performance Swift implementation of the Liquid template language
//

/// A single provenance span mapping an output range to its source origin.
public struct RenderSpan: Sendable, Equatable {
    /// UTF-8 byte offset range in the rendered output.
    public let outputRange: Range<Int>

    /// UTF-8 byte offset range in the source template.
    public let sourceRange: Range<Int>

    /// What kind of Liquid construct produced this span.
    public let nodeKind: ProvenanceNodeKind

    /// Human-readable description of the source construct (e.g., "product.name | upcase").
    public let sourceDescription: String?

    public init(
        outputRange: Range<Int>,
        sourceRange: Range<Int>,
        nodeKind: ProvenanceNodeKind,
        sourceDescription: String? = nil
    ) {
        self.outputRange = outputRange
        self.sourceRange = sourceRange
        self.nodeKind = nodeKind
        self.sourceDescription = sourceDescription
    }
}

/// Classifies the kind of Liquid construct that produced a render span.
public enum ProvenanceNodeKind: Sendable, Equatable {
    /// Literal passthrough text (not a Liquid construct).
    case literal

    /// Output tag: `{{ expression }}`.
    case outputTag

    /// Filter application within an output tag: `| filter_name`.
    case filter(name: String)

    /// Control flow tag: `{% if/for/case/unless/... %}`.
    case controlFlow(tag: String)

    /// Variable assignment: `{% assign/capture %}`.
    case assignment(tag: String)

    /// Template inclusion: `{% include/render %}`.
    case include(name: String)

    /// Comment block: `{% comment %}...{% endcomment %}`.
    case comment
}
