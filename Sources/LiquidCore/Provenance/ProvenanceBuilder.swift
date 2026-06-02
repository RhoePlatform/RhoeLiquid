//
//  ProvenanceBuilder.swift
//  LiquidCore
//
//  Created as part of RhoeLiquid
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation

/// Builds a ProvenanceMap by scanning the source template for Liquid constructs
/// and correlating them with the rendered output via content matching.
///
/// This is a post-hoc approach that works without modifications to the AST or Renderer.
/// It scans the source for `{{ }}` and `{% %}` tags, identifies literal regions between them,
/// then maps each region to the rendered output.
public struct ProvenanceBuilder: Sendable {
    public init() {}

    /// Build a provenance map by correlating source template constructs with rendered output.
    ///
    /// - Parameters:
    ///   - source: The original template source text
    ///   - output: The rendered output text
    /// - Returns: A ProvenanceMap with spans covering the output
    public func buildProvenanceMap(source: String, output: String) -> ProvenanceMap {
        let sourceConstructs = scanSourceConstructs(source)
        let spans = correlateWithOutput(
            sourceConstructs: sourceConstructs,
            source: source,
            output: output
        )
        return ProvenanceMap(spans: spans)
    }

    // MARK: - Source Scanning

    public struct SourceConstruct: Sendable {
        public let range: Range<Int>          // byte range in source
        public let kind: ProvenanceNodeKind
        public let content: String            // the raw source text of this construct
        public let innerContent: String?      // content inside delimiters (for tags)
    }

    public func scanSourceConstructs(_ source: String) -> [SourceConstruct] {
        let bytes = Array(source.utf8)
        var constructs: [SourceConstruct] = []
        var position = 0
        var literalStart = 0

        while position < bytes.count {
            // Check for Liquid tag opening
            if position + 1 < bytes.count, bytes[position] == UInt8(ascii: "{") {
                let nextByte = bytes[position + 1]

                if nextByte == UInt8(ascii: "{") || nextByte == UInt8(ascii: "%") {
                    // Record any literal text before this tag
                    if position > literalStart {
                        let literalContent = String(bytes: Array(bytes[literalStart ..< position]), encoding: .utf8) ?? ""
                        constructs.append(SourceConstruct(
                            range: literalStart ..< position,
                            kind: .literal,
                            content: literalContent,
                            innerContent: nil
                        ))
                    }

                    // Find the end of this tag
                    let isOutput = nextByte == UInt8(ascii: "{")
                    let closingPattern: (UInt8, UInt8) = isOutput
                        ? (UInt8(ascii: "}"), UInt8(ascii: "}"))
                        : (UInt8(ascii: "%"), UInt8(ascii: "}"))

                    if let tagEnd = findTagEnd(bytes: bytes, from: position, closing: closingPattern) {
                        let tagRange = position ..< tagEnd
                        let tagContent = String(bytes: Array(bytes[tagRange]), encoding: .utf8) ?? ""
                        let inner = extractInnerContent(tagContent, isOutput: isOutput)
                        let kind = classifyTag(inner: inner, isOutput: isOutput)

                        constructs.append(SourceConstruct(
                            range: tagRange,
                            kind: kind,
                            content: tagContent,
                            innerContent: inner
                        ))

                        position = tagEnd
                        literalStart = tagEnd
                        continue
                    }
                }
            }

            position += 1
        }

        // Trailing literal
        if literalStart < bytes.count {
            let literalContent = String(bytes: Array(bytes[literalStart...]), encoding: .utf8) ?? ""
            constructs.append(SourceConstruct(
                range: literalStart ..< bytes.count,
                kind: .literal,
                content: literalContent,
                innerContent: nil
            ))
        }

        return constructs
    }

    private func findTagEnd(bytes: [UInt8], from start: Int, closing: (UInt8, UInt8)) -> Int? {
        var pos = start + 2 // skip opening {{ or {%

        while pos + 1 < bytes.count {
            // Handle trim markers: -%} or -}}
            if bytes[pos] == closing.0, bytes[pos + 1] == closing.1 {
                return pos + 2
            }
            if bytes[pos] == UInt8(ascii: "-"), pos + 2 < bytes.count,
               bytes[pos + 1] == closing.0, bytes[pos + 2] == closing.1
            {
                return pos + 3
            }
            pos += 1
        }

        return nil
    }

    private func extractInnerContent(_ tag: String, isOutput: Bool) -> String {
        var inner = tag

        // Strip outer delimiters and trim markers
        if isOutput {
            inner = inner.replacingOccurrences(of: "{{-", with: "")
            inner = inner.replacingOccurrences(of: "-}}", with: "")
            inner = inner.replacingOccurrences(of: "{{", with: "")
            inner = inner.replacingOccurrences(of: "}}", with: "")
        } else {
            inner = inner.replacingOccurrences(of: "{%-", with: "")
            inner = inner.replacingOccurrences(of: "-%}", with: "")
            inner = inner.replacingOccurrences(of: "{%", with: "")
            inner = inner.replacingOccurrences(of: "%}", with: "")
        }

        return inner.trimmingCharacters(in: .whitespaces)
    }

