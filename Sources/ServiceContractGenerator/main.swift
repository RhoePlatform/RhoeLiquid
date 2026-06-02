import Foundation
import ServiceCore

@main
struct ServiceContractGenerator {
    static func main() throws {
        let arguments = Array(CommandLine.arguments.dropFirst())
        let yaml = ServiceContractCatalog.openAPIYAML()
        let schemaJSON = try ServiceContractCatalog.schemaJSON()
        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let openAPIURL = cwd.appendingPathComponent("api/openapi.yaml")
        let schemaURL = cwd.appendingPathComponent("api/schema.json")

        if arguments.first == "--write" {
            try FileManager.default.createDirectory(
                at: openAPIURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try yaml.write(to: openAPIURL, atomically: true, encoding: .utf8)
            try schemaJSON.write(to: schemaURL, atomically: true, encoding: .utf8)
            FileHandle.standardError.write(Data("Wrote \(openAPIURL.path)\n".utf8))
            FileHandle.standardError.write(Data("Wrote \(schemaURL.path)\n".utf8))
            return
        }

        if arguments.first == "--check" {
            let checkedInYAML = try String(contentsOf: openAPIURL, encoding: .utf8)
            let checkedInJSON = try String(contentsOf: schemaURL, encoding: .utf8)

            guard checkedInYAML == yaml else {
                FileHandle.standardError.write(Data("OpenAPI snapshot drift detected at \(openAPIURL.path)\n".utf8))
                throw ExitCode.failure
            }

            guard checkedInJSON == schemaJSON else {
                FileHandle.standardError.write(Data("Schema JSON snapshot drift detected at \(schemaURL.path)\n".utf8))
                throw ExitCode.failure
            }

            FileHandle.standardError.write(Data("Contract snapshots are synchronized.\n".utf8))
            return
        }

        FileHandle.standardOutput.write(Data(yaml.utf8))
    }
}

private enum ExitCode {
    static let failure = NSError(domain: "ServiceContractGenerator", code: 1)
}
