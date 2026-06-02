//
//  TablerowTests.swift
//  GoldenLiquidTests
//
//  Auto-generated from golden_liquid.json — do not edit manually
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import OrderedCollections
import Testing
@testable import RhoeLiquid

@Suite("Golden: tablerow", .serialized)
struct GoldenTablerowTests {

    @Test("tags, tablerow, break from a tablerow loop", .timeLimit(.minutes(1)))
    func breakFromATablerowLoop() async throws {
        let result = try await renderWithTimeout(template: "{% tablerow n in (1..3) cols:2 %}{{n}}{% break %}{{n}}{% endtablerow %}", context: [:])
        #expect(result == "<tr class=\"row1\">\n<td class=\"col1\">1</td></tr>\n")
    }

    @Test("tags, tablerow, break from a tablerow loop inside a for loop", .timeLimit(.minutes(1)))
    func breakFromATablerowLoopInsideAForLoop() async throws {
        let result = try await renderWithTimeout(template: "{% for i in (1..2) -%}\\n{% for j in (1..2) -%}\\n{% tablerow k in (1..3) %}{% break %}{% endtablerow -%}\\nloop j={{ j }}\\n{% endfor -%}\\nloop i={{ i }}\\n{% endfor -%}\\nafter loop\\n", context: [:])
        #expect(result == "\\n\\n<tr class=\"row1\">\n<td class=\"col1\"></td></tr>\n\\nloop j=1\\n\\n<tr class=\"row1\">\n<td class=\"col1\"></td></tr>\n\\nloop j=2\\n\\nloop i=1\\n\\n\\n<tr class=\"row1\">\n<td class=\"col1\"></td></tr>\n\\nloop j=1\\n\\n<tr class=\"row1\">\n<td class=\"col1\"></td></tr>\n\\nloop j=2\\n\\nloop i=2\\n\\nafter loop\\n")
    }

    @Test("tags, tablerow, cols is a float", .timeLimit(.minutes(1)))
    func colsIsAFloat() async throws {
        let result = try await renderWithTimeout(template: "{% tablerow i in (1..4) cols:2.6 %}{{ i }} {{ tablerowloop.col_first }}{% endtablerow %}", context: [:])
        #expect(result == "<tr class=\"row1\">\n<td class=\"col1\">1 true</td><td class=\"col2\">2 false</td></tr>\n<tr class=\"row2\"><td class=\"col1\">3 true</td><td class=\"col2\">4 false</td></tr>\n")
    }

    @Test("tags, tablerow, cols is a string", .timeLimit(.minutes(1)))
    func colsIsAString() async throws {
        let result = try await renderWithTimeout(template: "{% tablerow i in (1..4) cols:'2' %}{{ i }} {{ tablerowloop.col_first }}{% endtablerow %}", context: [:])
        #expect(result == "<tr class=\"row1\">\n<td class=\"col1\">1 true</td><td class=\"col2\">2 false</td></tr>\n<tr class=\"row2\"><td class=\"col1\">3 true</td><td class=\"col2\">4 false</td></tr>\n")
    }

    @Test("tags, tablerow, continue from a tablerow loop", .timeLimit(.minutes(1)))
    func continueFromATablerowLoop() async throws {
        let result = try await renderWithTimeout(template: "{% tablerow n in (1..3) cols:2 %}{{n}}{% continue %}{{n}}{% endtablerow %}", context: [:])
        #expect(result == "<tr class=\"row1\">\n<td class=\"col1\">1</td><td class=\"col2\">2</td></tr>\n<tr class=\"row2\"><td class=\"col1\">3</td></tr>\n")
    }

    @Test("tags, tablerow, limit is a string", .timeLimit(.minutes(1)))
    func limitIsAString() async throws {
        let result = try await renderWithTimeout(template: "{% tablerow i in (1..4) limit:'2' %}{{ i }} {{ tablerowloop.col_first }}{% endtablerow %}", context: [:])
        #expect(result == "<tr class=\"row1\">\n<td class=\"col1\">1 true</td><td class=\"col2\">2 false</td></tr>\n")
    }

    @Test("tags, tablerow, no cols param", .timeLimit(.minutes(1)))
    func noColsParam() async throws {
        let result = try await renderWithTimeout(template: "{% tablerow i in (1..2) %}\ncol: {{ tablerowloop.col }}\ncol0: {{ tablerowloop.col0 }}\ncol_first: {{ tablerowloop.col_first }}\ncol_last: {{ tablerowloop.col_last }}\nfirst: {{ tablerowloop.first }}\nindex: {{ tablerowloop.index }}\nindex0: {{ tablerowloop.index0 }}\nlast: {{ tablerowloop.last }}\nlength: {{ tablerowloop.length }}\nrindex: {{ tablerowloop.rindex }}\nrindex0: {{ tablerowloop.rindex0 }}\nrow: {{ tablerowloop.row }}\n{% endtablerow %}", context: [:])
        #expect(result == "<tr class=\"row1\">\n<td class=\"col1\">\ncol: 1\ncol0: 0\ncol_first: true\ncol_last: false\nfirst: true\nindex: 1\nindex0: 0\nlast: false\nlength: 2\nrindex: 2\nrindex0: 1\nrow: 1\n</td><td class=\"col2\">\ncol: 2\ncol0: 1\ncol_first: false\ncol_last: true\nfirst: false\nindex: 2\nindex0: 1\nlast: true\nlength: 2\nrindex: 1\nrindex0: 0\nrow: 1\n</td></tr>\n")
    }

