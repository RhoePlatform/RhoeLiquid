//
//  ValidateCommand.swift
//  LiquidCLICore
//
//  Created as part of RhoeLiquid
//  A high-performance Swift implementation of the Liquid template language
//

import ArgumentParser
import Foundation
import RhoeLiquid

public struct ValidateCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "validate",
        abstract: "Validate Liquid template syntax.",
        discussion: """
        Discovers template files at a path and performs a render-time syntax \
        validation pass with an empty context, reporting all discovered failures.
        """
    )

    @Argument(
        help: "Template file or directory path.",
        completion: .file(extensions: ["liquid", "html"])
    )
    public var path: String

    @Flag(name: .long, help: "Show detailed output for each valid file.")
    public var verbose: Bool = false

    public init() {}

    public func run() async throws {
        let templates = try discoverTemplates(at: path)
        if templates.isEmpty {
            TerminalUI.warn("No template files found at \(path)")
            throw ExitCode.failure
        }

        let engine = LiquidEngine()
        var errorCount = 0
        var validCount = 0

        for info in templates {
            let source = try String(contentsOfFile: info.path, encoding: .utf8)
            do {
                _ = try await engine.render(template: source, context: [:])
                validCount += 1
                if verbose {
                    TerminalUI.success(info.name)
                }
            } catch {
                errorCount += 1
                TerminalUI.error("\(info.name): \(error)")
            }
        }

        print("")
        if errorCount == 0 {
            TerminalUI.success("All \(validCount) template(s) valid")
        } else {
            TerminalUI.error("\(errorCount) error(s) in \(templates.count) template(s)")
            throw ExitCode.failure
        }
    }
}
