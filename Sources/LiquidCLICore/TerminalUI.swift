//
//  TerminalUI.swift
//  LiquidCLICore
//
//  Created as part of RhoeLiquid
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation

/// ANSI terminal formatting utilities for the Liquid CLI.
enum TerminalUI {
    // ANSI codes
    static let reset = "\u{001B}[0m"
    static let bold = "\u{001B}[1m"
    static let dim = "\u{001B}[2m"
    static let red = "\u{001B}[31m"
    static let green = "\u{001B}[32m"
    static let yellow = "\u{001B}[33m"
    static let blue = "\u{001B}[34m"
    static let cyan = "\u{001B}[36m"
    static let white = "\u{001B}[37m"

    // Status symbols
    static let checkmark = "\(green)✓\(reset)"
    static let cross = "\(red)✗\(reset)"
    static let warning = "\(yellow)⚠\(reset)"
    static let info = "\(cyan)ℹ\(reset)"
    static let arrow = "\(cyan)→\(reset)"

    static func success(_ msg: String) { print("\(checkmark) \(msg)") }
    static func error(_ msg: String) { print("\(cross) \(red)\(msg)\(reset)") }
    static func warn(_ msg: String) { print("\(warning) \(yellow)\(msg)\(reset)") }
    static func info(_ msg: String) { print("\(self.info) \(msg)") }
    static func header(_ msg: String) { print("\n\(bold)\(msg)\(reset)") }

    static func progressBar(current: Int, total: Int, width: Int = 30) -> String {
        let fraction = Double(current) / Double(max(total, 1))
        let filled = Int(fraction * Double(width))
        let bar = String(repeating: "█", count: filled) + String(repeating: "░", count: width - filled)
        let pct = Int(fraction * 100)
        return "[\(bar)] \(pct)% (\(current)/\(total))"
    }

    static func duration(_ seconds: Double) -> String {
        if seconds < 0.001 { return String(format: "%.0fµs", seconds * 1_000_000) }
        if seconds < 1.0 { return String(format: "%.1fms", seconds * 1000) }
        return String(format: "%.2fs", seconds)
    }

    static func fileSize(_ bytes: Int) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        if bytes < 1_048_576 { return String(format: "%.1f KB", Double(bytes) / 1024) }
        return String(format: "%.1f MB", Double(bytes) / 1_048_576)
    }
}
