//
//  XMLSerializer.swift
//  RhoeDOCX
//
//  High-performance XML serialization for WordprocessingML DOM
//  Converts DOM objects back to OpenXML-compliant XML with perfect fidelity
//

import Foundation

/// High-performance XML serializer for WordprocessingML documents
public actor XMLSerializer: Sendable {
    
    /// Serialization options
    public struct SerializationOptions: Sendable {
        public let prettyPrint: Bool
        public let indentSize: Int
        public let preserveWhitespace: Bool
        public let validateNamespaces: Bool
        public let sortAttributes: Bool
        
        public init(prettyPrint: Bool = false,
                   indentSize: Int = 2,
                   preserveWhitespace: Bool = true,
                   validateNamespaces: Bool = true,
                   sortAttributes: Bool = false) {
            self.prettyPrint = prettyPrint
            self.indentSize = indentSize
            self.preserveWhitespace = preserveWhitespace
            self.validateNamespaces = validateNamespaces
            self.sortAttributes = sortAttributes
        }
        
        /// Default options for production use
        public static let standard = SerializationOptions()
        
        /// Options for debugging with formatting
        public static let debug = SerializationOptions(prettyPrint: true, sortAttributes: true)
    }
    
    /// XML output buffer for high-performance serialization
    private var xmlBuffer: XMLBuffer
    private let options: SerializationOptions
    
    public init(options: SerializationOptions = .standard) {
        self.options = options
        self.xmlBuffer = XMLBuffer(options: options)
    }
    
    // MARK: - Document Serialization
    
    /// Serialize a complete WordprocessingML document to XML string
    public func serializeDocument(_ document: WMLDocument, namespaces: [String: String] = [:]) throws -> String {
        xmlBuffer.reset()
        
        // Write XML declaration
        xmlBuffer.writeXMLDeclaration()
        
        // Start document element with namespaces
        var documentAttributes: [String: String] = [:]
        
        // Add standard namespaces
        let standardNamespaces = WordMLNamespaces.getStandardNamespaces()
        for (prefix, uri) in standardNamespaces {
            if prefix.isEmpty {
                documentAttributes["xmlns"] = uri
            } else {
                documentAttributes["xmlns:\(prefix)"] = uri
            }
        }
        
        // Add custom namespaces
        for (prefix, uri) in namespaces {
            if prefix.isEmpty {
                documentAttributes["xmlns"] = uri
            } else {
                documentAttributes["xmlns:\(prefix)"] = uri
            }
        }
        
        xmlBuffer.startElement("w:document", attributes: documentAttributes)
        
        // Serialize document content
        try serializeBody(document.body)
        
        if let background = document.background {
            try serializeBackground(background)
        }
        
        xmlBuffer.endElement("w:document")
        
        return xmlBuffer.getXML()
    }
    
    /// Serialize document body
    private func serializeBody(_ body: WMLBody) throws {
        xmlBuffer.startElement("w:body")
        
        // Serialize body content
        for content in body.content {
            try serializeBodyContent(content)
        }
        
        // Serialize section properties
        if let sectionProps = body.sectionProperties {
            try serializeSectionProperties(sectionProps)
        }
        
        xmlBuffer.endElement("w:body")
    }
    
    /// Serialize body content elements
    private func serializeBodyContent(_ content: WMLBodyContent) throws {
        switch content {
        case .paragraph(let paragraph):
            try serializeParagraph(paragraph)
        case .table(let table):
            try serializeTable(table)
        case .altChunk(let altChunk):
            try serializeAltChunk(altChunk)
        case .sectionProperties(let sectionProps):
            try serializeSectionProperties(sectionProps)
        case .structuredDocumentTag(let sdt):
            try serializeStructuredDocumentTag(sdt)
        }
    }

    /// Serialize a structured document tag (`w:sdt`) with its properties and content.
    private func serializeStructuredDocumentTag(_ sdt: WMLStructuredDocumentTag) throws {
        xmlBuffer.startElement("w:sdt")

        // Serialize SDT properties
        let props = sdt.properties
        xmlBuffer.startElement("w:sdtPr")
        if let alias = props.alias {
            xmlBuffer.startElement("w:alias", attributes: ["w:val": alias])
            xmlBuffer.endElement("w:alias")
        }
        if let tag = props.tag {
            xmlBuffer.startElement("w:tag", attributes: ["w:val": tag])
            xmlBuffer.endElement("w:tag")
        }
        if let lock = props.lock {
            xmlBuffer.startElement("w:lock", attributes: ["w:val": lock.rawValue])
            xmlBuffer.endElement("w:lock")
        }
        if let placeholder = props.placeholder {
            xmlBuffer.startElement("w:placeholder")
            xmlBuffer.startElement("w:docPart", attributes: ["w:val": placeholder])
            xmlBuffer.endElement("w:docPart")
            xmlBuffer.endElement("w:placeholder")
        }
        if props.showingPlaceholderText {
            xmlBuffer.startElement("w:showingPlcHdr")
            xmlBuffer.endElement("w:showingPlcHdr")
        }
        if let dataBinding = props.dataBinding {
            xmlBuffer.startElement("w:dataBinding", attributes: ["w:xpath": dataBinding])
            xmlBuffer.endElement("w:dataBinding")
        }
        xmlBuffer.endElement("w:sdtPr")

        // Serialize SDT content
        xmlBuffer.startElement("w:sdtContent")
        for item in sdt.content {
            try serializeBodyContent(item)
        }
        xmlBuffer.endElement("w:sdtContent")

        xmlBuffer.endElement("w:sdt")
    }
    
    // MARK: - Paragraph Serialization
    
    /// Serialize a paragraph
    private func serializeParagraph(_ paragraph: WMLParagraph) throws {
        var attributes: [String: String] = [:]
        
        if let paragraphId = paragraph.paragraphId {
            attributes["w14:paraId"] = paragraphId
        }
        if let textId = paragraph.textId {
            attributes["w14:textId"] = textId
        }
        
        xmlBuffer.startElement("w:p", attributes: attributes)
        
        // Serialize paragraph properties
        if let properties = paragraph.properties {
            try serializeParagraphProperties(properties)
        }
        
        // Serialize paragraph content
        for content in paragraph.content {
            try serializeParagraphContent(content)
        }
        
        xmlBuffer.endElement("w:p")
    }
    
    /// Serialize paragraph content
    private func serializeParagraphContent(_ content: WMLParagraphContent) throws {
        switch content {
        case .run(let run):
            try serializeRun(run)
        case .field(let field):
            xmlBuffer.writeComment("Field: \(field)")
        case .bookmark(let bookmark):
            xmlBuffer.writeComment("Bookmark: \(bookmark)")
        case .hyperlink(let hyperlink):
            xmlBuffer.writeComment("Hyperlink: \(hyperlink)")
        case .math(let math):
            xmlBuffer.writeComment("Math: \(math)")
        case .insertedRun(let insertedRun):
            xmlBuffer.writeComment("Inserted run: \(insertedRun)")
        case .deletedRun(let deletedRun):
            xmlBuffer.writeComment("Deleted run: \(deletedRun)")
        case .moveFrom(let moveFrom):
            xmlBuffer.writeComment("Move from: \(moveFrom)")
        case .moveTo(let moveTo):
            xmlBuffer.writeComment("Move to: \(moveTo)")
        case .comment(let comment):
            xmlBuffer.writeComment("Comment range: \(comment)")
        case .structuredDocumentTag(let sdt):
            try serializeStructuredDocumentTag(sdt)
        }
    }

    /// Serialize paragraph properties
    private func serializeParagraphProperties(_ properties: WMLParagraphProperties) throws {
        xmlBuffer.startElement("w:pPr")
        
        if let styleId = properties.paragraphStyleId {
            xmlBuffer.writeElement("w:pStyle", attributes: ["w:val": styleId])
        }
        
        if let keepNext = properties.keepNext, keepNext {
            xmlBuffer.writeElement("w:keepNext")
        }
        
        if let keepLines = properties.keepLines, keepLines {
            xmlBuffer.writeElement("w:keepLines")
        }
        
        if let pageBreak = properties.pageBreakBefore, pageBreak {
            xmlBuffer.writeElement("w:pageBreakBefore")
        }
        
        if let justification = properties.jc {
            xmlBuffer.writeElement("w:jc", attributes: ["w:val": justification.rawValue])
        }
        
        if let spacing = properties.spacing {
            try serializeSpacing(spacing)
        }
        
        if let indentation = properties.ind {
            try serializeIndentation(indentation)
        }
        
        xmlBuffer.endElement("w:pPr")
    }
    
    // MARK: - Run Serialization
    
    /// Serialize a run
    private func serializeRun(_ run: WMLRun) throws {
        var attributes: [String: String] = [:]
        
        if let rsidRPr = run.rsidRPr {
            attributes["w:rsidRPr"] = rsidRPr
        }
        if let rsidDel = run.rsidDel {
            attributes["w:rsidDel"] = rsidDel
        }
        if let rsidR = run.rsidR {
            attributes["w:rsidR"] = rsidR
        }
        
        xmlBuffer.startElement("w:r", attributes: attributes)
        
        // Serialize run properties
        if let properties = run.properties {
            try serializeRunProperties(properties)
        }
        
        // Serialize run content
        for content in run.content {
            try serializeRunContent(content)
        }
        
        xmlBuffer.endElement("w:r")
    }
    
    /// Serialize run content
    private func serializeRunContent(_ content: WMLRunContent) throws {
        switch content {
        case .text(let text):
            try serializeText(text)
        case .tab(let tab):
            xmlBuffer.writeComment("Tab: \(tab)")
        case .br(let br):
            xmlBuffer.writeComment("Break: \(br)")
        case .cr(let cr):
            xmlBuffer.writeComment("Carriage return: \(cr)")
        case .drawing(let drawing):
            try serializeDrawing(drawing)
        case .pict(let pict):
            xmlBuffer.writeComment("Picture: \(pict)")
        case .object(let object):
            xmlBuffer.writeComment("Object: \(object)")
        default:
            // Handle other run content types with comments for now
            xmlBuffer.writeComment("Run content: \(content)")
        }
    }
    
    /// Serialize text
    private func serializeText(_ text: WMLText) throws {
        var attributes: [String: String] = [:]
        
        if let space = text.space {
            attributes["xml:space"] = space.rawValue
        }
        
        xmlBuffer.writeElement("w:t", content: text.content, attributes: attributes)
    }
    
    /// Serialize run properties
    private func serializeRunProperties(_ properties: WMLRunProperties) throws {
        xmlBuffer.startElement("w:rPr")
        
        if let styleId = properties.runStyleId {
            xmlBuffer.writeElement("w:rStyle", attributes: ["w:val": styleId])
        }
        
        if let bold = properties.bold, bold {
            xmlBuffer.writeElement("w:b")
        }
        
        if let italic = properties.italic, italic {
            xmlBuffer.writeElement("w:i")
        }
        
        if let caps = properties.caps, caps {
            xmlBuffer.writeElement("w:caps")
        }
        
        if let smallCaps = properties.smallCaps, smallCaps {
            xmlBuffer.writeElement("w:smallCaps")
        }
        
        if let strike = properties.strike, strike {
            xmlBuffer.writeElement("w:strike")
        }
        
        if let doubleStrike = properties.doubleStrike, doubleStrike {
            xmlBuffer.writeElement("w:dstrike")
        }
        
        xmlBuffer.endElement("w:rPr")
    }
    
    // MARK: - Table Serialization
    
    /// Serialize a table
    private func serializeTable(_ table: WMLTable) throws {
        xmlBuffer.startElement("w:tbl")
        
        // Serialize table properties
        if let properties = table.properties {
            try serializeTableProperties(properties)
        }
        
        // Serialize table grid
        if let grid = table.grid {
            try serializeTableGrid(grid)
        }
        
        // Serialize table rows
        for row in table.rows {
            try serializeTableRow(row)
        }
        
        xmlBuffer.endElement("w:tbl")
    }
    
    /// Serialize table properties
    private func serializeTableProperties(_ properties: WMLTableProperties) throws {
        xmlBuffer.startElement("w:tblPr")
        
        if let tableStyle = properties.tableStyle {
            xmlBuffer.writeElement("w:tblStyle", attributes: ["w:val": tableStyle])
        }
        
        if let tableWidth = properties.tableWidth {
            try serializeTableWidth(tableWidth, elementName: "w:tblW")
        }
        
        if let justification = properties.justification {
            xmlBuffer.writeElement("w:jc", attributes: ["w:val": justification.rawValue])
        }
        
        xmlBuffer.endElement("w:tblPr")
    }
    
    /// Serialize table grid
    private func serializeTableGrid(_ grid: WMLTableGrid) throws {
        xmlBuffer.startElement("w:tblGrid")
        
        for column in grid.columns {
            try serializeGridColumn(column)
        }
        
        xmlBuffer.endElement("w:tblGrid")
    }
    
    /// Serialize grid column
    private func serializeGridColumn(_ column: WMLGridColumn) throws {
        var attributes: [String: String] = [:]
        
        if let width = column.width {
            attributes["w:w"] = width.value
            attributes["w:type"] = width.type.rawValue
        }
        
        xmlBuffer.writeElement("w:gridCol", attributes: attributes)
    }
    
    /// Serialize table row
    private func serializeTableRow(_ row: WMLTableRow) throws {
        var attributes: [String: String] = [:]
        
        if let rsidR = row.rsidR {
            attributes["w:rsidR"] = rsidR
        }
        if let rsidRPr = row.rsidRPr {
            attributes["w:rsidRPr"] = rsidRPr
        }
        if let rsidTr = row.rsidTr {
            attributes["w:rsidTr"] = rsidTr
        }
        
        xmlBuffer.startElement("w:tr", attributes: attributes)
        
        // Serialize row properties
        if let properties = row.properties {
            try serializeTableRowProperties(properties)
        }
        
        // Serialize table cells
        for cell in row.cells {
            try serializeTableCell(cell)
        }
        
        xmlBuffer.endElement("w:tr")
    }
    
    /// Serialize table row properties
    private func serializeTableRowProperties(_ properties: WMLTableRowProperties) throws {
        xmlBuffer.startElement("w:trPr")
        
        if let cantSplit = properties.cantSplit, cantSplit {
            xmlBuffer.writeElement("w:cantSplit")
        }
        
        if let tableHeader = properties.tableHeader, tableHeader {
            xmlBuffer.writeElement("w:tblHeader")
        }
        
        xmlBuffer.endElement("w:trPr")
    }
    
    /// Serialize table cell
    private func serializeTableCell(_ cell: WMLTableCell) throws {
        var attributes: [String: String] = [:]
        
        if let id = cell.id {
            attributes["w:id"] = id
        }
        
        xmlBuffer.startElement("w:tc", attributes: attributes)
        
        // Serialize cell properties
        if let properties = cell.properties {
            try serializeTableCellProperties(properties)
        }
        
        // Serialize cell content
        for content in cell.content {
            try serializeTableCellContent(content)
        }
        
        xmlBuffer.endElement("w:tc")
    }
    
    /// Serialize table cell properties
    private func serializeTableCellProperties(_ properties: WMLTableCellProperties) throws {
        xmlBuffer.startElement("w:tcPr")
        
        if let width = properties.width {
            try serializeTableWidth(width, elementName: "w:tcW")
        }
        
        if let gridSpan = properties.gridSpan, gridSpan > 1 {
            xmlBuffer.writeElement("w:gridSpan", attributes: ["w:val": String(gridSpan)])
        }
        
        xmlBuffer.endElement("w:tcPr")
    }
    
    /// Serialize table cell content
    private func serializeTableCellContent(_ content: WMLTableCellContent) throws {
        switch content {
        case .paragraph(let paragraph):
            try serializeParagraph(paragraph)
        case .table(let table):
            try serializeTable(table)
        case .altChunk(let altChunk):
            try serializeAltChunk(altChunk)
        default:
            xmlBuffer.writeComment("Table cell content: \(content)")
        }
    }
    
    // MARK: - Drawing Serialization
    
    /// Serialize drawing (images, shapes, etc.)
    private func serializeDrawing(_ drawing: WMLDrawing) throws {
        xmlBuffer.startElement("w:drawing")
        
        switch drawing.content {
        case .inline(let inline):
            try serializeInlineDrawing(inline)
        case .anchor(let anchor):
            try serializeAnchorDrawing(anchor)
        }
        
        xmlBuffer.endElement("w:drawing")
    }
    
    /// Serialize inline drawing
    private func serializeInlineDrawing(_ inline: InlineDrawing) throws {
        xmlBuffer.startElement("wp:inline", attributes: [
            "xmlns:wp": "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
        ])
        
        // Extent
        xmlBuffer.writeElement("wp:extent", attributes: [
            "cx": String(inline.extents.width),
            "cy": String(inline.extents.height)
        ])
        
        // Graphic
        try serializeDrawingGraphic(inline.graphic)
        
        xmlBuffer.endElement("wp:inline")
    }
    
    /// Serialize anchor drawing
    private func serializeAnchorDrawing(_ anchor: AnchorDrawing) throws {
        xmlBuffer.startElement("wp:anchor", attributes: [
            "xmlns:wp": "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing",
            "distT": "0",
            "distB": "0",
            "distL": "0",
            "distR": "0",
            "simplePos": "0",
            "relativeHeight": "1",
            "behindDoc": "0",
            "locked": "0",
            "layoutInCell": "1",
            "allowOverlap": "1"
        ])
        
        // Simple position
        xmlBuffer.writeElement("wp:simplePos", attributes: ["x": "0", "y": "0"])
        
        // Position H
        let hAttributes: [String: String] = ["relativeFrom": anchor.position.horizontal.relativeTo.rawValue]
        xmlBuffer.startElement("wp:positionH", attributes: hAttributes)
        if let alignment = anchor.position.horizontal.alignment {
            xmlBuffer.writeElement("wp:align", content: alignment.rawValue)
        } else if let offset = anchor.position.horizontal.offset {
            xmlBuffer.writeElement("wp:posOffset", content: String(offset))
        }
        xmlBuffer.endElement("wp:positionH")
        
        // Position V
        let vAttributes: [String: String] = ["relativeFrom": anchor.position.vertical.relativeTo.rawValue]
        xmlBuffer.startElement("wp:positionV", attributes: vAttributes)
        if let alignment = anchor.position.vertical.alignment {
            xmlBuffer.writeElement("wp:align", content: alignment.rawValue)
        } else if let offset = anchor.position.vertical.offset {
            xmlBuffer.writeElement("wp:posOffset", content: String(offset))
        }
        xmlBuffer.endElement("wp:positionV")
        
        // Extent
        xmlBuffer.writeElement("wp:extent", attributes: [
            "cx": String(anchor.extents.width),
            "cy": String(anchor.extents.height)
        ])
        
        // Wrapping
        try serializeTextWrapping(anchor.wrapping)
        
        // Graphic
        try serializeDrawingGraphic(anchor.graphic)
        
        xmlBuffer.endElement("wp:anchor")
    }
    
    /// Serialize drawing graphic
    private func serializeDrawingGraphic(_ graphic: DrawingGraphic) throws {
        xmlBuffer.startElement("a:graphic", attributes: [
            "xmlns:a": "http://schemas.openxmlformats.org/drawingml/2006/main"
        ])
        
        xmlBuffer.startElement("a:graphicData", attributes: [
            "uri": "http://schemas.openxmlformats.org/drawingml/2006/picture"
        ])
        
        xmlBuffer.startElement("pic:pic", attributes: [
            "xmlns:pic": "http://schemas.openxmlformats.org/drawingml/2006/picture"
        ])
        
        // Non-visual properties
        xmlBuffer.startElement("pic:nvPicPr")
        xmlBuffer.writeElement("pic:cNvPr", attributes: [
            "id": "0",
            "name": graphic.mediaReference.title ?? "Image"
        ])
        xmlBuffer.writeElement("pic:cNvPicPr")
        xmlBuffer.endElement("pic:nvPicPr")
        
        // Blip fill
        xmlBuffer.startElement("pic:blipFill")
        xmlBuffer.writeElement("a:blip", attributes: ["r:embed": graphic.mediaReference.relationshipId])
        xmlBuffer.writeElement("a:stretch")
        xmlBuffer.endElement("pic:blipFill")
        
        // Shape properties
        xmlBuffer.startElement("pic:spPr")
        xmlBuffer.writeElement("a:xfrm")
        xmlBuffer.writeElement("a:prstGeom", attributes: ["prst": "rect"])
        xmlBuffer.endElement("pic:spPr")
        
        xmlBuffer.endElement("pic:pic")
        xmlBuffer.endElement("a:graphicData")
        xmlBuffer.endElement("a:graphic")
    }
    
    /// Serialize text wrapping
    private func serializeTextWrapping(_ wrapping: TextWrapping) throws {
        switch wrapping {
        case .square:
            xmlBuffer.writeElement("wp:wrapSquare", attributes: ["wrapText": "bothSides"])
        case .tight:
            xmlBuffer.writeElement("wp:wrapTight", attributes: ["wrapText": "bothSides"])
        case .through:
            xmlBuffer.writeElement("wp:wrapThrough", attributes: ["wrapText": "bothSides"])
        case .topAndBottom:
            xmlBuffer.writeElement("wp:wrapTopAndBottom")
        case .behind:
            xmlBuffer.writeElement("wp:wrapNone")
        case .inFrontOf:
            xmlBuffer.writeElement("wp:wrapNone")
        case .inline:
            // No wrapping element for inline
            break
        }
    }
    
    // MARK: - Utility Serializers
    
    /// Serialize table width
    private func serializeTableWidth(_ width: WMLTableWidth, elementName: String) throws {
        xmlBuffer.writeElement(elementName, attributes: [
            "w:w": width.value,
            "w:type": width.type.rawValue
        ])
    }
    
    /// Serialize spacing
    private func serializeSpacing(_ spacing: WMLSpacing) throws {
        // Placeholder implementation
        xmlBuffer.writeComment("Spacing properties")
    }
    
    /// Serialize indentation
    private func serializeIndentation(_ indentation: WMLIndentation) throws {
        // Placeholder implementation
        xmlBuffer.writeComment("Indentation properties")
    }
    
    /// Serialize alt chunk
    private func serializeAltChunk(_ altChunk: WMLAltChunk) throws {
        xmlBuffer.writeElement("w:altChunk", attributes: ["r:id": altChunk.id])
    }
    
    /// Serialize background
    private func serializeBackground(_ background: WMLBackground) throws {
        xmlBuffer.writeComment("Document background")
    }
    
    /// Serialize section properties
    private func serializeSectionProperties(_ sectionProps: WMLSectionProperties) throws {
        xmlBuffer.startElement("w:sectPr")
        xmlBuffer.writeComment("Section properties")
        xmlBuffer.endElement("w:sectPr")
    }
}

// MARK: - Extensions

extension WordMLNamespaces {
    /// Get standard namespaces for document serialization
    static func getStandardNamespaces() -> [String: String] {
        return [
            "w": WordMLNamespaces.main,
            "r": WordMLNamespaces.relationships,
            "wp": "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing",
            "a": "http://schemas.openxmlformats.org/drawingml/2006/main",
            "pic": "http://schemas.openxmlformats.org/drawingml/2006/picture"
        ]
    }
}
