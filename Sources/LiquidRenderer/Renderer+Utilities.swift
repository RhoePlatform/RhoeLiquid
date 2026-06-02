//
//  Renderer+Utilities.swift
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
    // MARK: - Utility Functions
    
    /// Converts any value to a string representation
    /// Format a Double value for Liquid output.
    /// Shopify Liquid always shows the decimal for Doubles (5.0 → "5.0").
    @inline(__always)
    internal func formatDouble(_ num: Double) -> String {
        if num == floor(num), !num.isInfinite, !num.isNaN {
            // Whole-number doubles: show as "5.0" not "5"
            return String(format: "%.1f", num)
        }
        // Use Swift's default which gives shortest round-trip representation
        let full = String(num)
        // Detect floating-point noise: patterns like "7.8999999999999995" or "3.0000000000000004"
        // These have 16 significant digits and end with runs of 9s or 0s followed by small digits
        if full.count >= 16, let dotIndex = full.firstIndex(of: ".") {
            let decimals = String(full[full.index(after: dotIndex)...])
            // Check for trailing noise: many 9s or 0s near the end
            if decimals.count >= 13 {
                let last5 = String(decimals.suffix(5))
                let nineCount = last5.filter { $0 == "9" }.count
                let zeroCount = last5.filter { $0 == "0" }.count
                if nineCount >= 4 || zeroCount >= 4 {
                    // Round to 10 significant digits to eliminate noise
                    let rounded = String(format: "%.10g", num)
                    return rounded
                }
            }
        }
        return full
    }

    internal func stringify(_ value: Any, escape: Bool? = nil) -> String {
        if let escape {
            let stringValue = stringifyUnescapedPreservingSafeHTML(value)
            return escape ? HTMLEscape.escape(stringValue) : stringValue
        }

        if autoEscapeEnabled {
            if let safeHTML = value as? SafeHTML {
                return safeHTML.value
            }
            return HTMLEscape.escape(stringifyUnescaped(value))
        }

        return stringifyUnescapedPreservingSafeHTML(value)
    }

    @inline(__always)
    internal func stringifyUnescapedPreservingSafeHTML(_ value: Any) -> String {
        if let safeHTML = value as? SafeHTML {
            return safeHTML.value
        }
        return stringifyUnescaped(value)
    }

    @inline(__always)
    internal func stringifyUnescaped(_ value: Any) -> String {
        switch value {
        case let str as String:
            return str
        case let inline as InlineString:
            return inline.string
        case let num as Double:
            return formatDouble(num)
        case let num as Int:
            return String(num)
        case let bool as Bool:
            return bool ? "true" : "false"
        case let number as NSNumber:
            return number.doubleValue == floor(number.doubleValue)
                ? String(number.intValue)
                : String(number.doubleValue)
        case is NSNull:
            return ""
        case let array as [Any]:
            return joinedStringifiedValues(array, separator: "", escapeElements: false)
        case let dict as [String: Any]:
            // Shopify Liquid outputs dictionaries as {"key"=>"value"} format
            if dict.isEmpty { return "{}" }
            let pairs = dict.sorted(by: { $0.key < $1.key })
                .map { "\"\($0.key)\"=>\(stringifyUnescaped($0.value))" }
            return "{\(pairs.joined(separator: ", "))}"
        case let ordered as OrderedDictionary<String, Any>:
            if ordered.isEmpty { return "{}" }
            let pairs = ordered.map { "\"\($0.key)\"=>\(stringifyUnescaped($0.value))" }
            return "{\(pairs.joined(separator: ", "))}"
        default:
            return String(describing: value)
        }
    }

    internal func joinedStringifiedValues(_ array: [Any], separator: String, escapeElements: Bool) -> String {
        guard !array.isEmpty else { return "" }

        var parts: [String] = []
        parts.reserveCapacity(array.count)

        var estimatedCapacity = separator.utf8.count * max(0, array.count - 1)
        for value in array {
            let rendered = escapeElements ? stringify(value) : stringifyUnescaped(value)
            estimatedCapacity += rendered.utf8.count
            parts.append(rendered)
        }

        var result = ""
        result.reserveCapacity(estimatedCapacity)

        for index in parts.indices {
            if index > 0 {
                result += separator
            }
            result += parts[index]
        }

        return result
    }

    @inline(__always)
    internal func integerValue(_ value: Any) -> Int? {
        switch value {
        case let int as Int:
            return int
        case let double as Double:
            return Int(double)
        case is Bool:
            return nil
        case let string as String:
            return Int(string)
        case let inline as InlineString:
            return Int(inline.string)
        case let safeHTML as SafeHTML:
            return Int(safeHTML.value)
        case let number as NSNumber:
            return number.intValue
        default:
            return nil
        }
    }

    @inline(__always)
    internal func numericValue(_ value: Any) -> Double? {
        switch value {
        case let double as Double:
            return double
        case let int as Int:
            return Double(int)
        case is Bool:
            return nil
        case let string as String:
            return Double(string)
        case let inline as InlineString:
            return Double(inline.string)
        case let safeHTML as SafeHTML:
            return Double(safeHTML.value)
        case let number as NSNumber:
            return number.doubleValue
        default:
            return nil
        }
    }
    
    /// Checks if a value is truthy in Liquid.
    /// Per Shopify spec: only nil and false are falsy — everything else is truthy,
    /// including empty strings, 0, and empty arrays.
    internal func isTruthy(_ value: Any) -> Bool {
        switch value {
        case let bool as Bool:
            return bool
        case is NSNull:
            return false
        default:
            return true
        }
    }
    
    /// Checks if two values are equal
    internal func isEqual(_ left: Any, _ right: Any) -> Bool {
        // Implement Liquid equality semantics
        // IMPORTANT: Bool must be checked BEFORE Int/Double because Swift bridges
        // Bool to NSNumber, making true matchable as Int(1) and false as Int(0)
        switch (left, right) {
        case (let l as Bool, let r as Bool):
            return l == r
        case (is Bool, _), (_, is Bool):
            // Bool compared to non-Bool is always false in Shopify Liquid
            return false
        case (let l as String, let r as String):
            return l == r
        // Shopify 'empty' keyword (empty string) equals empty arrays and empty dicts
        case (let s as String, let arr as [Any]) where s.isEmpty:
            return arr.isEmpty
        case (let arr as [Any], let s as String) where s.isEmpty:
            return arr.isEmpty
        case (let s as String, let dict as [String: Any]) where s.isEmpty:
            return dict.isEmpty
        case (let dict as [String: Any], let s as String) where s.isEmpty:
            return dict.isEmpty
        case (let s as String, let ordered as OrderedDictionary<String, Any>) where s.isEmpty:
            return ordered.isEmpty
        case (let ordered as OrderedDictionary<String, Any>, let s as String) where s.isEmpty:
            return ordered.isEmpty
        case (let l as Int, let r as Int):
            return l == r
        case (let l as Double, let r as Double):
            return l == r
        case (let l as Int, let r as Double):
            return Double(l) == r
        case (let l as Double, let r as Int):
            return l == Double(r)
        case (is NSNull, is NSNull):
            return true
        // Handle NSNumber types
        case (let l as NSNumber, let r as NSNumber):
            return l == r
        case (let l as NSNumber, let r as Int):
            return l.intValue == r
        case (let l as Int, let r as NSNumber):
            return l == r.intValue
        case (let l as NSNumber, let r as Double):
            return l.doubleValue == r
        case (let l as Double, let r as NSNumber):
            return l == r.doubleValue
        // String compared to number: not equal in Shopify Liquid (different types)
        case (is String, is Int), (is Int, is String):
            return false
        case (is String, is Double), (is Double, is String):
            return false
        default:
            // Fallback: compare stringified values for same-type comparisons
            return stringify(left) == stringify(right)
        }
    }

    /// Comparison functions — numeric first, then string lexicographic fallback
    internal func isLess(_ left: Any, _ right: Any) throws -> Bool {
        return try compareValues(left, right) < 0
    }

    internal func isLessEqual(_ left: Any, _ right: Any) throws -> Bool {
        return try compareValues(left, right) <= 0
    }

    internal func isGreater(_ left: Any, _ right: Any) throws -> Bool {
        return try compareValues(left, right) > 0
    }

    internal func isGreaterEqual(_ left: Any, _ right: Any) throws -> Bool {
        return try compareValues(left, right) >= 0
    }

    /// Compares two values for ordering. Returns negative, zero, or positive.
    /// Throws if the types are incompatible (e.g., string vs number).
    internal func compareValues(_ left: Any, _ right: Any) throws -> Int {
        // Both numeric (Int or Double, but NOT String coerced to number)
        let leftIsNumeric = left is Int || left is Double
        let rightIsNumeric = right is Int || right is Double

        if leftIsNumeric && rightIsNumeric {
            let l = numericValue(left) ?? 0
            let r = numericValue(right) ?? 0
            if l < r { return -1 }
            if l > r { return 1 }
            return 0
        }

        // Both strings
        if let l = left as? String, let r = right as? String {
            return l < r ? -1 : (l > r ? 1 : 0)
        }

        // NSNull comparisons
        if left is NSNull && right is NSNull { return 0 }
        if left is NSNull || right is NSNull {
            throw RenderError.typeError(expected: "comparable types", actual: "nil vs \(type(of: left is NSNull ? right : left))", operation: "comparison")
        }

        // Incompatible types — error (Shopify behavior)
        throw RenderError.typeError(expected: "comparable types", actual: "\(type(of: left)) vs \(type(of: right))", operation: "comparison")
    }
    
    /// Checks if a value looks like a float (Double type, or string containing ".")
    @inline(__always)
    internal func isFloatLike(_ value: Any) -> Bool {
        if value is Double { return true }
        if let str = value as? String, str.contains(".") { return true }
        if let inline = value as? InlineString, inline.string.contains(".") { return true }
        return false
    }

    // MARK: - Dictionary Helpers (OrderedDictionary support)

    @inline(__always)
    internal func orderedDictPairs(_ value: Any) -> [(key: String, value: Any)]? {
        if let ordered = value as? OrderedDictionary<String, Any> {
            return ordered.map { (key: $0.key, value: $0.value) }
        }
        if let dict = value as? [String: Any] {
            return dict.sorted(by: { $0.key < $1.key })
        }
        return nil
    }

    @inline(__always)
    internal func dictValue(_ value: Any, forKey key: String) -> Any? {
        if let ordered = value as? OrderedDictionary<String, Any> {
            return ordered[key]
        }
        if let dict = value as? [String: Any] {
            return dict[key]
        }
        return nil
    }

    @inline(__always)
    internal func isDictLike(_ value: Any) -> Bool {
        value is [String: Any] || value is OrderedDictionary<String, Any>
    }

    @inline(__always)
    internal func dictCount(_ value: Any) -> Int? {
        if let ordered = value as? OrderedDictionary<String, Any> {
            return ordered.count
        }
        if let dict = value as? [String: Any] {
            return dict.count
        }
        return nil
    }

    /// Arithmetic operations
    internal func add(_ left: Any, _ right: Any) throws -> Any {
        if let l = left as? Int, let r = right as? Int { return l + r }
        let hasFloat = isFloatLike(left) || isFloatLike(right)
        let l = numericValue(left) ?? 0
        let r = numericValue(right) ?? 0
        let result = l + r
        if !hasFloat, result == result.rounded(.towardZero) { return Int(result) }
        return result
    }

    internal func subtract(_ left: Any, _ right: Any) throws -> Any {
        if let l = left as? Int, let r = right as? Int { return l - r }
        let hasFloat = isFloatLike(left) || isFloatLike(right)
        let l = numericValue(left) ?? 0
        let r = numericValue(right) ?? 0
        let result = l - r
        if !hasFloat, result == result.rounded(.towardZero) { return Int(result) }
        return result
    }

    internal func multiply(_ left: Any, _ right: Any) throws -> Any {
        if let l = left as? Int, let r = right as? Int { return l * r }
        let hasFloat = isFloatLike(left) || isFloatLike(right)
        let l = numericValue(left) ?? 0
        let r = numericValue(right) ?? 0
        let result = l * r
        if !hasFloat, result == result.rounded(.towardZero) { return Int(result) }
        return result
    }

    internal func divide(_ left: Any, _ right: Any) throws -> Any {
        // Integer division when both operands are integers (Shopify behavior: 5/3=1)
        if let l = left as? Int, let r = right as? Int {
            guard r != 0 else { throw RenderError.arithmeticError("Division by zero") }
            return l / r
        }
        // Float division if either operand is actually a Double or float-like string
        let hasFloat = isFloatLike(left) || isFloatLike(right)
        let l = numericValue(left) ?? 0
        let r = numericValue(right) ?? 0
        guard r != 0 else {
            throw RenderError.arithmeticError("Division by zero")
        }
        let result = l / r
        // If neither input was a float, return Int (string coercion case)
        if !hasFloat, result == result.rounded(.towardZero) {
            return Int(result)
        }
        return result
    }

    internal func modulo(_ left: Any, _ right: Any) throws -> Any {
        if let l = left as? Int, let r = right as? Int {
            guard r != 0 else { throw RenderError.arithmeticError("Division by zero") }
            return l % r
        }
        let hasFloat = isFloatLike(left) || isFloatLike(right)
        let l = numericValue(left) ?? 0
        let r = numericValue(right) ?? 0
        guard r != 0 else {
            throw RenderError.arithmeticError("Division by zero")
        }
        let result = l.truncatingRemainder(dividingBy: r)
        if !hasFloat, result == result.rounded(.towardZero) {
            return Int(result)
        }
        return result
    }

    // MARK: - Split Filter (shared implementation)

    /// Applies the split filter to a value with the given separator.
    /// Consolidates the split logic used by builtin, single-arg, and multi-arg filter paths.
    /// Ruby's `split(" ")` splits on ANY whitespace run (special behavior).
    internal func applySplitFilter(_ value: Any, separator: Any) -> Any {
        let str = stringify(value)
        if separator is NSNull {
            return str.isEmpty ? [Any]() : str.map { String($0) } as [Any]
        }
        let sep = stringify(separator)
        if sep.isEmpty {
            return str.isEmpty ? [Any]() : str.map { String($0) } as [Any]
        }
        // Ruby's split(" ") splits on ANY whitespace run
        if sep == " " {
            let parts = str.split(omittingEmptySubsequences: true, whereSeparator: { $0.isWhitespace })
            return parts.map { String($0) } as [Any]
        }
        // Standard split — preserve empty parts if any non-empty parts exist
        let parts = str.components(separatedBy: sep)
        return parts.contains(where: { !$0.isEmpty }) ? parts : [Any]()
    }

    /// Collection operations
    internal func contains(_ haystack: Any, _ needle: Any) -> Bool {
        // Shopify: contains with false/nil/undefined needle always returns false
        if needle is Bool || needle is NSNull { return false }
        if let s = needle as? String, s.isEmpty { return false }  // undefined var

        if let str = haystack as? String {
            return str.contains(stringify(needle))
        }
        if let array = haystack as? [Any] {
            return array.contains { isEqual($0, needle) }
        }
        return false
    }
    
    internal func getSize(_ value: Any) -> Int {
        if let str = value as? String {
            return str.count
        }
        if let array = value as? [Any] {
            return array.count
        }
        if let count = dictCount(value) { return count }
        return 0
    }
    
    internal func getFirst(_ value: Any) -> Any {
        if let array = value as? [Any], !array.isEmpty {
            return array[0]
        }
        if let pairs = orderedDictPairs(value), let first = pairs.first {
            return [first.key, first.value] as [Any]
        }
        return NSNull()
    }

    internal func getLast(_ value: Any) -> Any {
        if let array = value as? [Any], !array.isEmpty {
            return array[array.count - 1]
        }
        return ""
    }
    
    internal func isNilOrEmpty(_ value: Any) -> Bool {
        switch value {
        case is NSNull:
            return true
        case let str as String:
            return str.isEmpty
        case let array as [Any]:
            return array.isEmpty
        case let dict as [String: Any]:
            return dict.isEmpty
        case let ordered as OrderedDictionary<String, Any>:
            return ordered.isEmpty
        case let bool as Bool:
            return !bool
        default:
            // Check for empty string representation
            let str = stringify(value)
            return str.isEmpty || str == "\"\""
        }
    }
    
    internal func isEmpty(_ value: Any) -> Bool {
        switch value {
        case let str as String:
            return str.isEmpty
        case let array as [Any]:
            return array.isEmpty
        case is NSNull:
            return true
        default:
            return false
        }
    }
    
    internal func isBlank(_ value: Any) -> Bool {
        switch value {
        case let str as String:
            return str.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case is NSNull:
            return true
        default:
            return isEmpty(value)
        }
    }
    
    internal func joinArray(_ value: Any, separator: String) -> String {
        guard let array = value as? [Any] else { return stringify(value) }
        // Flatten nested arrays before joining (Shopify behavior)
        let flat = flattenArray(array)
        return joinedStringifiedValues(flat, separator: separator, escapeElements: true)
    }

    /// Compare two values for sort — numeric values compared numerically, otherwise string comparison.
    internal func compareForSort(_ a: Any, _ b: Any) -> Bool {
        // If both are numeric, compare numerically
        if let na = numericValue(a), let nb = numericValue(b),
           (a is Int || a is Double), (b is Int || b is Double) {
            return na < nb
        }
        return stringify(a) < stringify(b)
    }

    internal func compareForSortNatural(_ a: Any, _ b: Any) -> Bool {
        if a is NSNull { return false }
        if b is NSNull { return true }
        if let na = numericValue(a), let nb = numericValue(b),
           (a is Int || a is Double), (b is Int || b is Double) {
            return na < nb
        }
        return stringify(a).lowercased() < stringify(b).lowercased()
    }

    internal func flattenArray(_ array: [Any]) -> [Any] {
        var result: [Any] = []
        for item in array {
            if let nested = item as? [Any] {
                result.append(contentsOf: flattenArray(nested))
            } else {
                result.append(item)
            }
        }
        return result
    }
    
    internal func reverseValue(_ value: Any) -> Any {
        if let array = value as? [Any] {
            return Array(array.reversed())
        }
        return value
    }
    
    internal func sortValue(_ value: Any) -> Any {
        if let array = value as? [Any] {
            return array.sorted { compareForSort($0, $1) }
        }
        return value
    }
    
    internal func roundNumber(_ value: Any, precision: Int) -> Any {
        let num: Double
        switch value {
        case let d as Double: num = d
        case let i as Int: if precision >= 0 { return i } else { num = Double(i) }
        case let n as NSNumber: num = n.doubleValue
        default:
            guard let n = numericValue(value) else { return 0 }
            num = n
        }
        let result = roundedDouble(num, precision: precision)
        if precision == 0 {
            return Int(result)
        }
        return result
    }

    @inline(__always)
    internal func renderRoundedValueFast(_ value: Any, precision: Int) -> String {
        switch value {
        case let num as Double:
            return stringifyRoundedDouble(roundedDouble(num, precision: precision))
        case let num as Int:
            return precision >= 0
                ? String(num)
                : stringifyRoundedDouble(roundedDouble(Double(num), precision: precision))
        case let number as NSNumber:
            let doubleValue = number.doubleValue
            if precision >= 0, doubleValue.rounded(.towardZero) == doubleValue {
                return String(number.intValue)
            }
            return stringifyRoundedDouble(roundedDouble(doubleValue, precision: precision))
        case let string as String:
            guard let num = Double(string) else {
                return stringify(string)
            }
            return stringifyRoundedDouble(roundedDouble(num, precision: precision))
        case let inline as InlineString:
            guard let num = Double(inline.string) else {
                return stringify(inline)
            }
            return stringifyRoundedDouble(roundedDouble(num, precision: precision))
        case let safeHTML as SafeHTML:
            guard let num = Double(safeHTML.value) else {
                return stringify(safeHTML)
            }
            return stringifyRoundedDouble(roundedDouble(num, precision: precision))
        default:
            let roundedValue = roundNumber(value, precision: precision)
            return stringify(roundedValue)
        }
    }


    @inline(__always)
    internal func stringifyRoundedDouble(_ value: Double) -> String {
        value == floor(value) ? String(Int(value)) : String(value)
    }

    @inline(__always)
    internal func roundedDouble(_ num: Double, precision: Int) -> Double {
        let multiplier: Double
        switch precision {
        case 0:
            return num.rounded()
        case 1:
            multiplier = 10
        case 2:
            multiplier = 100
        case 3:
            multiplier = 1_000
        case 4:
            multiplier = 10_000
        default:
            multiplier = pow(10.0, Double(precision))
        }
        return (num * multiplier).rounded() / multiplier
    }
    
    /// Gets a property from an object using key-value coding or reflection
    internal func getProperty(from object: Any, key: String) -> Any? {
        // This is a simplified implementation
        // In a full implementation, you'd use Mirror or KVC
        if let val = dictValue(object, forKey: key) { return val }
        if isDictLike(object) { return nil }
        return nil
    }
}
