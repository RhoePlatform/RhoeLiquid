//
//  CustomXMLParts.swift
//  RhoeDOCX
//
//  Complete custom XML parts system for WordprocessingML documents
//  Handles custom XML storage, data binding, and schema validation
//

import Foundation

/// Custom XML parts manager for DOCX documents
public actor CustomXMLPartsManager: Sendable {
    
    /// All custom XML parts indexed by ID
    private var xmlParts: [String: WMLCustomXMLPart] = [:]
    
    /// Custom XML properties indexed by part ID
    private var xmlProperties: [String: WMLCustomXMLProperties] = [:]
    
    /// Schema library for validation
    private var schemaLibrary: [String: XMLSchema] = [:]
    
    /// Next available part ID
    private var nextPartId: Int = 1
    
    /// Custom XML statistics
    private var statistics = CustomXMLStatistics()
    
    public init() {}
    
    // MARK: - Custom XML Parts Management
    
    /// Add custom XML part
    public func addCustomXMLPart(_ part: WMLCustomXMLPart) {
        xmlParts[part.partId] = part
        updateStatistics()
    }
    
    /// Create custom XML part with auto-generated ID
    public func createCustomXMLPart(
        xmlContent: String,
        schemaReferences: [WMLSchemaReference] = [],
        namespaces: [String: String] = [:]
    ) throws -> WMLCustomXMLPart {
        let partId = "customXml\(nextPartId)"
        nextPartId += 1
        
        // Validate XML content
        guard isValidXML(xmlContent) else {
            throw CustomXMLError.invalidXMLContent(partId)
        }
        
        let part = WMLCustomXMLPart(
            partId: partId,
            xmlContent: xmlContent,
            schemaReferences: schemaReferences,
            namespaces: namespaces
        )
        
        addCustomXMLPart(part)
        return part
    }
    
    /// Get custom XML part by ID
    public func getCustomXMLPart(id: String) -> WMLCustomXMLPart? {
        return xmlParts[id]
    }
    
    /// Get all custom XML parts
    public func getAllCustomXMLParts() -> [WMLCustomXMLPart] {
        return Array(xmlParts.values)
    }
    
    /// Remove custom XML part
    public func removeCustomXMLPart(id: String) -> WMLCustomXMLPart? {
        let removed = xmlParts.removeValue(forKey: id)
        xmlProperties.removeValue(forKey: id)
        if removed != nil {
            updateStatistics()
        }
        return removed
    }
    
    /// Update custom XML part content
    public func updateCustomXMLPart(id: String, xmlContent: String) throws -> Bool {
        guard var part = xmlParts[id] else { return false }
        
        // Validate new XML content
        guard isValidXML(xmlContent) else {
            throw CustomXMLError.invalidXMLContent(id)
        }
        
        part = WMLCustomXMLPart(
            partId: part.partId,
            xmlContent: xmlContent,
            schemaReferences: part.schemaReferences,
            namespaces: part.namespaces
        )
        
        xmlParts[id] = part
        updateStatistics()
        return true
    }
    
    // MARK: - Custom XML Properties Management
    
    /// Set properties for custom XML part
    public func setCustomXMLProperties(partId: String, properties: WMLCustomXMLProperties) {
        xmlProperties[partId] = properties
        updateStatistics()
    }
    
    /// Get properties for custom XML part
    public func getCustomXMLProperties(partId: String) -> WMLCustomXMLProperties? {
        return xmlProperties[partId]
    }
    
    /// Create standard custom XML properties
    public func createCustomXMLProperties(
        partId: String,
        schemaReferences: [WMLSchemaReference] = [],
        dataStoreItemId: String? = nil
    ) -> WMLCustomXMLProperties {
        let properties = WMLCustomXMLProperties(
            schemaReferences: schemaReferences,
            dataStoreItemId: dataStoreItemId ?? UUID().uuidString
        )
        
        setCustomXMLProperties(partId: partId, properties: properties)
        return properties
    }
    
    // MARK: - Schema Management
    
    /// Add XML schema to library
    public func addSchema(_ schema: XMLSchema) {
        schemaLibrary[schema.targetNamespace] = schema
        updateStatistics()
    }
    
    /// Get schema by namespace
    public func getSchema(namespace: String) -> XMLSchema? {
        return schemaLibrary[namespace]
    }
    
    /// Validate XML part against schema
    public func validateXMLPart(id: String) throws -> XMLValidationResult {
        guard let part = xmlParts[id] else {
            throw CustomXMLError.partNotFound(id)
        }
        
        var errors: [XMLValidationError] = []
        var warnings: [XMLValidationWarning] = []
        
        // Basic XML well-formedness check
        if !isValidXML(part.xmlContent) {
            errors.append(XMLValidationError.malformedXML(part.partId, "XML is not well-formed"))
        }
        
        // Schema validation if references exist
        for schemaRef in part.schemaReferences {
            if let schema = schemaLibrary[schemaRef.uri] {
                let schemaResult = validateAgainstSchema(part.xmlContent, schema: schema)
                errors.append(contentsOf: schemaResult.errors)
                warnings.append(contentsOf: schemaResult.warnings)
            } else {
                warnings.append(XMLValidationWarning.schemaNotFound(schemaRef.uri))
            }
        }
        
        return XMLValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings,
            partId: id
        )
    }
    
    // MARK: - Data Binding
    
    /// Create data binding for custom XML
    public func createDataBinding(
        xmlPartId: String,
        xpath: String,
        prefixMappings: [String: String] = [:]
    ) throws -> WMLDataBinding {
        guard xmlParts[xmlPartId] != nil else {
            throw CustomXMLError.partNotFound(xmlPartId)
        }
        
        return WMLDataBinding(
            xmlPartId: xmlPartId,
            xpath: xpath,
            prefixMappings: prefixMappings,
            storeItemId: UUID().uuidString
        )
    }
    
    /// Evaluate XPath against custom XML part
    public func evaluateXPath(partId: String, xpath: String) throws -> [XMLNode] {
        guard let part = xmlParts[partId] else {
            throw CustomXMLError.partNotFound(partId)
        }
        
        // Simple XPath evaluation (in a real implementation, you'd use a proper XPath engine)
        return parseXMLForXPath(part.xmlContent, xpath: xpath)
    }
    
    // MARK: - Import/Export
    
    /// Import custom XML from file
    public func importCustomXML(from data: Data, withSchema schema: XMLSchema? = nil) throws -> String {
        guard let xmlString = String(data: data, encoding: .utf8) else {
            throw CustomXMLError.invalidEncoding
        }
        
        guard isValidXML(xmlString) else {
            throw CustomXMLError.invalidXMLContent("imported")
        }
        
        var schemaReferences: [WMLSchemaReference] = []
        if let schema = schema {
            schemaReferences.append(WMLSchemaReference(uri: schema.targetNamespace))
            addSchema(schema)
        }
        
        let part = try createCustomXMLPart(
            xmlContent: xmlString,
            schemaReferences: schemaReferences
        )
        
        return part.partId
    }
    
    /// Export custom XML part to data
    public func exportCustomXML(partId: String) throws -> Data {
        guard let part = xmlParts[partId] else {
            throw CustomXMLError.partNotFound(partId)
        }
        
        guard let data = part.xmlContent.data(using: .utf8) else {
            throw CustomXMLError.invalidEncoding
        }
        
        return data
    }
    
    // MARK: - Search and Query
    
    /// Find custom XML parts containing specific elements
    public func findPartsContaining(elementName: String) -> [WMLCustomXMLPart] {
        return xmlParts.values.filter { part in
            part.xmlContent.contains("<\(elementName)")
        }
    }
    
    /// Find custom XML parts with specific namespace
    public func findPartsWithNamespace(_ namespace: String) -> [WMLCustomXMLPart] {
        return xmlParts.values.filter { part in
            part.namespaces.values.contains(namespace)
        }
    }
    
    /// Search custom XML content
    public func searchXMLContent(query: String) -> [CustomXMLSearchResult] {
        var results: [CustomXMLSearchResult] = []
        
        for (partId, part) in xmlParts {
            let matches = findMatches(in: part.xmlContent, query: query)
            if !matches.isEmpty {
                results.append(CustomXMLSearchResult(
                    partId: partId,
                    matches: matches,
                    part: part
                ))
            }
        }
        
        return results
    }
    
    // MARK: - Statistics
    
    private func updateStatistics() {
        statistics.totalParts = xmlParts.count
        statistics.totalProperties = xmlProperties.count
        statistics.totalSchemas = schemaLibrary.count
        statistics.lastModified = Date()
        
        // Calculate total content size
        statistics.totalContentSize = xmlParts.values.reduce(0) { total, part in
            total + part.xmlContent.count
        }
        
        // Count namespace usage
        let allNamespaces = xmlParts.values.flatMap { $0.namespaces.values }
        statistics.uniqueNamespaces = Set(allNamespaces).count
    }
    
    /// Get custom XML statistics
    public func getStatistics() -> CustomXMLStatistics {
        return statistics
    }
    
    // MARK: - Helper Methods
    
    private func isValidXML(_ xmlString: String) -> Bool {
        guard let data = xmlString.data(using: .utf8) else { return false }
        
        let parser = XMLParser(data: data)
        let delegate = XMLValidationDelegate()
        parser.delegate = delegate
        
        return parser.parse() && !delegate.hasError
    }
    
    private func validateAgainstSchema(_ xmlContent: String, schema: XMLSchema) -> XMLValidationResult {
        // Simplified schema validation
        // In a real implementation, you'd use a proper XML Schema validator
        var errors: [XMLValidationError] = []
        let warnings: [XMLValidationWarning] = []
        
        // Check if XML contains required elements from schema
        for requiredElement in schema.requiredElements {
            if !xmlContent.contains("<\(requiredElement)") {
                errors.append(XMLValidationError.missingRequiredElement(schema.targetNamespace, requiredElement))
            }
        }
        
        return XMLValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings,
            partId: ""
        )
    }
    
    private func parseXMLForXPath(_ xmlContent: String, xpath: String) -> [XMLNode] {
        // Simplified XPath evaluation
        // In a real implementation, you'd use a proper XPath engine
        var nodes: [XMLNode] = []
        
        // Basic element selection
        if xpath.starts(with: "//") {
            let elementName = String(xpath.dropFirst(2))
            let pattern = "<\(elementName)[^>]*>(.*?)</\(elementName)>"
            
            if let regex = try? NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators) {
                let range = NSRange(xmlContent.startIndex..., in: xmlContent)
                let matches = regex.matches(in: xmlContent, options: [], range: range)
                
                for match in matches {
                    if let range = Range(match.range(at: 1), in: xmlContent) {
                        let content = String(xmlContent[range])
                        nodes.append(XMLNode(name: elementName, content: content))
                    }
                }
            }
        }
        
        return nodes
    }
    
    private func findMatches(in content: String, query: String) -> [XMLMatch] {
        var matches: [XMLMatch] = []
        let lowercaseContent = content.lowercased()
        let lowercaseQuery = query.lowercased()
        
        var searchRange = lowercaseContent.startIndex..<lowercaseContent.endIndex
        
        while let range = lowercaseContent.range(of: lowercaseQuery, range: searchRange) {
            let location = lowercaseContent.distance(from: lowercaseContent.startIndex, to: range.lowerBound)
            matches.append(XMLMatch(location: location, length: query.count, context: getContext(content, at: location)))
            
            searchRange = range.upperBound..<lowercaseContent.endIndex
        }
        
        return matches
    }
    
    private func getContext(_ content: String, at location: Int) -> String {
        let startIndex = content.index(content.startIndex, offsetBy: max(0, location - 50))
        let endIndex = content.index(content.startIndex, offsetBy: min(content.count, location + 50))
        return String(content[startIndex..<endIndex])
    }
}

