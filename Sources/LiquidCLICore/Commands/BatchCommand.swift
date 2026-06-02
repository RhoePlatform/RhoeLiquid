//
//  BatchCommand.swift
//  LiquidCLICore
//
//  Created as part of RhoeLiquid
//  A high-performance Swift implementation of the Liquid template language
//

import ArgumentParser
import Foundation
import RhoeLiquid

public struct BatchCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "batch",
        abstract: "Batch-render multiple templates.",
        discussion: """
        Discovers `.liquid` and `.html` templates in a directory, renders them \
        with optional per-template JSON context files, and writes HTML output to \
        the selected output directory.
        """
    )

    @Argument(
        help: "Template directory path.",
        completion: .directory
    )
    public var templateDir: String

    @Option(
        name: .long,
        help: "Directory containing optional JSON context files.",
        completion: .directory
    )
    public var contextDir: String?

    @Option(
        name: .shortAndLong,
        help: "Output directory.",
        completion: .directory
    )
    public var output: String = "output"

    @Option(name: .long, help: "Maximum number of parallel renders. Must be greater than zero.")
    public var concurrency: Int = 4

    @Flag(name: .long, help: "Continue rendering remaining templates after a failure.")
    public var continueOnError: Bool = false

    public init() {}

    public func validate() throws {
        guard concurrency > 0 else {
            throw ValidationError("--concurrency must be greater than zero.")
        }
    }

    public func run() async throws {
        let templates = try discoverTemplates(at: templateDir)
        if templates.isEmpty {
            TerminalUI.warn("No templates found in \(templateDir)")
            throw ExitCode.failure
        }

        // Create output directory
        let fm = FileManager.default
        try fm.createDirectory(atPath: output, withIntermediateDirectories: true)

        TerminalUI.header("Batch Render")
        print("  Templates: \(templates.count)")
        print("  Output: \(output)")
        print("  Concurrency: \(concurrency)")
        print("")

        let engine = LiquidEngine()
        let startTime = Date().timeIntervalSinceReferenceDate
        var successCount = 0
        var errorCount = 0

        // Collect template paths and context dir for Sendable closure capture
        let capturedContextDir = contextDir
        let capturedOutput = output

        // Process with bounded concurrency
        let results: [(String, Result<String, Error>)] = await withTaskGroup(
            of: (String, Result<String, Error>).self,
            returning: [(String, Result<String, Error>)].self
        ) { group in
            var pending = 0
            var collected: [(String, Result<String, Error>)] = []

            for info in templates {
                if pending >= concurrency {
                    if let result = await group.next() {
                        collected.append(result)
                    }
                    pending -= 1
                }

                let templatePath = info.path
                let templateName = info.name
                group.addTask {
                    do {
                        let source = try String(contentsOfFile: templatePath, encoding: .utf8)
                        // Try to find matching context file
                        var ctx: [String: Any] = [:]
                        if let ctxDir = capturedContextDir {
                            let taskFM = FileManager.default
                            let ctxPath = (ctxDir as NSString).appendingPathComponent(
                                templateName.replacingOccurrences(of: ".liquid", with: ".json")
                            )
                            if taskFM.fileExists(atPath: ctxPath) {
                                ctx = (try? loadContextData(from: ctxPath)) ?? [:]
                            }
                        }
                        let rendered = try await engine.render(template: source, context: ctx)
                        return (templateName, .success(rendered))
                    } catch {
                        return (templateName, .failure(error))
                    }
                }
                pending += 1
            }

            for await result in group {
                collected.append(result)
            }

            return collected
        }

        // Process results sequentially
        for (name, outcome) in results {
            switch outcome {
            case .success(let rendered):
                let outPath = (capturedOutput as NSString).appendingPathComponent(
                    name.replacingOccurrences(of: ".liquid", with: ".html")
                )
                try? rendered.write(toFile: outPath, atomically: true, encoding: .utf8)
                successCount += 1
                print("  \(TerminalUI.checkmark) \(name)")
            case .failure(let error):
                errorCount += 1
                print("  \(TerminalUI.cross) \(name): \(error)")
            }
        }

        let elapsed = Date().timeIntervalSinceReferenceDate - startTime
        print("")
        TerminalUI.header("Summary")
        print("  \(TerminalUI.checkmark) \(successCount) succeeded")
        if errorCount > 0 { print("  \(TerminalUI.cross) \(errorCount) failed") }
        print("  Time: \(TerminalUI.duration(elapsed))")

        if errorCount > 0, !continueOnError {
            throw ExitCode.failure
        }
    }
}
