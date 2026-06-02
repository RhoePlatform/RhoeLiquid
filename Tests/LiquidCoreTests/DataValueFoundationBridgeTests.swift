import Foundation
import Testing
@testable import LiquidCore

@Suite("DataValue Foundation Bridge Tests")
struct DataValueFoundationBridgeTests {
    @Test("JSONSerialization dictionaries preserve keys and values")
    func jsonSerializationDictionaryBridges() throws {
        let data = #"{"name":"Ada","count":2}"#.data(using: .utf8)!
        let json = try JSONSerialization.jsonObject(with: data)
        let value = DataValue(from: json)

        guard case .object(let object) = value else {
            Issue.record("Expected object DataValue, got \(value)")
            return
        }

        #expect(object["name"] == .string("Ada"))
        #expect(object["count"] == .int(2))

        let liquidValue = value.liquidValue as? [String: Any]
        #expect(liquidValue?["name"] as? String == "Ada")
        #expect(liquidValue?["count"] as? Int == 2)
    }

    @Test("JSONDataSource preserves object fields when loading from disk")
    func jsonDataSourceLoadPreservesFields() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("liquidcore_json_load_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let file = directory.appendingPathComponent("payload.json")
        try #"{"name":"Ada","count":2}"#.write(to: file, atomically: true, encoding: .utf8)

        let loader = JSONDataSource()
        let value = try await loader.load(from: file, options: LoadOptions())

        guard case .object(let object) = value else {
            Issue.record("Expected object DataValue, got \(value)")
            return
        }

        #expect(object["name"] == .string("Ada"))
        #expect(object["count"] == .int(2))
    }

    @Test("DataLoaderRegistry preserves object fields for registered JSON loaders")
    func dataLoaderRegistryPreservesFields() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("liquidcore_registry_json_load_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let file = directory.appendingPathComponent("payload.json")
        try #"{"name":"Ada","count":2}"#.write(to: file, atomically: true, encoding: .utf8)

        let registry = DataLoaderRegistry()
        await registry.register(JSONDataSource())
        let value = try await registry.load(from: file.path)

        guard case .object(let object) = value else {
            Issue.record("Expected object DataValue, got \(value)")
            return
        }

        #expect(object["name"] == .string("Ada"))
        #expect(object["count"] == .int(2))
    }

    @Test("File-backed registry loads prefer the file extension over the generic file scheme")
    func fileRegistryPrefersExtensionSpecificLoader() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("liquidcore_registry_extension_priority_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let file = directory.appendingPathComponent("payload.json")
        try #"{"name":"Ada","count":2}"#.write(to: file, atomically: true, encoding: .utf8)

        let registry = DataLoaderRegistry()
        await registry.register(JSONDataSource())
        await registry.register(YAMLDataSource())
        await registry.register(TOMLDataSource())

        let value = try await registry.load(from: file.path)

        guard case .object(let object) = value else {
            Issue.record("Expected object DataValue, got \(value)")
            return
        }

        #expect(object["name"] == .string("Ada"))
        #expect(object["count"] == .int(2))
    }
}