// MARK: - Custom XML Part

/// WordprocessingML custom XML part
public struct WMLCustomXMLPart: Sendable, DocumentPart, Identifiable {
    
    /// Unique part identifier
    public let partId: String
    
    /// XML content
    public let xmlContent: String
    
    /// Schema references
    public let schemaReferences: [WMLSchemaReference]
    
    /// Namespace declarations
    public let namespaces: [String: String]
    
    public var id: String { partId }
    
    public init(
        partId: String,
        xmlContent: String,
        schemaReferences: [WMLSchemaReference] = [],
        namespaces: [String: String] = [:]
    ) {
        self.partId = partId
        self.xmlContent = xmlContent
        self.schemaReferences = schemaReferences
        self.namespaces = namespaces
    }
    
    /// Get content size in bytes
    public var contentSize: Int {
        return xmlContent.count
    }
    
    /// Check if part is empty
    public var isEmpty: Bool {
        return xmlContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Get root element name
    public var rootElementName: String? {
        guard let startIndex = xmlContent.firstIndex(of: "<"),
              let endIndex = xmlContent.firstIndex(of: ">") else {
            return nil
        }
        
        let startTagContent = String(xmlContent[xmlContent.index(after: startIndex)..<endIndex])
        let parts = startTagContent.components(separatedBy: .whitespaces)
        return parts.first
    }
}

// MARK: - Custom XML Properties

/// Custom XML properties part
public struct WMLCustomXMLProperties: Sendable {
    
