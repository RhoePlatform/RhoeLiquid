//
//  WordprocessingMLParser.swift
//  RhoeDOCX
//
//  WordprocessingML to DOM parser
//  Transforms XML events into structured DOM objects
//

import Foundation

/// Parser for converting WordprocessingML XML to DOM representation
public actor WordprocessingMLParser {
    
    /// Parsing context
    private struct ParsingContext {
        var elementStack: [String] = []
        var namespaceStack: [String] = []
        var textBuffer: String = ""
        var currentAttributes: [String: String] = [:]
    }
    
    /// Parse results
    public struct ParseResult: Sendable {
        public let document: WMLDocument
        public let namespaces: [String: String]
        public let processingInstructions: [String: String]
        
        public init(document: WMLDocument, 
                   namespaces: [String: String], 
                   processingInstructions: [String: String]) {
            self.document = document
            self.namespaces = namespaces
            self.processingInstructions = processingInstructions
        }
    }
    
    /// Parsing state
    private var context = ParsingContext()
    private var dom = WordprocessingMLDOM()
    private var documentBuilder: DocumentBuilder?
    private var processingInstructions: [String: String] = [:]
    
    public init() {}
    
    /// Parse WordprocessingML document from data
    public func parse(data: Data) async throws -> ParseResult {
        reset()
        
        let parser = SimpleXMLParser()
        documentBuilder = DocumentBuilder()
        
        let events = try parser.parse(data: data)
        
        for event in events {
            handleEvent(event)
        }
        
        guard let document = documentBuilder?.build() else {
            throw WordprocessingMLError.parsingFailed("Failed to build document")
        }
        
        let namespaces = await dom.getAllNamespaces()
        
        return ParseResult(
            document: document,
            namespaces: namespaces,
            processingInstructions: processingInstructions
        )
    }
    
    /// Parse WordprocessingML document from file
    public func parse(url: URL) async throws -> ParseResult {
        let data = try Data(contentsOf: url)
        return try await parse(data: data)
    }
    
    /// Parse WordprocessingML document from string
    public func parse(string: String) async throws -> ParseResult {
        guard let data = string.data(using: .utf8) else {
            throw WordprocessingMLError.encodingError("Failed to encode string as UTF-8")
        }
        return try await parse(data: data)
    }
    
    // MARK: - Private Methods
    
    private func reset() {
        context = ParsingContext()
        dom = WordprocessingMLDOM()
        documentBuilder = nil
        processingInstructions.removeAll()
    }
    
    private func handleEvent(_ event: SimpleXMLParser.Event) {
        switch event {
        case .startDocument:
            break
            
        case .endDocument:
            break
            
        case .startElement(let name, let namespace, let attributes):
            handleStartElement(name: name, namespace: namespace, attributes: attributes)
            
        case .endElement(let name, let namespace):
            handleEndElement(name: name, namespace: namespace)
            
        case .characters(let text):
            handleCharacters(text)
            
        case .processingInstruction(let target, let data):
            processingInstructions[target] = data
            
        case .comment:
            break // Comments are ignored in WordprocessingML parsing
            
        case .error(let error):
            // Handle parsing errors
            print("XML Parsing Error: \(error)")
        }
    }
    
    private func handleStartElement(name: String, namespace: String?, attributes: [String: String]) {
        context.elementStack.append(name)
        context.namespaceStack.append(namespace ?? "")
        context.currentAttributes = attributes
        
        // Flush any pending text before starting new element
        flushTextBuffer()
        
        // Add namespace to DOM if not already present
        if let namespace = namespace {
            Task { await dom.addNamespace(prefix: name, uri: namespace) }
        }
        
        // Route to appropriate handler based on namespace and element
        guard let namespace = namespace else { return }
        
        if WordMLNamespaces.isMain(namespace) {
            handleMainNamespaceElement(name: name, attributes: attributes)
        } else if WordMLNamespaces.isRelationships(namespace) {
            handleRelationshipsElement(name: name, attributes: attributes)
        } else if WordMLNamespaces.isDrawingML(namespace) {
            handleDrawingMLElement(name: name, attributes: attributes)
        }
    }
    
    private func handleEndElement(name: String, namespace: String?) {
        defer {
            context.elementStack.removeLast()
            context.namespaceStack.removeLast()
            context.currentAttributes.removeAll()
        }
        
        guard let namespace = namespace else { return }
        
        if WordMLNamespaces.isMain(namespace) {
            handleMainNamespaceEndElement(name: name)
        }
    }
    
    private func handleCharacters(_ text: String) {
        context.textBuffer += text
    }
    
    private func flushTextBuffer() {
        if !context.textBuffer.isEmpty {
            // Handle text content if we're in a text element
            if let currentElement = context.elementStack.last, currentElement == "t" {
                documentBuilder?.addText(context.textBuffer, attributes: context.currentAttributes)
            }
            context.textBuffer = ""
        }
    }
    
    // MARK: - Element Handlers
    
    private func handleMainNamespaceElement(name: String, attributes: [String: String]) {
        switch name {
        case "document":
            documentBuilder?.startDocument(attributes: attributes)
        case "body":
            documentBuilder?.startBody(attributes: attributes)
        case "p":
            documentBuilder?.startParagraph(attributes: attributes)
        case "pPr":
            documentBuilder?.startParagraphProperties(attributes: attributes)
        case "r":
            documentBuilder?.startRun(attributes: attributes)
        case "rPr":
            documentBuilder?.startRunProperties(attributes: attributes)
        case "t":
            documentBuilder?.startText(attributes: attributes)
        case "tbl":
            documentBuilder?.startTable(attributes: attributes)
        case "tblPr":
            documentBuilder?.startTableProperties(attributes: attributes)
        case "tblGrid":
            documentBuilder?.startTableGrid(attributes: attributes)
        case "gridCol":
            documentBuilder?.startGridColumn(attributes: attributes)
        case "tr":
            documentBuilder?.startTableRow(attributes: attributes)
        case "trPr":
            documentBuilder?.startTableRowProperties(attributes: attributes)
        case "tc":
            documentBuilder?.startTableCell(attributes: attributes)
        case "tcPr":
            documentBuilder?.startTableCellProperties(attributes: attributes)
        case "sectPr":
            documentBuilder?.startSectionProperties(attributes: attributes)
        case "sdt":
            documentBuilder?.startStructuredDocumentTag(attributes: attributes)
        case "sdtPr":
            documentBuilder?.startSDTProperties(attributes: attributes)
        case "sdtContent":
            documentBuilder?.startSDTContent(attributes: attributes)
        case "tag":
            documentBuilder?.handleSDTTag(attributes: attributes)
        case "alias":
            documentBuilder?.handleSDTAlias(attributes: attributes)
        case "lock":
            documentBuilder?.handleSDTLock(attributes: attributes)
        case "showingPlcHdr":
            documentBuilder?.handleSDTShowingPlaceholder()
        default:
            documentBuilder?.startGenericElement(name: name, attributes: attributes)
        }
    }
    
    private func handleMainNamespaceEndElement(name: String) {
        switch name {
        case "document":
            documentBuilder?.endDocument()
        case "body":
            documentBuilder?.endBody()
        case "p":
            documentBuilder?.endParagraph()
        case "pPr":
            documentBuilder?.endParagraphProperties()
        case "r":
            documentBuilder?.endRun()
        case "rPr":
            documentBuilder?.endRunProperties()
        case "t":
            flushTextBuffer()
            documentBuilder?.endText()
        case "tbl":
            documentBuilder?.endTable()
        case "tblPr":
            documentBuilder?.endTableProperties()
        case "tblGrid":
            documentBuilder?.endTableGrid()
        case "gridCol":
            documentBuilder?.endGridColumn()
        case "tr":
            documentBuilder?.endTableRow()
        case "trPr":
            documentBuilder?.endTableRowProperties()
        case "tc":
            documentBuilder?.endTableCell()
        case "tcPr":
            documentBuilder?.endTableCellProperties()
        case "sectPr":
            documentBuilder?.endSectionProperties()
        case "sdt":
            documentBuilder?.endStructuredDocumentTag()
        case "sdtPr":
            documentBuilder?.endSDTProperties()
        case "sdtContent":
            documentBuilder?.endSDTContent()
        case "tag", "alias", "lock", "showingPlcHdr":
            break // Self-closing or handled on start
        default:
            documentBuilder?.endGenericElement(name: name)
        }
    }
    
    private func handleRelationshipsElement(name: String, attributes: [String: String]) {
        // Handle relationship elements if needed for inline processing
    }
    
    private func handleDrawingMLElement(name: String, attributes: [String: String]) {
        // Handle DrawingML elements for images, shapes, etc.
    }
}

