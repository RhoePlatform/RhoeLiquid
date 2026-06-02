//
//  WordprocessingMLDOM.swift
//  RhoeDOCX
//
//  Foundational WordprocessingML document models.
//

import Foundation

/// Stores a parsed WordprocessingML document and its namespace mappings.
///
/// The active package surface uses this actor as a lightweight container around
/// the normalized `WMLDocument` model.
public actor WordprocessingMLDOM: Sendable {
    
    /// Document root
    public private(set) var document: WMLDocument?
    
    /// Namespace context
    private var namespaces: [String: String] = [:]
    
    public init() {}
    
    /// Sets the current document root.
    public func setDocument(_ document: WMLDocument) {
        self.document = document
    }
    
    /// Registers a namespace prefix mapping.
    public func addNamespace(prefix: String, uri: String) {
        namespaces[prefix] = uri
    }
    
    /// Returns the namespace URI for a prefix, if one is registered.
    public func getNamespaceURI(for prefix: String) -> String? {
        return namespaces[prefix]
    }
    
    /// Returns all namespace mappings known to the DOM.
    public func getAllNamespaces() -> [String: String] {
        return namespaces
    }
}

// MARK: - Document Structure

/// The root `w:document` element.
public struct WMLDocument: Sendable {
    public let body: WMLBody
    public let background: WMLBackground?
    
    public init(body: WMLBody, background: WMLBackground? = nil) {
        self.body = body
        self.background = background
    }
}

/// The `w:body` element containing the document's block content.
public struct WMLBody: Sendable {
    public let content: [WMLBodyContent]
    public let sectionProperties: WMLSectionProperties?
    
    public init(content: [WMLBodyContent], sectionProperties: WMLSectionProperties? = nil) {
        self.content = content
        self.sectionProperties = sectionProperties
    }
}

/// The active block-level content variants supported in `w:body`.
public enum WMLBodyContent: Sendable {
    case paragraph(WMLParagraph)
    case table(WMLTable)
    case altChunk(WMLAltChunk)
    case sectionProperties(WMLSectionProperties)
    case structuredDocumentTag(WMLStructuredDocumentTag)
}

// MARK: - Paragraph Structure

/// A `w:p` paragraph node.
public struct WMLParagraph: Sendable {
    public let properties: WMLParagraphProperties?
    public let content: [WMLParagraphContent]
    public let paragraphId: String?
    public let textId: String?
    
    public init(properties: WMLParagraphProperties? = nil, 
                content: [WMLParagraphContent] = [],
                paragraphId: String? = nil,
                textId: String? = nil) {
        self.properties = properties
        self.content = content
        self.paragraphId = paragraphId
        self.textId = textId
    }
}

/// The inline content variants supported inside a paragraph.
public enum WMLParagraphContent: Sendable {
    case run(WMLRun)
    case field(WMLField)
    case bookmark(WMLBookmark)
    case hyperlink(WMLHyperlink)
    case math(WMLMath)
    case insertedRun(WMLInsertedRun)
    case deletedRun(WMLDeletedRun)
    case moveFrom(WMLMoveFrom)
    case moveTo(WMLMoveTo)
    case comment(WMLCommentRange)
    case structuredDocumentTag(WMLStructuredDocumentTag)
}

/// A `w:r` run node.
public struct WMLRun: Sendable {
    public let properties: WMLRunProperties?
    public let content: [WMLRunContent]
    public let rsidRPr: String?
    public let rsidDel: String?
    public let rsidR: String?
    
    public init(properties: WMLRunProperties? = nil,
                content: [WMLRunContent] = [],
                rsidRPr: String? = nil,
                rsidDel: String? = nil,
                rsidR: String? = nil) {
        self.properties = properties
        self.content = content
        self.rsidRPr = rsidRPr
        self.rsidDel = rsidDel
        self.rsidR = rsidR
    }
}

/// Content that may appear inside a run.
public enum WMLRunContent: Sendable {
    case text(WMLText)
    case tab(WMLTab)
    case br(WMLBreak)
    case cr(WMLCarriageReturn)
    case drawing(WMLDrawing)
    case pict(WMLPict)
    case object(WMLObject)
    case footnoteReference(WMLFootnoteReference)
    case endnoteReference(WMLEndnoteReference)
    case commentReference(WMLCommentReference)
    case separator(WMLSeparator)
    case continuationSeparator(WMLContinuationSeparator)
    case dayShort(WMLDayShort)
    case monthShort(WMLMonthShort)
    case yearShort(WMLYearShort)
    case dayLong(WMLDayLong)
    case monthLong(WMLMonthLong)
    case yearLong(WMLYearLong)
    case annotationRef(WMLAnnotationRef)
    case pgNum(WMLPageNumber)
    case noBreakHyphen(WMLNoBreakHyphen)
    case softHyphen(WMLSoftHyphen)
    case sym(WMLSymbol)
    case ptab(WMLPositionalTab)
    case lastRenderedPageBreak(WMLLastRenderedPageBreak)
    case ruby(WMLRuby)
}

/// A text node (`w:t`) inside a run.
public struct WMLText: Sendable {
    public let content: String
    public let space: WMLSpaceAttribute?
    
    public init(content: String, space: WMLSpaceAttribute? = nil) {
        self.content = content
        self.space = space
    }

    public init(content: String, xmlSpace: WMLSpaceAttribute?) {
        self.init(content: content, space: xmlSpace)
    }

    public var xmlSpace: WMLSpaceAttribute? {
        space
    }
}

/// Values for the `xml:space` attribute on text nodes.
public enum WMLSpaceAttribute: String, Sendable {
    case preserve = "preserve"
    case `default` = "default"
}

// MARK: - Table Structure

