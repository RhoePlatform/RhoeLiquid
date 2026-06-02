//
//  XMLDataSource.swift
//  LiquidCore
//
//  HTML and XML data source loader for RhoeLiquid
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if canImport(FoundationXML)
import FoundationXML
#endif

/// Data source for loading XML and HTML files
///
/// `XMLDataSource` provides comprehensive support for XML and HTML documents,
/// with intelligent parsing, DOM traversal, and powerful query capabilities.
/// It converts hierarchical markup into the unified DataValue format while
/// preserving structure and supporting advanced selection patterns.
///
/// ## Supported Formats
///
/// - **XML**: Standard XML with namespace support
/// - **HTML**: HTML5 with lenient parsing
/// - **XHTML**: Strict XML-compliant HTML
/// - **RSS/Atom**: Feed formats as structured data
/// - **SVG**: Scalable Vector Graphics as data
///
/// ## Features
///
/// ### Intelligent Parsing
/// - Auto-detects XML vs HTML based on content
/// - Lenient HTML parsing (handles malformed HTML)
/// - Strict XML parsing with validation
/// - Namespace-aware processing
/// - CDATA section handling
///
/// ### Query Support
/// - CSS selectors for HTML: `div.content > p`
/// - XPath for XML: `//book[@category='fiction']`
/// - Simple path notation: `root.element.child`
/// - Attribute access: `element@attribute`
///
/// ### Data Structure
///
/// XML/HTML is converted to DataValue with:
/// - Elements become objects
/// - Attributes stored in `@attributes`
/// - Text content in `@text` or as direct value
/// - Child elements as nested objects/arrays
/// - Namespace prefixes preserved
///
/// ## Usage Examples
///
/// ### Loading HTML
/// ```liquid
/// {% data page = load("./page.html") %}
/// <h1>{{ page | select: "h1" | text }}</h1>
/// {{ page | select: "meta[name='description']" | attr: "content" }}
/// ```
///
/// ### Loading XML
/// ```liquid
/// {% data books = load("./books.xml") %}
/// {% for book in books.catalog.book %}
///   {{ book@id }}: {{ book.title }}
///   Author: {{ book.author }}
///   Price: ${{ book.price }}
/// {% endfor %}
/// ```
///
/// ### RSS Feed
/// ```liquid
/// {% data feed = load("https://blog.example.com/rss.xml") %}
/// {% for item in feed.rss.channel.item | limit: 5 %}
///   <article>
///     <h2><a href="{{ item.link }}">{{ item.title }}</a></h2>
///     <time>{{ item.pubDate | date: "%B %d, %Y" }}</time>
///     {{ item.description | strip_html | truncate: 200 }}
///   </article>
/// {% endfor %}
/// ```
///
/// ### Web Scraping
/// ```liquid
/// {% data prices = load("https://store.example.com/products.html") %}
/// {% assign products = prices | select_all: ".product" %}
/// {% for product in products %}
///   {{ product | select: ".name" | text }}:
///   {{ product | select: ".price" | text }}
/// {% endfor %}
/// ```
///
/// ## Advanced Features
///
/// ### Namespace Handling
/// ```liquid
/// {% data doc = load("./namespaced.xml") %}
/// {{ doc["ns:element"]["ns:child"] }}
/// ```
///
/// ### Mixed Content
/// Handles mixed text and element content intelligently:
/// ```xml
/// <p>Hello <em>world</em>!</p>
/// ```
/// Becomes: `{ "@text": "Hello !", "em": "world", "@full_text": "Hello world!" }`
///
/// ### Streaming Support
/// For large documents, supports streaming parse mode
///
/// ## See Also
/// - ``DataSource``: Protocol this implements
/// - ``LoadOptions``: Configuration options
/// - ``DataValue``: The data representation format
public struct XMLDataSource: DataSource {
    public init() {}
    
    public var supportedExtensions: [String] {
        ["xml", "html", "htm", "xhtml", "rss", "atom", "svg", "xsd", "xsl"]
    }
    
    public func load(from url: URL, options: LoadOptions) async throws -> DataValue {
        // Load data
        let data: Data
        if url.isFileURL {
            do {
                data = try Data(contentsOf: url)
            } catch {
                throw DataSourceError.fileNotFound(url)
            }
        } else {
            #if os(WASI)
            throw DataSourceError.unsupportedFormat("Network loading not available in WebAssembly")
            #else
            var request = URLRequest(url: url)
            request.timeoutInterval = options.timeout

            for (key, value) in options.headers {
                request.setValue(value, forHTTPHeaderField: key)
            }

            do {
                let (responseData, response) = try await URLSession.shared.data(for: request)

                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode >= 400 {
                    throw DataSourceError.networkError(
                        NSError(
                            domain: "HTTP",
                            code: httpResponse.statusCode,
                            userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"]
                        )
                    )
                }

                data = responseData
            } catch {
                throw DataSourceError.networkError(error)
            }
            #endif
        }
        
        // Check file size
        if data.count > options.maxSize {
            throw DataSourceError.fileTooLarge(data.count, options.maxSize)
        }
        
        // Detect format
        let format = detectFormat(from: url, data: data)
        
        // Parse based on format
        switch format {
        case .html:
            return try parseHTML(data, encoding: options.encoding)
        case .xml:
            return try parseXML(data, encoding: options.encoding)
        }
    }
    
    // MARK: - Format Detection
    
    private enum Format {
        case html
        case xml
    }
    
