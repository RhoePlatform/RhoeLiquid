import Testing
import BenchmarkSupport

@Suite("Benchmark Summary Tests")
struct BenchmarkSummaryTests {
    @Test("Benchmark summaries include p95 and standard deviation")
    func benchmarkSummaryStatistics() {
        let summary = BenchmarkSummary(samplesMicroseconds: [10, 20, 30, 40, 100])

        #expect(summary.medianMicroseconds == 30)
        #expect(summary.meanMicroseconds == 40)
        #expect(summary.percentile95Microseconds == 100)
        #expect(abs(summary.standardDeviationMicroseconds - 31.6227766) < 0.0001)

        let formatted = summary.formatted(label: "Example", iterations: 5)
        #expect(formatted.contains("p95"))
        #expect(formatted.contains("stdev"))
    }
}
