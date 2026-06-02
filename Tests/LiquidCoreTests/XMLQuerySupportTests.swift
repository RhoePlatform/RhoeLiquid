import Foundation
import Testing
@testable import LiquidCore

@Suite("XML Query Support Tests")
struct XMLQuerySupportTests {
    @Test("HTML selectors match compound descendant and child patterns")
    func htmlSelectorsMatchCompoundPatterns() async throws {
        let html = """
        <!DOCTYPE html>
        <html>
          <body>
            <div id="main-content" class="content hero">
              <p class="product-item featured">First</p>
              <p class="product-item">Second</p>
            </div>
            <ul><li>One</li><li>Two</li></ul>
            <a class="btn btn-primary" target="_blank" href="/docs">Docs</a>
          </body>
        </html>
        """

        let document = try await loadMarkup(html, pathExtension: "html")

        #expect(document["select"] == .null)
        #expect(document["selectAll"] == .null)

        let featured = document.select("#main-content > p.featured")
        #expect(featured.textContent == "First")

        guard case .array(let productItems) = document.selectAll("div.content p.product-item") else {
            Issue.record("Expected CSS selector to return an array of matching elements")
            return
        }

        #expect(productItems.count == 2)
        #expect(productItems.compactMap(\.textContent) == ["First", "Second"])

        let externalLink = document.select("a.btn.btn-primary[target='_blank']")
        #expect(externalLink.attribute("href") == .string("/docs"))
    }

    @Test("XPath supports common predicates and attribute extraction")
    func xpathSupportsCommonPredicates() async throws {
        let xml = """
        <catalog>
          <book id="b1" category="fiction">
            <title>Guide One</title>
            <price>12.5</price>
          </book>
          <book id="b2" category="nonfiction">
            <title>Guide Two</title>
            <price>8.0</price>
          </book>
          <book id="b3" category="fiction">
            <title>Reference</title>
            <price>15.0</price>
          </book>
        </catalog>
        """

        let document = try await loadMarkup(xml, pathExtension: "xml")

        guard case .array(let fictionBooks) = document.xpath("//book[@category='fiction']") else {
            Issue.record("Expected XPath category selection to return an array")
            return
        }
        #expect(fictionBooks.count == 2)

        guard case .array(let expensiveBooks) = document.xpath("//book[price>10]") else {
            Issue.record("Expected XPath numeric predicate to return an array")
            return
        }
        #expect(expensiveBooks.count == 2)

        guard case .array(let guideTitles) = document.xpath("//title[contains(text(),'Guide')]") else {
            Issue.record("Expected XPath contains(text()) to return an array")
            return
        }
        #expect(guideTitles.compactMap(\.textContent) == ["Guide One", "Guide Two"])

        guard case .array(let categories) = document.xpath("//book/@category") else {
            Issue.record("Expected XPath attribute projection to return an array")
            return
        }
        #expect(categories == [.string("fiction"), .string("nonfiction"), .string("fiction")])
    }

    @Test("XPath supports positional predicates on descendant queries")
    func xpathSupportsPositionalPredicates() async throws {
        let xml = """
        <catalog>
          <book id="b1"><title>One</title></book>
          <book id="b2"><title>Two</title></book>
          <book id="b3"><title>Three</title></book>
        </catalog>
        """

        let document = try await loadMarkup(xml, pathExtension: "xml")

        #expect(document.xpath("//book[1]").attribute("id") == .string("b1"))
        #expect(document.xpath("//book[last()]").attribute("id") == .string("b3"))

        guard case .array(let trailingBooks) = document.xpath("//book[position()>1]") else {
            Issue.record("Expected positional XPath filter to return an array")
            return
        }

        #expect(trailingBooks.count == 2)
        #expect(trailingBooks.compactMap { $0.attribute("id") } == [.string("b2"), .string("b3")])
    }

    private func loadMarkup(_ source: String, pathExtension: String) async throws -> DataValue {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("liquidcore_xml_query_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let file = directory.appendingPathComponent("fixture.\(pathExtension)")
        try source.write(to: file, atomically: true, encoding: .utf8)

        return try await XMLDataSource().load(from: file, options: LoadOptions())
    }
}
