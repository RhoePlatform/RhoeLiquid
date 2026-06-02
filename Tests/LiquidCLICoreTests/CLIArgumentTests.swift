import ArgumentParser
import Testing
@testable import LiquidCLICore

@Suite("CLI Argument Tests")
struct CLIArgumentTests {
    @Test("Analysis output formats parse supported values")
    func outputFormatParsing() throws {
        #expect(OutputFormat(argument: "terminal") == .terminal)
        #expect(OutputFormat(argument: "json") == .json)
        #expect(OutputFormat(argument: "markdown") == .markdown)
        #expect(OutputFormat(argument: "yaml") == nil)

        let command = try AnalyzeCommand.parse(["template.liquid", "--format", "markdown"])
        #expect(command.format == .markdown)
    }

    @Test("Project types parse supported values")
    func projectTypeParsing() throws {
        #expect(ProjectType(argument: "simple") == .simple)
        #expect(ProjectType(argument: "web") == .web)
        #expect(ProjectType(argument: "api") == .api)
        #expect(ProjectType(argument: "documentation") == .documentation)
        #expect(ProjectType(argument: "theme") == nil)

        let command = try InitCommand.parse(["DemoProject", "--type", "api"])
        #expect(command.type == .api)
    }

    @Test("Invalid enum option values fail during parsing")
    func invalidEnumValuesFailParsing() {
        expectThrows {
            _ = try AnalyzeCommand.parse(["template.liquid", "--format", "yaml"])
        }

        expectThrows {
            _ = try InitCommand.parse(["DemoProject", "--type", "theme"])
        }
    }

    @Test("Batch concurrency must be greater than zero")
    func batchConcurrencyValidation() throws {
        let valid = try BatchCommand.parse(["templates", "--concurrency", "1"])
        try valid.validate()

        expectThrows {
            _ = try BatchCommand.parse(["templates", "--concurrency", "0"])
        }
    }

    @Test("Benchmark iterations must be greater than zero")
    func benchmarkIterationsValidation() throws {
        let valid = try BenchmarkCommand.parse(["template.liquid", "--iterations", "1"])
        try valid.validate()

        expectThrows {
            _ = try BenchmarkCommand.parse(["template.liquid", "--iterations", "0"])
        }
    }

    @Test("CLI metadata version follows the engine release version")
    func cliVersionFollowsEngineVersion() {
        #expect(LiquidCLIMetadata.version == "0.1.0")
    }

    private func expectThrows(_ operation: () throws -> Void, sourceLocation: SourceLocation = #_sourceLocation) {
        do {
            try operation()
            Issue.record("Expected operation to throw", sourceLocation: sourceLocation)
        } catch {
            #expect(String(describing: error).isEmpty == false)
        }
    }
}
