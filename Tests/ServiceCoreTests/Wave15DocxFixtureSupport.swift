import Foundation
import RhoeDOCX

struct Wave15DOCXMatrix: Decodable {
    struct Entry: Decodable {
        let id: String
        let fixture: String
        let analysis: String
        let preservedEntries: [String]
    }

    let version: String
    let trustedSubsetVersion: String
    let fixtures: [Entry]
}

struct Wave15DOCXFixture: Decodable {
    struct ArchiveEntry: Decodable {
        let path: String
        let encoding: String
        let content: String
    }

    let name: String
    let description: String
    let context: [String: JSONValue]
    let entries: [ArchiveEntry]
}

enum JSONValue: Decodable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value.")
        }
    }

    var anyValue: Any {
        switch self {
        case .string(let value):
            return value
        case .number(let value):
            return value.rounded(.towardZero) == value ? Int(value) : value
        case .bool(let value):
            return value
        case .object(let value):
            return value.mapValues(\.anyValue)
        case .array(let value):
            return value.map(\.anyValue)
        case .null:
            return NSNull()
        }
    }
}

struct LoadedWave15DOCXFixture {
    let entry: Wave15DOCXMatrix.Entry
    let fixture: Wave15DOCXFixture
    let expectedAnalysis: DOCXTemplateAnalysis
    let data: Data
}

enum Wave15DocxFixtureSupport {
    static func loadAllFixtures() async throws -> [LoadedWave15DOCXFixture] {
        let matrixURL = fixturesDirectory.appendingPathComponent("matrix.json")
        let matrixData = try Data(contentsOf: matrixURL)
        let matrix = try JSONDecoder().decode(Wave15DOCXMatrix.self, from: matrixData)

        return try await matrix.fixtures.mapAsync { entry in
            let fixtureURL = fixturesDirectory.appendingPathComponent(entry.fixture)
            let analysisURL = fixturesDirectory.appendingPathComponent(entry.analysis)
            let fixture = try JSONDecoder().decode(Wave15DOCXFixture.self, from: Data(contentsOf: fixtureURL))
            let expectedAnalysis = try JSONDecoder().decode(DOCXTemplateAnalysis.self, from: Data(contentsOf: analysisURL))
            let data = try await buildArchive(from: fixture)
            return LoadedWave15DOCXFixture(
                entry: entry,
                fixture: fixture,
                expectedAnalysis: expectedAnalysis,
                data: data
            )
        }
    }

    static func extractEntry(_ path: String, from data: Data) async throws -> Data {
        let archive = ZIPArchive(data: data)
        let package = try await archive.open()
        return try await package.extractData(for: path)
    }

    private static var fixturesDirectory: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures/Wave15DOCX")
    }

    private static func buildArchive(from fixture: Wave15DOCXFixture) async throws -> Data {
        let builder = ZIPBuilder()
        for entry in fixture.entries {
            let data: Data
            switch entry.encoding {
            case "utf8":
                data = Data(entry.content.utf8)
            case "base64":
                guard let decoded = Data(base64Encoded: entry.content) else {
                    throw NSError(domain: "Wave15DocxFixtureSupport", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid base64 fixture content for \(entry.path)"])
                }
                data = decoded
            default:
                throw NSError(domain: "Wave15DocxFixtureSupport", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unsupported fixture encoding \(entry.encoding) for \(entry.path)"])
            }

            await builder.addFile(
                path: entry.path,
                data: data,
                compressionMethod: .stored
            )
        }
        return try await builder.build()
    }
}

private extension Array {
    func mapAsync<T>(
        _ transform: (Element) async throws -> T
    ) async throws -> [T] {
        var results: [T] = []
        results.reserveCapacity(self.count)
        for element in self {
            results.append(try await transform(element))
        }
        return results
    }
}
