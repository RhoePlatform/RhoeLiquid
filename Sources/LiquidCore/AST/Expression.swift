//
//  Expression.swift
//  LiquidCore
//
//  Created as part of RhoeLiquid
//  A high-performance Swift 6.3 implementation of the Liquid template language
//

import Foundation

/// Represents expressions that can be evaluated during template rendering
///
/// Expressions are the building blocks of dynamic content in Liquid templates.
/// They can be simple literals, variables, complex operations, or filtered values.
public indirect enum Expression: Sendable, Equatable {
    // MARK: - Basic Values
    
    /// A literal value (string, number, boolean, null, array, object)
    case literal(Value)
    
    /// A variable reference (can be simple or dotted path)
    case variable(InlineString)
    
    // MARK: - Operations
    
    /// Binary operation (comparison, logical, arithmetic)
    case binary(left: Expression, op: BinaryOp, right: Expression)
    
    /// Unary operation (logical not)
    case unary(op: UnaryOp, expr: Expression)
    
    /// Range expression (e.g., 1..10)
    case range(start: Expression, end: Expression)
    
    // MARK: - Filters and Tests
    
    /// Expression with applied filters
    case filtered(expr: Expression, filters: [Filter])
    
    /// Test expression (e.g., variable is defined)
    case test(expr: Expression, test: TestOp)
    
    // MARK: - Collection Access
    
    /// Array or object property access (e.g., user.name, items[0])
    case access(expr: Expression, key: Expression)
    
    /// Function-call expressions used by the Rhoe authoring layer.
    ///
    /// Wave 16 activates this AST shape for macro invocation while keeping
    /// arbitrary function registries out of scope. Call expressions therefore
    /// resolve only against active macro definitions/imports.
    case call(name: InlineString, arguments: [CallArgument])
}

/// One positional or named argument in a call expression or tag-driven macro call.
public struct CallArgument: Sendable, Equatable {
    public let label: InlineString?
    public let value: Expression

    public init(label: InlineString? = nil, value: Expression) {
        self.label = label
        self.value = value
    }
}

extension CallArgument {
    public var containsVariables: Bool {
        value.containsVariables
    }

    public var referencedVariables: Set<String> {
        value.referencedVariables
    }

    public var complexityScore: Int {
        value.complexityScore
    }
}

// MARK: - Value Types

/// Represents literal values in expressions
public enum Value: Sendable, Equatable, Hashable {
    /// String literal
    case string(InlineString)
    
    /// Numeric literal (integers and floats)
    /// - Parameters:
    ///   - Double: The numeric value
    ///   - Bool: `true` if the source literal had a decimal point (e.g., `5.0`), `false` for integers (e.g., `5`)
    case number(Double, isFloat: Bool = false)
    
    /// Boolean literal
    case boolean(Bool)
    
    /// Null/nil value
    case null
    
    /// Array of values
    case array([Value])
    
    /// Object/dictionary of values
    case dictionary([String: Value])
}

// MARK: - Filter Type

/// Represents a filter with its name and arguments
public struct Filter: Sendable, Equatable {
    package enum BuiltinKind: UInt8, Sendable, Equatable {
        case upcase
        case downcase
        case capitalize
        case size
        case first
        case last
        case strip
        case reverse
        case raw
        case escape
        case escapeOnce
        case lstrip
        case rstrip
        case abs
        case date
        case json
        case sum
        case uniq
        case compact
        case slugify
        case join
        case split
        case append
        case prepend
        case plus
        case minus
        case times
        case dividedBy
        case round
        case atLeast
        case atMost
        case map
        case sort
        case limit
        case offset
        case `default`
        case ceil
        case floor
        case truncate
        case truncatewords
        case stripHTML
        case stripNewlines
        case newlineToBr
        case urlEncode
        case urlDecode
        case base64Encode
        case base64Decode
        case `where`
    }

    /// The name of the filter
    public let name: InlineString
    
    /// Positional arguments for the filter
    public let arguments: [Expression]
    
    /// Named arguments for the filter (for advanced filters)
    public let namedArguments: [String: Expression]

    package let builtinKind: BuiltinKind?
    package let singleLiteralIntegerArgument: Int?
    
    public init(
        name: InlineString,
        arguments: [Expression] = [],
        namedArguments: [String: Expression] = [:]
    ) {
        self.name = name
        self.arguments = arguments
        self.namedArguments = namedArguments
        self.builtinKind = Filter.builtinKind(for: name)
        if arguments.count == 1,
           namedArguments.isEmpty,
           case .literal(.number(let value, let isFloat)) = arguments[0],
           !isFloat,  // Only for integer literals (no decimal point in source)
           value.rounded(.towardZero) == value {
            self.singleLiteralIntegerArgument = Int(value)
        } else {
            self.singleLiteralIntegerArgument = nil
        }
    }

