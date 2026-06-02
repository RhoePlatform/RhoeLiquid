//
//  DataFilters.swift
//  LiquidFilters
//
//  Data manipulation filters for RhoeLiquid data sources
//

import Foundation
import LiquidCore

// MARK: - Where Filter

/// Filter array by condition
///
/// Usage:
/// {{ users | where: "active", true }}
/// {{ posts | where: "category", "tutorial" }}
public struct WhereFilter: CustomFilter {
    public let name = "where"
    
    public init() {}
    
    public func apply(
        to value: Any,
        arguments: [Any],
        namedArguments: [String: Any]
    ) async throws -> Any {
        guard arguments.count >= 2,
              let key = arguments[0] as? String else {
            return value
        }
        
        let compareValue = arguments[1]
        
        // Handle DataValue arrays
        if let dataValue = value as? DataValue,
           case .array(let items) = dataValue {
            let filtered = items.filter { item in
                let itemValue = item[key]
                return isEqual(itemValue.liquidValue, compareValue)
            }
            return DataValue.array(filtered).liquidValue
        }
        
        // Handle regular arrays
        if let array = value as? [Any] {
            return array.filter { item in
                if let dict = item as? [String: Any] {
                    return isEqual(dict[key], compareValue)
                }
                return false
            }
        }
        
        return value
    }
    
    private func isEqual(_ a: Any?, _ b: Any?) -> Bool {
        switch (a, b) {
        case (nil, nil): return true
        case (_ as NSNull, _ as NSNull): return true
        case (let a as Bool, let b as Bool): return a == b
        case (let a as Int, let b as Int): return a == b
        case (let a as Double, let b as Double): return a == b
        case (let a as String, let b as String): return a == b
        default: return false
        }
    }
}

// MARK: - Map Filter

/// Map array to property values
///
/// Usage:
/// {{ users | map: "name" }}
/// {{ products | map: "price" }}
public struct MapFilter: CustomFilter {
    public let name = "map"
    
    public init() {}
    
    public func apply(
        to value: Any,
        arguments: [Any],
        namedArguments: [String: Any]
    ) async throws -> Any {
        guard let key = arguments.first as? String else {
            return value
        }
        
        // Handle DataValue arrays
        if let dataValue = value as? DataValue,
           case .array(let items) = dataValue {
            let mapped = items.map { $0[key].liquidValue }
            return mapped
        }
        
        // Handle regular arrays
        if let array = value as? [Any] {
            return array.compactMap { item in
                if let dict = item as? [String: Any] {
                    return dict[key]
                }
                return nil
            }
        }
        
        return value
    }
}

// MARK: - Group By Filter

/// Group array by property value
///
/// Usage:
/// {{ users | group_by: "role" }}
/// {{ posts | group_by: "category" }}
public struct GroupByFilter: CustomFilter {
    public let name = "group_by"
    
    public init() {}
    
    public func apply(
        to value: Any,
        arguments: [Any],
        namedArguments: [String: Any]
    ) async throws -> Any {
        guard let key = arguments.first as? String else {
            return value
        }
        
        var groups: [String: [Any]] = [:]
        
        // Handle DataValue arrays
        if let dataValue = value as? DataValue,
           case .array(let items) = dataValue {
            for item in items {
                let groupKey = item[key].stringValue
                if groups[groupKey] == nil {
                    groups[groupKey] = []
                }
                groups[groupKey]?.append(item.liquidValue)
            }
        }
        
        // Handle regular arrays
        else if let array = value as? [Any] {
            for item in array {
                if let dict = item as? [String: Any],
                   let groupValue = dict[key] {
                    let groupKey = String(describing: groupValue)
                    if groups[groupKey] == nil {
                        groups[groupKey] = []
                    }
                    groups[groupKey]?.append(item)
                }
            }
        }
        
        // Convert to array of group objects
        return groups.map { key, items in
            ["key": key, "items": items]
        }
    }
}

// MARK: - Sort By Filter

/// Sort array by property value
///
/// Usage:
/// {{ products | sort_by: "price" }}
/// {{ posts | sort_by: "date" }}
public struct SortByFilter: CustomFilter {
    public let name = "sort_by"
    
    public init() {}
    
    public func apply(
        to value: Any,
        arguments: [Any],
        namedArguments: [String: Any]
    ) async throws -> Any {
        guard let key = arguments.first as? String else {
            return value
        }
        
        // Handle DataValue arrays
        if let dataValue = value as? DataValue,
           case .array(let items) = dataValue {
            let sorted = items.sorted { a, b in
                compareValues(a[key], b[key])
            }
            return DataValue.array(sorted).liquidValue
        }
        
        // Handle regular arrays
        if let array = value as? [Any] {
            return array.sorted { a, b in
                guard let dictA = a as? [String: Any],
                      let dictB = b as? [String: Any] else {
                    return false
                }
                return compareAny(dictA[key], dictB[key])
            }
        }
        
        return value
    }
    
    private func compareValues(_ a: DataValue, _ b: DataValue) -> Bool {
        switch (a, b) {
        case (.int(let a), .int(let b)): return a < b
        case (.double(let a), .double(let b)): return a < b
        case (.string(let a), .string(let b)): return a < b
        case (.date(let a), .date(let b)): return a < b
        default: return false
        }
    }
    
    private func compareAny(_ a: Any?, _ b: Any?) -> Bool {
        switch (a, b) {
        case (let a as Int, let b as Int): return a < b
        case (let a as Double, let b as Double): return a < b
        case (let a as String, let b as String): return a < b
        case (let a as Date, let b as Date): return a < b
        default: return false
        }
    }
}