/// A table (`w:tbl`) block.
public struct WMLTable: Sendable {
    public let properties: WMLTableProperties?
    public let grid: WMLTableGrid?
    public let rows: [WMLTableRow]
    
    public init(properties: WMLTableProperties? = nil,
                grid: WMLTableGrid? = nil,
                rows: [WMLTableRow] = []) {
        self.properties = properties
        self.grid = grid
        self.rows = rows
    }
}

/// The `w:tblPr` property bag for a table.
public struct WMLTableProperties: Sendable {
    public let tableStyle: String?
    public let tablePositionProperties: WMLTablePositionProperties?
    public let tableOverlap: WMLTableOverlap?
    public let bidiVisual: Bool?
    public let tableWidth: WMLTableWidth?
    public let justification: WMLTableJustification?
    public let cellSpacing: WMLTableCellSpacing?
    public let cellMargins: WMLTableCellMargins?
    public let borders: WMLTableBorders?
    public let shading: WMLShading?
    public let tableLayout: WMLTableLayout?
    public let cellMarginsDefault: WMLTableCellMarginsDefault?
    public let look: WMLTableLook?
    public let caption: String?
    public let description: String?
    
    public init(tableStyle: String? = nil,
                tablePositionProperties: WMLTablePositionProperties? = nil,
                tableOverlap: WMLTableOverlap? = nil,
                bidiVisual: Bool? = nil,
                tableWidth: WMLTableWidth? = nil,
                justification: WMLTableJustification? = nil,
                cellSpacing: WMLTableCellSpacing? = nil,
                cellMargins: WMLTableCellMargins? = nil,
                borders: WMLTableBorders? = nil,
                shading: WMLShading? = nil,
                tableLayout: WMLTableLayout? = nil,
                cellMarginsDefault: WMLTableCellMarginsDefault? = nil,
                look: WMLTableLook? = nil,
                caption: String? = nil,
                description: String? = nil) {
        self.tableStyle = tableStyle
        self.tablePositionProperties = tablePositionProperties
        self.tableOverlap = tableOverlap
        self.bidiVisual = bidiVisual
        self.tableWidth = tableWidth
        self.justification = justification
        self.cellSpacing = cellSpacing
        self.cellMargins = cellMargins
        self.borders = borders
        self.shading = shading
        self.tableLayout = tableLayout
        self.cellMarginsDefault = cellMarginsDefault
        self.look = look
        self.caption = caption
        self.description = description
    }
}

/// Column grid information for a table.
public struct WMLTableGrid: Sendable {
    public let columns: [WMLGridColumn]
    
    public init(columns: [WMLGridColumn] = []) {
        self.columns = columns
    }
}

/// Grid Column (w:gridCol)
public struct WMLGridColumn: Sendable {
    public let width: WMLTableWidth?
    
    public init(width: WMLTableWidth? = nil) {
        self.width = width
    }
}

/// Table Row (w:tr)
public struct WMLTableRow: Sendable {
    public let properties: WMLTableRowProperties?
    public let cells: [WMLTableCell]
    public let rsidR: String?
    public let rsidRPr: String?
    public let rsidTr: String?
    
    public init(properties: WMLTableRowProperties? = nil,
                cells: [WMLTableCell] = [],
                rsidR: String? = nil,
                rsidRPr: String? = nil,
                rsidTr: String? = nil) {
        self.properties = properties
        self.cells = cells
        self.rsidR = rsidR
        self.rsidRPr = rsidRPr
        self.rsidTr = rsidTr
    }
}

/// Table Row Properties (w:trPr)
public struct WMLTableRowProperties: Sendable {
    public let conditionalFormatting: WMLConditionalFormatting?
    public let divId: Int?
    public let gridBefore: Int?
    public let gridAfter: Int?
    public let widthBefore: WMLTableWidth?
    public let widthAfter: WMLTableWidth?
    public let tableRowHeight: WMLTableRowHeight?
    public let hidden: Bool?
    public let cantSplit: Bool?
    public let tableHeader: Bool?
    public let tableCellSpacing: WMLTableCellSpacing?
    public let justification: WMLTableJustification?
    
    public init(conditionalFormatting: WMLConditionalFormatting? = nil,
                divId: Int? = nil,
                gridBefore: Int? = nil,
                gridAfter: Int? = nil,
                widthBefore: WMLTableWidth? = nil,
                widthAfter: WMLTableWidth? = nil,
                tableRowHeight: WMLTableRowHeight? = nil,
                hidden: Bool? = nil,
                cantSplit: Bool? = nil,
                tableHeader: Bool? = nil,
                tableCellSpacing: WMLTableCellSpacing? = nil,
                justification: WMLTableJustification? = nil) {
        self.conditionalFormatting = conditionalFormatting
        self.divId = divId
        self.gridBefore = gridBefore
        self.gridAfter = gridAfter
        self.widthBefore = widthBefore
        self.widthAfter = widthAfter
        self.tableRowHeight = tableRowHeight
        self.hidden = hidden
        self.cantSplit = cantSplit
        self.tableHeader = tableHeader
        self.tableCellSpacing = tableCellSpacing
        self.justification = justification
    }
}

/// Table Cell (w:tc)
public struct WMLTableCell: Sendable {
    public let properties: WMLTableCellProperties?
    public let content: [WMLTableCellContent]
    public let id: String?
    
    public init(properties: WMLTableCellProperties? = nil,
                content: [WMLTableCellContent] = [],
                id: String? = nil) {
        self.properties = properties
        self.content = content
        self.id = id
    }
}

