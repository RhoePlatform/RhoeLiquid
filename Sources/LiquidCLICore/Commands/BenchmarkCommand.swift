//
//  BenchmarkCommand.swift
//  LiquidCLICore
//
//  Created as part of RhoeLiquid
//  A high-performance Swift implementation of the Liquid template language
//

import ArgumentParser
import Foundation
import RhoeLiquid

public struct BenchmarkCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "benchmark",
        abstract: "Benchmark template rendering performance.",
        discussion: """
        Renders a template repeatedly with an optional JSON context object and \
        reports mean, median, p95, min, max, total time, and throughput.
        """
    )

    @Argument(
        help: "Template file path.",
        completion: .file(extensions: ["liquid", "html"])
    )
    public var template: String

    @Option(name: .shortAndLong, help: "Number of render iterations. Must be greater than zero.")
    public var iterations: Int = 100

    @Option(
        name: .long,
        help: "Context data file containing a JSON object.",
        completion: .file(extensions: ["json"])
    )
    public var context: String?

    public init() {}

    public func validate() throws {
        guard iterations > 0 else {
            throw ValidationError("--iterations must be greater than zero.")
        }
    }

    public func run() async throws {
        guard FileManager.default.fileExists(atPath: template) else {
            TerminalUI.error("Template not found: \(template)")
            throw ExitCode.failure
        }

        let source = try String(contentsOfFile: template, encoding: .utf8)
        var contextData: [String: Any] = [:]
        if let contextPath = context {
            contextData = try loadContextData(from: contextPath)
        }

        TerminalUI.header("Benchmark: \((template as NSString).lastPathComponent)")
        print("  Iterations: \(iterations)")
        print("  Template size: \(TerminalUI.fileSize(source.utf8.count))")
        print("")

        let engine = LiquidEngine()

        // Warm up
        _ = try await engine.render(template: source, context: contextData)

        // Benchmark
        var times: [Double] = []
        times.reserveCapacity(iterations)

        for _ in 0..<iterations {
            let start = Date().timeIntervalSinceReferenceDate
            _ = try await engine.render(template: source, context: contextData)
            times.append(Date().timeIntervalSinceReferenceDate - start)
        }

        times.sort()
        let total = times.reduce(0, +)
        let mean = total / Double(iterations)
        let median = times[iterations / 2]
        let p95 = times[Int(Double(iterations) * 0.95)]
        let min = times.first!
        let max = times.last!

        TerminalUI.header("Results")
        print("  Mean:   \(TerminalUI.duration(mean))")
        print("  Median: \(TerminalUI.duration(median))")
        print("  P95:    \(TerminalUI.duration(p95))")
        print("  Min:    \(TerminalUI.duration(min))")
        print("  Max:    \(TerminalUI.duration(max))")
        print("  Total:  \(TerminalUI.duration(total))")
        print("  Throughput: \(Int(Double(iterations) / total)) renders/sec")
    }
}