    /// Schema references
    public let schemaReferences: [WMLSchemaReference]
    
    /// Data store item ID
    public let dataStoreItemId: String
    
    public init(schemaReferences: [WMLSchemaReference] = [], dataStoreItemId: String) {
        self.schemaReferences = schemaReferences
        self.dataStoreItemId = dataStoreItemId
    }
}

/// Schema reference in custom XML
public struct WMLSchemaReference: Sendable {
    
    /// Schema URI/namespace
    public let uri: String
    
    public init(uri: String) {
        self.uri = uri
    }
}

// MARK: - Data Binding

/// Data binding for custom XML content
public struct WMLDataBinding: Sendable {
    
    /// Custom XML part ID
    public let xmlPartId: String
    
    /// XPath expression
    public let xpath: String
    
    /// Namespace prefix mappings
    public let prefixMappings: [String: String]
    
    /// Data store item ID
    public let storeItemId: String
    
    public init(xmlPartId: String, xpath: String, prefixMappings: [String: String] = [:], storeItemId: String) {
        self.xmlPartId = xmlPartId
        self.xpath = xpath
        self.prefixMappings = prefixMappings
        self.storeItemId = storeItemId
    }
}

// MARK: - XML Schema Support

/// XML Schema definition
public struct XMLSchema: Sendable {
    