// MARK: - Document Builder

/// Builder for constructing WordprocessingML DOM objects
private class DocumentBuilder {
    
    /// Building stacks
    private var bodyContent: [WMLBodyContent] = []
    private var paragraphContent: [WMLParagraphContent] = []
    private var runContent: [WMLRunContent] = []
    private var tableCellContent: [WMLTableCellContent] = []
    private var currentParagraphProperties: WMLParagraphProperties?
    private var currentRunProperties: WMLRunProperties?
    private var currentSectionProperties: WMLSectionProperties?
    
    /// Table building state
    private var currentTable: WMLTable?
    private var tableRows: [WMLTableRow] = []
    private var tableRowCells: [WMLTableCell] = []
    private var tableGrid: WMLTableGrid?
    private var gridColumns: [WMLGridColumn] = []
    private var currentTableProperties: WMLTableProperties?
    private var currentTableRowProperties: WMLTableRowProperties?
    private var currentTableCellProperties: WMLTableCellProperties?
    
    /// Element stack for tracking context
    private var elementStack: [String] = []
    
    // MARK: - Document Structure
    
    func startDocument(attributes: [String: String]) {
        elementStack.append("document")
    }
    
    func endDocument() {
        elementStack.removeLast()
    }
    
    func startBody(attributes: [String: String]) {
        elementStack.append("body")
    }
    
