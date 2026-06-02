//
//  DOCXTemplateEngine.swift
//  RhoeDOCX
//
//  Lightweight active DOCX templating bridge for RhoeLiquid.
//

import Foundation
@preconcurrency import RhoeLiquid

// SAFETY: Immutable after init; contains [String: Any] which is not Sendable
private struct UnsafeLiquidContext: @unchecked Sendable {
    let values: [String: Any]
}

private extension LiquidEnvironment {
    nonisolated func render(
        template: String,
        uncheckedContext: UnsafeLiquidContext
    ) async throws -> String {
        try await render(template: template, context: uncheckedContext.values)
    }
}

/// Active DOCX template renderer used by the current package surface.
///
/// The older sprint-era templating stack has been archived while the core
/// document model is normalized. This engine keeps the public rendering API
/// available and safely renders Liquid expressions inside plain text nodes.
public actor DOCXTemplateEngine: Sendable {
    private let environment: LiquidEnvironment

    /// Creates a template engine backed by the supplied `LiquidEnvironment`.
    public init(environment: LiquidEnvironment = LiquidEnvironment()) {
        self.environment = environment
    }

    /// Render Liquid expressions inside the text nodes of a document.
    ///
    /// This lightweight renderer keeps all non-text document structure intact
    /// and only evaluates Liquid in plain text runs and hyperlink content.
    public func render(
        document: WMLDocument,
        context: [String: Any]
    ) async throws -> WMLDocument {
        let renderedBody = try await render(body: document.body, context: context)
        return WMLDocument(body: renderedBody, background: document.background)
    }

    private func render(body: WMLBody, context: [String: Any]) async throws -> WMLBody {
        var renderedContent: [WMLBodyContent] = []
        renderedContent.reserveCapacity(body.content.count)

        for item in body.content {
            renderedContent.append(try await render(bodyContent: item, context: context))
        }

        return WMLBody(content: renderedContent, sectionProperties: body.sectionProperties)
    }

    private func render(bodyContent: WMLBodyContent, context: [String: Any]) async throws -> WMLBodyContent {
        switch bodyContent {
        case .paragraph(let paragraph):
            return .paragraph(try await render(paragraph: paragraph, context: context))
        case .table(let table):
            return .table(try await render(table: table, context: context))
        case .structuredDocumentTag(let sdt):
            return .structuredDocumentTag(try await render(structuredDocumentTag: sdt, context: context))
        case .altChunk, .sectionProperties:
            return bodyContent
        }
    }

    private func render(structuredDocumentTag sdt: WMLStructuredDocumentTag, context: [String: Any]) async throws -> WMLStructuredDocumentTag {
        var renderedContent: [WMLBodyContent] = []
        renderedContent.reserveCapacity(sdt.content.count)

        for item in sdt.content {
            renderedContent.append(try await render(bodyContent: item, context: context))
        }

        return WMLStructuredDocumentTag(properties: sdt.properties, content: renderedContent)
    }

    private func render(paragraph: WMLParagraph, context: [String: Any]) async throws -> WMLParagraph {
        var renderedContent: [WMLParagraphContent] = []
        renderedContent.reserveCapacity(paragraph.content.count)

        for item in paragraph.content {
            renderedContent.append(try await render(paragraphContent: item, context: context))
        }

        return WMLParagraph(
            properties: paragraph.properties,
            content: renderedContent,
            paragraphId: paragraph.paragraphId,
            textId: paragraph.textId
        )
    }

    private func render(paragraphContent: WMLParagraphContent, context: [String: Any]) async throws -> WMLParagraphContent {
        switch paragraphContent {
        case .run(let run):
            return .run(try await render(run: run, context: context))
        case .hyperlink(let hyperlink):
            let renderedContent = try await render(paragraphContents: hyperlink.content, context: context)
            return .hyperlink(
                WMLHyperlink(
                    relationshipId: hyperlink.relationshipId,
                    anchor: hyperlink.anchor,
                    content: renderedContent
                )
            )
        default:
            return paragraphContent
        }
    }

    private func render(paragraphContents: [WMLParagraphContent], context: [String: Any]) async throws -> [WMLParagraphContent] {
        var rendered: [WMLParagraphContent] = []
        rendered.reserveCapacity(paragraphContents.count)

        for item in paragraphContents {
            rendered.append(try await render(paragraphContent: item, context: context))
        }

        return rendered
    }

    private func render(run: WMLRun, context: [String: Any]) async throws -> WMLRun {
        var renderedContent: [WMLRunContent] = []
        renderedContent.reserveCapacity(run.content.count)

        for item in run.content {
            renderedContent.append(try await render(runContent: item, context: context))
        }

        return WMLRun(
            properties: run.properties,
            content: renderedContent,
            rsidRPr: run.rsidRPr,
            rsidDel: run.rsidDel,
            rsidR: run.rsidR
        )
    }

    private func render(runContent: WMLRunContent, context: [String: Any]) async throws -> WMLRunContent {
        switch runContent {
        case .text(let text):
            let rendered = try await environment.render(
                template: text.content,
                uncheckedContext: UnsafeLiquidContext(values: context)
            )
            return .text(WMLText(content: rendered, xmlSpace: text.xmlSpace))
        default:
            return runContent
        }
    }

    private func render(table: WMLTable, context: [String: Any]) async throws -> WMLTable {
        var renderedRows = table.rows

        for rowIndex in renderedRows.indices {
            renderedRows[rowIndex] = try await render(row: renderedRows[rowIndex], context: context)
        }

        return WMLTable(properties: table.properties, grid: table.grid, rows: renderedRows)
    }

    private func render(row: WMLTableRow, context: [String: Any]) async throws -> WMLTableRow {
        var renderedCells = row.cells

        for cellIndex in renderedCells.indices {
            renderedCells[cellIndex] = try await render(cell: renderedCells[cellIndex], context: context)
        }

        return WMLTableRow(properties: row.properties, cells: renderedCells)
    }

    private func render(cell: WMLTableCell, context: [String: Any]) async throws -> WMLTableCell {
        var renderedContent: [WMLTableCellContent] = []
        renderedContent.reserveCapacity(cell.content.count)

        for item in cell.content {
            switch item {
            case .paragraph(let paragraph):
                renderedContent.append(.paragraph(try await render(paragraph: paragraph, context: context)))
            case .table(let table):
                renderedContent.append(.table(try await render(table: table, context: context)))
            default:
                renderedContent.append(item)
            }
        }

        return WMLTableCell(properties: cell.properties, content: renderedContent)
    }
}
