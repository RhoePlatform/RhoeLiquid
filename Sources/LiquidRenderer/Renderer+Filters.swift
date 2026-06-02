//
//  Renderer+Filters.swift
//  LiquidRenderer
//
//  Created as part of RhoeLiquid
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import LiquidCore
import LiquidExtensions
import LiquidParser
import LiquidTags
import LiquidUtilities
import OrderedCollections

extension Renderer {
    // MARK: - Filter Application
    
    /// Applies a filter to a value
    internal func applyFilter(_ filter: Filter, to value: Any, isChained: Bool = false, chainPosition: Int = 0) async throws -> Any {
        let filterName = filter.name

        guard let debugContext = configuration.debugContext else {
            return try await applyFilterFast(filter, to: value)
        }

        let args = try await evaluateFilterArguments(filter.arguments)

        let filterNameString = filterName.string

        let startTime = Date().timeIntervalSinceReferenceDate

        do {
            let result = try await applyFilterInternal(filterName: filterName, to: value, args: args)
            let duration = Date().timeIntervalSinceReferenceDate - startTime
            let inputValue = SendableAnyValue(value)
            let resultValue = SendableAnyValue(result)
            let argValues = args.map { SendableAnyValue($0) }

            Task {
                let execution = DebugFilterExecution(
                    filterName: filterNameString,
                    inputValue: inputValue,
                    arguments: argValues,
                    resultValue: resultValue,
                    location: LiquidSourceLocation(line: 0, column: 0, position: 0, templateName: nil),
                    duration: duration,
                    stackDepth: await debugContext.getCallStack().count,
                    isChained: isChained,
                    chainPosition: chainPosition
                )
                await debugContext.recordFilterExecution(execution)
            }

            return result
        } catch {
            let duration = Date().timeIntervalSinceReferenceDate - startTime
            let inputValue = SendableAnyValue(value)
            let argValues = args.map { SendableAnyValue($0) }

            Task {
                let execution = DebugFilterExecution(
                    filterName: filterNameString,
                    inputValue: inputValue,
                    arguments: argValues,
                    resultValue: nil,
                    location: LiquidSourceLocation(line: 0, column: 0, position: 0, templateName: nil),
                    duration: duration,
                    stackDepth: await debugContext.getCallStack().count,
                    error: error.localizedDescription,
                    isChained: isChained,
                    chainPosition: chainPosition
                )
                await debugContext.recordFilterExecution(execution)
            }

            throw error
        }
    }

    @inline(__always)
    internal func applyFilterFast(_ filter: Filter, to value: Any) async throws -> Any {
        // Handle default filter with allow_false named argument
        if filter.name.equals("default"), !filter.namedArguments.isEmpty {
            let defaultValue = filter.arguments.isEmpty ? "" : try await evaluateFilterArgumentFast(filter.arguments[0])
            if let allowFalseExpr = filter.namedArguments["allow_false"] {
                let allowFalse = try await evaluateExpression(allowFalseExpr)
                if allowFalse as? Bool == true {
                    // With allow_false: only use default for nil/empty, NOT for false
                    if value is NSNull || (value as? String)?.isEmpty == true {
                        return defaultValue
                    }
                    return value
                }
            }
            return isNilOrEmpty(value) ? defaultValue : value
        }

        switch filter.arguments.count {
        case 0:
            if let builtinKind = filter.builtinKind,
               let result = try applyBuiltinFilterWithoutArguments(kind: builtinKind, to: value) {
                return result
            }
            return try await applyFilterInternal(filterName: filter.name, to: value, args: [])
        case 1:
            let argument: Any
            if let literalArgument = filter.singleLiteralIntegerArgument {
                argument = literalArgument
            } else {
                argument = try await evaluateFilterArgumentFast(filter.arguments[0])
            }
            if let builtinKind = filter.builtinKind,
               let result = try applyBuiltinFilterSingleArgument(kind: builtinKind, to: value, argument: argument) {
                return result
            }
            return try await applyFilterInternal(filterName: filter.name, to: value, args: [argument])
        default:
            let args = try await evaluateFilterArgumentsFast(filter.arguments)
            return try await applyFilterInternal(filterName: filter.name, to: value, args: args)
        }
    }