    func endBody() {
        elementStack.removeLast()
    }
    
    // MARK: - Paragraphs
    
    func startParagraph(attributes: [String: String]) {
        elementStack.append("p")
        paragraphContent.removeAll()
        currentParagraphProperties = nil
    }
    
    func endParagraph() {
        elementStack.removeLast()
        let paragraph = WMLParagraph(
            properties: currentParagraphProperties,
            content: paragraphContent,
            paragraphId: nil,
            textId: nil
        )
        
        // Determine context - are we in a table cell or body?
        if elementStack.contains("tc") {
            tableCellContent.append(.paragraph(paragraph))
        } else {
            bodyContent.append(.paragraph(paragraph))
        }
        
        paragraphContent.removeAll()
        currentParagraphProperties = nil
    }
    
    func startParagraphProperties(attributes: [String: String]) {
        elementStack.append("pPr")
        // Start building paragraph properties
        currentParagraphProperties = WMLParagraphProperties()
    }
    
    func endParagraphProperties() {
        elementStack.removeLast()
        // Properties are already set in currentParagraphProperties
    }
    
    // MARK: - Runs
    
    func startRun(attributes: [String: String]) {
        elementStack.append("r")
        runContent.removeAll()
        currentRunProperties = nil
    }
    
    func endRun() {
        elementStack.removeLast()
        let run = WMLRun(
            properties: currentRunProperties,
            content: runContent,
            rsidRPr: nil,
            rsidDel: nil,
            rsidR: nil
        )
        paragraphContent.append(.run(run))
        runContent.removeAll()
        currentRunProperties = nil
    }
    
    func startRunProperties(attributes: [String: String]) {
        elementStack.append("rPr")
        currentRunProperties = WMLRunProperties()
    }
    
    func endRunProperties() {
        elementStack.removeLast()
    }
    
    // MARK: - Text
    
    func startText(attributes: [String: String]) {
        elementStack.append("t")
    }
    
    func endText() {
        elementStack.removeLast()
    }
    
    func addText(_ text: String, attributes: [String: String]) {
        let spaceAttribute = attributes["xml:space"].flatMap { WMLSpaceAttribute(rawValue: $0) }
        let wmlText = WMLText(content: text, space: spaceAttribute)
        runContent.append(.text(wmlText))
    }
    
    // MARK: - Tables
    
    func startTable(attributes: [String: String]) {
        elementStack.append("tbl")
        tableRows.removeAll()
        currentTableProperties = nil
        tableGrid = nil
        gridColumns.removeAll()
    }
    
    func endTable() {
        elementStack.removeLast()
        let table = WMLTable(
            properties: currentTableProperties,
            grid: tableGrid,
            rows: tableRows
        )
        bodyContent.append(.table(table))
        
        // Reset table state
        tableRows.removeAll()
        currentTableProperties = nil
        tableGrid = nil
        gridColumns.removeAll()
    }
    
    func startTableProperties(attributes: [String: String]) {
        elementStack.append("tblPr")
        // Create basic table properties for now
        currentTableProperties = WMLTableProperties()
    }
    
    func endTableProperties() {
        elementStack.removeLast()
    }
    
    func startTableGrid(attributes: [String: String]) {
        elementStack.append("tblGrid")
        gridColumns.removeAll()
    }
    
    func endTableGrid() {
        elementStack.removeLast()
        tableGrid = WMLTableGrid(columns: gridColumns)
    }
    
    func startGridColumn(attributes: [String: String]) {
        elementStack.append("gridCol")
        // Extract width from attributes
        var width: WMLTableWidth? = nil
        if let widthValue = attributes["w:w"], let widthType = attributes["w:type"] {
            width = WMLTableWidth(value: widthValue, type: WMLWidthType(rawValue: widthType) ?? .dxa)
        }
        let column = WMLGridColumn(width: width)
        gridColumns.append(column)
    }
    
    func endGridColumn() {
        elementStack.removeLast()
    }
    
    func startTableRow(attributes: [String: String]) {
        elementStack.append("tr")
        tableRowCells.removeAll()
        currentTableRowProperties = nil
    }
    
