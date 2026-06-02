//
//  ConsoleDebugHandler.swift
//  LiquidCore
//
//  Console-based debug output handler for interactive debugging
//

import Foundation

/// Console-based debug output handler
public final class ConsoleDebugHandler: DebugOutputHandler {
    /// Whether to use colors in output
    public let useColors: Bool
    
    /// Verbosity level
    public let verbosity: DebugLevel
    
    /// Whether to show timestamps
    public let showTimestamps: Bool
    
    /// Whether to show stack depth
    public let showStackDepth: Bool
    
    public init(
        useColors: Bool = true,
        verbosity: DebugLevel = .info,
        showTimestamps: Bool = true,
        showStackDepth: Bool = true
    ) {
        self.useColors = useColors
        self.verbosity = verbosity
        self.showTimestamps = showTimestamps
        self.showStackDepth = showStackDepth
    }
    
    // MARK: - DebugOutputHandler
    
    public func handleDebugOutput(_ output: DebugOutput) {
        switch output {
        case .trace(let entry):
            handleTrace(entry)
        case .variableAccess(let access):
            handleVariableAccess(access)
        case .profiling(let data):
            handleProfiling(data)
        case .message(let message, let level):
            handleMessage(message, level: level)
        case .expressionEvaluation(let evaluation):
            handleExpressionEvaluation(evaluation)
        case .filterExecution(let execution):
            handleFilterExecution(execution)
        }
    }
    
    public func handleBreakpoint(_ breakpoint: DebugBreakpoint, context: DebugContext) async -> DebugAction {
        print(colorize("🔴 Breakpoint hit at \(formatLocation(breakpoint.location))", color: .red))
        
        if let condition = breakpoint.condition {
            print(colorize("   Condition: \(condition)", color: .yellow))
        }
        
        print(colorize("   Hit count: \(breakpoint.hitCount)", color: .cyan))
        
        // Show current context
        await showContext(context)
        
        // Interactive prompt
        return await promptForAction()
    }
    
    public func handleDebugError(_ error: Error, context: DebugContext) {
        print(colorize("❌ Debug Error: \(error)", color: .red))
    }
    
    // MARK: - Output Handlers
    
    private func handleTrace(_ entry: DebugTraceEntry) {
        guard shouldShow(level: .verbose) else { return }
        
        var output = ""
        
        if showTimestamps {
            output += formatTimestamp(entry.timestamp) + " "
        }
        
        if showStackDepth {
            output += String(repeating: "  ", count: entry.stackDepth)
        }
        
        output += colorize("📍", color: .blue)
        output += " \(entry.nodeType): \(entry.operation)"
        output += " at \(formatLocation(entry.location))"
        
        if let duration = entry.duration {
            output += colorize(" (\(formatDuration(duration)))", color: .cyan)
        }
        
        print(output)
        
        // Show inputs if any
        if !entry.inputs.isEmpty {
            for (key, value) in entry.inputs {
                print(colorize("    📥 \(key): \(formatValue(value))", color: .green))
            }
        }
        
        // Show output if any
        if let output = entry.output {
            print(colorize("    📤 Output: \(formatValue(output))", color: .magenta))
        }
    }
    
    private func handleVariableAccess(_ access: DebugVariableAccess) {
        guard shouldShow(level: .verbose) else { return }
        
        let icon = accessIcon(access.accessType)
        let action = accessAction(access.accessType)
        
        var output = ""
        
        if showTimestamps {
            output += formatTimestamp(access.timestamp) + " "
        }
        
        if showStackDepth {
            output += String(repeating: "  ", count: access.stackDepth)
        }
        
        output += "\(icon) Variable \(action): \(access.variableName)"
        
        if let value = access.value {
            output += " = \(formatValue(value))"
        }
        
        if let previousValue = access.previousValue {
            output += colorize(" (was: \(formatValue(previousValue)))", color: .yellow)
        }
        
        output += " at \(formatLocation(access.location))"
        
        print(output)
    }
    
