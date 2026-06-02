import Foundation
import Testing
@testable import LiquidCore

@Suite("InlineString Memory Stats Tests")
struct InlineStringMemoryStatsTests {
    @Test("Empty collections report zeroed memory stats")
    func emptyCollectionsReportZeroes() {
        let stats = InlineString.memoryStats(for: [])

        #expect(stats.totalCount == 0)
        #expect(stats.totalBytes == 0)
        #expect(stats.inlineEfficiency == 0)
        #expect(stats.averageInlineSize == 0)
    }

    @Test("UTF-8 slice initializer preserves inline and heap-backed strings")
    func utf8SliceInitializerPreservesContent() {
        let inline = InlineString(utf8: Array("cafe".utf8)[...])
        let unicode = InlineString(utf8: Array("Grüße".utf8)[...])
        let heap = InlineString(utf8: Array("abcdefghijklmnopqrstuvwxyz".utf8)[...])

        #expect(inline.string == "cafe")
        #expect(inline.isInline)
        #expect(unicode.string == "Grüße")
        #expect(unicode.isInline)
        #expect(heap.string == "abcdefghijklmnopqrstuvwxyz")
        #expect(!heap.isInline)
    }
}
