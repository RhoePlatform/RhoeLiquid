import XCTest
@testable import ServiceCore

final class ServiceJobStoreTests: XCTestCase {
    func testExpiredJobsAreRemovedOnLookup() async throws {
        let storageDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = ServiceJobStore(storageDirectory: storageDirectory, retentionInterval: 0.05)

        let created = await store.create(kind: .render)
        try await Task.sleep(nanoseconds: 120_000_000)

        let expired = await store.job(id: created.id)
        XCTAssertNil(expired)

        try? FileManager.default.removeItem(at: storageDirectory)
    }

    func testCancelledJobsRemainVisibleUntilExpiry() async throws {
        let storageDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = ServiceJobStore(storageDirectory: storageDirectory, retentionInterval: 3600)

        let created = await store.create(kind: .renderDocx)
        let cancelled = await store.cancel(id: created.id)
        let fetched = await store.job(id: created.id)

        XCTAssertEqual(cancelled?.status, .cancelled)
        XCTAssertEqual(fetched?.status, .cancelled)
        XCTAssertEqual(fetched?.kind, .renderDocx)

        try? FileManager.default.removeItem(at: storageDirectory)
    }
}