    private func classifyTag(inner: String, isOutput: Bool) -> ProvenanceNodeKind {
        if isOutput {
            // Check for filters
            if inner.contains("|") {
                let parts = inner.split(separator: "|")
                if parts.count > 1 {
                    let filterName = parts[1].trimmingCharacters(in: .whitespaces)
                        .components(separatedBy: .whitespaces).first ?? ""
                    return .filter(name: String(filterName))
                }
            }
            return .outputTag
        }

        // Logic tag classification
        let tagName = inner.components(separatedBy: .whitespaces).first ?? ""
        switch tagName {
        case "if", "elsif", "else", "endif", "unless", "endunless",
             "for", "endfor", "break", "continue",
             "case", "when", "endcase",
             "tablerow", "endtablerow",
             "while", "endwhile":
            return .controlFlow(tag: tagName)

        case "assign", "capture", "endcapture", "increment", "decrement":
            return .assignment(tag: tagName)

        case "include", "render":
            let name = inner.replacingOccurrences(of: tagName, with: "")
                .trimmingCharacters(in: .whitespaces)
                .components(separatedBy: .whitespaces).first ?? ""
            return .include(name: name.replacingOccurrences(of: "'", with: "").replacingOccurrences(of: "\"", with: ""))

        case "comment", "endcomment":
            return .comment

        default:
            return .controlFlow(tag: tagName)
        }
    }

    // MARK: - Output Correlation

    private func correlateWithOutput(
        sourceConstructs: [SourceConstruct],
        source _: String,
        output: String
    ) -> [RenderSpan] {
        var spans: [RenderSpan] = []
        var outputPosition = 0
        let outputBytes = Array(output.utf8)

        for construct in sourceConstructs {
            switch construct.kind {
            case .literal:
                // Literal text should appear verbatim in the output
                let literalBytes = Array(construct.content.utf8)
                if outputPosition + literalBytes.count <= outputBytes.count {
                    let outputSlice = Array(outputBytes[outputPosition ..< outputPosition + literalBytes.count])
                    if outputSlice == literalBytes {
                        let outputRange = outputPosition ..< (outputPosition + literalBytes.count)
                        spans.append(RenderSpan(
                            outputRange: outputRange,
                            sourceRange: construct.range,
                            nodeKind: .literal,
                            sourceDescription: nil
                        ))
                        outputPosition += literalBytes.count
                    }
                }

            case .outputTag, .filter:
                // Output tags produce content in the output.
                // Find where the next literal starts to bound the output tag's contribution.
                let nextLiteralContent = findNextLiteral(after: construct, in: sourceConstructs)
                let outputTagEnd: Int

                if let nextLiteral = nextLiteralContent {
                    let nextLiteralBytes = Array(nextLiteral.utf8)
                    if let foundAt = findSubsequence(nextLiteralBytes, in: outputBytes, from: outputPosition) {
                        outputTagEnd = foundAt
                    } else {
                        outputTagEnd = outputBytes.count
                    }
                } else {
                    outputTagEnd = outputBytes.count
                }

                if outputPosition < outputTagEnd {
                    spans.append(RenderSpan(
                        outputRange: outputPosition ..< outputTagEnd,
                        sourceRange: construct.range,
                        nodeKind: construct.kind,
                        sourceDescription: construct.innerContent
                    ))
                    outputPosition = outputTagEnd
                }

            case .controlFlow, .assignment, .include, .comment:
                // Control flow tags don't directly produce output at this position.
                // Their effect is structural (they control what gets rendered).
                // We record them as zero-width spans for source highlighting.
                spans.append(RenderSpan(
                    outputRange: outputPosition ..< outputPosition,
                    sourceRange: construct.range,
                    nodeKind: construct.kind,
                    sourceDescription: construct.innerContent
                ))
            }
        }

        return spans
    }

    private func findNextLiteral(after construct: SourceConstruct, in constructs: [SourceConstruct]) -> String? {
        var found = false
        for c in constructs {
            if found, c.kind == .literal, !c.content.isEmpty {
                return c.content
            }
            if c.range == construct.range {
                found = true
            }
        }
        return nil
    }

    private func findSubsequence(_ needle: [UInt8], in haystack: [UInt8], from start: Int) -> Int? {
        guard !needle.isEmpty, start + needle.count <= haystack.count else { return nil }

        for i in start ... (haystack.count - needle.count) {
            var match = true
            for j in 0 ..< needle.count {
                if haystack[i + j] != needle[j] {
                    match = false
                    break
                }
            }
            if match { return i }
        }
        return nil
    }
}