// MARK: - Find Filter

/// Find first item matching condition
///
/// Usage:
/// {{ users | find: "email", "admin@example.com" }}
/// {{ posts | find: "slug", "hello-world" }}
public struct FindFilter: CustomFilter {
    public let name = "find"
    
    public init() {}
    
    public func apply(
        to value: Any,
        arguments: [Any],
        namedArguments: [String: Any]
    ) async throws -> Any {
        guard arguments.count >= 2,
              let key = arguments[0] as? String else {
            return NSNull()
        }
        
        let compareValue = arguments[1]
        
        // Handle DataValue arrays
        if let dataValue = value as? DataValue,
           case .array(let items) = dataValue {
            for item in items {
                let itemValue = item[key]
                if isEqual(itemValue.liquidValue, compareValue) {
                    return item.liquidValue
                }
            }
        }
        
        // Handle regular arrays
        if let array = value as? [Any] {
            for item in array {
                if let dict = item as? [String: Any],
                   isEqual(dict[key], compareValue) {
                    return item
                }
            }
        }
        
        return NSNull()
    }
    
    private func isEqual(_ a: Any?, _ b: Any?) -> Bool {
        switch (a, b) {
        case (nil, nil): return true
        case (_ as NSNull, _ as NSNull): return true
        case (let a as Bool, let b as Bool): return a == b
        case (let a as Int, let b as Int): return a == b
        case (let a as Double, let b as Double): return a == b
        case (let a as String, let b as String): return a == b
        default: return false
        }
    }
}

// MARK: - Sum Filter

/// Sum numeric values
///
/// Usage:
/// {{ prices | sum }}
/// {{ items | map: "quantity" | sum }}
public struct SumFilter: CustomFilter {
    public let name = "sum"
    
    public init() {}
    
    public func apply(
        to value: Any,
        arguments: [Any],
        namedArguments: [String: Any]
    ) async throws -> Any {
        var sum: Double = 0
        
        // Handle DataValue arrays
        if let dataValue = value as? DataValue,
           case .array(let items) = dataValue {
            for item in items {
                if let num = item.doubleValue {
                    sum += num
                }
            }
        }
        
        // Handle regular arrays
        else if let array = value as? [Any] {
            for item in array {
                if let num = item as? Double {
                    sum += num
                } else if let num = item as? Int {
                    sum += Double(num)
                }
            }
        }
        
        // Return as int if no decimal part
        if sum == Double(Int(sum)) {
            return Int(sum)
        }
        
        return sum
    }
}

// MARK: - Pluck Filter

/// Extract values at a path
///
/// Usage:
/// {{ users | pluck: "profile.email" }}
/// {{ data | pluck: "meta.tags[0]" }}
public struct PluckFilter: CustomFilter {
    public let name = "pluck"
    
    public init() {}
    
    public func apply(
        to value: Any,
        arguments: [Any],
        namedArguments: [String: Any]
    ) async throws -> Any {
        guard let path = arguments.first as? String else {
            return value
        }
        
        // Handle DataValue
        if let dataValue = value as? DataValue {
            return dataValue.value(at: path).liquidValue
        }
        
        // Handle regular values
        return extractValue(from: value, path: path)
    }
    
    private func extractValue(from value: Any, path: String) -> Any {
        let components = path.split(separator: ".").map(String.init)
        var current: Any = value
        
        for component in components {
            // Check for array index
            if let match = component.firstMatch(of: /^(\w+)\[(\d+)\]$/) {
                let key = String(match.output.1)
                let index = Int(match.output.2) ?? 0
                
                if let dict = current as? [String: Any],
                   let array = dict[key] as? [Any],
                   index < array.count {
                    current = array[index]
                } else {
                    return NSNull()
                }
            } else {
                // Regular property access
                if let dict = current as? [String: Any] {
                    current = dict[component] ?? NSNull()
                } else {
                    return NSNull()
                }
            }
        }
        
        return current
    }
}

// MARK: - Limit Filter

/// Limit array to first N items
///
/// Usage:
/// {{ posts | limit: 5 }}
/// {{ items | limit: 10 }}
public struct LimitFilter: CustomFilter {
    public let name = "limit"
    
    public init() {}
    
    public func apply(
        to value: Any,
        arguments: [Any],
        namedArguments: [String: Any]
    ) async throws -> Any {
        guard let limit = arguments.first as? Int, limit > 0 else {
            return value
        }
        
        // Handle DataValue arrays
        if let dataValue = value as? DataValue,
           case .array(let items) = dataValue {
            let limited = Array(items.prefix(limit))
            return DataValue.array(limited).liquidValue
        }
        
        // Handle regular arrays
        if let array = value as? [Any] {
            return Array(array.prefix(limit))
        }
        
        return value
    }
}

// MARK: - Offset Filter

/// Skip first N items
///
/// Usage:
/// {{ posts | offset: 10 }}
/// {{ items | offset: 5 | limit: 10 }}
public struct OffsetFilter: CustomFilter {
    public let name = "offset"
    
    public init() {}
    
    public func apply(
        to value: Any,
        arguments: [Any],
        namedArguments: [String: Any]
    ) async throws -> Any {
        guard let offset = arguments.first as? Int, offset >= 0 else {
            return value
        }
        
        // Handle DataValue arrays
        if let dataValue = value as? DataValue,
           case .array(let items) = dataValue {
            let offsetItems = Array(items.dropFirst(offset))
            return DataValue.array(offsetItems).liquidValue
        }
        
        // Handle regular arrays
        if let array = value as? [Any] {
            return Array(array.dropFirst(offset))
        }
        
        return value
    }
}