//
//  LoadTag.swift
//  LiquidTags
//
//  Simple data loading tag implementation
//

import Foundation
import LiquidCore

/// Built-in data-loading tag for simple `load(...)` assignments.
public struct LoadTag: CustomTag {
    public let name = "data"
    public let type = TagType.simple
    
    public init() {}
    
    public func parse(_ parameters: String, context: TagParsingContext) async throws -> TagParameters {
        let trimmed = parameters.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw TagParsingError.invalidSyntax("Expected 'name = load(...)'")
        }

        let components = trimmed.split(separator: "=", maxSplits: 1).map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard components.count == 2 else {
            throw TagParsingError.invalidSyntax("Expected assignment syntax: data name = load(...)")
        }

        let target = components[0]
        guard !target.isEmpty else {
            throw TagParsingError.missingRequiredParameter("target")
        }

        let invocation = components[1]
        guard invocation.hasPrefix("load("), invocation.hasSuffix(")") else {
            throw TagParsingError.invalidSyntax("Expected load(...) invocation")
        }

        let argumentString = String(invocation.dropFirst("load(".count).dropLast())
        let arguments = try parseArguments(argumentString)
        guard let source = arguments.first, !source.isEmpty else {
            throw TagParsingError.missingRequiredParameter("source")
        }

        var params: [String: Any] = [
            "target": target,
            "source": source
        ]

        var options: [String: Any] = [:]
        for argument in arguments.dropFirst() {
            let parts = argument.split(separator: ":", maxSplits: 1).map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            guard parts.count == 2 else {
                throw TagParsingError.invalidSyntax("Invalid load option: \(argument)")
            }
            options[parts[0]] = parts[1]
        }

        if !options.isEmpty {
            params["options"] = options
        }

        return TagParameters(params)
    }
    
    public func execute(parameters: TagParameters, content: String?, context: TagExecutionContext) async throws -> String {
        let target: String = try parameters.require("target")
        let sourceTemplate: String = try parameters.require("source")
        let rawOptions: [String: String] = parameters.get("options", default: [:])

        let sourcePath = try resolveStringExpression(sourceTemplate, context: context)
        let options = try resolveLoadOptions(rawOptions, context: context)
        let data = try await context.loadData(from: sourcePath, options: options)

        context.setVariable(data.liquidValue, for: target)
        return ""
    }

    private func parseArguments(_ input: String) throws -> [String] {
        var arguments: [String] = []
        var current = ""
        var inQuotes = false
        var quoteCharacter: Character?
        var nestingDepth = 0

        for character in input {
            switch character {
            case "\"", "'":
                if inQuotes && character == quoteCharacter {
                    inQuotes = false
                    quoteCharacter = nil
                } else if !inQuotes {
                    inQuotes = true
                    quoteCharacter = character
                }
                current.append(character)
            case "(":
                nestingDepth += 1
                current.append(character)
            case ")":
                nestingDepth = max(0, nestingDepth - 1)
                current.append(character)
            case "," where !inQuotes && nestingDepth == 0:
                let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    arguments.append(trimmed)
                }
                current.removeAll(keepingCapacity: true)
            default:
                current.append(character)
            }
        }

        let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            arguments.append(trimmed)
        }

        return arguments
    }

    private func resolveLoadOptions(
        _ rawOptions: [String: String],
        context: TagExecutionContext
    ) throws -> LoadOptions {
        let cacheDuration = try rawOptions["cache"].map { try resolveTimeIntervalExpression($0, context: context) }
        let watch = try rawOptions["watch"].map { try resolveBooleanExpression($0, context: context) } ?? false
        let timeout = try rawOptions["timeout"].map { try resolveTimeIntervalExpression($0, context: context) } ?? 30

        return LoadOptions(
            cacheDuration: cacheDuration,
            watch: watch,
            timeout: timeout
        )
    }

    private func resolveStringExpression(_ expression: String, context: TagExecutionContext) throws -> String {
        let resolved = resolveExpression(expression, context: context)
        if let string = resolved as? String {
            return string
        }
        return String(describing: resolved)
    }

    private func resolveBooleanExpression(_ expression: String, context: TagExecutionContext) throws -> Bool {
        let resolved = resolveExpression(expression, context: context)
        if let bool = resolved as? Bool {
            return bool
        }
        if let string = resolved as? String {
            switch string.lowercased() {
            case "true", "yes", "1":
                return true
            case "false", "no", "0":
                return false
            default:
                break
            }
        }
        throw TagExecutionError.executionFailed("Unable to resolve '\(expression)' as Bool")
    }

    private func resolveTimeIntervalExpression(_ expression: String, context: TagExecutionContext) throws -> TimeInterval {
        let resolved = resolveExpression(expression, context: context)
        if let interval = resolved as? TimeInterval {
            return interval
        }
        if let int = resolved as? Int {
            return TimeInterval(int)
        }
        if let string = resolved as? String, let interval = TimeInterval(string) {
            return interval
        }
        throw TagExecutionError.executionFailed("Unable to resolve '\(expression)' as time interval")
    }

    private func resolveExpression(_ expression: String, context: TagExecutionContext) -> Any {
        let trimmed = expression.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return ""
        }

        if (trimmed.hasPrefix("\"") && trimmed.hasSuffix("\"")) ||
            (trimmed.hasPrefix("'") && trimmed.hasSuffix("'")) {
            return String(trimmed.dropFirst().dropLast())
        }

        switch trimmed.lowercased() {
        case "true":
            return true
        case "false":
            return false
        case "nil", "null":
            return NSNull()
        default:
            break
        }

        if let int = Int(trimmed) {
            return int
        }
        if let double = Double(trimmed) {
            return double
        }

        return resolveVariable(path: trimmed, context: context)
    }

    private func resolveVariable(path: String, context: TagExecutionContext) -> Any {
        let components = path.split(separator: ".").map(String.init)
        var current: Any = context.variables

        for component in components {
            if let dictionary = current as? [String: Any] {
                current = dictionary[component] ?? ""
            } else if let dataValue = current as? DataValue {
                current = dataValue[component].liquidValue
            } else {
                return ""
            }
        }

        return current
    }
}