/// Table Cell Content
public enum WMLTableCellContent: Sendable {
    case paragraph(WMLParagraph)
    case table(WMLTable)
    case altChunk(WMLAltChunk)
    case customXML(WMLCustomXML)
    case smartTag(WMLSmartTag)
    case structuredDocumentTag(WMLStructuredDocumentTag)
    case proofError(WMLProofError)
    case permissionStart(WMLPermissionStart)
    case permissionEnd(WMLPermissionEnd)
    case bookmarkStart(WMLBookmarkStart)
    case bookmarkEnd(WMLBookmarkEnd)
    case moveFromRangeStart(WMLMoveFromRangeStart)
    case moveFromRangeEnd(WMLMoveFromRangeEnd)
    case moveToRangeStart(WMLMoveToRangeStart)
    case moveToRangeEnd(WMLMoveToRangeEnd)
    case commentRangeStart(WMLCommentRangeStart)
    case commentRangeEnd(WMLCommentRangeEnd)
    case insertedRun(WMLInsertedRun)
    case deletedRun(WMLDeletedRun)
    case moveFrom(WMLMoveFrom)
    case moveTo(WMLMoveTo)
}

/// Table Cell Properties (w:tcPr)
public struct WMLTableCellProperties: Sendable {
    public let conditionalFormatting: WMLConditionalFormatting?
    public let width: WMLTableWidth?
    public let gridSpan: Int?
    public let horizontalMerge: WMLHorizontalMerge?
    public let verticalMerge: WMLVerticalMerge?
    public let borders: WMLTableCellBorders?
    public let shading: WMLShading?
    public let noWrap: Bool?
    public let margins: WMLTableCellMargins?
    public let textDirection: WMLTextDirection?
    public let fit: Bool?
    public let verticalAlignment: WMLVerticalAlignment?
    public let hideMark: Bool?
    public let headers: [String]?
    
    public init(conditionalFormatting: WMLConditionalFormatting? = nil,
                width: WMLTableWidth? = nil,
                gridSpan: Int? = nil,
                horizontalMerge: WMLHorizontalMerge? = nil,
                verticalMerge: WMLVerticalMerge? = nil,
                borders: WMLTableCellBorders? = nil,
                shading: WMLShading? = nil,
                noWrap: Bool? = nil,
                margins: WMLTableCellMargins? = nil,
                textDirection: WMLTextDirection? = nil,
                fit: Bool? = nil,
                verticalAlignment: WMLVerticalAlignment? = nil,
                hideMark: Bool? = nil,
                headers: [String]? = nil) {
        self.conditionalFormatting = conditionalFormatting
        self.width = width
        self.gridSpan = gridSpan
        self.horizontalMerge = horizontalMerge
        self.verticalMerge = verticalMerge
        self.borders = borders
        self.shading = shading
        self.noWrap = noWrap
        self.margins = margins
        self.textDirection = textDirection
        self.fit = fit
        self.verticalAlignment = verticalAlignment
        self.hideMark = hideMark
        self.headers = headers
    }
}

// MARK: - Header/Footer Support

/// Header Part (header1.xml, header2.xml, etc.)
public struct WMLHeaderPart: Sendable, DocumentPart {
    public let content: [WMLHeaderFooterContent]
    public let type: WMLHeaderFooterType
    
    public init(content: [WMLHeaderFooterContent] = [], type: WMLHeaderFooterType) {
        self.content = content
        self.type = type
    }
}

/// Footer Part (footer1.xml, footer2.xml, etc.)
public struct WMLFooterPart: Sendable, DocumentPart {
    public let content: [WMLHeaderFooterContent]
    public let type: WMLHeaderFooterType
    
    public init(content: [WMLHeaderFooterContent] = [], type: WMLHeaderFooterType) {
        self.content = content
        self.type = type
    }
}

/// Header/Footer Content
public enum WMLHeaderFooterContent: Sendable {
    case paragraph(WMLParagraph)
    case table(WMLTable)
    case altChunk(WMLAltChunk)
    case customXML(WMLCustomXML)
    case structuredDocumentTag(WMLStructuredDocumentTag)
    case proofError(WMLProofError)
    case permissionStart(WMLPermissionStart)
    case permissionEnd(WMLPermissionEnd)
    case bookmarkStart(WMLBookmarkStart)
    case bookmarkEnd(WMLBookmarkEnd)
    case moveFromRangeStart(WMLMoveFromRangeStart)
    case moveFromRangeEnd(WMLMoveFromRangeEnd)
    case moveToRangeStart(WMLMoveToRangeStart)
    case moveToRangeEnd(WMLMoveToRangeEnd)
    case commentRangeStart(WMLCommentRangeStart)
    case commentRangeEnd(WMLCommentRangeEnd)
    case insertedRun(WMLInsertedRun)
    case deletedRun(WMLDeletedRun)
    case moveFrom(WMLMoveFrom)
    case moveTo(WMLMoveTo)
}

/// Header/Footer Type
public enum WMLHeaderFooterType: String, Sendable, CaseIterable {
    case `default` = "default"
    case even = "even"
    case first = "first"
}

// MARK: - Document Part Protocol

/// Protocol for document parts
public protocol DocumentPart: Sendable {
    // Common properties for all document parts
}

// MARK: - Properties

/// Paragraph Properties (w:pPr)
public struct WMLParagraphProperties: Sendable {
    public let paragraphStyleId: String?
    public let keepNext: Bool?
    public let keepLines: Bool?
    public let pageBreakBefore: Bool?
    public let framePr: WMLFrameProperties?
    public let widowControl: Bool?
    public let numPr: WMLNumberingProperties?
    public let suppressLineNumbers: Bool?
    public let pbdr: WMLParagraphBorders?
    public let shd: WMLShading?
    public let tabs: WMLTabs?
    public let suppressAutoHyphens: Bool?
    public let kinsoku: Bool?
    public let wordWrap: Bool?
    public let overflowPunct: Bool?
    public let topLinePunct: Bool?
    public let autoSpaceDE: Bool?
    public let autoSpaceDN: Bool?
    public let bidi: Bool?
    public let adjustRightInd: Bool?
    public let snapToGrid: Bool?
    public let spacing: WMLSpacing?
    public let ind: WMLIndentation?
    public let contextualSpacing: Bool?
    public let mirrorIndents: Bool?
    public let suppressOverlap: Bool?
    public let jc: WMLTableJustification?
    public let textDirection: WMLTextDirection?
    public let textAlignment: WMLTextAlignment?
    public let textboxTightWrap: WMLTextboxTightWrap?
    public let outlineLvl: Int?
    public let divId: Int?
    public let cnfStyle: WMLConditionalFormatting?
    
