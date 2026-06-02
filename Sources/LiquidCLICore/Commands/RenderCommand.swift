//
//  RenderCommand.swift
//  LiquidCLICore
//
//  Created as part of RhoeLiquid
//  A high-performance Swift implementation of the Liquid template language
//

import ArgumentParser
import Foundation
import RhoeLiquid

public struct RenderCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "render",
        abstract: "Render a Liquid template.",
        discussion: """
        Reads a `.liquid` or HTML template from disk, optionally loads a JSON \
        context object, and writes rendered output to stdout or a file.
        """
    )

    @Argument(
        help: "Template file path.",
        completion: .file(extensions: ["liquid", "html"])
    )
    public var template: String

    @Option(
        name: .long,
        help: "Context data file containing a JSON object.",
        completion: .file(extensions: ["json"])
    )
    public var context: String?

    @Option(
        name: .shortAndLong,
        help: "Output file path. Defaults to stdout.",
        completion: .file()
    )
    public var output: String?

    @Flag(name: .long, help: "Show render timing and byte-size metrics.")
    public var metrics: Bool = false

    public init() {}

    public func run() async throws {
        let fm = FileManager.default
        guard fm.fileExists(atPath: template) else {
            TerminalUI.error("Template not found: \(template)")
            throw ExitCode.failure
        }

        let source = try String(contentsOfFile: template, encoding: .utf8)
        var contextData: [String: Any] = [:]
        if let contextPath = context {
            contextData = try loadContextData(from: contextPath)
        }

        let cliContext = CLIContext()
        let start = Date().timeIntervalSinceReferenceDate
        let result = try await cliContext.render(template: source, context: contextData)
        let elapsed = Date().timeIntervalSinceReferenceDate - start

        if let outputPath = output {
            try result.write(toFile: outputPath, atomically: true, encoding: .utf8)
            TerminalUI.success("Rendered to \(outputPath)")
        } else {
            print(result)
        }

        if metrics {
            TerminalUI.header("Performance")
            print("  Render time: \(TerminalUI.duration(elapsed))")
            print("  Template size: \(TerminalUI.fileSize(source.utf8.count))")
            print("  Output size: \(TerminalUI.fileSize(result.utf8.count))")
        }
    }
}
