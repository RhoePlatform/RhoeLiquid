//
//  HighlightTag.swift
//  LiquidTags
//
//  Created as part of RhoeLiquid
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import LiquidCore

/// Custom tag for syntax highlighting code blocks with CSS-class-based markup.
///
/// Generates HTML with semantic CSS classes suitable for client-side or
/// server-side highlighting themes.
///
/// ## Usage
///
/// ```liquid
/// {% highlight swift %}
/// func hello() {
///     print("Hello, World!")
/// }
/// {% endhighlight %}
/// ```
///
/// ```liquid
/// {% highlight python linenos linenostart=10 hl_lines=1,3-5 %}
/// def greet(name):
///     message = f"Hello, {name}!"
///     print(message)
///     return message
/// {% endhighlight %}
/// ```
///
/// ## Parameters
/// - `language`: Programming language for highlighting (required)
/// - `linenos`: Show line numbers (flag, no value needed)
/// - `linenostart`: Starting line number (default: 1)
/// - `hl_lines`: Lines to highlight, e.g. "1,3-5"
public struct HighlightTag: CustomTag {
    public let name = "highlight"
    public let type = TagType.block
    public let allowsNesting = false

    /// Languages accepted by the tag. Unknown languages are rejected at parse time.
    private static let supportedLanguages: Set<String> = [
        "swift", "objc", "c", "cpp", "cxx", "c++",
        "python", "py", "javascript", "js", "typescript", "ts",
        "java", "kotlin", "go", "rust", "ruby", "rb",
        "php", "html", "xml", "css", "scss", "sass",
        "json", "yaml", "yml", "toml", "ini",
        "bash", "sh", "zsh", "fish",
        "sql", "markdown", "md", "text", "plain",
        "r", "lua", "perl", "elixir", "haskell", "scala",
        "dart", "dockerfile", "makefile", "graphql",
    ]

    public init() {}

    public func parse(_ parameters: String, context: TagParsingContext) async throws -> TagParameters {
        let trimmed = parameters.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(separator: " ").map(String.init)

        guard let first = parts.first else {
            throw TagParsingError.missingRequiredParameter("language")
        }

        let language = first.lowercased()
        guard Self.supportedLanguages.contains(language) else {
            throw TagParsingError.invalidParameterValue(
                "language",
                expected: "supported language (e.g. swift, python, javascript)"
            )
        }

        var params: [String: Any] = ["language": language]
        var lineNumbers = false
        var lineNumberStart = 1
        var highlightLines: [Int] = []

        for i in 1 ..< parts.count {
            let part = parts[i]

            if part == "linenos" {
                lineNumbers = true
            } else if part.hasPrefix("linenostart=") {
                let raw = String(part.dropFirst("linenostart=".count))
                guard let start = Int(raw), start > 0 else {
                    throw TagParsingError.invalidParameterValue("linenostart", expected: "positive integer")
                }
                lineNumberStart = start
            } else if part.hasPrefix("hl_lines=") {
                let raw = String(part.dropFirst("hl_lines=".count))
                highlightLines = try parseHighlightLines(raw)
            }
        }

        params["line_numbers"] = lineNumbers
        params["line_number_start"] = lineNumberStart
        params["highlight_lines"] = highlightLines

        return TagParameters(params)
    }

    public func execute(parameters: TagParameters, content: String?, context: TagExecutionContext) async throws -> String {
        guard let code = content?.trimmingCharacters(in: .whitespacesAndNewlines), !code.isEmpty else {
            return ""
        }

        let language: String = try parameters.require("language")
        let lineNumbers: Bool = parameters.get("line_numbers", default: false)
        let lineNumberStart: Int = parameters.get("line_number_start", default: 1)
        let highlightLines: [Int] = parameters.get("highlight_lines", default: [])

        return buildHighlightHTML(
            code: code,
            language: language,
            showLineNumbers: lineNumbers,
            startingLineNumber: lineNumberStart,
            highlightLines: Set(highlightLines)
        )
    }

    // MARK: - Private Helpers

    /// Parses a comma-separated list of line numbers and ranges (e.g. "1,3-5,8").
    private func parseHighlightLines(_ value: String) throws -> [Int] {
        var lines: [Int] = []
        let segments = value.split(separator: ",")

        for segment in segments {
            let trimmed = segment.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmed.contains("-") {
                let parts = trimmed.split(separator: "-")
                guard parts.count == 2,
                      let start = Int(parts[0]),
                      let end = Int(parts[1]),
                      start > 0, start <= end
                else {
                    throw TagParsingError.invalidParameterValue("hl_lines", expected: "valid range (e.g. 3-5)")
                }
                lines.append(contentsOf: start ... end)
            } else {
                guard let line = Int(trimmed), line > 0 else {
                    throw TagParsingError.invalidParameterValue("hl_lines", expected: "positive integer")
                }
                lines.append(line)
            }
        }

        return lines.sorted()
    }

    /// Generates the HTML output for a highlighted code block.
    private func buildHighlightHTML(
        code: String,
        language: String,
        showLineNumbers: Bool,
        startingLineNumber: Int,
        highlightLines: Set<Int>
    ) -> String {
        let lines = code.components(separatedBy: "\n")
        var parts: [String] = []

        parts.append("<div class=\"highlight\">")
        parts.append("<pre class=\"highlight-\(language)\">")
        parts.append("<code>")

        for (index, line) in lines.enumerated() {
            let lineNumber = startingLineNumber + index
            let isHighlighted = highlightLines.contains(lineNumber)

            if showLineNumbers {
                let hlClass = isHighlighted ? " highlight-line" : ""
                parts.append("<span class=\"line\(hlClass)\">")
                parts.append("<span class=\"line-number\">\(lineNumber)</span>")
                parts.append("<span class=\"line-content\">\(escapeHTML(line))</span>")
                parts.append("</span>")
            } else if isHighlighted {
                parts.append("<span class=\"highlight-line\">\(escapeHTML(line))</span>")
            } else {
                parts.append(escapeHTML(line))
            }

            if index < lines.count - 1 {
                parts.append("\n")
            }
        }

        parts.append("</code>")
        parts.append("</pre>")
        parts.append("</div>")

        return parts.joined()
    }

    /// Minimal HTML entity escaping for code content.
    private func escapeHTML(_ text: String) -> String {
        var result = text
        // Order matters: ampersand first to avoid double-escaping.
        result = result.replacingOccurrences(of: "&", with: "&amp;")
        result = result.replacingOccurrences(of: "<", with: "&lt;")
        result = result.replacingOccurrences(of: ">", with: "&gt;")
        result = result.replacingOccurrences(of: "\"", with: "&quot;")
        result = result.replacingOccurrences(of: "'", with: "&#x27;")
        return result
    }
}