    public init(paragraphStyleId: String? = nil,
                keepNext: Bool? = nil,
                keepLines: Bool? = nil,
                pageBreakBefore: Bool? = nil,
                framePr: WMLFrameProperties? = nil,
                widowControl: Bool? = nil,
                numPr: WMLNumberingProperties? = nil,
                suppressLineNumbers: Bool? = nil,
                pbdr: WMLParagraphBorders? = nil,
                shd: WMLShading? = nil,
                tabs: WMLTabs? = nil,
                suppressAutoHyphens: Bool? = nil,
                kinsoku: Bool? = nil,
                wordWrap: Bool? = nil,
                overflowPunct: Bool? = nil,
                topLinePunct: Bool? = nil,
                autoSpaceDE: Bool? = nil,
                autoSpaceDN: Bool? = nil,
                bidi: Bool? = nil,
                adjustRightInd: Bool? = nil,
                snapToGrid: Bool? = nil,
                spacing: WMLSpacing? = nil,
                ind: WMLIndentation? = nil,
                contextualSpacing: Bool? = nil,
                mirrorIndents: Bool? = nil,
                suppressOverlap: Bool? = nil,
                jc: WMLJustification? = nil,
                textDirection: WMLTextDirection? = nil,
                textAlignment: WMLTextAlignment? = nil,
                textboxTightWrap: WMLTextboxTightWrap? = nil,
                outlineLvl: Int? = nil,
                divId: Int? = nil,
                cnfStyle: WMLConditionalFormatting? = nil) {
        self.paragraphStyleId = paragraphStyleId
        self.keepNext = keepNext
        self.keepLines = keepLines
        self.pageBreakBefore = pageBreakBefore
        self.framePr = framePr
        self.widowControl = widowControl
        self.numPr = numPr
        self.suppressLineNumbers = suppressLineNumbers
        self.pbdr = pbdr
        self.shd = shd
        self.tabs = tabs
        self.suppressAutoHyphens = suppressAutoHyphens
        self.kinsoku = kinsoku
        self.wordWrap = wordWrap
        self.overflowPunct = overflowPunct
        self.topLinePunct = topLinePunct
        self.autoSpaceDE = autoSpaceDE
        self.autoSpaceDN = autoSpaceDN
        self.bidi = bidi
        self.adjustRightInd = adjustRightInd
        self.snapToGrid = snapToGrid
        self.spacing = spacing
        self.ind = ind
        self.contextualSpacing = contextualSpacing
        self.mirrorIndents = mirrorIndents
        self.suppressOverlap = suppressOverlap
        self.jc = jc
        self.textDirection = textDirection
        self.textAlignment = textAlignment
        self.textboxTightWrap = textboxTightWrap
        self.outlineLvl = outlineLvl
        self.divId = divId
        self.cnfStyle = cnfStyle
    }
}

/// Run Properties (w:rPr)
public struct WMLRunProperties: Sendable {
    public let runStyleId: String?
    public let runFonts: WMLRunFonts?
    public let bold: Bool?
    public let boldComplexScript: Bool?
    public let italic: Bool?
    public let italicComplexScript: Bool?
    public let caps: Bool?
    public let smallCaps: Bool?
    public let strike: Bool?
    public let doubleStrike: Bool?
    public let outline: Bool?
    public let shadow: Bool?
    public let emboss: Bool?
    public let imprint: Bool?
    public let noProof: Bool?
    public let snapToGrid: Bool?
    public let vanish: Bool?
    public let webHidden: Bool?
    public let color: WMLColor?
    public let spacing: Int?
    public let w: Int?
    public let kern: Int?
    public let position: Int?
    public let sz: Int?
    public let szCs: Int?
    public let highlight: WMLHighlight?
    public let underline: WMLUnderline?
    public let effect: WMLTextEffect?
    public let border: WMLBorder?
    public let shd: WMLShading?
    public let fitText: WMLFitText?
    public let vertAlign: WMLVerticalTextAlignment?
    public let rtl: Bool?
    public let cs: Bool?
    public let em: WMLEmphasisMark?
    public let lang: WMLLanguage?
    public let eastAsianLayout: WMLEastAsianLayout?
    public let specVanish: Bool?
    public let oMath: Bool?
    