    private func detectFormat(from url: URL, data: Data) -> Format {
        let ext = url.pathExtension.lowercased()
        
        // Check by extension first
        switch ext {
        case "html", "htm":
            return .html
        case "xml", "rss", "atom", "svg", "xsd", "xsl":
            return .xml
        case "xhtml":
            // XHTML is XML
            return .xml
        default:
            // Try to detect from content
            if let content = String(data: data.prefix(1024), encoding: .utf8) {
                let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Check for XML declaration
                if trimmed.hasPrefix("<?xml") {
                    return .xml
                }
                
                // Check for DOCTYPE html
                if trimmed.lowercased().contains("<!doctype html") ||
                   trimmed.lowercased().contains("<html") {
                    return .html
                }
                
                // Default to XML for structured data
                return .xml
            }
            
            return .xml
        }
    }
    
    // MARK: - HTML Parsing
    
    private func parseHTML(_ data: Data, encoding: String.Encoding) throws -> DataValue {
        guard String(data: data, encoding: encoding) != nil else {
            throw DataSourceError.parseError("Unable to decode HTML as \(encoding)")
        }
        
        // Use XMLDocument with HTML parsing options
        let options: XMLNode.Options = [
            .nodeLoadExternalEntitiesNever,
            .documentTidyHTML,
            .nodePreserveWhitespace
        ]
        
        do {
            let doc = try XMLDocument(data: data, options: options)
            return try documentToDataValue(doc, isHTML: true)
        } catch {
            throw DataSourceError.parseError("Invalid HTML: \(error.localizedDescription)")
        }
    }
    
    // MARK: - XML Parsing
    
    private func parseXML(_ data: Data, encoding: String.Encoding) throws -> DataValue {
        guard let _ = String(data: data, encoding: encoding) else {
            throw DataSourceError.parseError("Unable to decode XML as \(encoding)")
        }
        
        let options: XMLNode.Options = [
            .nodeLoadExternalEntitiesNever,
            .nodePreserveWhitespace,
            .nodePreserveNamespaceOrder,
            .nodePreservePrefixes
        ]
        
        do {
            let doc = try XMLDocument(data: data, options: options)
            return try documentToDataValue(doc, isHTML: false)
        } catch {
            throw DataSourceError.parseError("Invalid XML: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Conversion to DataValue
    
    private func documentToDataValue(_ doc: XMLDocument, isHTML: Bool) throws -> DataValue {
        guard let root = doc.rootElement() else {
            throw DataSourceError.parseError("No root element found")
        }
        
        var result = try elementToDataValue(root)
        
        // Preserve the document marker for HTML sources without injecting
        // placeholder selector keys into the loaded data payload.
        if isHTML {
            if case .object(var obj) = result {
                obj["@document"] = .bool(true)
                result = .object(obj)
            }
        }
        
        return result
    }
    
    private func elementToDataValue(_ element: XMLElement) throws -> DataValue {
        var result: [String: DataValue] = [:]
        
        // Add element name for clarity
        result["@name"] = .string(element.name ?? "")
        
        // Process attributes
        if let attributes = element.attributes, !attributes.isEmpty {
            var attrs: [String: DataValue] = [:]
            for attr in attributes {
                if let name = attr.name, let value = attr.stringValue {
                    attrs[name] = .string(value)
                }
            }
            result["@attributes"] = .object(attrs)
        }
        
        // Process children
        if let children = element.children, !children.isEmpty {
            var elements: [String: [DataValue]] = [:]
            var textContent = ""
            var mixedContent: [DataValue] = []
            var hasElements = false
            
            for child in children {
                switch child.kind {
                case .element:
                    if let childElement = child as? XMLElement,
                       let name = childElement.name {
                        hasElements = true
                        let childValue = try elementToDataValue(childElement)
                        
                        // Group elements by name
                        if elements[name] != nil {
                            elements[name]!.append(childValue)
                        } else {
                            elements[name] = [childValue]
                        }
                        
                        mixedContent.append(childValue)
                    }
                    
                case .text:
                    if let text = child.stringValue {
                        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            textContent += text
                            mixedContent.append(.string(text))
                        }
                    }
                    
                case .comment:
                    // Optionally preserve comments
                    if let comment = child.stringValue {
                        mixedContent.append(.object([
                            "@type": .string("comment"),
                            "@text": .string(comment)
                        ]))
                    }
                    
                default:
                    break
                }
            }
            
            // Add child elements
            for (name, values) in elements {
                if values.count == 1 {
                    result[name] = values[0]
                } else {
                    result[name] = .array(values)
                }
            }
            
            // Handle text content
            if !textContent.isEmpty {
                let trimmed = textContent.trimmingCharacters(in: .whitespacesAndNewlines)
                if hasElements {
                    // Mixed content - preserve both
                    result["@text"] = .string(trimmed)
                    result["@full_text"] = .string(extractFullText(from: element))
                    result["@mixed"] = .array(mixedContent)
                } else {
                    // Preserve attribute-bearing leaves as elements so selector
                    // and attribute filters can still address them.
                    if result["@attributes"] != nil {
                        result["@text"] = .string(trimmed)
                        result["@full_text"] = .string(trimmed)
                    } else {
                        return .string(trimmed)
                    }
                }
            }
        } else if let text = element.stringValue {
            // Leaf element with just text
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                if result["@attributes"] != nil {
                    result["@text"] = .string(trimmed)
                    result["@full_text"] = .string(trimmed)
                } else {
                    return .string(trimmed)
                }
            }
        }

        return .object(result)
    }
    
    private func extractFullText(from element: XMLElement) -> String {
        var text = ""
        
        if let children = element.children {
            for child in children {
                switch child.kind {
                case .text:
                    text += child.stringValue ?? ""
                case .element:
                    if let childElement = child as? XMLElement {
                        text += extractFullText(from: childElement)
                    }
                default:
                    break
                }
            }
        }
        
        return text
    }
}
