//
//  ArrayFilters.swift
//  LiquidFilters
//
//  Built-in array manipulation filters
//

import Foundation
import LiquidCore

// MARK: - Array Filters

/// Removes nil values from an array
public struct CompactFilter: CustomFilter {
    public let name = "compact"
    
    public init() {}
    
    public func apply(to value: Any, arguments: [Any], namedArguments: [String: Any]) async throws -> Any {
        guard let array = value as? [Any] else { return value }
        
        return array.compactMap { item -> Any? in
            if item is NSNull { return nil }
            if let str = item as? String, str.isEmpty { return nil }
            return item
        }
    }
}

/// Returns unique values from an array
public struct UniqFilter: CustomFilter {
    public let name = "uniq"
    
    public init() {}
    
    public func apply(to value: Any, arguments: [Any], namedArguments: [String: Any]) async throws -> Any {
        guard let array = value as? [Any] else { return value }
        
        var seen = Set<String>()
        var unique: [Any] = []
        
        for item in array {
            let key = String(describing: item)
            if !seen.contains(key) {
                seen.insert(key)
                unique.append(item)
            }
        }
        
        return unique
    }
}

// Note: Map, Where, SortBy, GroupBy, and Find filters are already defined in DataFilters.swift

/// Concatenates two arrays
public struct ConcatFilter: CustomFilter {
    public let name = "concat"
    
    public init() {}
    
    public func apply(to value: Any, arguments: [Any], namedArguments: [String: Any]) async throws -> Any {
        guard let array1 = value as? [Any],
              let array2 = arguments.first as? [Any] else { return value }
        
        return array1 + array2
    }
}

/// Returns the index of an element in an array
public struct IndexFilter: CustomFilter {
    public let name = "index"
    
    public init() {}
    
    public func apply(to value: Any, arguments: [Any], namedArguments: [String: Any]) async throws -> Any {
        guard let array = value as? [Any],
              let searchValue = arguments.first else { return NSNull() }
        
        for (index, item) in array.enumerated() {
            if areEqual(item, searchValue) {
                return index
            }
        }
        
        return NSNull()
    }
    
    private func areEqual(_ a: Any, _ b: Any) -> Bool {
        switch (a, b) {
        case (let a as String, let b as String): return a == b
        case (let a as Int, let b as Int): return a == b
        case (let a as Double, let b as Double): return a == b
        case (let a as Bool, let b as Bool): return a == b
        default: return String(describing: a) == String(describing: b)
        }
    }
}