    public init(runStyleId: String? = nil,
                runFonts: WMLRunFonts? = nil,
                bold: Bool? = nil,
                boldComplexScript: Bool? = nil,
                italic: Bool? = nil,
                italicComplexScript: Bool? = nil,
                caps: Bool? = nil,
                smallCaps: Bool? = nil,
                strike: Bool? = nil,
                doubleStrike: Bool? = nil,
                outline: Bool? = nil,
                shadow: Bool? = nil,
                emboss: Bool? = nil,
                imprint: Bool? = nil,
                noProof: Bool? = nil,
                snapToGrid: Bool? = nil,
                vanish: Bool? = nil,
                webHidden: Bool? = nil,
                color: WMLColor? = nil,
                spacing: Int? = nil,
                w: Int? = nil,
                kern: Int? = nil,
                position: Int? = nil,
                sz: Int? = nil,
                szCs: Int? = nil,
                highlight: WMLHighlight? = nil,
                underline: WMLUnderline? = nil,
                effect: WMLTextEffect? = nil,
                border: WMLBorder? = nil,
                shd: WMLShading? = nil,
                fitText: WMLFitText? = nil,
                vertAlign: WMLVerticalTextAlignment? = nil,
                rtl: Bool? = nil,
                cs: Bool? = nil,
                em: WMLEmphasisMark? = nil,
                lang: WMLLanguage? = nil,
                eastAsianLayout: WMLEastAsianLayout? = nil,
                specVanish: Bool? = nil,
                oMath: Bool? = nil) {
        self.runStyleId = runStyleId
        self.runFonts = runFonts
        self.bold = bold
        self.boldComplexScript = boldComplexScript
        self.italic = italic
        self.italicComplexScript = italicComplexScript
        self.caps = caps
        self.smallCaps = smallCaps
        self.strike = strike
        self.doubleStrike = doubleStrike
        self.outline = outline
        self.shadow = shadow
        self.emboss = emboss
        self.imprint = imprint
        self.noProof = noProof
        self.snapToGrid = snapToGrid
        self.vanish = vanish
        self.webHidden = webHidden
        self.color = color
        self.spacing = spacing
        self.w = w
        self.kern = kern
        self.position = position
        self.sz = sz
        self.szCs = szCs
        self.highlight = highlight
        self.underline = underline
        self.effect = effect
        self.border = border
        self.shd = shd
        self.fitText = fitText
        self.vertAlign = vertAlign
        self.rtl = rtl
        self.cs = cs
        self.em = em
        self.lang = lang
        self.eastAsianLayout = eastAsianLayout
        self.specVanish = specVanish
        self.oMath = oMath
    }
}

// MARK: - Supporting Types (Basic implementations)

public struct WMLBackground: Sendable {
    public let color: String?
    public let themeColor: String?
    
    public init(color: String? = nil, themeColor: String? = nil) {
        self.color = color
        self.themeColor = themeColor
    }
}

public struct WMLSectionProperties: Sendable {
    public let headerReference: [WMLHeaderReference]
    public let footerReference: [WMLFooterReference]
    public let footnotePr: WMLFootnoteProperties?
    public let endnotePr: WMLEndnoteProperties?
    public let type: WMLSectionType?
    public let pageSize: WMLPageSize?
    public let pageMargin: WMLPageMargin?
    public let paperSource: WMLPaperSource?
    public let pageLayout: WMLPageLayout?
    public let referencePr: WMLReferenceProperties?
    public let pgBorders: WMLPageBorders?
    public let lnNumType: WMLLineNumberType?
    public let pgNumType: WMLPageNumberType?
    public let cols: WMLColumns?
    public let formProt: Bool?
    public let vAlign: WMLVerticalJustification?
    public let noEndnote: Bool?
    public let titlePg: Bool?
    public let textDirection: WMLTextDirection?
    public let bidi: Bool?
    public let rtlGutter: Bool?
    public let docGrid: WMLDocumentGrid?
    public let printerSettings: WMLPrinterSettings?
    public let sectPrChange: WMLSectionPropertiesChange?
    
    public init(headerReference: [WMLHeaderReference] = [],
                footerReference: [WMLFooterReference] = [],
                footnotePr: WMLFootnoteProperties? = nil,
                endnotePr: WMLEndnoteProperties? = nil,
                type: WMLSectionType? = nil,
                pageSize: WMLPageSize? = nil,
                pageMargin: WMLPageMargin? = nil,
                paperSource: WMLPaperSource? = nil,
                pageLayout: WMLPageLayout? = nil,
                referencePr: WMLReferenceProperties? = nil,
                pgBorders: WMLPageBorders? = nil,
                lnNumType: WMLLineNumberType? = nil,
                pgNumType: WMLPageNumberType? = nil,
                cols: WMLColumns? = nil,
                formProt: Bool? = nil,
                vAlign: WMLVerticalJustification? = nil,
                noEndnote: Bool? = nil,
                titlePg: Bool? = nil,
                textDirection: WMLTextDirection? = nil,
                bidi: Bool? = nil,
                rtlGutter: Bool? = nil,
                docGrid: WMLDocumentGrid? = nil,
                printerSettings: WMLPrinterSettings? = nil,
                sectPrChange: WMLSectionPropertiesChange? = nil) {
        self.headerReference = headerReference
        self.footerReference = footerReference
        self.footnotePr = footnotePr
        self.endnotePr = endnotePr
        self.type = type
        self.pageSize = pageSize
        self.pageMargin = pageMargin
        self.paperSource = paperSource
        self.pageLayout = pageLayout
        self.referencePr = referencePr
        self.pgBorders = pgBorders
        self.lnNumType = lnNumType
        self.pgNumType = pgNumType
        self.cols = cols
        self.formProt = formProt
        self.vAlign = vAlign
        self.noEndnote = noEndnote
        self.titlePg = titlePg
        self.textDirection = textDirection
        self.bidi = bidi
        self.rtlGutter = rtlGutter
        self.docGrid = docGrid
        self.printerSettings = printerSettings
        self.sectPrChange = sectPrChange
    }
}

// MARK: - Placeholder types (to be expanded)

public struct WMLAltChunk: Sendable {
    public let relationshipId: String

    public init(relationshipId: String) {
        self.relationshipId = relationshipId
    }

    public init(id: String) {
        self.relationshipId = id
    }

    public var id: String {
        relationshipId
    }
}

// MARK: - Table-Related Types

/// Table Width (w:w)
public struct WMLTableWidth: Sendable {
    public let value: String
    public let type: WMLWidthType
    
    public init(value: String, type: WMLWidthType) {
        self.value = value
        self.type = type
    }
}