    @inline(__always)
    internal func applyBuiltinFilterWithoutArguments(kind: Filter.BuiltinKind, to value: Any) throws -> Any? {
        switch kind {
        case .upcase:
            return stringify(value).uppercased()
        case .downcase:
            return stringify(value).lowercased()
        case .capitalize:
            return stringify(value).capitalized
        case .size:
            return getSize(value)
        case .first:
            return getFirst(value)
        case .last:
            return getLast(value)
        case .strip:
            return stringify(value).trimmingCharacters(in: .whitespacesAndNewlines)
        case .reverse:
            return reverseValue(value)
        case .raw:
            return SafeHTML(stringify(value, escape: false))
        case .escape:
            return SafeHTML(HTMLEscape.escape(stringify(value, escape: false)))
        case .escapeOnce:
            return SafeHTML(HTMLEscape.escapeOnce(stringify(value, escape: false)))
        case .lstrip:
            return stringify(value, escape: false)
                .replacingOccurrences(of: "^\\s+", with: "", options: .regularExpression)
        case .rstrip:
            return stringify(value, escape: false)
                .replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression)
        case .abs:
            if let intVal = value as? Int { return Swift.abs(intVal) }
            let a = abs(numericValue(value) ?? 0)
            return a == a.rounded(.towardZero) ? Int(a) : a
        case .date:
            return try formatDate(value, format: nil)
        case .json:
            return try jsonEncode(value)
        case .sum:
            return try sumValues(value)
        case .uniq:
            return uniqueArray(value)
        case .compact:
            return compactArray(value)
        case .slugify:
            return slugify(stringify(value))
        default:
            return nil
        }
    }

    @inline(__always)
    internal func applyBuiltinFilterSingleArgument(kind: Filter.BuiltinKind, to value: Any, argument: Any) throws -> Any? {
        switch kind {
        case .join:
            return joinArray(value, separator: stringify(argument))
        case .split:
            return applySplitFilter(value, separator: argument)
        case .append:
            return stringify(value) + stringify(argument)
        case .prepend:
            return stringify(argument) + stringify(value)
        case .plus:
            return try add(value, argument)
        case .minus:
            return try subtract(value, argument)
        case .times:
            return try multiply(value, argument)
        case .dividedBy:
            return try divide(value, argument)
        case .round:
            return roundNumber(value, precision: integerValue(argument) ?? 0)
        case .atLeast:
            if let l = value as? Int, let r = argument as? Int { return Swift.max(l, r) }
            let left = numericValue(value) ?? 0, right = numericValue(argument) ?? 0
            let result = Swift.max(left, right)
            if result == result.rounded(.towardZero) { return Int(result) }
            return result
        case .atMost:
            if let l = value as? Int, let r = argument as? Int { return Swift.min(l, r) }
            let left = numericValue(value) ?? 0, right = numericValue(argument) ?? 0
            let result = Swift.min(left, right)
            if result == result.rounded(.towardZero) { return Int(result) }
            return result
        case .date:
            return try formatDate(value, format: argument as? String, allowNilFormat: argument is NSNull)
        case .map:
            return try mapFilter(value, args: [argument])
        case .sort:
            return try sortFilter(value, args: [argument])
        case .limit:
            guard let array = value as? [Any] else { return value }
            return Array(array.prefix(integerValue(argument) ?? 0))
        case .offset:
            guard let array = value as? [Any] else { return value }
            return Array(array.dropFirst(integerValue(argument) ?? 0))
        case .default:
            return isNilOrEmpty(value) ? argument : value
        default:
            return nil
        }
    }

    @inline(__always)
    internal func evaluateFilterArgumentFast(_ expression: LiquidCore.Expression) async throws -> Any {
        switch expression {
        case .literal(let value):
            return try evaluateValue(value)
        case .variable(let name):
            return context.getVariable(name.string) ?? NSNull()
        case .access:
            if let path = expression.staticVariablePath {
                return context.getVariable(path) ?? NSNull()
            }
            return try await evaluateExpressionFast(expression)
        default:
            return try await evaluateExpressionFast(expression)
        }
    }

    @inline(__always)
    internal func evaluateFilterArgumentsFast(_ expressions: [LiquidCore.Expression]) async throws -> [Any] {
        switch expressions.count {
        case 0:
            return []
        case 1:
            return [try await evaluateFilterArgumentFast(expressions[0])]
        default:
            var args: [Any] = []
            args.reserveCapacity(expressions.count)
            for expression in expressions {
                args.append(try await evaluateFilterArgumentFast(expression))
            }
            return args
        }
    }

    internal func evaluateFilterArguments(_ expressions: [LiquidCore.Expression]) async throws -> [Any] {
        switch expressions.count {
        case 0:
            return []
        case 1:
            return [try await evaluateExpression(expressions[0])]
        default:
            var args: [Any] = []
            args.reserveCapacity(expressions.count)
            for expression in expressions {
                args.append(try await evaluateExpression(expression))
            }
            return args
        }
    }

    // MARK: - Filter Argument Validation

    /// Allowed argument counts per filter. nil = no validation (custom filters).
    /// Format: (min, max) inclusive.
    internal static let filterArgCounts: [String: (min: Int, max: Int)] = [
        // Zero-arg filters
        "abs": (0, 0), "capitalize": (0, 0), "downcase": (0, 0), "upcase": (0, 0),
        "ceil": (0, 0), "floor": (0, 0),
        "strip": (0, 0), "lstrip": (0, 0), "rstrip": (0, 0),
        "escape": (0, 0), "escape_once": (0, 0),
        "strip_html": (0, 0), "strip_newlines": (0, 0), "newline_to_br": (0, 0),
        "url_encode": (0, 0), "url_decode": (0, 0),
        "base64_decode": (0, 0), "base64_encode": (0, 0),
        "base64_url_safe_decode": (0, 0), "base64_url_safe_encode": (0, 0),
        "first": (0, 0), "last": (0, 0), "size": (0, 0),
        "reverse": (0, 0), "compact": (0, 1), "uniq": (0, 1),
        // Single-arg filters
        "append": (1, 1), "prepend": (1, 1),
        "remove": (1, 1), "remove_first": (1, 1), "remove_last": (1, 1),
        "split": (1, 1), "join": (0, 1),
        "plus": (1, 1), "minus": (1, 1), "times": (1, 1),
        "divided_by": (1, 1), "modulo": (1, 1),
        "at_least": (1, 1), "at_most": (1, 1),
        "map": (1, 1), "concat": (1, 1),
        // Multi-arg filters
        "replace": (1, 2), "replace_first": (1, 2), "replace_last": (2, 2),
        "slice": (1, 2), "truncate": (0, 2), "truncatewords": (0, 2),
        "round": (0, 1), "sort": (0, 1), "sort_natural": (0, 1),
        "date": (1, 1), "default": (0, 2), "sum": (0, 1),
        "where": (1, 2), "find": (1, 2), "find_index": (1, 2),
        "has": (0, 2), "reject": (1, 2),
    ]

    internal func validateFilterArgs(_ filterName: InlineString, args: [Any]) throws {
        guard let (minArgs, maxArgs) = Self.filterArgCounts[filterName.string] else { return }
        if args.count < minArgs {
            throw RenderError.undefinedFilter("\(filterName.string): expected at least \(minArgs) argument(s), got \(args.count)")
        }
        if args.count > maxArgs {
            throw RenderError.undefinedFilter("\(filterName.string): expected at most \(maxArgs) argument(s), got \(args.count)")
        }
    }

    /// Internal filter application (extracted for debug wrapping)
    internal func applyFilterInternal(filterName: InlineString, to value: Any, args: [Any]) async throws -> Any {
        // Validate argument count
        try validateFilterArgs(filterName, args: args)
        if filterName.equals("upcase") {
            return stringify(value).uppercased()
        }
        if filterName.equals("downcase") {
            return stringify(value).lowercased()
        }
        if filterName.equals("capitalize") {
            return stringify(value).capitalized
        }
        if filterName.equals("size") {
            return getSize(value)
        }
        if filterName.equals("first") {
            return getFirst(value)
        }
        if filterName.equals("last") {
            return getLast(value)
        }
        if filterName.equals("strip") {
            return stringify(value).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if filterName.equals("join") {
            let separator = args.isEmpty ? " " : stringify(args[0])
            return joinArray(value, separator: separator)
        }
        if filterName.equals("split") {
            return applySplitFilter(value, separator: args.first ?? NSNull())
        }
        if filterName.equals("reverse") {
            return reverseValue(value)
        }
        if filterName.equals("append") {
            let suffix = args.first ?? ""
            return stringify(value) + stringify(suffix)
        }
        if filterName.equals("prepend") {
            let prefix = args.first ?? ""
            return stringify(prefix) + stringify(value)
        }
        if filterName.equals("plus") {
            let addend = args.first ?? 0
            return try add(value, addend)
        }
        if filterName.equals("minus") {
            let subtrahend = args.first ?? 0
            return try subtract(value, subtrahend)
        }
        if filterName.equals("times") {
            let multiplier = args.first ?? 1
            return try multiply(value, multiplier)
        }
        if filterName.equals("divided_by") {
            let divisor = args.first ?? 1
            return try divide(value, divisor)
        }
        if filterName.equals("modulo") {
            let divisor = args.first ?? 1
            return try modulo(value, divisor)
        }
        if filterName.equals("round") {
            let precision = args.first.flatMap(integerValue) ?? 0
            return roundNumber(value, precision: precision)
        }
        if filterName.equals("ceil") {
            if value is Int { return value }
            return Int(ceil(numericValue(value) ?? 0))
        }
        if filterName.equals("floor") {
            if value is Int { return value }
            return Int(floor(numericValue(value) ?? 0))
        }
        if filterName.equals("raw") {
            // Mark string as safe HTML that should not be escaped
            return SafeHTML(stringify(value, escape: false))
        }
        if filterName.equals("escape") {
            // Explicitly escape HTML
            return SafeHTML(HTMLEscape.escape(stringify(value, escape: false)))
        }
        if filterName.equals("escape_once") {
            // Escape HTML but don't double-escape already escaped entities
            let str = stringify(value, escape: false)
            return SafeHTML(HTMLEscape.escapeOnce(str))
        }
        if filterName.equals("truncate") {
            if let firstArg = args.first, firstArg is NSNull {
                throw RenderError.typeError(expected: "integer", actual: "nil", operation: "truncate")
            }
            let length = args.first.flatMap(integerValue) ?? 50
            let ending: String
            if let secondArg = args.dropFirst().first {
                ending = secondArg is NSNull ? "" : stringify(secondArg)
            } else {
                ending = "..."
            }
            return truncateString(stringify(value, escape: false), length: length, ending: ending)
        }
        if filterName.equals("truncatewords") {
            if let firstArg = args.first, firstArg is NSNull {
                throw RenderError.typeError(expected: "integer", actual: "nil", operation: "truncatewords")
            }
            let count = max(args.first.flatMap(integerValue) ?? 15, 1)  // Min 1 word (Shopify: 0→1)
            let ending: String
            if let secondArg = args.dropFirst().first {
                ending = secondArg is NSNull ? "" : stringify(secondArg)
            } else {
                ending = "..."
            }
            return truncateWords(stringify(value, escape: false), count: count, ending: ending)
        }
        if filterName.equals("strip_html") {
            return stripHTML(stringify(value, escape: false))
        }
        if filterName.equals("strip_newlines") {
            return stringify(value, escape: false)
                .replacingOccurrences(of: "\n", with: "")
                .replacingOccurrences(of: "\r", with: "")
        }
        if filterName.equals("newline_to_br") {
            // Replace \r\n, \n, or \r with <br />\n — order matters to avoid double-conversion
            return stringify(value, escape: false)
                .replacingOccurrences(of: "\r\n", with: "\n")
                .replacingOccurrences(of: "\r", with: "\n")
                .replacingOccurrences(of: "\n", with: "<br />\n")
        }
        if filterName.equals("url_encode") {
            let str = stringify(value, escape: false)
            // Shopify uses form-encoding: spaces become +, @ and ! are encoded
            var allowed = CharacterSet.alphanumerics
            allowed.insert(charactersIn: "-._~")
            guard let encoded = str.addingPercentEncoding(withAllowedCharacters: allowed) else { return str }
            return encoded.replacingOccurrences(of: "%20", with: "+")
        }
        if filterName.equals("url_decode") {
            let str = stringify(value, escape: false)
            // Shopify decodes + as space (form-encoding)
            let plusDecoded = str.replacingOccurrences(of: "+", with: " ")
            return plusDecoded.removingPercentEncoding ?? plusDecoded
        }
        if filterName.equals("base64_encode") {
            let str = stringify(value, escape: false)
            return str.data(using: .utf8)?.base64EncodedString() ?? str
        }
        if filterName.equals("base64_decode") {
            if value is NSNull { return "" }
            guard value is String || value is InlineString else {
                throw RenderError.typeError(expected: "string", actual: "\(type(of: value))", operation: "base64_decode")
            }
            let str = stringify(value, escape: false)
            guard let data = Data(base64Encoded: str),
                  let decoded = String(data: data, encoding: .utf8) else { return str }
            return decoded
        }
        if filterName.equals("lstrip") {
            return stringify(value, escape: false)
                .replacingOccurrences(of: "^\\s+", with: "", options: .regularExpression)
        }
        if filterName.equals("rstrip") {
            return stringify(value, escape: false)
                .replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression)
        }
        if filterName.equals("abs") {
            if let intVal = value as? Int { return Swift.abs(intVal) }
            let a = abs(numericValue(value) ?? 0)
            return a == a.rounded(.towardZero) ? Int(a) : a
        }
        if filterName.equals("at_least") {
            if let l = value as? Int, let r = args.first as? Int { return Swift.max(l, r) }
            let r = Swift.max(numericValue(value) ?? 0, args.first.flatMap(numericValue) ?? 0)
            return r == r.rounded(.towardZero) ? Int(r) : r
        }
        if filterName.equals("at_most") {
            if let l = value as? Int, let r = args.first as? Int { return Swift.min(l, r) }
            let r = Swift.min(numericValue(value) ?? 0, args.first.flatMap(numericValue) ?? 0)
            return r == r.rounded(.towardZero) ? Int(r) : r
        }
        if filterName.equals("date") {
            let dateArg = args.first
            return try formatDate(value, format: dateArg as? String, allowNilFormat: dateArg is NSNull)
        }
        if filterName.equals("json") {
            return try jsonEncode(value)
        }
        if filterName.equals("where") {
            return try whereFilter(value, args: args)
        }
        if filterName.equals("map") {
            return try mapFilter(value, args: args)
        }
        if filterName.equals("concat") {
            let left: [Any]
            if let arr = value as? [Any] { left = arr }
            else if value is NSNull { left = [] }
            else if let s = value as? String, s.isEmpty { left = [] }
            else { left = [value] }
            guard let right = args.first as? [Any] else {
                throw RenderError.typeError(expected: "array", actual: "\(type(of: args.first ?? NSNull()))", operation: "concat")
            }
            return left + right
        }
        if filterName.equals("sort") {
            return try sortFilter(value, args: args)
        }
        if filterName.equals("sort_natural") {
            return try sortNaturalFilter(value, args: args)
        }
        if filterName.equals("sum") {
            let property = args.first as? String
            return try sumValues(value, property: property)
        }
        if filterName.equals("remove") {
            guard let target = args.first else { return value }
            return stringify(value).replacingOccurrences(of: stringify(target), with: "")
        }
        if filterName.equals("remove_first") {
            guard let target = args.first else { return value }
            let str = stringify(value)
            let sub = stringify(target)
            if let range = str.range(of: sub) {
                return str.replacingCharacters(in: range, with: "")
            }
            return str
        }
        if filterName.equals("replace") {
            guard !args.isEmpty else { return value }
            let search = stringify(args[0])
            let replacement = args.count >= 2 ? stringify(args[1]) : ""
            let str = stringify(value)
            if search.isEmpty {
                // Replace empty string: insert replacement between every character
                return replacement + str.map { String($0) }.joined(separator: replacement) + replacement
            }
            return str.replacingOccurrences(of: search, with: replacement)
        }
        if filterName.equals("replace_first") {
            guard !args.isEmpty else { return value }
            let str = stringify(value)
            let search = stringify(args[0])
            let replacement = args.count >= 2 ? stringify(args[1]) : ""
            if search.isEmpty {
                return replacement + str  // Insert at beginning
            }
            if let range = str.range(of: search) {
                return str.replacingCharacters(in: range, with: replacement)
            }
            return str
        }
        if filterName.equals("replace_last") {
            guard !args.isEmpty else { return value }
            let str = stringify(value)
            let search = stringify(args[0])
            let replacement = args.count >= 2 ? stringify(args[1]) : ""
            if search.isEmpty {
                return str + replacement  // Insert at end
            }
            if let range = str.range(of: search, options: .backwards) {
                return str.replacingCharacters(in: range, with: replacement)
            }
            return str
        }
        if filterName.equals("slice") {
            guard let firstArg = args.first else { return value }
            // Float arguments are errors in Shopify Liquid
            if firstArg is Double || isFloatLike(firstArg) {
                throw RenderError.typeError(expected: "integer", actual: "float", operation: "slice")
            }
            if firstArg is NSNull {
                throw RenderError.typeError(expected: "integer", actual: "nil", operation: "slice")
            }
            guard let rawOffset = integerValue(firstArg) else {
                throw RenderError.typeError(expected: "integer", actual: "\(type(of: firstArg))", operation: "slice")
            }
            // Second arg: NSNull/undefined → default to 1; float → error
            var length = 1
            if args.count > 1 {
                let secondArg = args[1]
                if secondArg is Double || isFloatLike(secondArg) {
                    throw RenderError.typeError(expected: "integer", actual: "float", operation: "slice")
                }
                if secondArg is NSNull {
                    // NSNull → default to 1
                } else {
                    guard let secondLength = integerValue(secondArg) else {
                        throw RenderError.typeError(expected: "integer", actual: "\(type(of: secondArg))", operation: "slice")
                    }
                    length = secondLength
                }
            }

            // Array slice
            if let array = value as? [Any] {
                var offset = Int(rawOffset)
                if offset < 0 { offset = array.count + offset }
                guard offset >= 0, offset < array.count, length > 0 else { return NSNull() }
                let endOffset = min(offset + length, array.count)
                return Array(array[offset ..< endOffset])
            }

            // String slice
            let str = stringify(value)
            var offset = Int(rawOffset)
            if offset < 0 { offset = str.count + offset }
            guard offset >= 0, offset < str.count, length > 0 else { return "" }
            let startIdx = str.index(str.startIndex, offsetBy: offset)
            let endOffset = min(offset + length, str.count)
            guard endOffset > offset else { return "" }
            let endIdx = str.index(str.startIndex, offsetBy: endOffset)
            return String(str[startIdx ..< endIdx])
        }
        if filterName.equals("limit") {
            guard let array = value as? [Any],
                  let limit = args.first else { return value }
            let count = integerValue(limit) ?? 0
            return Array(array.prefix(count))
        }
        if filterName.equals("offset") {
            guard let array = value as? [Any],
                  let offset = args.first else { return value }
            let skip = integerValue(offset) ?? 0
            return Array(array.dropFirst(skip))
        }
        if filterName.equals("default") {
            // Return default value if input is nil, empty, or false
            let defaultValue = args.first ?? ""
            return isNilOrEmpty(value) ? defaultValue : value
        }
        if filterName.equals("uniq") {
            return uniqueArray(value, key: args.first as? String)
        }
        if filterName.equals("compact") {
            return compactArray(value, key: args.first as? String)
        }
        if filterName.equals("slugify") {
            let str = stringify(value)
            // Simple slugification: lowercase, replace spaces with hyphens
            return str.lowercased()
                .replacingOccurrences(of: " ", with: "-")
                .replacingOccurrences(of: "_", with: "-")
                .filter { $0.isLetter || $0.isNumber || $0 == "-" }
        }

        // MARK: Base64 filters
        if filterName.equals("base64_decode") {
            if value is NSNull { return "" }
            guard value is String || value is InlineString else {
                throw RenderError.typeError(expected: "string", actual: "\(type(of: value))", operation: "base64_decode")
            }
            let str = stringify(value, escape: false)
            guard let data = Data(base64Encoded: str) else { return str }
            return String(data: data, encoding: .utf8) ?? str
        }
        if filterName.equals("base64_encode") {
            let str = stringify(value)
            return Data(str.utf8).base64EncodedString()
        }
        if filterName.equals("base64_url_safe_decode") {
            if value is NSNull { return "" }
            guard value is String else {
                throw RenderError.typeError(expected: "string", actual: "\(type(of: value))", operation: "base64_url_safe_decode")
            }
            var str = stringify(value, escape: false)
            // Convert URL-safe base64 to standard base64
            str = str.replacingOccurrences(of: "-", with: "+")
                .replacingOccurrences(of: "_", with: "/")
            // Add padding if needed
            let remainder = str.count % 4
            if remainder > 0 {
                str += String(repeating: "=", count: 4 - remainder)
            }
            guard let data = Data(base64Encoded: str) else { return stringify(value) }
            return String(data: data, encoding: .utf8) ?? stringify(value)
        }
        if filterName.equals("base64_url_safe_encode") {
            let str = stringify(value)
            return Data(str.utf8).base64EncodedString()
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
        }

        // MARK: Array search filters (find, find_index, has, reject)
        if filterName.equals("find") {
            // String input: check substring containment
            if let str = value as? String {
                let search = stringify(args.first ?? "")
                if args.count > 1 {
                    // Two-arg: find(key, value) — check if contains key AND key == value
                    let target = stringify(args[1])
                    if str.contains(search) && search == target { return str }
                } else {
                    if str.contains(search) { return str }
                }
                return NSNull()
            }
            // Wrap dict input as single-element array
            let array: [Any]
            if let arr = value as? [Any] { array = arr }
            else if isDictLike(value) { array = [value] }
            else { return NSNull() }

            let property = args.first as? String
            let hasTarget = args.count > 1 && !(args[1] is NSNull)
            if let property {
                // Check for mixed arrays (has BOTH dict and non-dict items) — return nil
                let hasDicts = array.contains { isDictLike($0) }
                let hasNonDict = array.contains { !isDictLike($0) }
                if hasDicts && hasNonDict { return NSNull() }

                if hasDicts {
                    // Array of hashes: property-based search
                    for item in array {
                        guard isDictLike(item) else { continue }
                        if hasTarget {
                            if areValuesEqual(dictValue(item, forKey: property), args[1]) { return item }
                        } else {
                            if let val = dictValue(item, forKey: property), !(val is NSNull), isTruthy(val) { return item }
                        }
                    }
                } else {
                    // Non-dict array: must be pure strings (no nil/bool/int mixed in)
                    let hasNonString = array.contains { !($0 is String) }
                    if hasNonString { return NSNull() }
                    // Array of strings: substring matching
                    for item in array {
                        if let str = item as? String {
                            if hasTarget {
                                if areValuesEqual(str, args[1]) { return item }
                            } else {
                                if str.contains(property) { return item }
                            }
                        }
                    }
                }
            } else if hasTarget {
                let target = args[1]
                for item in array {
                    if areValuesEqual(item, target) { return item }
                }
            }
            return NSNull()
        }
        if filterName.equals("find_index") {
            // String input: check substring containment — must come before array cast
            if let str = value as? String {
                let search = stringify(args.first ?? "")
                if args.count > 1 {
                    let target = stringify(args[1])
                    if str.contains(search) && search == target { return 0 }
                } else {
                    if str.contains(search) { return 0 }
                }
                return NSNull()
            }

            let array: [Any]
            if let arr = value as? [Any] { array = arr }
            else if isDictLike(value) { array = [value] }
            else { return NSNull() }

            let property = args.first as? String
            let hasTarget = args.count > 1 && !(args[1] is NSNull)
            if let property {
                // Check for mixed arrays — return nil
                let hasDicts = array.contains { isDictLike($0) }
                let hasNonDict = array.contains { !isDictLike($0) }
                if hasDicts && hasNonDict { return NSNull() }

                if hasDicts {
                    for (index, item) in array.enumerated() {
                        guard isDictLike(item) else { continue }
                        if hasTarget {
                            if areValuesEqual(dictValue(item, forKey: property), args[1]) { return index }
                        } else {
                            if let val = dictValue(item, forKey: property), !(val is NSNull), isTruthy(val) { return index }
                        }
                    }
                } else {
                    // Non-dict array: must be pure strings (no nil/bool/int mixed in)
                    let hasNonString = array.contains { !($0 is String) }
                    if hasNonString { return NSNull() }
                    // String array: substring matching
                    for (index, item) in array.enumerated() {
                        if let str = item as? String {
                            if hasTarget {
                                if areValuesEqual(str, args[1]) { return index }
                            } else {
                                if str.contains(property) { return index }
                            }
                        }
                    }
                }
            } else if hasTarget {
                let target = args[1]
                for (index, item) in array.enumerated() {
                    if areValuesEqual(item, target) { return index }
                }
            }
            return NSNull()
        }
        if filterName.equals("has") {
            // String input: check substring containment
            if let str = value as? String {
                let search = stringify(args.first ?? "")
                return str.contains(search)
            }
            // Hash input: check if key exists with matching value
            if isDictLike(value) {
                if let key = args.first as? String {
                    // Use truthiness check when second arg is nil/NSNull
                    let hasTarget = args.count >= 2 && !(args[1] is NSNull)
                    if hasTarget {
                        // Strict type comparison (no int-string coercion)
                        let dictVal = dictValue(value, forKey: key)
                        let target = args[1]
                        // Strict: Int vs String never equal
                        if (dictVal is Int && target is String) || (dictVal is String && target is Int) {
                            return false
                        }
                        return areValuesEqual(dictVal, target)
                    } else {
                        // has('key'): check if dict has truthy value for key
                        if let val = dictValue(value, forKey: key), !(val is NSNull) { return isTruthy(val) }
                        return false
                    }
                }
                return false
            }
            guard let array = value as? [Any] else { return false }

            if args.count >= 2, let property = args[0] as? String {
                // has(key, value): check if any item[key] == value
                // Mixed arrays (has BOTH dict and non-dict items) → return nil
                let hasDicts = array.contains { isDictLike($0) }
                let hasNonDict = array.contains { !isDictLike($0) }
                if hasDicts && hasNonDict { return NSNull() }
                let target = args[1]
                for item in array {
                    if isDictLike(item) {
                        if areValuesEqual(dictValue(item, forKey: property), target) { return true }
                    }
                }
                return false
            }

            if args.count == 1 {
                let arg = args[0]
                if let property = arg as? String {
                    // has('key'): check if any item has truthy value for key
                    let hasDicts = array.contains { isDictLike($0) }
                    let hasNonDict = array.contains { !isDictLike($0) }
                    if hasDicts && hasNonDict { return NSNull() }
                    if hasDicts {
                        for item in array {
                            if isDictLike(item),
                               let val = dictValue(item, forKey: property), !(val is NSNull), isTruthy(val) {
                                return true
                            }
                        }
                        return false
                    }
                    // Arrays with non-string/non-dict elements → return nil or throw
                    let hasNonStringNonDict = array.contains { !($0 is String) && !isDictLike($0) && !($0 is NSNull) }
                    if hasNonStringNonDict {
                        // Pure int arrays → throw; mixed arrays → return nil
                        let allInts = array.allSatisfy { $0 is Int }
                        if allInts {
                            throw RenderError.typeError(expected: "string or hash", actual: "int array", operation: "has")
                        }
                        return NSNull()
                    }
                    // String array: substring matching
                    for item in array {
                        if let str = item as? String, str.contains(property) { return true }
                    }
                    return false
                } else {
                    // has(non-string): all-primitive arrays with string arg → throw
                    // For numeric arg, check value containment
                    for item in array {
                        if areValuesEqual(item, arg) { return true }
                    }
                    return false
                }
            }

            return false
        }
        if filterName.equals("reject") {
            // Hash input → return array of single-entry dicts (for nested for-loop iteration)
            if let pairs = orderedDictPairs(value) {
                let firstArg = args.first
                let property = firstArg as? String
                let targetArg: Any? = args.count > 1 ? args[1] : nil
                let hasTarget = args.count > 1 && !(targetArg is NSNull)

                if let property {
                    let propVal = dictValue(value, forKey: property)
                    let shouldReject: Bool
                    if hasTarget {
                        shouldReject = areValuesEqual(propVal, targetArg)
                    } else {
                        // reject: 'key' → reject if hash has truthy value for key
                        shouldReject = propVal != nil && !(propVal is NSNull) && isTruthy(propVal!)
                    }
                    if shouldReject {
                        return [Any]()
                    }
                }
                // Not rejected — return array of single-entry OrderedDictionaries
                // so {% for itm in obj %} iterates each entry as a key-value pair
                return pairs.map { (key, val) in
                    OrderedDictionary<String, Any>(uniqueKeysWithValues: [(key, val)]) as Any
                }
            }
            // Wrap string input as single-element array, flatten nested arrays
            let array: [Any]
            if let arr = value as? [Any] {
                array = flattenArray(arr)
            } else if let str = value as? String, !str.isEmpty {
                array = [str]
            } else {
                return [Any]()
            }
            let firstArg = args.first
            let property = firstArg as? String
            // Treat NSNull second arg as undefined → truthy check
            let targetArg: Any? = args.count > 1 ? args[1] : nil
            let hasTarget = args.count > 1 && !(targetArg is NSNull)

            // For non-dict arrays
            if property == nil || !array.contains(where: { isDictLike($0) }) {
                // If firstArg is NSNull, reject all truthy elements
                if firstArg is NSNull {
                    return array.filter { !isTruthy($0) }
                }
                // For string arrays, do substring matching
                if let searchStr = property {
                    // If array has non-string items (nil, bool, int), throw or return empty
                    let hasNonString = array.contains { !($0 is String) }
                    if hasNonString {
                        if array.contains(where: { $0 is Int }) {
                            throw RenderError.typeError(expected: "string or hash", actual: "Int", operation: "reject")
                        }
                        return [Any]()
                    }
                    var result: [Any] = []
                    for item in array {
                        if let str = item as? String {
                            if !str.contains(searchStr) { result.append(item) }
                        } else {
                            result.append(item)
                        }
                    }
                    return result
                }
                return array
            }

            guard let property else { return array }
            return array.filter { item in
                guard isDictLike(item) else { return true }  // Keep non-dict items
                let propVal = dictValue(item, forKey: property)
                if hasTarget {
                    return !areValuesEqual(propVal, targetArg)
                } else {
                    // Keep items where property is falsy (nil, null, false, 0)
                    guard let val = propVal else { return true }  // missing key → keep
                    if val is NSNull { return true }
                    return !isTruthy(val)
                }
            }
        }

        if let customFilter = customFilters[filterName.string] {
            return try await customFilter.apply(
                to: value,
                arguments: args,
                namedArguments: [:]
            )
        }

        throw RenderError.undefinedFilter(filterName.string)
    }
}