    func endTableRow() {
        elementStack.removeLast()
        let row = WMLTableRow(
            properties: currentTableRowProperties,
            cells: tableRowCells
        )
        tableRows.append(row)
        tableRowCells.removeAll()
        currentTableRowProperties = nil
    }
    
    func startTableRowProperties(attributes: [String: String]) {
        elementStack.append("trPr")
        currentTableRowProperties = WMLTableRowProperties()
    }
    
    func endTableRowProperties() {
        elementStack.removeLast()
    }
    
    func startTableCell(attributes: [String: String]) {
        elementStack.append("tc")
        tableCellContent.removeAll()
        currentTableCellProperties = nil
    }
    
    func endTableCell() {
        elementStack.removeLast()
        let cell = WMLTableCell(
            properties: currentTableCellProperties,
            content: tableCellContent
        )
        tableRowCells.append(cell)
        tableCellContent.removeAll()
        currentTableCellProperties = nil
    }
    
    func startTableCellProperties(attributes: [String: String]) {
        elementStack.append("tcPr")
        currentTableCellProperties = WMLTableCellProperties()
    }
    
    func endTableCellProperties() {
        elementStack.removeLast()
    }
    
    // MARK: - Section Properties
    
    func startSectionProperties(attributes: [String: String]) {
        elementStack.append("sectPr")
        currentSectionProperties = WMLSectionProperties()
    }
    
    func endSectionProperties() {
        elementStack.removeLast()
    }
    
    // MARK: - Structured Document Tags

    /// SDT building state
    private var sdtTag: String?
    private var sdtAlias: String?
    private var sdtLock: WMLSDTLock?
    private var sdtShowingPlaceholder = false
    private var savedBodyContent: [[WMLBodyContent]] = []
    private var inSDTContent = false

    func startStructuredDocumentTag(attributes: [String: String]) {
        elementStack.append("sdt")
        sdtTag = nil
        sdtAlias = nil
        sdtLock = nil
        sdtShowingPlaceholder = false
    }

    func startSDTProperties(attributes: [String: String]) {
        elementStack.append("sdtPr")
    }

    func endSDTProperties() {
        elementStack.removeLast()
    }

    func handleSDTTag(attributes: [String: String]) {
        sdtTag = attributes["w:val"]
    }

    func handleSDTAlias(attributes: [String: String]) {
        sdtAlias = attributes["w:val"]
    }

    func handleSDTLock(attributes: [String: String]) {
        if let val = attributes["w:val"] {
            sdtLock = WMLSDTLock(rawValue: val)
        }
    }

    func handleSDTShowingPlaceholder() {
        sdtShowingPlaceholder = true
    }

    func startSDTContent(attributes: [String: String]) {
        elementStack.append("sdtContent")
        // Save current body content and start collecting SDT content separately
        savedBodyContent.append(bodyContent)
        bodyContent = []
        inSDTContent = true
    }

    func endSDTContent() {
        elementStack.removeLast()
        inSDTContent = false
    }

    func endStructuredDocumentTag() {
        elementStack.removeLast()

        let sdtBodyContent = bodyContent
        let properties = WMLSDTProperties(
            tag: sdtTag,
            alias: sdtAlias,
            lock: sdtLock,
            showingPlaceholderText: sdtShowingPlaceholder
        )
        let sdt = WMLStructuredDocumentTag(properties: properties, content: sdtBodyContent)

        // Restore saved body content and append the SDT
        bodyContent = savedBodyContent.popLast() ?? []
        bodyContent.append(.structuredDocumentTag(sdt))

        // Reset SDT state
        sdtTag = nil
        sdtAlias = nil
        sdtLock = nil
        sdtShowingPlaceholder = false
    }

    // MARK: - Generic Elements

    func startGenericElement(name: String, attributes: [String: String]) {
        elementStack.append(name)
        // Handle other elements as needed
    }
    
    func endGenericElement(name: String) {
        elementStack.removeLast()
    }
    
    // MARK: - Build Result
    
    func build() -> WMLDocument? {
        let body = WMLBody(content: bodyContent, sectionProperties: currentSectionProperties)
        return WMLDocument(body: body, background: nil)
    }
}

// MARK: - Error Types

public enum WordprocessingMLError: Error, Sendable {
    case parsingFailed(String)
    case encodingError(String)
    case structureError(String)
    case unsupportedElement(String)
}

extension WordprocessingMLError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .parsingFailed(let message):
            return "WordprocessingML parsing failed: \(message)"
        case .encodingError(let message):
            return "Encoding error: \(message)"
        case .structureError(let message):
            return "Document structure error: \(message)"
        case .unsupportedElement(let element):
            return "Unsupported element: \(element)"
        }
    }
}
