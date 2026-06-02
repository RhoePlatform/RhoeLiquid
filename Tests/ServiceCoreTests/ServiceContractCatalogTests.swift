import Foundation
import XCTest
@testable import ServiceCore

final class ServiceContractCatalogTests: XCTestCase {
    func testCheckedInOpenAPIYAMLMatchesGeneratedContract() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let openAPIURL = repositoryRoot.appendingPathComponent("api/openapi.yaml")

        let checkedIn = try String(contentsOf: openAPIURL, encoding: .utf8)
        let generated = ServiceContractCatalog.openAPIYAML()

        XCTAssertEqual(checkedIn, generated)
    }

    func testCheckedInSchemaJSONMatchesGeneratedContract() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let schemaURL = repositoryRoot.appendingPathComponent("api/schema.json")

        let checkedIn = try String(contentsOf: schemaURL, encoding: .utf8)
        let generated = try ServiceContractCatalog.schemaJSON()

        XCTAssertEqual(checkedIn, generated)
    }
}
