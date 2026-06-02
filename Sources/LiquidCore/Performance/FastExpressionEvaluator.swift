//
//  FastExpressionEvaluator.swift
//  LiquidCore
//
//  Ultra-fast expression evaluator with optimized property access
//

import Foundation

/// High-performance expression evaluator with specialized fast paths
/// for common expression patterns
public struct FastExpressionEvaluator: Sendable {
    
    /// Cached property accessors for fast object traversal
    private let propertyCache: PropertyAccessCache
    
    /// Pre-compiled variable access patterns
    private let accessPatterns: [String: AccessPattern]
    
    public init(accessPatterns: [String: AccessPattern] = [:]) {
        self.accessPatterns = accessPatterns
        self.propertyCache = PropertyAccessCache()
    }
    
    /// Fast-path expression evaluation with specialized optimizations
    public func evaluate(_ expression: LiquidCore.Expression, context: [String: Any]) throws -> Any {
        if let path = expression.staticVariablePath {
            return evaluateVariable(path, context: context)
        }

        switch expression {
        case .variable(let name):
            return evaluateVariable(name.string, context: context)
            
        case .access(let expr, let key):
            return try evaluateAccess(expr, key: key, context: context)
            
        case .literal(let value):
            return evaluateLiteral(value)
            
        case .binary(let left, let op, let right):
            return try evaluateBinary(left: left, op: op, right: right, context: context)
            
        case .filtered(let expr, let filters):
            return try evaluateFiltered(expr, filters: filters, context: context)
            
        default:
            throw RenderError.custom("Unsupported expression type in fast evaluator")
        }
    }
    
    // MARK: - Optimized Evaluators
    
    private func evaluateVariable(_ name: String, context: [String: Any]) -> Any {
        // Fast path for simple variables
        if let value = context[name] {
            return value
        }
        
        // Check for dot notation with cached patterns
        if name.contains(".") {
            let components = name.split(separator: ".").map(String.init)
            return evaluatePropertyPath(components, context: context)
        }
        
        return ""
    }
    
    private func evaluatePropertyPath(_ path: [String], context: [String: Any]) -> Any {
        guard !path.isEmpty else { return "" }
        
        var current: Any = context[path[0]] ?? ""
        
        for component in path.dropFirst() {
            current = getProperty(from: current, key: component)
        }
        
        return current
    }
    
    private func evaluateAccess(_ expr: LiquidCore.Expression, key: LiquidCore.Expression, context: [String: Any]) throws -> Any {
        let object = try evaluate(expr, context: context)
        let keyValue = try evaluate(key, context: context)
        
        // Fast path for string keys
        if let keyStr = keyValue as? String {
            return getProperty(from: object, key: keyStr)
        }
        
        // Array access
        if let array = object as? [Any], let index = keyValue as? Double {
            let idx = Int(index)
            guard idx >= 0 && idx < array.count else { return "" }
            return array[idx]
        }
        
        return ""
    }
    
    private func evaluateLiteral(_ value: Value) -> Any {
        switch value {
        case .string(let s): return s
        case .number(let n, _): return n
        case .boolean(let b): return b
        case .null: return NSNull()
        case .array(let arr): return arr.map { evaluateLiteral($0) }
        case .dictionary(let obj): return obj.mapValues { evaluateLiteral($0) }
        }
    }
    
    private func evaluateBinary(left: LiquidCore.Expression, op: BinaryOp, right: LiquidCore.Expression, context: [String: Any]) throws -> Any {
        let leftValue = try evaluate(left, context: context)
        let rightValue = try evaluate(right, context: context)
        
        switch op {
        case .equals:
            return isEqual(leftValue, rightValue)
        case .notEquals:
            return !isEqual(leftValue, rightValue)
        case .lessThan:
            return isLess(leftValue, rightValue)
        case .lessThanOrEqual:
            return isLessEqual(leftValue, rightValue)
        case .greaterThan:
            return isGreater(leftValue, rightValue)
        case .greaterThanOrEqual:
            return isGreaterEqual(leftValue, rightValue)
        case .and:
            return isTruthy(leftValue) && isTruthy(rightValue)
        case .or:
            return isTruthy(leftValue) || isTruthy(rightValue)
        case .plus:
            return performAddition(leftValue, rightValue)
        case .minus:
            return performSubtraction(leftValue, rightValue)
        case .multiply:
            return performMultiplication(leftValue, rightValue)
        case .divide:
            return performDivision(leftValue, rightValue)
        case .modulo:
            return performModulo(leftValue, rightValue)
        case .contains:
            return checkContains(leftValue, rightValue)
        }
    }
    
