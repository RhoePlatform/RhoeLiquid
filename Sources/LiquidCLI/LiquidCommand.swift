//
//  LiquidCommand.swift
//  LiquidCLI
//
//  Created as part of RhoeLiquid
//  A high-performance Swift implementation of the Liquid template language
//

import ArgumentParser
import LiquidCLICore

@main
struct LiquidCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: LiquidCLIMetadata.commandName,
        abstract: LiquidCLIMetadata.abstract,
        discussion: LiquidCLIMetadata.discussion,
        version: LiquidCLIMetadata.version,
        subcommands: [
            RenderCommand.self,
            AnalyzeCommand.self,
            BatchCommand.self,
            ValidateCommand.self,
            BenchmarkCommand.self,
            InitCommand.self,
        ],
        defaultSubcommand: RenderCommand.self
    )
}