/// Width Type
public enum WMLWidthType: String, Sendable {
    case auto = "auto"
    case dxa = "dxa"  // twentieths of a point
    case nil_ = "nil"
    case pct = "pct"  // percentage
}

/// Table Position Properties (w:tblpPr)
public struct WMLTablePositionProperties: Sendable {
    public let leftFromText: String?
    public let rightFromText: String?
    public let topFromText: String?
    public let bottomFromText: String?
    public let vertAnchor: WMLVerticalAnchor?
    public let horzAnchor: WMLHorizontalAnchor?
    public let tblpXSpec: WMLTablePositionXSpec?
    public let tblpX: String?
    public let tblpYSpec: WMLTablePositionYSpec?
    public let tblpY: String?
    
    public init(leftFromText: String? = nil, rightFromText: String? = nil, 
                topFromText: String? = nil, bottomFromText: String? = nil,
                vertAnchor: WMLVerticalAnchor? = nil, horzAnchor: WMLHorizontalAnchor? = nil,
                tblpXSpec: WMLTablePositionXSpec? = nil, tblpX: String? = nil,
                tblpYSpec: WMLTablePositionYSpec? = nil, tblpY: String? = nil) {
        self.leftFromText = leftFromText
        self.rightFromText = rightFromText
        self.topFromText = topFromText
        self.bottomFromText = bottomFromText
        self.vertAnchor = vertAnchor
        self.horzAnchor = horzAnchor
        self.tblpXSpec = tblpXSpec
        self.tblpX = tblpX
        self.tblpYSpec = tblpYSpec
        self.tblpY = tblpY
    }
}

/// Table Overlap (w:tblOverlap)
public enum WMLTableOverlap: String, Sendable {
    case never = "never"
    case overlap = "overlap"
}

/// Table Justification (w:jc)
public enum WMLTableJustification: String, Sendable {
    case left = "left"
    case center = "center"
    case right = "right"
    case both = "both"
    case distribute = "distribute"
    case numTab = "numTab"
    case highKashida = "highKashida"
    case lowKashida = "lowKashida"
    case thaiDistribute = "thaiDistribute"
}

/// Table Cell Spacing (w:tblCellSpacing)
public struct WMLTableCellSpacing: Sendable {
    public let width: WMLTableWidth
    public let type: WMLCellSpacingType
    
    public init(width: WMLTableWidth, type: WMLCellSpacingType = .dxa) {
        self.width = width
        self.type = type
    }
}

/// Cell Spacing Type
public enum WMLCellSpacingType: String, Sendable {
    case dxa = "dxa"
    case auto = "auto"
    case nil_ = "nil"
}

/// Table Cell Margins (w:tblCellMar)
public struct WMLTableCellMargins: Sendable {
    public let top: WMLTableWidth?
    public let left: WMLTableWidth?
    public let bottom: WMLTableWidth?
    public let right: WMLTableWidth?
    
    public init(top: WMLTableWidth? = nil, left: WMLTableWidth? = nil,
                bottom: WMLTableWidth? = nil, right: WMLTableWidth? = nil) {
        self.top = top
        self.left = left
        self.bottom = bottom
        self.right = right
    }
}

/// Table Borders (w:tblBorders)
public struct WMLTableBorders: Sendable {
    public let top: WMLBorder?
    public let left: WMLBorder?
    public let bottom: WMLBorder?
    public let right: WMLBorder?
    public let insideH: WMLBorder?
    public let insideV: WMLBorder?
    
    public init(top: WMLBorder? = nil, left: WMLBorder? = nil,
                bottom: WMLBorder? = nil, right: WMLBorder? = nil,
                insideH: WMLBorder? = nil, insideV: WMLBorder? = nil) {
        self.top = top
        self.left = left
        self.bottom = bottom
        self.right = right
        self.insideH = insideH
        self.insideV = insideV
    }
}

/// Table Layout (w:tblLayout)
public enum WMLTableLayout: String, Sendable {
    case fixed = "fixed"
    case autofit = "autofit"
}

/// Table Cell Margins Default (w:tblCellMarDefault)
public struct WMLTableCellMarginsDefault: Sendable {
    public let top: WMLTableWidth?
    public let left: WMLTableWidth?
    public let bottom: WMLTableWidth?
    public let right: WMLTableWidth?
    
    public init(top: WMLTableWidth? = nil, left: WMLTableWidth? = nil,
                bottom: WMLTableWidth? = nil, right: WMLTableWidth? = nil) {
        self.top = top
        self.left = left
        self.bottom = bottom
        self.right = right
    }
}

/// Table Look (w:tblLook)
public struct WMLTableLook: Sendable {
    public let firstRow: Bool?
    public let lastRow: Bool?
    public let firstColumn: Bool?
    public let lastColumn: Bool?
    public let noHBand: Bool?
    public let noVBand: Bool?
    public let val: String?
    
    public init(firstRow: Bool? = nil, lastRow: Bool? = nil,
                firstColumn: Bool? = nil, lastColumn: Bool? = nil,
                noHBand: Bool? = nil, noVBand: Bool? = nil,
                val: String? = nil) {
        self.firstRow = firstRow
        self.lastRow = lastRow
        self.firstColumn = firstColumn
        self.lastColumn = lastColumn
        self.noHBand = noHBand
        self.noVBand = noVBand
        self.val = val
    }
}

/// Table Row Height (w:trHeight)
public struct WMLTableRowHeight: Sendable {
    public let height: String
    public let rule: WMLHeightRule
    
    public init(height: String, rule: WMLHeightRule = .auto) {
        self.height = height
        self.rule = rule
    }
}

/// Height Rule
public enum WMLHeightRule: String, Sendable {
    case auto = "auto"
    case exact = "exact"
    case atLeast = "atLeast"
}

