//
//  ProvenanceMap.swift
//  LiquidCore
//
//  Created as part of RhoeLiquid
//  A high-performance Swift implementation of the Liquid template language
//

/// Maps character ranges in rendered output back to source template constructs.
/// Each span identifies what portion of the output came from which part of the source
/// and what kind of Liquid construct produced it.
public struct ProvenanceMap: Sendable, Equatable {
    /// Ordered list of spans covering the entire output.
    public let spans: [RenderSpan]

    public init(spans: [RenderSpan]) {
        self.spans = spans
    }

    /// Find the source span that produced a given output offset.
    public func sourceSpan(forOutputOffset offset: Int) -> RenderSpan? {
        spans.first { $0.outputRange.contains(offset) }
    }

    /// Find all output spans produced by a given source offset.
    public func outputSpans(forSourceOffset offset: Int) -> [RenderSpan] {
        spans.filter { $0.sourceRange.contains(offset) }
    }

    /// Find all spans of a given node kind.
    public func spans(ofKind kind: ProvenanceNodeKind) -> [RenderSpan] {
        spans.filter { $0.nodeKind == kind }
    }

    /// Total output length covered by Liquid-generated (non-literal) content.
    public var liquidGeneratedLength: Int {
        spans
            .filter { $0.nodeKind != .literal }
            .reduce(0) { $0 + $1.outputRange.count }
    }

    /// An empty provenance map.
    public static let empty = ProvenanceMap(spans: [])
}
