//
//  SQLiteFilters.swift
//  LiquidFilters
//
//  SQLite query filters for RhoeLiquid
//

import Foundation
import LiquidCore

// MARK: - SQL Query Filter

/// Build and execute SQL queries safely
///
/// Usage:
/// {{ "users" | sql_query: "active = ?", true }}
/// {{ "products" | sql_query: "price < ?", 100, limit: 10 }}
public struct SQLQueryFilter: CustomFilter {
    public let name = "sql_query"
    
    public init() {}
    
    public func apply(
        to value: Any,
        arguments: [Any],
        namedArguments: [String: Any]
    ) async throws -> Any {
        // This filter would build a query configuration
        // that gets passed to the SQLite loader
        
        guard let tableName = value as? String else {
            return NSNull()
        }
        
        var queryConfig: [String: Any] = [
            "table": tableName,
            "mode": "query"
        ]
        
        // Build WHERE clause from arguments
        if !arguments.isEmpty {
            queryConfig["where"] = arguments
        }
        
        // Add named arguments
        if let limit = namedArguments["limit"] as? Int {
            queryConfig["limit"] = limit
        }
        
        if let offset = namedArguments["offset"] as? Int {
            queryConfig["offset"] = offset
        }
        
        if let orderBy = namedArguments["order_by"] as? String {
            queryConfig["order_by"] = orderBy
        }
        
        return queryConfig
    }
}

// MARK: - SQL Select Filter

/// Select specific columns from query results
///
/// Usage:
/// {{ db_results | sql_select: "id", "name", "email" }}
public struct SQLSelectFilter: CustomFilter {
    public let name = "sql_select"
    
    public init() {}
    
    public func apply(
        to value: Any,
        arguments: [Any],
        namedArguments: [String: Any]
    ) async throws -> Any {
        guard let rows = value as? [Any] else {
            return value
        }
        
        let columns = arguments.compactMap { $0 as? String }
        guard !columns.isEmpty else {
            return value
        }
        
        var result: [[String: Any]] = []
        
        for row in rows {
            if let dict = row as? [String: Any] {
                var selected: [String: Any] = [:]
                for column in columns {
                    if let value = dict[column] {
                        selected[column] = value
                    }
                }
                result.append(selected)
            }
        }
        
        return result
    }
}

// MARK: - SQL Join Filter

/// Join data from multiple tables
///
/// Usage:
/// {{ users | sql_join: orders, "users.id = orders.user_id" }}
///
/// The joined right-side row is exposed under the right table name (or an explicit
/// `as:` alias) to avoid flattening collisions into the left row shape.
public struct SQLJoinFilter: CustomFilter {
    public let name = "sql_join"
    
    public init() {}
    
    public func apply(
        to value: Any,
        arguments: [Any],
        namedArguments: [String: Any]
    ) async throws -> Any {
        guard let leftRows = sqlRows(from: value),
              let rightDataset = arguments.first,
              let rightRows = sqlRows(from: rightDataset) else {
            return value
        }

        let rawCondition = (arguments.count >= 2 ? arguments[1] as? String : nil)
            ?? (namedArguments["on"] as? String)
        guard let rawCondition,
              let condition = SQLJoinCondition(rawCondition) else {
            return value
        }

        let joinType = ((namedArguments["type"] as? String) ?? "inner").lowercased()
        let requestedAlias = ((namedArguments["as"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines))
            .flatMap { $0.isEmpty ? nil : $0 }
            ?? condition.rightAlias
            ?? "joined"
        let alias = resolvedJoinAlias(requestedAlias, across: leftRows)

        var results: [DataValue] = []
        results.reserveCapacity(max(leftRows.count, 1))

        for leftRow in leftRows {
            guard case .object(let leftObject) = leftRow else {
                continue
            }

            let leftValue = leftRow.value(at: condition.leftPath)
            var matched = false

            for rightRow in rightRows {
                let rightValue = rightRow.value(at: condition.rightPath)
                if sqlValuesEqual(leftValue, rightValue) {
                    matched = true
                    results.append(mergedJoinRow(left: leftObject, right: rightRow, alias: alias))
                }
            }

            if !matched, joinType == "left" {
                results.append(mergedJoinRow(left: leftObject, right: .null, alias: alias))
            }
        }

        return DataValue.array(results).liquidValue
    }
}

// MARK: - SQL Aggregate Filters

/// Count rows in result set
///
/// Usage:
/// {{ users | sql_count }}
/// {{ orders | sql_count: "status", "completed" }}
public struct SQLCountFilter: CustomFilter {
    public let name = "sql_count"
    