    package static func builtinKind(for name: InlineString) -> BuiltinKind? {
        if name.equals("upcase") { return .upcase }
        if name.equals("downcase") { return .downcase }
        if name.equals("capitalize") { return .capitalize }
        if name.equals("size") { return .size }
        if name.equals("first") { return .first }
        if name.equals("last") { return .last }
        if name.equals("strip") { return .strip }
        if name.equals("reverse") { return .reverse }
        if name.equals("raw") { return .raw }
        if name.equals("escape") { return .escape }
        if name.equals("escape_once") { return .escapeOnce }
        if name.equals("lstrip") { return .lstrip }
        if name.equals("rstrip") { return .rstrip }
        if name.equals("abs") { return .abs }
        if name.equals("date") { return .date }
        if name.equals("json") { return .json }
        if name.equals("sum") { return .sum }
        if name.equals("uniq") { return .uniq }
        if name.equals("compact") { return .compact }
        if name.equals("slugify") { return .slugify }
        if name.equals("join") { return .join }
        if name.equals("split") { return .split }
        if name.equals("append") { return .append }
        if name.equals("prepend") { return .prepend }
        if name.equals("plus") { return .plus }
        if name.equals("minus") { return .minus }
        if name.equals("times") { return .times }
        if name.equals("divided_by") { return .dividedBy }
        if name.equals("round") { return .round }
        if name.equals("at_least") { return .atLeast }
        if name.equals("at_most") { return .atMost }
        if name.equals("map") { return .map }
        if name.equals("sort") { return .sort }
        if name.equals("limit") { return .limit }
        if name.equals("offset") { return .offset }
        if name.equals("default") { return .default }
        if name.equals("ceil") { return .ceil }
        if name.equals("floor") { return .floor }
        if name.equals("truncate") { return .truncate }
        if name.equals("truncatewords") { return .truncatewords }
        if name.equals("strip_html") { return .stripHTML }
        if name.equals("strip_newlines") { return .stripNewlines }
        if name.equals("newline_to_br") { return .newlineToBr }
        if name.equals("url_encode") { return .urlEncode }
        if name.equals("url_decode") { return .urlDecode }
        if name.equals("base64_encode") { return .base64Encode }
        if name.equals("base64_decode") { return .base64Decode }
        if name.equals("where") { return .where }
        return nil
    }
}

// MARK: - Operator Types

/// Binary operators for expressions
public enum BinaryOp: String, Sendable, CaseIterable, Equatable {
    // Comparison operators
    case equals = "=="
    case notEquals = "!="
    case lessThan = "<"
    case greaterThan = ">"
    case lessThanOrEqual = "<="
    case greaterThanOrEqual = ">="
    
    // Logical operators
    case and = "and"
    case or = "or"
    
    // Membership operator
    case contains = "contains"
    
    // Arithmetic operators (for future extension)
    case plus = "+"
    case minus = "-"
    case multiply = "*"
    case divide = "/"
    case modulo = "%"
}

/// Unary operators for expressions
public enum UnaryOp: String, Sendable, CaseIterable, Equatable {
    /// Logical not
    case not = "not"
    
    /// Arithmetic negation (for future extension)
    case negate = "-"
}

/// Test operators for type and state checking
public enum TestOp: String, Sendable, CaseIterable, Equatable {
    // Existence tests
    case defined = "defined"
    case undefined = "undefined"
    
    // Content tests
    case empty = "empty"
    case blank = "blank"
    case present = "present"
    
    // Type tests
    case number = "number"
    case string = "string"
    case array = "array"
    case boolean = "boolean"
    case object = "object"
    
    // Numeric tests
    case odd = "odd"
    case even = "even"
    case positive = "positive"
    case negative = "negative"
    case zero = "zero"
    
    // Collection tests
    case iterable = "iterable"
    case finite = "finite"
}

// MARK: - Expression Analysis and Utilities

extension Expression {
    /// Returns the static dotted path for simple variable/access chains.
    ///
    /// Examples:
    /// - `user` -> `"user"`
    /// - `product.title` -> `"product.title"`
    /// - `items.0.name` -> `"items.0.name"`
    ///
    /// Dynamic keys, filter results, and computed expressions return `nil`.
    public var staticVariablePath: String? {
        guard let components = staticVariablePathComponents else {
            return nil
        }
        return components.joined(separator: ".")
    }