    /// Target namespace
    public let targetNamespace: String
    
    /// Schema content (XSD)
    public let schemaContent: String
    
    /// Required elements
    public let requiredElements: [String]
    
    /// Optional elements
    public let optionalElements: [String]
    
    public init(
        targetNamespace: String,
        schemaContent: String,
        requiredElements: [String] = [],
        optionalElements: [String] = []
    ) {
        self.targetNamespace = targetNamespace
        self.schemaContent = schemaContent
        self.requiredElements = requiredElements
        self.optionalElements = optionalElements
    }
}

// MARK: - Validation Support

/// XML validation result
public struct XMLValidationResult: Sendable {
    
    /// Whether XML is valid
    public let isValid: Bool
    
    /// Validation errors
    public let errors: [XMLValidationError]
    
    /// Validation warnings
    public let warnings: [XMLValidationWarning]
    
    /// Part ID that was validated
    public let partId: String
    
    /// Human-readable summary
    public var summary: String {
        if isValid && errors.isEmpty && warnings.isEmpty {
            return "✅ Valid XML"
        } else {
            var parts: [String] = []
            if !errors.isEmpty { parts.append("\(errors.count) errors") }
            if !warnings.isEmpty { parts.append("\(warnings.count) warnings") }
            
            let status = isValid ? "⚠️" : "❌"
            return "\(status) \(parts.joined(separator: ", "))"
        }
    }
}

/// XML validation errors
public enum XMLValidationError: Sendable {
    case malformedXML(String, String)
    case missingRequiredElement(String, String)
    case invalidElementContent(String, String)
    case schemaViolation(String, String)
}

/// XML validation warnings
public enum XMLValidationWarning: Sendable {
    case schemaNotFound(String)
    case unexpectedElement(String)
    case deprecatedElement(String)
}

/// Simple XML node for XPath results
public struct XMLNode: Sendable {
    
    /// Element name
    public let name: String
    
    /// Element content
    public let content: String
    
    /// Element attributes
    public let attributes: [String: String]
    
    public init(name: String, content: String, attributes: [String: String] = [:]) {
        self.name = name
        self.content = content
        self.attributes = attributes
    }
}

// MARK: - Search Support

/// Custom XML search result
public struct CustomXMLSearchResult: Sendable {
    
    /// Part ID containing matches
    public let partId: String
    
    /// Search matches
    public let matches: [XMLMatch]
    
    /// The custom XML part
    public let part: WMLCustomXMLPart
}

/// XML search match
public struct XMLMatch: Sendable {
    
    /// Location in content
    public let location: Int
    
    /// Match length
    public let length: Int
    
    /// Surrounding context
    public let context: String
}

// MARK: - Statistics

/// Custom XML statistics
public struct CustomXMLStatistics: Sendable {
    
    /// Total number of custom XML parts
    public var totalParts: Int = 0
    
    /// Total number of custom XML properties
    public var totalProperties: Int = 0
    
    /// Total number of schemas
    public var totalSchemas: Int = 0
    
    /// Total content size in characters
    public var totalContentSize: Int = 0
    
    /// Number of unique namespaces
    public var uniqueNamespaces: Int = 0
    
    /// Last modification time
    public var lastModified: Date?
    
    /// Human-readable summary
    public var summary: String {
        return "\(totalParts) XML parts, \(totalSchemas) schemas, \(totalContentSize) chars"
    }
}

// MARK: - XML Validation Delegate

private class XMLValidationDelegate: NSObject, XMLParserDelegate {
    var hasError = false
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        hasError = true
    }
    
    func parser(_ parser: XMLParser, validationErrorOccurred validationError: Error) {
        hasError = true
    }
}

// MARK: - Custom XML Errors

/// Custom XML related errors
public enum CustomXMLError: Error, Sendable {
    case partNotFound(String)
    case invalidXMLContent(String)
    case invalidEncoding
    case schemaValidationFailed(String)
    case xpathEvaluationFailed(String)
    case duplicatePartId(String)
}

extension CustomXMLError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .partNotFound(let id):
            return "Custom XML part not found: \(id)"
        case .invalidXMLContent(let partId):
            return "Invalid XML content in part: \(partId)"
        case .invalidEncoding:
            return "Invalid character encoding"
        case .schemaValidationFailed(let details):
            return "Schema validation failed: \(details)"
        case .xpathEvaluationFailed(let xpath):
            return "XPath evaluation failed: \(xpath)"
        case .duplicatePartId(let id):
            return "Duplicate custom XML part ID: \(id)"
        }
    }
}