    private func evaluateFiltered(_ expr: LiquidCore.Expression, filters: [Filter], context: [String: Any]) throws -> Any {
        var value = try evaluate(expr, context: context)
        
        for filter in filters {
            value = try applyFilter(filter, to: value, context: context)
        }
        
        return value
    }
    
    // MARK: - Optimized Property Access
    
    private func getProperty(from object: Any, key: String) -> Any {
        // Use cached accessor if available
        if let cached = propertyCache.getAccessor(for: type(of: object), key: key) {
            return cached(object) ?? ""
        }
        
        // Fast paths for common types
        if let dict = object as? [String: Any] {
            return dict[key] ?? ""
        }
        
        if let array = object as? [Any] {
            // Handle special array properties
            switch key {
            case "size", "length":
                return array.count
            case "first":
                return array.first ?? ""
            case "last":
                return array.last ?? ""
            default:
                if let index = Int(key), index >= 0 && index < array.count {
                    return array[index]
                }
                return ""
            }
        }
        
        if let str = object as? String {
            switch key {
            case "size", "length":
                return str.count
            default:
                return ""
            }
        }
        
        // Use reflection as fallback (cache the result)
        let accessor = createPropertyAccessor(for: type(of: object), key: key)
        propertyCache.setAccessor(for: type(of: object), key: key, accessor: accessor)
        
        return accessor(object) ?? ""
    }
    
    private func createPropertyAccessor(for type: Any.Type, key: String) -> (Any) -> Any? {
        return { object in
            let mirror = Mirror(reflecting: object)
            for child in mirror.children {
                if child.label == key {
                    return child.value
                }
            }
            return nil
        }
    }
    
    // MARK: - Fast Comparison Operations
    
    private func isEqual(_ left: Any, _ right: Any) -> Bool {
        switch (left, right) {
        case (let l as String, let r as String): return l == r
        case (let l as Double, let r as Double): return l == r
        case (let l as Int, let r as Int): return l == r
        case (let l as Int, let r as Double): return Double(l) == r
        case (let l as Double, let r as Int): return l == Double(r)
        case (let l as Bool, let r as Bool): return l == r
        case (is NSNull, is NSNull): return true
        default: return false
        }
    }
    
    private func isLess(_ left: Any, _ right: Any) -> Bool {
        switch (left, right) {
        case (let l as Double, let r as Double): return l < r
        case (let l as Int, let r as Int): return l < r
        case (let l as Int, let r as Double): return Double(l) < r
        case (let l as Double, let r as Int): return l < Double(r)
        case (let l as String, let r as String): return l < r
        default: return false
        }
    }
    
    private func isLessEqual(_ left: Any, _ right: Any) -> Bool {
        return isLess(left, right) || isEqual(left, right)
    }
    
    private func isGreater(_ left: Any, _ right: Any) -> Bool {
        return !isLessEqual(left, right)
    }
    
    private func isGreaterEqual(_ left: Any, _ right: Any) -> Bool {
        return !isLess(left, right)
    }
    
    // MARK: - Fast Arithmetic Operations
    
    private func performAddition(_ left: Any, _ right: Any) -> Any {
        switch (left, right) {
        case (let l as Double, let r as Double): return l + r
        case (let l as Int, let r as Int): return l + r
        case (let l as Int, let r as Double): return Double(l) + r
        case (let l as Double, let r as Int): return l + Double(r)
        case (let l as String, let r): return l + stringify(r)
        case (let l, let r as String): return stringify(l) + r
        default: return 0
        }
    }
    