    /// Returns the static path components for simple variable/access chains.
    public var staticVariablePathComponents: [String]? {
        switch self {
        case .variable(let name):
            return [name.string]

        case .access(let expr, let key):
            guard var components = expr.staticVariablePathComponents else {
                return nil
            }

            switch key {
            case .literal(.string(let keyName)):
                components.append(keyName.string)
                return components
            case .literal(.number(let number, _)):
                guard number.rounded(.towardZero) == number, number >= 0 else {
                    return nil  // Negative indices need dynamic evaluation
                }
                components.append(String(Int(number)))
                return components
            default:
                return nil
            }

        default:
            return nil
        }
    }

    /// Returns true if this expression is a simple literal value
    public var isLiteral: Bool {
        if case .literal = self {
            return true
        }
        return false
    }
    
    /// Returns true if this expression is a simple variable reference
    public var isVariable: Bool {
        if case .variable = self {
            return true
        }
        return false
    }
    
    /// Returns true if this expression contains any variables (not constant)
    public var containsVariables: Bool {
        switch self {
        case .literal:
            return false
        case .variable:
            return true
        case .binary(let left, _, let right):
            return left.containsVariables || right.containsVariables
        case .unary(_, let expr):
            return expr.containsVariables
        case .range(let start, let end):
            return start.containsVariables || end.containsVariables
        case .filtered(let expr, let filters):
            return expr.containsVariables || filters.contains { filter in
                filter.arguments.contains { $0.containsVariables } ||
                filter.namedArguments.values.contains { $0.containsVariables }
            }
        case .test(let expr, _):
            return expr.containsVariables
        case .access(let expr, let key):
            return expr.containsVariables || key.containsVariables
        case .call(_, let arguments):
            return arguments.contains { $0.containsVariables }
        }
    }
    
    /// Returns all variable names referenced in this expression
    public var referencedVariables: Set<String> {
        switch self {
        case .literal:
            return []
        case .variable(let name):
            return [name.description]
        case .binary(let left, _, let right):
            return left.referencedVariables.union(right.referencedVariables)
        case .unary(_, let expr):
            return expr.referencedVariables
        case .range(let start, let end):
            return start.referencedVariables.union(end.referencedVariables)
        case .filtered(let expr, let filters):
            var variables = expr.referencedVariables
            for filter in filters {
                for arg in filter.arguments {
                    variables.formUnion(arg.referencedVariables)
                }
                for (_, arg) in filter.namedArguments {
                    variables.formUnion(arg.referencedVariables)
                }
            }
            return variables
        case .test(let expr, _):
            return expr.referencedVariables
        case .access(let expr, let key):
            return expr.referencedVariables.union(key.referencedVariables)
        case .call(_, let arguments):
            return arguments.reduce(into: Set<String>()) { result, arg in
                result.formUnion(arg.referencedVariables)
            }
        }
    }
    
    /// Returns the complexity score of this expression (for optimization)
    public var complexityScore: Int {
        switch self {
        case .literal:
            return 1
        case .variable:
            return 1
        case .binary(let left, _, let right):
            return left.complexityScore + right.complexityScore + 1
        case .unary(_, let expr):
            return expr.complexityScore + 1
        case .range(let start, let end):
            return start.complexityScore + end.complexityScore + 1
        case .filtered(let expr, let filters):
            let filterComplexity = filters.reduce(0) { total, filter in
                let argComplexity = filter.arguments.reduce(0) { $0 + $1.complexityScore }
                let namedArgComplexity = filter.namedArguments.values.reduce(0) { $0 + $1.complexityScore }
                return total + argComplexity + namedArgComplexity + 1
            }
            return expr.complexityScore + filterComplexity
        case .test(let expr, _):
            return expr.complexityScore + 1
        case .access(let expr, let key):
            return expr.complexityScore + key.complexityScore + 1
        case .call(_, let arguments):
            return arguments.reduce(1) { $0 + $1.complexityScore }
        }
    }
}

// MARK: - Value Utilities

extension Value {
    /// Returns true if this value is considered "truthy" in Liquid
    public var isTruthy: Bool {
        switch self {
        case .boolean(let value):
            return value
        case .null:
            return false
        case .string(let str):
            return !str.isEmpty
        case .number(let num, _):
            return num != 0
        case .array(let arr):
            return !arr.isEmpty
        case .dictionary(let dict):
            return !dict.isEmpty
        }
    }
    
    /// Returns true if this value is empty (used by the 'empty' test)
    public var isEmpty: Bool {
        switch self {
        case .null:
            return true
        case .string(let str):
            return str.isEmpty
        case .array(let arr):
            return arr.isEmpty
        case .dictionary(let dict):
            return dict.isEmpty
        case .boolean, .number:
            return false
        }
    }
    