    public init() {}
    
    public func apply(
        to value: Any,
        arguments: [Any],
        namedArguments: [String: Any]
    ) async throws -> Any {
        guard let rows = value as? [Any] else {
            return 0
        }
        
        // Simple count
        if arguments.isEmpty {
            return rows.count
        }
        
        // Count with condition
        if arguments.count >= 2,
           let field = arguments[0] as? String {
            let matchValue = arguments[1]
            
            return rows.filter { row in
                if let dict = row as? [String: Any],
                   let value = dict[field] {
                    return isEqual(value, matchValue)
                }
                return false
            }.count
        }
        
        return rows.count
    }
    
    private func isEqual(_ a: Any, _ b: Any) -> Bool {
        switch (a, b) {
        case (let a as Int, let b as Int): return a == b
        case (let a as Double, let b as Double): return a == b
        case (let a as String, let b as String): return a == b
        case (let a as Bool, let b as Bool): return a == b
        default: return false
        }
    }
}

/// Calculate sum of a column
///
/// Usage:
/// {{ orders | sql_sum: "total" }}
public struct SQLSumFilter: CustomFilter {
    public let name = "sql_sum"
    
    public init() {}
    
    public func apply(
        to value: Any,
        arguments: [Any],
        namedArguments: [String: Any]
    ) async throws -> Any {
        guard let rows = value as? [Any],
              let column = arguments.first as? String else {
            return 0
        }
        
        var sum: Double = 0
        
        for row in rows {
            if let dict = row as? [String: Any],
               let value = dict[column] {
                if let num = value as? Double {
                    sum += num
                } else if let num = value as? Int {
                    sum += Double(num)
                }
            }
        }
        
        return sum
    }
}

/// Calculate average of a column
///
/// Usage:
/// {{ products | sql_avg: "price" }}
public struct SQLAverageFilter: CustomFilter {
    public let name = "sql_avg"
    
    public init() {}
    
    public func apply(
        to value: Any,
        arguments: [Any],
        namedArguments: [String: Any]
    ) async throws -> Any {
        guard let rows = value as? [Any],
              let column = arguments.first as? String,
              !rows.isEmpty else {
            return 0
        }
        
        var sum: Double = 0
        var count: Int = 0
        
        for row in rows {
            if let dict = row as? [String: Any],
               let value = dict[column] {
                if let num = value as? Double {
                    sum += num
                    count += 1
                } else if let num = value as? Int {
                    sum += Double(num)
                    count += 1
                }
            }
        }
        
        return count > 0 ? sum / Double(count) : 0
    }
}

/// Get minimum value from a column
///
/// Usage:
/// {{ products | sql_min: "price" }}
public struct SQLMinFilter: CustomFilter {
    public let name = "sql_min"
    
    public init() {}
    
    public func apply(
        to value: Any,
        arguments: [Any],
        namedArguments: [String: Any]
    ) async throws -> Any {
        guard let rows = value as? [Any],
              let column = arguments.first as? String,
              !rows.isEmpty else {
            return NSNull()
        }
        
        var minValue: Double?
        
        for row in rows {
            if let dict = row as? [String: Any],
               let value = dict[column] {
                let num: Double?
                if let d = value as? Double {
                    num = d
                } else if let i = value as? Int {
                    num = Double(i)
                } else {
                    num = nil
                }
                
                if let n = num {
                    minValue = minValue.map { min($0, n) } ?? n
                }
            }
        }
        
        return minValue ?? NSNull()
    }
}

/// Get maximum value from a column
///
/// Usage:
/// {{ products | sql_max: "price" }}
public struct SQLMaxFilter: CustomFilter {
    public let name = "sql_max"
    
    public init() {}
    
    public func apply(
        to value: Any,
        arguments: [Any],
        namedArguments: [String: Any]
    ) async throws -> Any {
        guard let rows = value as? [Any],
              let column = arguments.first as? String,
              !rows.isEmpty else {
            return NSNull()
        }
        
        var maxValue: Double?
        
        for row in rows {
            if let dict = row as? [String: Any],
               let value = dict[column] {
                let num: Double?
                if let d = value as? Double {
                    num = d
                } else if let i = value as? Int {
                    num = Double(i)
                } else {
                    num = nil
                }
                
                if let n = num {
                    maxValue = maxValue.map { max($0, n) } ?? n
                }
            }
        }
        
        return maxValue ?? NSNull()
    }
}

// MARK: - SQL Distinct Filter

/// Get distinct values from a column
///
/// Usage:
/// {{ users | sql_distinct: "city" }}
public struct SQLDistinctFilter: CustomFilter {
    public let name = "sql_distinct"
    