    @Test("tags, tablerow, offset is a string", .timeLimit(.minutes(1)))
    func offsetIsAString() async throws {
        let result = try await renderWithTimeout(template: "{% tablerow i in (1..4) offset:'2' %}{{ i }} {{ tablerowloop.col_first }}{% endtablerow %}", context: [:])
        #expect(result == "<tr class=\"row1\">\n<td class=\"col1\">3 true</td><td class=\"col2\">4 false</td></tr>\n")
    }

    @Test("tags, tablerow, one row", .timeLimit(.minutes(1)))
    func oneRow() async throws {
        let ctx: [String: Any] = [
            "collection": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("tags", ["tag1", "tag2", "tag3", "tag4"] as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% tablerow tag in collection.tags %}{{ tag }}{% endtablerow %}", context: ctx)
        #expect(result == "<tr class=\"row1\">\n<td class=\"col1\">tag1</td><td class=\"col2\">tag2</td><td class=\"col3\">tag3</td><td class=\"col4\">tag4</td></tr>\n")
    }

    @Test("tags, tablerow, one row with limit", .timeLimit(.minutes(1)))
    func oneRowWithLimit() async throws {
        let ctx: [String: Any] = [
            "collection": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("tags", ["tag1", "tag2", "tag3", "tag4"] as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% tablerow tag in collection.tags limit: 2 %}{{ tag }}{% endtablerow %}", context: ctx)
        #expect(result == "<tr class=\"row1\">\n<td class=\"col1\">tag1</td><td class=\"col2\">tag2</td></tr>\n")
    }

    @Test("tags, tablerow, one row with offset", .timeLimit(.minutes(1)))
    func oneRowWithOffset() async throws {
        let ctx: [String: Any] = [
            "collection": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("tags", ["tag1", "tag2", "tag3", "tag4"] as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% tablerow tag in collection.tags offset: 2 %}{{ tag }}{% endtablerow %}", context: ctx)
        #expect(result == "<tr class=\"row1\">\n<td class=\"col1\">tag3</td><td class=\"col2\">tag4</td></tr>\n")
    }

    @Test("tags, tablerow, two column odd range", .timeLimit(.minutes(1)))
    func twoColumnOddRange() async throws {
        let result = try await renderWithTimeout(template: "{% tablerow i in (1..5) cols:2 %}{{ i }} {{ tablerowloop.col_first }}{% endtablerow %}", context: [:])
        #expect(result == "<tr class=\"row1\">\n<td class=\"col1\">1 true</td><td class=\"col2\">2 false</td></tr>\n<tr class=\"row2\"><td class=\"col1\">3 true</td><td class=\"col2\">4 false</td></tr>\n<tr class=\"row3\"><td class=\"col1\">5 true</td></tr>\n")
    }

    @Test("tags, tablerow, two column odd range row numbers", .timeLimit(.minutes(1)))
    func twoColumnOddRangeRowNumbers() async throws {
        let result = try await renderWithTimeout(template: "{% tablerow i in (1..5) cols:2 %}{{ i }} {{ tablerowloop.row }}{% endtablerow %}", context: [:])
        #expect(result == "<tr class=\"row1\">\n<td class=\"col1\">1 1</td><td class=\"col2\">2 1</td></tr>\n<tr class=\"row2\"><td class=\"col1\">3 2</td><td class=\"col2\">4 2</td></tr>\n<tr class=\"row3\"><td class=\"col1\">5 3</td></tr>\n")
    }

    @Test("tags, tablerow, two column range", .timeLimit(.minutes(1)))
    func twoColumnRange() async throws {
        let result = try await renderWithTimeout(template: "{% tablerow i in (1..4) cols:2 %}{{ i }} {{ tablerowloop.col_first }}{% endtablerow %}", context: [:])
        #expect(result == "<tr class=\"row1\">\n<td class=\"col1\">1 true</td><td class=\"col2\">2 false</td></tr>\n<tr class=\"row2\"><td class=\"col1\">3 true</td><td class=\"col2\">4 false</td></tr>\n")
    }

    @Test("tags, tablerow, two columns", .timeLimit(.minutes(1)))
    func twoColumns() async throws {
        let ctx: [String: Any] = [
            "collection": OrderedDictionary<String, Any>(uniqueKeysWithValues: [
                ("tags", ["tag1", "tag2", "tag3", "tag4"] as Any)
            ])
        ] as [String: Any]
        let result = try await renderWithTimeout(template: "{% tablerow tag in collection.tags cols:2 %}{{ tag }}{% endtablerow %}", context: ctx)
        #expect(result == "<tr class=\"row1\">\n<td class=\"col1\">tag1</td><td class=\"col2\">tag2</td></tr>\n<tr class=\"row2\"><td class=\"col1\">tag3</td><td class=\"col2\">tag4</td></tr>\n")
    }
}