    private func handleProfiling(_ data: DebugProfilingData) {
        guard shouldShow(level: .info) else { return }
        
        var output = colorize("⏱️  ", color: .cyan)
        output += "\(data.operation): \(formatDuration(data.duration))"
        output += " at \(formatLocation(data.location))"
        
        if let memory = data.memoryUsage {
            output += colorize(" (memory: \(formatBytes(memory)))", color: .yellow)
        }
        
        print(output)
        
        // Show additional metrics
        if !data.metrics.isEmpty {
            for (key, value) in data.metrics {
                print(colorize("    📊 \(key): \(value)", color: .cyan))
            }
        }
    }
    
    private func handleMessage(_ message: String, level: DebugLevel) {
        guard shouldShow(level: level) else { return }
        
        let icon = levelIcon(level)
        let color = levelColor(level)
        
        var output = ""
        
        if showTimestamps {
            output += formatTimestamp(Date()) + " "
        }
        
        output += colorize("\(icon) \(message)", color: color)
        
        print(output)
    }
    
    private func handleExpressionEvaluation(_ evaluation: DebugExpressionEvaluation) {
        guard shouldShow(level: .verbose) else { return }
        
        var output = ""
        
        if showTimestamps {
            output += formatTimestamp(Date()) + " "
        }
        
        if showStackDepth {
            output += String(repeating: "  ", count: evaluation.stackDepth)
        }
        
        output += colorize("🧮", color: .magenta)
        output += " Expression: \(evaluation.expressionType)"
        output += " [\(evaluation.expression)]"
        
        // Show inputs if any
        if !evaluation.inputs.isEmpty {
            output += colorize(" inputs:", color: .green)
            for (key, value) in evaluation.inputs {
                output += " \(key)=\(formatValue(value))"
            }
        }
        
        // Show result
        if let result = evaluation.result {
            output += colorize(" → \(formatValue(result))", color: .blue)
        }
        
        // Show error if any
        if let error = evaluation.error {
            output += colorize(" ❌ Error: \(error)", color: .red)
        }
        
        // Show duration if significant
        if evaluation.duration > 0.0001 {
            output += colorize(" (\(formatDuration(evaluation.duration)))", color: .cyan)
        }
        
        print(output)
    }
    
    private func handleFilterExecution(_ execution: DebugFilterExecution) {
        guard shouldShow(level: .verbose) else { return }
        
        var output = ""
        
        if showTimestamps {
            output += formatTimestamp(Date()) + " "
        }
        
        if showStackDepth {
            output += String(repeating: "  ", count: execution.stackDepth)
        }
        
        // Filter chain indicator
        let chainInfo = execution.isChained ? " [\(execution.chainPosition + 1)]" : ""
        output += colorize("🔄", color: .cyan)
        output += " Filter: \(execution.filterName)\(chainInfo)"
        
        // Show input value
        output += " ← \(formatValue(execution.inputValue))"
        
        // Show arguments if any
        if !execution.arguments.isEmpty {
            let argsStr = execution.arguments.map { formatValue($0) }.joined(separator: ", ")
            output += colorize(" (\(argsStr))", color: .yellow)
        }
        
        // Show result
        if let result = execution.resultValue {
            output += colorize(" → \(formatValue(result))", color: .green)
        }
        
        // Show error if any
        if let error = execution.error {
            output += colorize(" ❌ Error: \(error)", color: .red)
        }
        
        // Show duration if significant
        if execution.duration > 0.0001 {
            output += colorize(" (\(formatDuration(execution.duration)))", color: .gray)
        }
        
        print(output)
    }
    
    // MARK: - Interactive Debugging
    
    private func showContext(_ context: DebugContext) async {
        print(colorize("\n📋 Current Context:", color: .cyan))
        
        // Show call stack
        let callStack = await context.getCallStack()
        if !callStack.isEmpty {
            print(colorize("   Call Stack:", color: .yellow))
            for (index, frame) in callStack.enumerated() {
                let indent = String(repeating: "    ", count: index + 1)
                print("\(indent)📁 \(frame.functionName) at \(formatLocation(frame.location))")
            }
        }
        
        // Show current template
        if let template = await context.getCurrentTemplate() {
            print(colorize("   Template: \(template)", color: .green))
        }
        
        // Show execution state
        let state = await context.getExecutionState()
        print(colorize("   State: \(state)", color: .blue))
        
        print()
    }
    
