import Testing
@testable import RhoeLiquid

@Suite("Performance Metrics Tests")
struct PerformanceMetricsTests {
    @Test("renderWithMetrics reports actual AST node counts")
    func renderWithMetricsReportsNodeCounts() async throws {
        let engine = LiquidEngine(configuration: LiquidConfiguration(cacheEnabled: false))

        let (_, metrics) = try await engine.renderWithMetrics(
            template: "Hi {{ name }}",
            context: ["name": "World"]
        )

        #expect(metrics.nodeCount == 3)
        #expect(metrics.tokenCount > 0)
    }

    @Test("renderWithMetrics reports inline and heap-backed string storage")
    func renderWithMetricsReportsMemoryAccounting() async throws {
        let engine = LiquidEngine(configuration: LiquidConfiguration(cacheEnabled: false))
        let template = """
        {{ "supercalifragilisticexpialidocious" }}
        {{ short }}
        """

        let (_, metrics) = try await engine.renderWithMetrics(
            template: template,
            context: ["short": "ok"]
        )

        #expect(metrics.memoryStats.totalCount > 0)
        #expect(metrics.memoryStats.totalBytes > 0)
        #expect(metrics.memoryStats.inlineCount > 0)
        #expect(metrics.memoryStats.heapCount > 0)
        #expect(metrics.memoryStats.inlineEfficiency > 0)
    }

    @Test("Cached metric renders still report memory stats")
    func cachedMetricsRetainMemoryAccounting() async throws {
        let engine = LiquidEngine(configuration: LiquidConfiguration(cacheEnabled: true))
        let template = "{{ \"supercalifragilisticexpialidocious\" }} {{ value }}"

        _ = try await engine.renderWithMetrics(template: template, context: ["value": "v"])
        let (_, metrics) = try await engine.renderWithMetrics(template: template, context: ["value": "v"])

        #expect(metrics.cacheHit)
        #expect(metrics.tokenCount == 0)
        #expect(metrics.memoryStats.totalCount > 0)
        #expect(metrics.memoryStats.heapCount > 0)
    }
}