/// Horizontal Merge (w:hMerge)
public enum WMLHorizontalMerge: String, Sendable {
    case restart = "restart"
    case continue_ = "continue"
}

/// Vertical Merge (w:vMerge)
public enum WMLVerticalMerge: String, Sendable {
    case restart = "restart"
    case continue_ = "continue"
}

/// Table Cell Borders (w:tcBorders)
public struct WMLTableCellBorders: Sendable {
    public let top: WMLBorder?
    public let left: WMLBorder?
    public let bottom: WMLBorder?
    public let right: WMLBorder?
    public let insideH: WMLBorder?
    public let insideV: WMLBorder?
    public let tl2br: WMLBorder?  // top-left to bottom-right diagonal
    public let tr2bl: WMLBorder?  // top-right to bottom-left diagonal
    
    public init(top: WMLBorder? = nil, left: WMLBorder? = nil,
                bottom: WMLBorder? = nil, right: WMLBorder? = nil,
                insideH: WMLBorder? = nil, insideV: WMLBorder? = nil,
                tl2br: WMLBorder? = nil, tr2bl: WMLBorder? = nil) {
        self.top = top
        self.left = left
        self.bottom = bottom
        self.right = right
        self.insideH = insideH
        self.insideV = insideV
        self.tl2br = tl2br
        self.tr2bl = tr2bl
    }
}

/// Vertical Alignment (w:vAlign)
public enum WMLVerticalAlignment: String, Sendable {
    case top = "top"
    case center = "center"
    case both = "both"
    case bottom = "bottom"
}

/// Vertical Anchor
public enum WMLVerticalAnchor: String, Sendable {
    case margin = "margin"
    case page = "page"
    case text = "text"
}

/// Horizontal Anchor
public enum WMLHorizontalAnchor: String, Sendable {
    case margin = "margin"
    case page = "page"
    case text = "text"
}

/// Table Position X Specification
public enum WMLTablePositionXSpec: String, Sendable {
    case left = "left"
    case center = "center"
    case right = "right"
    case inside = "inside"
    case outside = "outside"
}

/// Table Position Y Specification
public enum WMLTablePositionYSpec: String, Sendable {
    case top = "top"
    case center = "center"
    case bottom = "bottom"
    case inside = "inside"
    case outside = "outside"
}

// Additional placeholder types (to be fully implemented)
public typealias WMLField = String  // Placeholder
public typealias WMLBookmark = String  // Placeholder
public typealias WMLMath = String  // Placeholder
public typealias WMLInsertedRun = String  // Placeholder
public typealias WMLDeletedRun = String  // Placeholder
public typealias WMLMoveFrom = String  // Placeholder
public typealias WMLMoveTo = String  // Placeholder
public typealias WMLCommentRange = String  // Placeholder
public typealias WMLTab = String  // Placeholder
public typealias WMLBreak = String  // Placeholder
public typealias WMLCarriageReturn = String  // Placeholder
// WMLDrawing is now properly defined in MediaPart.swift
public typealias WMLPict = String  // Placeholder
public typealias WMLObject = String  // Placeholder
public typealias WMLSeparator = String  // Placeholder
public typealias WMLContinuationSeparator = String  // Placeholder
public typealias WMLDayShort = String  // Placeholder
public typealias WMLMonthShort = String  // Placeholder
public typealias WMLYearShort = String  // Placeholder
public typealias WMLDayLong = String  // Placeholder
public typealias WMLMonthLong = String  // Placeholder
public typealias WMLYearLong = String  // Placeholder
public typealias WMLAnnotationRef = String  // Placeholder
public typealias WMLPageNumber = String  // Placeholder
public typealias WMLNoBreakHyphen = String  // Placeholder
public typealias WMLSoftHyphen = String  // Placeholder
public typealias WMLSymbol = String  // Placeholder
public typealias WMLPositionalTab = String  // Placeholder
public typealias WMLLastRenderedPageBreak = String  // Placeholder
public typealias WMLRuby = String  // Placeholder
public typealias WMLCustomXML = String  // Placeholder
public typealias WMLSmartTag = String  // Placeholder
// MARK: - Structured Document Tag (Content Control)

/// A `w:sdt` structured document tag — Word's Content Control element.
/// SDTs provide labeled, typed input regions in a document and map naturally
/// to Liquid template variables (e.g., `{{ user.name }}` → plain text CC).
public struct WMLStructuredDocumentTag: Sendable {
    public let properties: WMLSDTProperties
    public let content: [WMLBodyContent]

    public init(properties: WMLSDTProperties = WMLSDTProperties(), content: [WMLBodyContent] = []) {
        self.properties = properties
        self.content = content
    }
}

/// Properties of a structured document tag (`w:sdtPr`).
public struct WMLSDTProperties: Sendable {
    /// The programmatic tag (`w:tag w:val="..."`), used for variable binding (e.g., `liquid:user.name`).
    public let tag: String?
    /// The human-readable alias (`w:alias w:val="..."`), shown as the CC title in Word.
    public let alias: String?
    /// Lock mode (`w:lock w:val="..."`).
    public let lock: WMLSDTLock?
    /// Placeholder text docPart reference (`w:placeholder/w:docPart w:val="..."`).
    public let placeholder: String?
    /// Whether the CC is currently showing placeholder text.
    public let showingPlaceholderText: Bool
    /// XPath data binding expression (`w:dataBinding w:xpath="..."`).
    public let dataBinding: String?

    public init(tag: String? = nil, alias: String? = nil, lock: WMLSDTLock? = nil,
                placeholder: String? = nil, showingPlaceholderText: Bool = false,
                dataBinding: String? = nil) {
        self.tag = tag
        self.alias = alias
        self.lock = lock
        self.placeholder = placeholder
        self.showingPlaceholderText = showingPlaceholderText
        self.dataBinding = dataBinding
    }
}

