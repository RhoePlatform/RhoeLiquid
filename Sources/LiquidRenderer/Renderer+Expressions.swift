//
//  Renderer+Expressions.swift
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
    // MARK: - Expression Evaluation
    
    /// Renders an expression to a string
    internal func renderExpression(_ expression: LiquidCore.Expression) async throws -> String {
        guard configuration.debugContext == nil else {
            let value = try await evaluateExpression(expression)
            return stringify(value)
        }

        return try await renderExpressionFast(expression)
    }

    @inline(__always)
    internal func renderExpressionFast(_ expression: LiquidCore.Expression) async throws -> String {
        switch expression {
        case .literal(let value):
            return stringify(try evaluateValue(value))
        case .variable(let name):
            return stringify(context.getVariable(name.string) ?? NSNull())
        case .access:
            if let path = expression.staticVariablePath {
                return stringify(context.getVariable(path) ?? NSNull())
            }
            return stringify(try await evaluateExpressionFast(expression))
        case .filtered(let expr, let filters):
            if filters.count == 1,
               let rendered = try await renderSingleBuiltinFilteredExpressionFast(
                    baseExpression: expr,
                    filter: filters[0]
               ) {
                return rendered
            }
            let baseValue = try await evaluateFilteredBaseValueFast(expr)
            let renderedValue = try await evaluateFilteredValue(baseValue: baseValue, filters: filters)
            return stringify(renderedValue)
        default:
            return stringify(try await evaluateExpressionFast(expression))
        }
    }

    @inline(__always)
    internal func renderSingleBuiltinFilteredExpressionFast(
        baseExpression: LiquidCore.Expression,
        filter: Filter
    ) async throws -> String? {
        guard filter.namedArguments.isEmpty,
              let builtinKind = filter.builtinKind else {
            return nil
        }

        switch builtinKind {
        case .upcase:
            guard filter.arguments.isEmpty else {
                return nil
            }
            let baseValue = try await evaluateFilteredBaseValueFast(baseExpression)
            if let string = baseValue as? String {
                return string.uppercased()
            }
            return stringify(baseValue).uppercased()

        case .round:
            guard filter.arguments.count == 1 else {
                return nil
            }
            let baseValue = try await evaluateFilteredBaseValueFast(baseExpression)
            let precision: Int
            if let literalArgument = filter.singleLiteralIntegerArgument {
                precision = literalArgument
            } else {
                let argument = try await evaluateFilterArgumentFast(filter.arguments[0])
                precision = integerValue(argument) ?? 0
            }
            return renderRoundedValueFast(baseValue, precision: precision)

        default:
            return nil
        }
    }

    
    /// Evaluates an expression to a value
    internal func evaluateExpression(_ expression: LiquidCore.Expression) async throws -> Any {
        guard let debugContext = configuration.debugContext else {
            return try await evaluateExpressionFast(expression)
        }

        let startTime = Date().timeIntervalSinceReferenceDate
        let debugMetadata = debugMetadata(for: expression)
        var inputs: [String: SendableAnyValue] = [:]
        let result: Any

        do {
            result = try await evaluateExpressionCore(expression) { key, value in
                inputs[key] = SendableAnyValue(value)
            }

            let duration = Date().timeIntervalSinceReferenceDate - startTime
            let resultValue = SendableAnyValue(result)
            let recordedInputs = inputs
            Task {
                let evaluation = DebugExpressionEvaluation(
                    expressionType: debugMetadata.type,
                    expression: debugMetadata.description,
                    inputs: recordedInputs,
                    result: resultValue,
                    location: LiquidSourceLocation(line: 0, column: 0, position: 0, templateName: nil),
                    duration: duration,
                    stackDepth: await debugContext.getCallStack().count
                )
                await debugContext.recordExpressionEvaluation(evaluation)
            }

            return result
        } catch {
            let duration = Date().timeIntervalSinceReferenceDate - startTime
            let recordedInputs = inputs
            Task {
                let evaluation = DebugExpressionEvaluation(
                    expressionType: debugMetadata.type,
                    expression: debugMetadata.description,
                    inputs: recordedInputs,
                    result: nil,
                    location: LiquidSourceLocation(line: 0, column: 0, position: 0, templateName: nil),
                    duration: duration,
                    stackDepth: await debugContext.getCallStack().count,
                    error: error.localizedDescription
                )
                await debugContext.recordExpressionEvaluation(evaluation)
            }

            throw error
        }
    }

    internal func evaluateExpressionFast(_ expression: LiquidCore.Expression) async throws -> Any {
        switch expression {
        case .literal(let value):
            return try evaluateValue(value)

        case .variable(let name):
            return context.getVariable(name.string) ?? NSNull()

        case .access(let expr, let key):
            if let path = expression.staticVariablePath {
                return context.getVariable(path) ?? NSNull()
            }
            // Handle bracket notation sentinel: .access(.variable(""), key)
            // [expr] means indirect lookup: evaluate expr, use result as variable name
            if case .variable(let name) = expr, name.string.isEmpty {
                let keyValue = try await evaluateExpressionFast(key)
                let varName = stringify(keyValue)
                return context.getVariable(varName) ?? NSNull()
            }
            let baseValue = try await evaluateExpressionFast(expr)
            switch key {
            case .literal(.string(let keyName)):
                return evaluateAccessValueWithStringKey(baseValue: baseValue, key: keyName.string)
            case .literal(.number(let number, _)):
                return evaluateAccessValueWithIndex(baseValue: baseValue, index: Int(number))
            default:
                let keyValue = try await evaluateExpressionFast(key)
                return try await evaluateAccessValueWithKey(baseValue: baseValue, keyValue: keyValue)
            }

        case .filtered(let expr, let filters):
            let baseValue = try await evaluateFilteredBaseValueFast(expr)
            return try await evaluateFilteredValue(baseValue: baseValue, filters: filters)

        case .binary(let left, let op, let right):
            let leftValue = try await evaluateExpressionFast(left)
            let rightValue = try await evaluateExpressionFast(right)
            return try await evaluateBinaryValues(leftValue: leftValue, op: op, rightValue: rightValue)

        case .unary(let op, let expr):
            let exprValue = try await evaluateExpressionFast(expr)
            return try await evaluateUnaryValue(op: op, value: exprValue)

        case .range(let start, let end):
            let startValue = try await evaluateExpressionFast(start)
            let endValue = try await evaluateExpressionFast(end)
            return try await evaluateRangeValues(startValue: startValue, endValue: endValue)

        case .test(let expr, let test):
            let exprValue = try await evaluateExpressionFast(expr)
            return try await evaluateTestValue(exprValue: exprValue, test: test)

        case .call(let name, let arguments):
            return try await evaluateCall(name: name, arguments: arguments, fast: true)
        }
    }

    internal func evaluateExpressionCore(
        _ expression: LiquidCore.Expression,
        recordInput: ((String, Any) -> Void)?
    ) async throws -> Any {
        switch expression {
        case .literal(let value):
            return try evaluateValue(value)

        case .variable(let name):
            return context.getVariable(name.string) ?? NSNull()

        case .access(let expr, let key):
            if let path = expression.staticVariablePath {
                recordInput?("path", path)
                return context.getVariable(path) ?? NSNull()
            }
            // Handle bracket notation sentinel: .access(.variable(""), key)
            if case .variable(let name) = expr, name.string.isEmpty {
                let keyValue = try await evaluateExpression(key)
                recordInput?("indirectKey", keyValue)
                let varName = stringify(keyValue)
                return context.getVariable(varName) ?? NSNull()
            }
            let baseValue = try await evaluateExpression(expr)
            recordInput?("base", baseValue)
            let keyValue = try await evaluateExpression(key)
            recordInput?("key", keyValue)
            return try await evaluateAccessValueWithKey(baseValue: baseValue, keyValue: keyValue)

        case .filtered(let expr, let filters):
            let baseValue = try await evaluateExpression(expr)
            recordInput?("base", baseValue)
            recordInput?("filterCount", filters.count)
            return try await evaluateFilteredValue(baseValue: baseValue, filters: filters)

        case .binary(let left, let op, let right):
            let leftValue = try await evaluateExpression(left)
            let rightValue = try await evaluateExpression(right)
            recordInput?("left", leftValue)
            recordInput?("right", rightValue)
            recordInput?("operator", String(describing: op))
            return try await evaluateBinaryValues(leftValue: leftValue, op: op, rightValue: rightValue)

        case .unary(let op, let expr):
            let exprValue = try await evaluateExpression(expr)
            recordInput?("operand", exprValue)
            recordInput?("operator", String(describing: op))
            return try await evaluateUnaryValue(op: op, value: exprValue)

        case .range(let start, let end):
            let startValue = try await evaluateExpression(start)
            let endValue = try await evaluateExpression(end)
            recordInput?("start", startValue)
            recordInput?("end", endValue)
            return try await evaluateRangeValues(startValue: startValue, endValue: endValue)

        case .test(let expr, let test):
            let exprValue = try await evaluateExpression(expr)
            recordInput?("expression", exprValue)
            recordInput?("test", String(describing: test))
            return try await evaluateTestValue(exprValue: exprValue, test: test)

        case .call(let name, let arguments):
            for (index, arg) in arguments.enumerated() {
                let argValue = try await evaluateExpression(arg.value)
                if let label = arg.label {
                    recordInput?("arg:\(label.string)", argValue)
                } else {
                    recordInput?("arg\(index)", argValue)
                }
            }
            recordInput?("function", name.string)
            return try await evaluateCall(name: name, arguments: arguments, fast: false)
        }
    }

    internal func debugMetadata(for expression: LiquidCore.Expression) -> (type: String, description: String) {
        switch expression {
        case .literal(let value):
            return ("literal", String(describing: value))
        case .variable(let name):
            return ("variable", name.string)
        case .access:
            return ("access", String(describing: expression))
        case .filtered:
            return ("filtered", String(describing: expression))
        case .binary(let left, let op, let right):
            return ("binary", "\(String(describing: left)) \(op) \(String(describing: right))")
        case .unary(let op, let expr):
            return ("unary", "\(op) \(String(describing: expr))")
        case .range(let start, let end):
            return ("range", "\(String(describing: start))..\(String(describing: end))")
        case .test(let expr, let test):
            return ("test", "\(String(describing: expr)) \(test)")
        case .call(let name, _):
            return ("call", "\(name.string)()")
        }
    }
    
    /// Evaluates a Value to a native Swift type
    internal func evaluateValue(_ value: Value) throws -> Any {
        switch value {
        case .string(let str):
            return str.string
        case .number(let num, let isFloat):
            // Use source literal info to distinguish Int (5) from Float (5.0)
            if isFloat {
                return num  // Keep as Double — source had decimal point
            }
            // Integer literal — convert to Int for proper stringification
            if num == floor(num), !num.isInfinite, !num.isNaN,
               num >= Double(Int.min), num <= Double(Int.max) {
                return Int(num)
            }
            return num
        case .boolean(let bool):
            return bool
        case .null:
            return NSNull()
        case .array(let values):
            return try values.map { try evaluateValue($0) }
        case .dictionary(let dict):
            var result: [String: Any] = [:]
            for (key, val) in dict {
                result[key] = try evaluateValue(val)
            }
            return result
        }
    }
    
    /// Evaluates property/array access
    internal func evaluateAccess(expr: LiquidCore.Expression, key: LiquidCore.Expression) async throws -> Any {
        let object = try await evaluateExpression(expr)
        let keyValue = try await evaluateExpression(key)
        return try await evaluateAccessValueWithKey(baseValue: object, keyValue: keyValue)
    }
    
    /// Evaluates property/array access on values
    internal func evaluateAccessValue(baseValue: Any, key: LiquidCore.Expression) async throws -> Any {
        switch key {
        case .literal(.string(let keyName)):
            return evaluateAccessValueWithStringKey(baseValue: baseValue, key: keyName.string)
        case .literal(.number(let number, _)):
            return evaluateAccessValueWithIndex(baseValue: baseValue, index: Int(number))
        default:
            let keyValue = try await evaluateExpression(key)
            return try await evaluateAccessValueWithKey(baseValue: baseValue, keyValue: keyValue)
        }
    }
    
    /// Evaluates property/array access with evaluated key
    internal func evaluateAccessValueWithKey(baseValue: Any, keyValue: Any) async throws -> Any {
        if let index = keyValue as? Int {
            return evaluateAccessValueWithIndex(baseValue: baseValue, index: index)
        }
        if let index = keyValue as? Double {
            return evaluateAccessValueWithIndex(baseValue: baseValue, index: Int(index))
        }
        if let key = keyValue as? String {
            return evaluateAccessValueWithStringKey(baseValue: baseValue, key: key)
        }
        if let key = keyValue as? InlineString {
            return evaluateAccessValueWithStringKey(baseValue: baseValue, key: key.string)
        }
        if let key = keyValue as? SafeHTML {
            return evaluateAccessValueWithStringKey(baseValue: baseValue, key: key.value)
        }

        return evaluateAccessValueWithStringKey(baseValue: baseValue, key: stringify(keyValue))
    }

    @inline(__always)
    internal func evaluateAccessValueWithIndex(baseValue: Any, index: Int) -> Any {
        guard let array = baseValue as? [Any] else {
            return NSNull()
        }
        // Support negative indexing (Shopify behavior: a[-1] is last element)
        let resolvedIndex = index < 0 ? array.count + index : index
        guard resolvedIndex >= 0 && resolvedIndex < array.count else {
            return NSNull()
        }
        return array[resolvedIndex]
    }

    @inline(__always)
    internal func evaluateAccessValueWithStringKey(baseValue: Any, key: String) -> Any {
        // Dictionary lookup takes priority — enables forloop.first, forloop.last, forloop.length
        if let val = dictValue(baseValue, forKey: key) { return val }
        if isDictLike(baseValue) { /* key not found, fall through */ }
        if key == "size" || key == "length" {
            return getSize(baseValue)
        }
        if key == "first" {
            if let array = baseValue as? [Any], !array.isEmpty {
                return array[0]
            }
            if let pairs = orderedDictPairs(baseValue), let first = pairs.first {
                return [first.0, first.1] as [Any]
            }
            return NSNull()
        }
        if key == "last" {
            if let array = baseValue as? [Any], !array.isEmpty {
                return array[array.count - 1]
            }
            // Note: .last is NOT supported for hashes in Shopify Liquid (only .first is)
            return NSNull()
        }
        if let dataValue = baseValue as? DataValue {
            return dataValue[key].liquidValue
        }
        let mirror = Mirror(reflecting: baseValue)
        for child in mirror.children {
            if child.label == key {
                return child.value
            }
        }
        return ""
    }
    
    /// Evaluates filtered expressions
    internal func evaluateFiltered(expr: LiquidCore.Expression, filters: [Filter]) async throws -> Any {
        let value = try await evaluateExpression(expr)
        return try await evaluateFilteredValue(baseValue: value, filters: filters)
    }

    @inline(__always)
    internal func evaluateFilteredBaseValueFast(_ expression: LiquidCore.Expression) async throws -> Any {
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
    
    /// Evaluates filters on values
    internal func evaluateFilteredValue(baseValue: Any, filters: [Filter]) async throws -> Any {
        guard configuration.debugContext != nil else {
            return try await evaluateFilteredValueFast(baseValue: baseValue, filters: filters)
        }

        var value = baseValue
        let isChained = filters.count > 1
        
        for (index, filter) in filters.enumerated() {
            value = try await applyFilter(filter, to: value, isChained: isChained, chainPosition: index)
        }
        
        return value
    }

    @inline(__always)
    internal func evaluateFilteredValueFast(baseValue: Any, filters: [Filter]) async throws -> Any {
        switch filters.count {
        case 0:
            return baseValue
        case 1:
            return try await applyFilterFast(filters[0], to: baseValue)
        default:
            var value = baseValue
            for filter in filters {
                value = try await applyFilterFast(filter, to: value)
            }
            return value
        }
    }
    
    /// Evaluates binary operations (expression version - kept for compatibility)
    internal func evaluateBinary(left: LiquidCore.Expression, op: BinaryOp, right: LiquidCore.Expression) async throws -> Any {
        let leftValue = try await evaluateExpression(left)
        let rightValue = try await evaluateExpression(right)
        return try await evaluateBinaryValues(leftValue: leftValue, op: op, rightValue: rightValue)
    }
    
    /// Evaluates binary operations with values
    internal func evaluateBinaryValues(leftValue: Any, op: BinaryOp, rightValue: Any) async throws -> Any {
        switch op {
        case .equals:
            return isEqual(leftValue, rightValue)
        case .notEquals:
            return !isEqual(leftValue, rightValue)
        case .lessThan:
            return try isLess(leftValue, rightValue)
        case .lessThanOrEqual:
            return try isLessEqual(leftValue, rightValue)
        case .greaterThan:
            return try isGreater(leftValue, rightValue)
        case .greaterThanOrEqual:
            return try isGreaterEqual(leftValue, rightValue)
        case .and:
            return isTruthy(leftValue) && isTruthy(rightValue)
        case .or:
            return isTruthy(leftValue) || isTruthy(rightValue)
        case .contains:
            return contains(leftValue, rightValue)
        case .plus:
            return try add(leftValue, rightValue)
        case .minus:
            return try subtract(leftValue, rightValue)
        case .multiply:
            return try multiply(leftValue, rightValue)
        case .divide:
            return try divide(leftValue, rightValue)
        case .modulo:
            return try modulo(leftValue, rightValue)
        }
    }
    
    /// Evaluates unary operations
    internal func evaluateUnary(op: UnaryOp, expr: LiquidCore.Expression) async throws -> Any {
        let value = try await evaluateExpression(expr)
        return try await evaluateUnaryValue(op: op, value: value)
    }
    
    /// Evaluates unary operations on values
    internal func evaluateUnaryValue(op: UnaryOp, value: Any) async throws -> Any {
        switch op {
        case .not:
            return !isTruthy(value)
        case .negate:
            guard let num = value as? Double else {
                throw RenderError.typeError(expected: "number", actual: "\(type(of: value))", operation: "negation")
            }
            return -num
        }
    }
    
    /// Evaluates range expressions
    internal func evaluateRange(start: LiquidCore.Expression, end: LiquidCore.Expression) async throws -> Any {
        let startValue = try await evaluateExpression(start)
        let endValue = try await evaluateExpression(end)
        return try await evaluateRangeValues(startValue: startValue, endValue: endValue)
    }
    
    /// Evaluates range from values
    internal func evaluateRangeValues(startValue: Any, endValue: Any) async throws -> Any {
        // Coerce to numeric: non-numeric strings → 0, nil → 0
        let startNum = numericValue(startValue) ?? 0
        let endNum = numericValue(endValue)

        // If end is not a number (e.g., "foo"), return empty array
        guard let endNum else {
            return [Any]()
        }

        let startInt = Int(startNum)
        let endInt = Int(endNum)

        if startInt > endInt {
            return [Any]()
        }
        return Array(startInt...endInt) as [Any]
    }
    
    /// Evaluates test expressions
    internal func evaluateTest(expr: LiquidCore.Expression, test: TestOp) async throws -> Any {
        let value = try await evaluateExpression(expr)
        return try await evaluateTestValue(exprValue: value, test: test)
    }
    
    /// Evaluates test on values
    internal func evaluateTestValue(exprValue: Any, test: TestOp) async throws -> Any {
        switch test {
        case .defined:
            return !(exprValue is NSNull) && exprValue as? String != ""
        case .undefined:
            return (exprValue is NSNull) || exprValue as? String == ""
        case .empty:
            return isEmpty(exprValue)
        case .blank:
            return isBlank(exprValue)
        case .present:
            return !isEmpty(exprValue)
        case .number:
            return exprValue is Double
        case .string:
            return exprValue is String
        case .array:
            return exprValue is [Any]
        case .boolean:
            return exprValue is Bool
        case .object:
            return exprValue is [String: Any] || exprValue is OrderedDictionary<String, Any>
        case .odd:
            guard let num = exprValue as? Double else { return false }
            return Int(num) % 2 == 1
        case .even:
            guard let num = exprValue as? Double else { return false }
            return Int(num) % 2 == 0
        case .positive:
            guard let num = exprValue as? Double else { return false }
            return num > 0
        case .negative:
            guard let num = exprValue as? Double else { return false }
            return num < 0
        case .zero:
            guard let num = exprValue as? Double else { return false }
            return num == 0
        case .iterable:
            return exprValue is [Any] || exprValue is String
        case .finite:
            guard let num = exprValue as? Double else { return false }
            return num.isFinite
        }
    }
    
    /// Evaluates function-call expressions.
    ///
    /// Function calls are explicitly out of scope for the active 1.x release
    /// surface. This method remains only so the renderer can fail that dormant
    /// AST shape with a precise error.
    internal func evaluateCall(
        name: InlineString,
        arguments: [CallArgument],
        fast: Bool
    ) async throws -> Any {
        var evaluatedArguments: [EvaluatedCallArgument] = []
        evaluatedArguments.reserveCapacity(arguments.count)
        for argument in arguments {
            let value: Any
            if fast {
                value = try await evaluateExpressionFast(argument.value)
            } else {
                value = try await evaluateExpression(argument.value)
            }
            evaluatedArguments.append(
                EvaluatedCallArgument(
                    label: argument.label?.string,
                    value: value
                )
            )
        }
        return try await evaluateCallValues(name: name, argumentValues: evaluatedArguments)
    }
    
    /// Evaluates function-call expressions with already-computed arguments.
    internal func evaluateCallValues(name: InlineString, argumentValues: [EvaluatedCallArgument]) async throws -> Any {
        try await renderMacroCall(name: name, argumentValues: argumentValues, body: nil)
    }
}