    /// Returns true if this value is blank (empty or whitespace-only string)
    public var isBlank: Bool {
        switch self {
        case .string(let str):
            return str.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        default:
            return isEmpty
        }
    }
    
    /// Returns the type name of this value
    public var typeName: String {
        switch self {
        case .string: return "string"
        case .number: return "number"
        case .boolean: return "boolean"
        case .null: return "null"
        case .array: return "array"
        case .dictionary: return "object"
        }
    }
    
    /// Converts this value to a Swift Any for interoperability
    public func toAny() -> Any {
        switch self {
        case .string(let str):
            return str.description
        case .number(let num, _):
            return num
        case .boolean(let bool):
            return bool
        case .null:
            return NSNull()
        case .array(let arr):
            return arr.map { $0.toAny() }
        case .dictionary(let dict):
            return dict.mapValues { $0.toAny() }
        }
    }
    
    /// Creates a Value from a Swift Any
    public static func from(_ any: Any) -> Value {
        switch any {
        case let str as String:
            return .string(InlineString(str))
        case let num as Double:
            return .number(num)
        case let num as Int:
            return .number(Double(num))
        case let num as Float:
            return .number(Double(num))
        case let bool as Bool:
            return .boolean(bool)
        case is NSNull:
            return .null
        case let arr as [Any]:
            return .array(arr.map { Value.from($0) })
        case let dict as [String: Any]:
            return .dictionary(dict.mapValues { Value.from($0) })
        default:
            return .string(InlineString(String(describing: any)))
        }
    }
}

// MARK: - Operator Utilities

extension BinaryOp {
    /// Returns the precedence of this operator (higher = evaluated first)
    public var precedence: Int {
        switch self {
        case .multiply, .divide, .modulo:
            return 6
        case .plus, .minus:
            return 5
        case .lessThan, .greaterThan, .lessThanOrEqual, .greaterThanOrEqual:
            return 4
        case .equals, .notEquals:
            return 3
        case .contains:
            return 3
        case .and:
            return 2
        case .or:
            return 1
        }
    }
    
    /// Returns true if this operator is left-associative
    public var isLeftAssociative: Bool {
        return true // All current operators are left-associative
    }
    
    /// Returns true if this operator is a comparison operator
    public var isComparison: Bool {
        switch self {
        case .equals, .notEquals, .lessThan, .greaterThan, .lessThanOrEqual, .greaterThanOrEqual:
            return true
        default:
            return false
        }
    }
    
    /// Returns true if this operator is a logical operator
    public var isLogical: Bool {
        switch self {
        case .and, .or:
            return true
        default:
            return false
        }
    }
}

// MARK: - CustomStringConvertible

extension Expression: CustomStringConvertible {
    public var description: String {
        switch self {
        case .literal(let value):
            return value.description
        case .variable(let name):
            return name.description
        case .binary(let left, let op, let right):
            return "(\(left) \(op.rawValue) \(right))"
        case .unary(let op, let expr):
            return "\(op.rawValue)(\(expr))"
        case .range(let start, let end):
            return "(\(start)..\(end))"
        case .filtered(let expr, let filters):
            let filterString = filters.map { "| \($0.name)" }.joined(separator: " ")
            return "\(expr) \(filterString)"
        case .test(let expr, let test):
            return "\(expr) is \(test.rawValue)"
        case .access(let expr, let key):
            return "\(expr)[\(key)]"
        case .call(let name, let arguments):
            let argString = arguments.map { $0.description }.joined(separator: ", ")
            return "\(name)(\(argString))"
        }
    }
}

extension CallArgument: CustomStringConvertible {
    public var description: String {
        if let label {
            return "\(label): \(value)"
        }
        return value.description
    }
}

extension Value: CustomStringConvertible {
    public var description: String {
        switch self {
        case .string(let str):
            return "\"\(str)\""
        case .number(let num, _):
            return String(num)
        case .boolean(let bool):
            return String(bool)
        case .null:
            return "null"
        case .array(let arr):
            let elements = arr.map { $0.description }.joined(separator: ", ")
            return "[\(elements)]"
        case .dictionary(let dict):
            let pairs = dict.map { "\($0.key): \($0.value.description)" }.joined(separator: ", ")
            return "{\(pairs)}"
        }
    }
}

extension Filter: CustomStringConvertible {
    public var description: String {
        if arguments.isEmpty && namedArguments.isEmpty {
            return name.description
        }
        
        var argStrings: [String] = []
        argStrings.append(contentsOf: arguments.map { $0.description })
        argStrings.append(contentsOf: namedArguments.map { "\($0.key): \($0.value.description)" })
        
        return "\(name): \(argStrings.joined(separator: ", "))"
    }
}