    private func promptForAction() async -> DebugAction {
        print(colorize("Debug> ", color: .cyan), terminator: "")
        
        guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return .continue
        }
        
        switch input.lowercased() {
        case "c", "continue":
            return .continue
        case "s", "step", "stepover":
            return .stepOver
        case "si", "stepinto":
            return .stepInto
        case "so", "stepout":
            return .stepOut
        case "q", "quit", "abort":
            return .abort
        case let expr where expr.starts(with: "eval "):
            let expression = String(expr.dropFirst(5))
            return .evaluate(expression)
        default:
            print(colorize("Commands: (c)ontinue, (s)tep, (si)stepinto, (so)stepout, (q)uit, eval <expr>", color: .yellow))
            return await promptForAction()
        }
    }
    
    // MARK: - Formatting Helpers
    
    private func formatLocation(_ location: LiquidSourceLocation) -> String {
        var result = ""
        if let template = location.templateName {
            result += "\(template):"
        }
        result += "\(location.line):\(location.column)"
        return result
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return colorize(formatter.string(from: date), color: .gray)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        if duration < 0.001 {
            return String(format: "%.2fμs", duration * 1_000_000)
        } else if duration < 1.0 {
            return String(format: "%.2fms", duration * 1000)
        } else {
            return String(format: "%.2fs", duration)
        }
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let units = ["B", "KB", "MB", "GB"]
        var value = Double(bytes)
        var unitIndex = 0
        
        while value >= 1024 && unitIndex < units.count - 1 {
            value /= 1024
            unitIndex += 1
        }
        
        return String(format: "%.1f%@", value, units[unitIndex])
    }
    
    private func formatValue(_ value: Any) -> String {
        // Unwrap SendableAnyValue if needed
        let actualValue: Any
        if let sendableValue = value as? SendableAnyValue {
            actualValue = sendableValue.value
        } else {
            actualValue = value
        }
        
        switch actualValue {
        case let string as String:
            return "\"\(string)\""
        case let array as [Any]:
            return "[\(array.count) items]"
        case let dict as [String: Any]:
            return "{\(dict.count) keys}"
        default:
            return "\(actualValue)"
        }
    }
    
    private func shouldShow(level: DebugLevel) -> Bool {
        switch verbosity {
        case .verbose:
            return true
        case .info:
            return level != .verbose
        case .warning:
            return level == .warning || level == .error
        case .error:
            return level == .error
        }
    }
    
    // MARK: - Icons and Colors
    
    private func accessIcon(_ type: DebugVariableAccessType) -> String {
        switch type {
        case .read: return "👁️"
        case .write: return "✏️"
        case .delete: return "🗑️"
        case .create: return "✨"
        }
    }
    
    private func accessAction(_ type: DebugVariableAccessType) -> String {
        switch type {
        case .read: return "read"
        case .write: return "write"
        case .delete: return "delete"
        case .create: return "create"
        }
    }
    
    private func levelIcon(_ level: DebugLevel) -> String {
        switch level {
        case .verbose: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        }
    }
    
    private func levelColor(_ level: DebugLevel) -> AnsiColor {
        switch level {
        case .verbose: return .gray
        case .info: return .blue
        case .warning: return .yellow
        case .error: return .red
        }
    }
    
    private func colorize(_ text: String, color: AnsiColor) -> String {
        guard useColors else { return text }
        return "\(color.code)\(text)\(AnsiColor.reset.code)"
    }
}

// MARK: - ANSI Color Support

private enum AnsiColor {
    case reset, black, red, green, yellow, blue, magenta, cyan, gray
    
    var code: String {
        switch self {
        case .reset: return "\u{001B}[0m"
        case .black: return "\u{001B}[30m"
        case .red: return "\u{001B}[31m"
        case .green: return "\u{001B}[32m"
        case .yellow: return "\u{001B}[33m"
        case .blue: return "\u{001B}[34m"
        case .magenta: return "\u{001B}[35m"
        case .cyan: return "\u{001B}[36m"
        case .gray: return "\u{001B}[90m"
        }
    }
}