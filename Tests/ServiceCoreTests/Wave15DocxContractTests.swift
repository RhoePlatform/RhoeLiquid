import XCTest
@testable import ServiceCore

@MainActor
final class Wave15DocxContractTests: XCTestCase {
    func testSharedFixturesMatchServiceDocxAnalysisSnapshots() async throws {
        let manager = ServiceManager(configuration: self.makeConfiguration())
        try await manager.startService()
        defer { Task { await manager.stopService() } }

        for loaded in try await Wave15DocxFixtureSupport.loadAllFixtures() {
            let context = loaded.fixture.context.mapValues(\.anyValue)
            let result = try await manager.processDocxTemplate(loaded.data, context: context)

            XCTAssertEqual(
                result.analysis,
                loaded.expectedAnalysis,
                "Expected service analysis to match the shared snapshot for fixture \(loaded.entry.id)"
            )

            for preservedPath in loaded.entry.preservedEntries {
                let original = try await Wave15DocxFixtureSupport.extractEntry(preservedPath, from: loaded.data)
                let rendered = try await Wave15DocxFixtureSupport.extractEntry(preservedPath, from: result.docxData)
                XCTAssertEqual(rendered, original, "Expected preserved entry \(preservedPath) to survive fixture \(loaded.entry.id) byte-for-byte.")
            }
        }
    }

    private func makeConfiguration() -> ServiceConfiguration {
        ServiceConfiguration(
            httpPort: 13482,
            enableSecurity: false,
            performanceMode: .development,
            storageDirectory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString),
            logLevel: .debug
        )
    }
}
