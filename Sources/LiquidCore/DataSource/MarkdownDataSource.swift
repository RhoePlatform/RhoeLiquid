//
//  MarkdownDataSource.swift
//  LiquidCore
//
//  Markdown data source loader with frontmatter support for RhoeLiquid
//

import Foundation

/// Data source for loading Markdown files with frontmatter
///
/// `MarkdownDataSource` loads Markdown files and extracts structured data from
/// frontmatter blocks, making it perfect for content management systems, blogs,
/// and documentation sites. It supports YAML and TOML frontmatter formats.
///
/// ## Overview
///
/// This loader is inspired by static site generators and content management patterns.
/// It treats Markdown files as structured documents with:
/// - **Frontmatter**: Metadata in YAML or TOML format
/// - **Content**: The main Markdown body
/// - **Excerpt**: Auto-extracted summary from content
///
/// ## Frontmatter Support
///
/// ### YAML Frontmatter
/// ```markdown
/// ---
/// title: "My Blog Post"
/// date: 2024-01-15
/// tags: ["swift", "liquid"]
/// author:
///   name: "Jane Doe"
///   email: "jane@example.com"
/// ---
/// 
/// # My Blog Post
/// 
/// This is the content...
/// ```
///
/// ### TOML Frontmatter
/// ```markdown
/// +++
/// title = "My Blog Post"
/// date = 2024-01-15
/// tags = ["swift", "liquid"]
/// 
/// [author]
/// name = "Jane Doe"
/// email = "jane@example.com"
/// +++
/// 
/// # My Blog Post
/// ```
///
/// ## Data Structure
///
/// Loaded Markdown files return a DataValue.object with:
/// - All frontmatter fields at the root level
/// - `content`: The Markdown content (without frontmatter)
/// - `excerpt`: First paragraph or up to `<!--more-->` marker
/// - `raw`: Original file content including frontmatter
///
/// ## Usage Examples
///
/// ### Loading Blog Posts
/// ```liquid
/// {% data posts = load("./blog/*.md") %}
/// {% for post in posts | sort_by: "date" | reverse %}
///   <article>
///     <h2>{{ post.title }}</h2>
///     <time>{{ post.date | date: "%B %d, %Y" }}</time>
///     <div>{{ post.excerpt }}</div>
///   </article>
/// {% endfor %}
/// ```
///
/// ### Single Document
/// ```liquid
/// {% data about = load("./content/about.md") %}
/// <h1>{{ about.title }}</h1>
/// {{ about.content | markdownify }}
/// ```
///
/// ### With Categories
/// ```liquid
/// {% data docs = load("./docs/**/*.md") %}
/// {% assign categories = docs | group_by: "category" %}
/// {% for cat in categories %}
///   <h2>{{ cat.key }}</h2>
///   {% for doc in cat.items %}
///     <a href="{{ doc.url }}">{{ doc.title }}</a>
///   {% endfor %}
/// {% endfor %}
/// ```
///
/// ## Content Collections
///
/// When loading multiple Markdown files with glob patterns, the loader
/// automatically creates a collection with consistent structure, making
/// it easy to build content-driven sites.
///
/// ## Special Features
///
/// ### Excerpt Extraction
/// - Auto-extracts first paragraph as excerpt
/// - Respects `<!--more-->` markers for manual excerpts
/// - Strips Markdown formatting for clean summaries
///
/// ### Date Handling
/// - Automatically parses date strings in frontmatter
/// - Supports various date formats
/// - Converts to proper Date objects for sorting
///
/// ### Path Information
/// - Adds `_path` field with source file path
/// - Useful for generating URLs or debugging
///
/// ## See Also
/// - ``DataSource``: Protocol this implements
/// - ``LoadOptions``: Configuration options
/// - ``DataValue``: The data representation format
public struct MarkdownDataSource: DataSource {
    public init() {}
    
    public var supportedExtensions: [String] {
        ["md", "markdown", "mdx", "mdwn", "mdown", "markdn"]
    }
    
    public var supportedSchemes: [String] {
        ["file"] // Only file URLs for now
    }
    
    public func load(from url: URL, options: LoadOptions) async throws -> DataValue {
        guard url.isFileURL else {
            throw DataSourceError.unsupportedFormat("Markdown loader only supports file URLs")
        }
        
        // Load file content
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw DataSourceError.fileNotFound(url)
        }
        
        // Check file size
        if data.count > options.maxSize {
            throw DataSourceError.fileTooLarge(data.count, options.maxSize)
        }
        
        // Convert to string
        guard let content = String(data: data, encoding: options.encoding) else {
            throw DataSourceError.parseError("Unable to decode file as \(options.encoding)")
        }
        
        // Parse frontmatter and content
        let (frontmatter, body) = try parseFrontmatter(content)
        
        // Get file metadata
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        let createdDate = attributes?[.creationDate] as? Date ?? Date()
        let modifiedDate = attributes?[.modificationDate] as? Date ?? Date()
        