    private func performSubtraction(_ left: Any, _ right: Any) -> Any {
        switch (left, right) {
        case (let l as Double, let r as Double): return l - r
        case (let l as Int, let r as Int): return l - r
        case (let l as Int, let r as Double): return Double(l) - r
        case (let l as Double, let r as Int): return l - Double(r)
        default: return 0
        }
    }
    
    private func performMultiplication(_ left: Any, _ right: Any) -> Any {
        switch (left, right) {
        case (let l as Double, let r as Double): return l * r
        case (let l as Int, let r as Int): return l * r
        case (let l as Int, let r as Double): return Double(l) * r
        case (let l as Double, let r as Int): return l * Double(r)
        default: return 0
        }
    }
    
    private func performDivision(_ left: Any, _ right: Any) -> Any {
        switch (left, right) {
        case (let l as Double, let r as Double) where r != 0: return l / r
        case (let l as Int, let r as Int) where r != 0: return l / r
        case (let l as Int, let r as Double) where r != 0: return Double(l) / r
        case (let l as Double, let r as Int) where r != 0: return l / Double(r)
        default: return 0
        }
    }
    
    private func performModulo(_ left: Any, _ right: Any) -> Any {
        switch (left, right) {
        case (let l as Int, let r as Int) where r != 0: return l % r
        case (let l as Double, let r as Double) where r != 0: return l.truncatingRemainder(dividingBy: r)
        default: return 0
        }
    }
    
    private func checkContains(_ left: Any, _ right: Any) -> Bool {
        if let array = left as? [Any] {
            return array.contains { isEqual($0, right) }
        }
        if let str = left as? String, let substr = right as? String {
            return str.contains(substr)
        }
        return false
    }
    
    // MARK: - Utilities
    
    private func isTruthy(_ value: Any) -> Bool {
        switch value {
        case let b as Bool: return b
        case is NSNull: return false
        case let s as String: return !s.isEmpty
        case let n as Double: return n != 0
        case let n as Int: return n != 0
        case let arr as [Any]: return !arr.isEmpty
        case let dict as [String: Any]: return !dict.isEmpty
        default: return true
        }
    }
    
    private func stringify(_ value: Any) -> String {
        switch value {
        case let s as String: return s
        case let n as Double: return String(n)
        case let n as Int: return String(n)
        case let b as Bool: return String(b)
        case is NSNull: return ""
        default: return String(describing: value)
        }
    }
    
    private func applyFilter(_ filter: Filter, to value: Any, context: [String: Any]) throws -> Any {
        let filterName = filter.name.string
        let _ = try filter.arguments.map { try evaluate($0, context: context) }
        
        // Fast paths for common filters
        switch filterName {
        case "upcase":
            return stringify(value).uppercased()
        case "downcase":
            return stringify(value).lowercased()
        case "size":
            if let array = value as? [Any] { return array.count }
            if let str = value as? String { return str.count }
            if let dict = value as? [String: Any] { return dict.count }
            return 0
        case "first":
            if let array = value as? [Any] { return array.first ?? "" }
            return ""
        case "last":
            if let array = value as? [Any] { return array.last ?? "" }
            return ""
        default:
            // Fallback to regular filter processing
            throw RenderError.undefinedFilter(filterName)
        }
    }
}

// MARK: - Property Access Cache

// SAFETY: NSLock-protected mutable state (cache, lock)
private final class PropertyAccessCache: @unchecked Sendable {
    private var cache: [ObjectIdentifier: [String: (Any) -> Any?]] = [:]
    private let lock = NSLock()
    
    func getAccessor(for type: Any.Type, key: String) -> ((Any) -> Any?)? {
        lock.lock()
        defer { lock.unlock() }
        
        let typeId = ObjectIdentifier(type)
        return cache[typeId]?[key]
    }
    
    func setAccessor(for type: Any.Type, key: String, accessor: @escaping (Any) -> Any?) {
        lock.lock()
        defer { lock.unlock() }
        
        let typeId = ObjectIdentifier(type)
        if cache[typeId] == nil {
            cache[typeId] = [:]
        }
        cache[typeId]?[key] = accessor
    }
}