/// Lock modes for structured document tags.
public enum WMLSDTLock: String, Sendable {
    case sdtLocked         // Cannot delete CC
    case contentLocked     // Cannot edit content
    case sdtContentLocked  // Cannot delete or edit
    case unlocked          // Default
}
public typealias WMLProofError = String  // Placeholder
public typealias WMLPermissionStart = String  // Placeholder
public typealias WMLPermissionEnd = String  // Placeholder
public typealias WMLMoveFromRangeStart = String  // Placeholder
public typealias WMLMoveFromRangeEnd = String  // Placeholder
public typealias WMLMoveToRangeStart = String  // Placeholder
public typealias WMLMoveToRangeEnd = String  // Placeholder
public struct WMLHyperlink: Sendable {
    public let relationshipId: String?
    public let anchor: String?
    public let content: [WMLParagraphContent]

    public init(
        relationshipId: String? = nil,
        anchor: String? = nil,
        content: [WMLParagraphContent] = []
    ) {
        self.relationshipId = relationshipId
        self.anchor = anchor
        self.content = content
    }
}

public struct WMLFootnoteReference: Sendable {
    public let id: String

    public init(id: String) {
        self.id = id
    }
}

public struct WMLEndnoteReference: Sendable {
    public let id: String

    public init(id: String) {
        self.id = id
    }
}

public struct WMLCommentReference: Sendable {
    public let id: String

    public init(id: String) {
        self.id = id
    }
}

public struct WMLBookmarkStart: Sendable {
    public let id: String
    public let name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

public struct WMLBookmarkEnd: Sendable {
    public let id: String

    public init(id: String) {
        self.id = id
    }
}

public struct WMLCommentRangeStart: Sendable {
    public let id: String

    public init(id: String) {
        self.id = id
    }
}

public struct WMLCommentRangeEnd: Sendable {
    public let id: String

    public init(id: String) {
        self.id = id
    }
}

// Property types (placeholders - to be fully implemented)
public typealias WMLFrameProperties = String
public typealias WMLNumberingProperties = String
public typealias WMLParagraphBorders = String
public typealias WMLShading = String
public typealias WMLTabs = String
public typealias WMLSpacing = String
public typealias WMLIndentation = String
public typealias WMLJustification = WMLTableJustification  // Reuse table justification
public typealias WMLTextDirection = String
public typealias WMLTextAlignment = String
public typealias WMLTextboxTightWrap = String
public typealias WMLConditionalFormatting = String
public struct WMLRunFonts: Sendable {
    public let ascii: String?
    public let hAnsi: String?
    public let cs: String?
    public let eastAsia: String?
    public let hint: WMLFontHint?

    public init(
        ascii: String? = nil,
        hAnsi: String? = nil,
        cs: String? = nil,
        eastAsia: String? = nil,
        hint: WMLFontHint? = nil
    ) {
        self.ascii = ascii
        self.hAnsi = hAnsi
        self.cs = cs
        self.eastAsia = eastAsia
        self.hint = hint
    }
}

public enum WMLFontHint: String, Sendable, CaseIterable {
    case `default` = "default"
    case eastAsia = "eastAsia"
    case cs = "cs"
}

public struct WMLColor: Sendable {
    public let val: String

    public init(val: String) {
        self.val = val
    }
}

public struct WMLHighlight: Sendable {
    public let val: String

    public init(val: String) {
        self.val = val
    }
}

public struct WMLUnderline: Sendable {
    public let style: WMLUnderlineStyle
    public let color: String?

    public init(style: WMLUnderlineStyle, color: String? = nil) {
        self.style = style
        self.color = color
    }
}

public enum WMLUnderlineStyle: String, Sendable, CaseIterable {
    case none = "none"
    case single = "single"
    case double = "double"
    case dotted = "dotted"
    case dashed = "dashed"
}
public typealias WMLTextEffect = String
public struct WMLBorder: Sendable {
    public let style: WMLBorderStyle
    public let size: Int?
    public let space: Int?
    public let color: String?

    public init(
        style: WMLBorderStyle? = nil,
        type: WMLBorderStyle? = nil,
        size: Int? = nil,
        space: Int? = nil,
        color: String? = nil
    ) {
        self.style = style ?? type ?? .single
        self.size = size
        self.space = space
        self.color = color
    }
}

public enum WMLBorderStyle: String, Sendable, CaseIterable {
    case none = "none"
    case single = "single"
    case double = "double"
    case dotted = "dotted"
    case dashed = "dashed"
}
public typealias WMLFitText = String
public typealias WMLVerticalTextAlignment = String
public typealias WMLEmphasisMark = String
public typealias WMLLanguage = String
public typealias WMLEastAsianLayout = String
// Note: WMLBackground and WMLSectionProperties are properly defined as structs above
// Note: WMLJustification reuses WMLTableJustification defined above
// Note: Other property types are defined elsewhere in the file
public typealias WMLHeaderReference = String
public typealias WMLFooterReference = String
public typealias WMLFootnoteProperties = String
public typealias WMLEndnoteProperties = String
public typealias WMLSectionType = String
public typealias WMLPageSize = String
public typealias WMLPageMargin = String
public typealias WMLPaperSource = String
public typealias WMLPageLayout = String
public typealias WMLReferenceProperties = String
public typealias WMLPageBorders = String
public typealias WMLLineNumberType = String
public typealias WMLPageNumberType = String
public typealias WMLColumns = String
public typealias WMLVerticalJustification = String
public typealias WMLDocumentGrid = String
public typealias WMLPrinterSettings = String
public typealias WMLSectionPropertiesChange = String