    public init() {}
    
    public func apply(
        to value: Any,
        arguments: [Any],
        namedArguments: [String: Any]
    ) async throws -> Any {
        guard let rows = value as? [Any] else {
            return []
        }
        
        // Get all distinct rows if no column specified
        if arguments.isEmpty {
            // This would need a proper implementation for row comparison
            return rows
        }
        
        // Get distinct values for a specific column
        guard let column = arguments.first as? String else {
            return rows
        }
        
        var distinctValues = Set<String>()
        var result: [Any] = []
        
        for row in rows {
            if let dict = row as? [String: Any],
               let value = dict[column] {
                let key = String(describing: value)
                if !distinctValues.contains(key) {
                    distinctValues.insert(key)
                    result.append(value)
                }
            }
        }
        
        return result
    }
}

// MARK: - SQL Schema Filter

/// Get table schema information
///
/// Usage:
/// {{ db | sql_schema: "users" }}
public struct SQLSchemaFilter: CustomFilter {
    public let name = "sql_schema"
    
    public init() {}
    
    public func apply(
        to value: Any,
        arguments: [Any],
        namedArguments: [String: Any]
    ) async throws -> Any {
        // This would return schema information
        // Placeholder for now
        return [
            "columns": [
                ["name": "id", "type": "INTEGER", "nullable": false, "primary_key": true],
                ["name": "name", "type": "TEXT", "nullable": false, "primary_key": false],
                ["name": "email", "type": "TEXT", "nullable": false, "primary_key": false]
            ]
        ]
    }
}

// MARK: - SQL Filter Helpers

private struct SQLJoinCondition {
    let leftPath: [String]
    let rightPath: [String]
    let rightAlias: String?

    init?(_ raw: String) {
        let parts = raw.split(separator: "=", maxSplits: 1).map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard parts.count == 2,
              let leftSide = SQLJoinSide(parts[0]),
              let rightSide = SQLJoinSide(parts[1]),
              !leftSide.path.isEmpty,
              !rightSide.path.isEmpty else {
            return nil
        }

        self.leftPath = leftSide.path
        self.rightPath = rightSide.path
        self.rightAlias = rightSide.alias
    }
}

private struct SQLJoinSide {
    let alias: String?
    let path: [String]

    init?(_ raw: String) {
        let components = raw.split(separator: ".").map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }.filter { !$0.isEmpty }

        guard !components.isEmpty else {
            return nil
        }

        if components.count >= 2 {
            self.alias = components.first
            self.path = Array(components.dropFirst())
        } else {
            self.alias = nil
            self.path = components
        }
    }
}

private func sqlRows(from value: Any) -> [DataValue]? {
    if let dataValue = value as? DataValue,
       case .array(let rows) = dataValue {
        return rows
    }

    if let rows = value as? [Any] {
        return rows.map(DataValue.init(from:))
    }

    return nil
}

private func resolvedJoinAlias(_ requested: String, across leftRows: [DataValue]) -> String {
    let trimmed = requested.trimmingCharacters(in: .whitespacesAndNewlines)
    let base = trimmed.isEmpty ? "joined" : trimmed

    let collides = leftRows.contains { row in
        guard case .object(let object) = row else {
            return false
        }
        return object[base] != nil
    }

    return collides ? "\(base)_row" : base
}

private func mergedJoinRow(left: [String: DataValue], right: DataValue, alias: String) -> DataValue {
    var result = left
    result[alias] = right
    return .object(result)
}

private func sqlValuesEqual(_ lhs: DataValue, _ rhs: DataValue) -> Bool {
    if lhs == .null || rhs == .null {
        return false
    }

    if let leftNumeric = lhs.doubleValue,
       let rightNumeric = rhs.doubleValue {
        return leftNumeric == rightNumeric
    }

    switch (lhs, rhs) {
    case (.bool(let left), .bool(let right)):
        return left == right

    case (.string(let left), .string(let right)):
        return left == right

    default:
        return lhs.stringValue == rhs.stringValue
    }
}
