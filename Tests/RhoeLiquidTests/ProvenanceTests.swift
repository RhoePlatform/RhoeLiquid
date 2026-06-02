//
//  ProvenanceTests.swift
//  RhoeLiquidTests
//
//  Created as part of RhoeLiquid
//  A high-performance Swift implementation of the Liquid template language
//

import Testing
@testable import LiquidCore
@testable import RhoeLiquid

@Suite("Provenance")
struct ProvenanceTests {
    // MARK: - ProvenanceBuilder

    @Test("Scans source constructs correctly")
    func scanSourceConstructs() {
        let builder = ProvenanceBuilder()
        let source = "Hello {{ name }}! {% if show %}yes{% endif %}"
        let constructs = builder.scanSourceConstructs(source)

        #expect(constructs.count == 6) // "Hello " + {{ name }} + "! " + {% if show %} + "yes" + {% endif %}

        // First is literal "Hello "
        #expect(constructs[0].kind == .literal)
        #expect(constructs[0].content == "Hello ")

        // Second is output tag
        #expect(constructs[1].kind == .outputTag)
        #expect(constructs[1].innerContent == "name")
    }

    @Test("Classifies output tags with filters")
    func classifyFilters() {
        let builder = ProvenanceBuilder()
        let source = "{{ name | upcase }}"
        let constructs = builder.scanSourceConstructs(source)

        #expect(constructs.count == 1)
        #expect(constructs[0].kind == .filter(name: "upcase"))
    }

    @Test("Classifies control flow tags")
    func classifyControlFlow() {
        let builder = ProvenanceBuilder()
        let source = "{% for item in items %}{{ item }}{% endfor %}"
        let constructs = builder.scanSourceConstructs(source)

        let forTag = constructs.first { if case .controlFlow(tag: "for") = $0.kind { return true }; return false }
        #expect(forTag != nil)
    }

    @Test("Classifies assign tags")
    func classifyAssignment() {
        let builder = ProvenanceBuilder()
        let source = #"{% assign x = "hello" %}"#
        let constructs = builder.scanSourceConstructs(source)

        #expect(constructs.count == 1)
        if case .assignment(tag: "assign") = constructs[0].kind {
            // pass
        } else {
            Issue.record("Expected assignment tag")
        }
    }

    @Test("Handles trim markers")
    func handleTrimMarkers() {
        let builder = ProvenanceBuilder()
        let source = "{%- if true -%}yes{%- endif -%}"
        let constructs = builder.scanSourceConstructs(source)

        // Should find: {%- if true -%}, "yes", {%- endif -%}
        #expect(constructs.count == 3)
    }

    // MARK: - ProvenanceMap

    @Test("Builds provenance map for simple template")
    func buildSimpleProvenanceMap() {
        let builder = ProvenanceBuilder()
        let source = "Hello {{ name }}!"
        let output = "Hello World!"

        let map = builder.buildProvenanceMap(source: source, output: output)

        #expect(!map.spans.isEmpty)

        // Should have spans for: "Hello " (literal), "World" (from output tag), "!" (literal)
        let literals = map.spans(ofKind: .literal)
        #expect(!literals.isEmpty)
    }

    @Test("Source span lookup works")
    func sourceSpanLookup() {
        let spans = [
            RenderSpan(outputRange: 0 ..< 6, sourceRange: 0 ..< 6, nodeKind: .literal),
            RenderSpan(outputRange: 6 ..< 11, sourceRange: 6 ..< 20, nodeKind: .outputTag, sourceDescription: "name"),
            RenderSpan(outputRange: 11 ..< 12, sourceRange: 20 ..< 21, nodeKind: .literal),
        ]
        let map = ProvenanceMap(spans: spans)

        // Lookup in literal region
        let literalSpan = map.sourceSpan(forOutputOffset: 3)
        #expect(literalSpan?.nodeKind == .literal)

        // Lookup in output tag region
        let outputSpan = map.sourceSpan(forOutputOffset: 8)
        #expect(outputSpan?.nodeKind == .outputTag)
    }

    @Test("Output spans for source offset")
    func outputSpansForSource() {
        let spans = [
            RenderSpan(outputRange: 0 ..< 6, sourceRange: 0 ..< 6, nodeKind: .literal),
            RenderSpan(outputRange: 6 ..< 11, sourceRange: 6 ..< 20, nodeKind: .outputTag, sourceDescription: "name"),
        ]
        let map = ProvenanceMap(spans: spans)

        let results = map.outputSpans(forSourceOffset: 10) // Inside {{ name }}
        #expect(results.count == 1)
        #expect(results[0].nodeKind == .outputTag)
    }

    @Test("Liquid generated length calculation")
    func liquidGeneratedLength() {
        let spans = [
            RenderSpan(outputRange: 0 ..< 6, sourceRange: 0 ..< 6, nodeKind: .literal),
            RenderSpan(outputRange: 6 ..< 11, sourceRange: 6 ..< 20, nodeKind: .outputTag),
        ]
        let map = ProvenanceMap(spans: spans)
        #expect(map.liquidGeneratedLength == 5) // Only the output tag contributes
    }

    // MARK: - Integration with LiquidEngine

    @Test("renderWithProvenance produces output and map")
    func renderWithProvenance() async throws {
        let engine = LiquidEngine()
        let (output, provenance) = try await engine.renderWithProvenance(
            template: "Hello {{ name }}!",
            context: ["name": "World"]
        )

        #expect(output == "Hello World!")
        #expect(!provenance.spans.isEmpty)
    }

    @Test("Empty provenance map")
    func emptyMap() {
        let map = ProvenanceMap.empty
        #expect(map.spans.isEmpty)
        #expect(map.liquidGeneratedLength == 0)
        #expect(map.sourceSpan(forOutputOffset: 0) == nil)
    }
}