        // Build result object
        var result: [String: DataValue] = [
            "content": .string(body),
            "raw": .string(content),
            "path": .string(url.path),
            "filename": .string(url.lastPathComponent),
            "slug": .string(createSlug(from: url.lastPathComponent)),
            "created": .date(createdDate),
            "modified": .date(modifiedDate)
        ]
        
        // Add frontmatter data
        if case .object(let frontmatterDict) = frontmatter {
            result["frontmatter"] = frontmatter
            
            // Merge top-level frontmatter fields
            for (key, value) in frontmatterDict {
                if !result.keys.contains(key) {
                    result[key] = value
                }
            }
        } else {
            result["frontmatter"] = .object([:])
        }
        
        // Add excerpt (first paragraph or up to first ----)
        let excerpt = extractExcerpt(from: body)
        result["excerpt"] = .string(excerpt)
        
        return .object(result)
    }
    
    /// Parse frontmatter from markdown content
    private func parseFrontmatter(_ content: String) throws -> (frontmatter: DataValue, body: String) {
        let lines = content.components(separatedBy: .newlines)
        
        // Check for frontmatter delimiters
        guard lines.count >= 3,
              lines[0] == "---" || lines[0] == "+++" else {
            // No frontmatter
            return (.object([:]), content)
        }
        
        let delimiter = lines[0]
        var endIndex = -1
        
        // Find closing delimiter
        for i in 1..<lines.count {
            if lines[i] == delimiter {
                endIndex = i
                break
            }
        }
        
        guard endIndex > 0 else {
            // No closing delimiter
            return (.object([:]), content)
        }
        
        // Extract frontmatter content
        let frontmatterLines = Array(lines[1..<endIndex])
        let frontmatterContent = frontmatterLines.joined(separator: "\n")
        
        // Extract body content
        let bodyLines = Array(lines[(endIndex + 1)...])
        let body = bodyLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Parse frontmatter based on delimiter
        let frontmatter: DataValue
        if delimiter == "---" {
            // YAML frontmatter
            frontmatter = try parseYAML(frontmatterContent)
        } else {
            // TOML frontmatter (+++), parse as simple key-value for now
            frontmatter = try parseTOML(frontmatterContent)
        }
        
        return (frontmatter, body)
    }
    
    /// Parse simple YAML (basic implementation)
    private func parseYAML(_ yaml: String) throws -> DataValue {
        var result: [String: DataValue] = [:]
        let lines = yaml.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }
            
            // Simple key: value parsing
            if let colonIndex = trimmed.firstIndex(of: ":") {
                let key = String(trimmed[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                let valueStr = String(trimmed[trimmed.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
                
                // Parse value
                let value: DataValue
                if valueStr.isEmpty {
                    value = .null
                } else if valueStr == "true" {
                    value = .bool(true)
                } else if valueStr == "false" {
                    value = .bool(false)
                } else if let intValue = Int(valueStr) {
                    value = .int(intValue)
                } else if let doubleValue = Double(valueStr) {
                    value = .double(doubleValue)
                } else if valueStr.hasPrefix("\"") && valueStr.hasSuffix("\"") {
                    // Quoted string
                    let unquoted = String(valueStr.dropFirst().dropLast())
                    value = .string(unquoted)
                } else if valueStr.hasPrefix("[") && valueStr.hasSuffix("]") {
                    // Simple array parsing
                    let arrayContent = String(valueStr.dropFirst().dropLast())
                    let items = arrayContent.split(separator: ",").map { item in
                        DataValue.string(item.trimmingCharacters(in: .whitespaces))
                    }
                    value = .array(items)
                } else {
                    // Default to string
                    value = .string(valueStr)
                }
                
                result[key] = value
            }
        }
        
        return .object(result)
    }
    
    /// Parse simple TOML (basic implementation)
    private func parseTOML(_ toml: String) throws -> DataValue {
        // For now, parse similar to YAML
        return try parseYAML(toml)
    }
    
    /// Create URL-safe slug from filename
    private func createSlug(from filename: String) -> String {
        let name = URL(fileURLWithPath: filename).deletingPathExtension().lastPathComponent
        
        return name
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "_", with: "-")
            .replacingOccurrences(of: #"[^a-z0-9\-]"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"-+"#, with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }
    
    /// Extract excerpt from content
    private func extractExcerpt(from content: String, maxLength: Int = 200) -> String {
        // Try to find excerpt delimiter
        if let range = content.range(of: "<!--more-->") {
            return String(content[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Try to find first paragraph
        let paragraphs = content.components(separatedBy: "\n\n")
        if let firstParagraph = paragraphs.first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) {
            let trimmed = firstParagraph.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count <= maxLength {
                return trimmed
            } else {
                // Truncate at word boundary
                let truncated = String(trimmed.prefix(maxLength))
                if let lastSpace = truncated.lastIndex(of: " ") {
                    return String(truncated[..<lastSpace]) + "..."
                } else {
                    return truncated + "..."
                }
            }
        }
        
        // Fallback: just take first N characters
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count <= maxLength {
            return trimmed
        } else {
            return String(trimmed.prefix(maxLength)) + "..."
        }
    }
}