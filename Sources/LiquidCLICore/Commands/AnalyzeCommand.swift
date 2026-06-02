//
//  AnalyzeCommand.swift
//  LiquidCLICore
//
//  Created as part of RhoeLiquid
//  A high-performance Swift implementation of the Liquid template language
//

import ArgumentParser
import Foundation
import RhoeLiquid

public struct AnalyzeCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "analyze",
        abstract: "Analyze template structure and complexity.",
        discussion: """
        Scans a template without rendering it and reports structural metrics such \
        as variable count, tag usage, filters, and a simple complexity estimate.
        """
    )

    @Argument(
        help: "Template file path.",
        completion: .file(extensions: ["liquid", "html"])
    )
    public var template: String

    @Option(
        name: .long,
        help: "Output format: terminal, json, or markdown.",
        completion: OutputFormat.completion
    )
    public var format: OutputFormat = .terminal

    public init() {}

    public func run() async throws {
        guard FileManager.default.fileExists(atPath: template) else {
            TerminalUI.error("Template not found: \(template)")
            throw ExitCode.failure
        }

        let source = try String(contentsOfFile: template, encoding: .utf8)
        let analysis = analyzeTemplate(source)

        switch format {
        case .json:
            printJSON(analysis)
        case .markdown:
            printMarkdown(analysis)
        case .terminal:
            printTerminal(analysis)
        }
    }

    // Template analysis using regex pattern matching on template source
    private func analyzeTemplate(_ source: String) -> TemplateAnalysis {
        let lines = source.components(separatedBy: "\n")
        // Count template constructs via pattern matching
        let tagPattern = /\{%[-]?\s*(\w+)/
        let variablePattern = /\{\{/
        let filterPattern = /\|\s*(\w+)/
        let commentPattern = /\{%[-]?\s*comment/

        var tagCounts: [String: Int] = [:]
        var filterNames: Set<String> = []
        var variableCount = 0
        var commentCount = 0

        for line in lines {
            // Count variables
            let varMatches = line.matches(of: variablePattern)
            variableCount += varMatches.count

            // Count tags
            for match in line.matches(of: tagPattern) {
                let tag = String(match.1)
                tagCounts[tag, default: 0] += 1
                if tag == "comment" { commentCount += 1 }
            }

            // Collect filter names
            for match in line.matches(of: filterPattern) {
                filterNames.insert(String(match.1))
            }
        }

        // Use commentPattern to suppress unused variable warning
        _ = commentPattern

        // Complexity scoring
        let nestingDepth = max(
            tagCounts["if", default: 0],
            tagCounts["for", default: 0],
            tagCounts["case", default: 0]
        )
        let complexity: String
        let totalTags = tagCounts.values.reduce(0, +)
        if totalTags > 50 || nestingDepth > 5 { complexity = "high" }
        else if totalTags > 20 || nestingDepth > 3 { complexity = "medium" }
        else { complexity = "low" }

        return TemplateAnalysis(
            fileName: (template as NSString).lastPathComponent,
            lineCount: lines.count,
            byteSize: source.utf8.count,
            variableCount: variableCount,
            tagCounts: tagCounts,
            filterNames: Array(filterNames).sorted(),
            commentCount: commentCount,
            complexity: complexity,
            nestingDepth: nestingDepth
        )
    }

    private func printTerminal(_ a: TemplateAnalysis) {
        TerminalUI.header("Template Analysis: \(a.fileName)")
        print("  Lines: \(a.lineCount)")
        print("  Size: \(TerminalUI.fileSize(a.byteSize))")
        print("  Variables: \(a.variableCount)")
        print("  Complexity: \(a.complexity)")
        print("  Max nesting: \(a.nestingDepth)")

        if !a.tagCounts.isEmpty {
            TerminalUI.header("Tags")
            for (tag, count) in a.tagCounts.sorted(by: { $0.value > $1.value }) {
                print("  \(tag): \(count)")
            }
        }
        if !a.filterNames.isEmpty {
            TerminalUI.header("Filters")
            print("  \(a.filterNames.joined(separator: ", "))")
        }
    }

    private func printJSON(_ a: TemplateAnalysis) {
        let dict: [String: Any] = [
            "fileName": a.fileName,
            "lineCount": a.lineCount,
            "byteSize": a.byteSize,
            "variableCount": a.variableCount,
            "tags": a.tagCounts,
            "filters": a.filterNames,
            "complexity": a.complexity,
            "nestingDepth": a.nestingDepth,
        ]
        if let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
           let json = String(data: data, encoding: .utf8)
        {
            print(json)
        }
    }

    private func printMarkdown(_ a: TemplateAnalysis) {
        print("# Template Analysis: \(a.fileName)\n")
        print("| Metric | Value |")
        print("|--------|-------|")
        print("| Lines | \(a.lineCount) |")
        print("| Size | \(TerminalUI.fileSize(a.byteSize)) |")
        print("| Variables | \(a.variableCount) |")
        print("| Complexity | \(a.complexity) |")
        print("| Max Nesting | \(a.nestingDepth) |")
        if !a.filterNames.isEmpty {
            print("\n## Filters\n\n\(a.filterNames.joined(separator: ", "))")
        }
    }
}

struct TemplateAnalysis {
    let fileName: String
    let lineCount: Int
    let byteSize: Int
    let variableCount: Int
    let tagCounts: [String: Int]
    let filterNames: [String]
    let commentCount: Int
    let complexity: String
    let nestingDepth: Int
}
