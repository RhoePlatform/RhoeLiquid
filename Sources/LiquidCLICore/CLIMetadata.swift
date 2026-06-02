//
//  CLIMetadata.swift
//  LiquidCLICore
//
//  Public CLI metadata shared by help output, generated manuals, and release gates.
//

import LiquidCore

/// Stable metadata for the public `liquid` executable.
public enum LiquidCLIMetadata {
    public static let commandName = "liquid"
    public static let version = liquidCoreVersion

    public static let abstract = "Render, analyze, validate, and scaffold Liquid template projects."

    public static let discussion = """
    RhoeLiquid is a Swift-native Liquid template engine for local tools, services, \
    document pipelines, and WebAssembly deployments.

    Use `liquid render` for one-off template rendering, `liquid validate` and \
    `liquid analyze` for authoring checks, `liquid batch` for directory-scale \
    rendering, and `liquid init` to scaffold a small starter project.
    """

    public static let manualDate = "2026-06-01"
    public static let manualAuthor = "RhoePlatform Maintainers"
}
