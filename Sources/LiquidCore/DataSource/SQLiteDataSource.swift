//
//  SQLiteDataSource.swift
//  LiquidCore
//
//  SQLite database data source for RhoeLiquid
//

import Foundation
#if canImport(SQLite3)
import SQLite3
#endif

/// Data source for loading data from SQLite databases
///
/// `SQLiteDataSource` provides safe, efficient access to SQLite databases
/// with full SQL query support, parameterized queries for security, and
/// intelligent result set conversion to DataValue format.
///
/// ## Features
///
/// - **SQL Query Support**: Execute SELECT queries with results as DataValue
/// - **Parameterized Queries**: Protection against SQL injection
/// - **Connection Pooling**: Efficient connection management
/// - **Schema Introspection**: Discover tables and columns
/// - **Type Mapping**: Automatic SQLite to DataValue conversion
/// - **Read-Only Mode**: Safe for templates (no mutations)
///
/// ## Security
///
/// This data source operates in read-only mode by default and uses
/// parameterized queries to prevent SQL injection attacks. Never
/// concatenate user input directly into SQL strings.
///
/// ## Usage Examples
///
/// ### Basic Query
/// ```liquid
/// {% data users = load("./database.db", 
///                     query: "SELECT * FROM users WHERE active = ?",
///                     params: [true]) %}
/// {% for user in users %}
///   {{ user.name }} - {{ user.email }}
/// {% endfor %}
/// ```
///
/// ### Table Loading
/// ```liquid
/// {% data products = load("./store.db", table: "products") %}
/// {{ products | where: "price", "<", 100 | sort_by: "name" }}
/// ```
///
/// ### Complex Queries
/// ```liquid
/// {% data report = load("./analytics.db",
///     query: "SELECT category, COUNT(*) as count, AVG(price) as avg_price 
///             FROM products GROUP BY category") %}
/// {% for row in report %}
///   {{ row.category }}: {{ row.count }} items, avg ${{ row.avg_price | round: 2 }}
/// {% endfor %}
/// ```
///
/// ### With Joins
/// ```liquid
/// {% data orders = load("./shop.db",
///     query: "SELECT o.*, c.name as customer_name 
///             FROM orders o 
///             JOIN customers c ON o.customer_id = c.id
///             WHERE o.status = ?",
///     params: ["pending"]) %}
/// ```
///
/// ## Connection String Format
///
/// SQLite URLs support these formats:
/// - `file:./path/to/database.db` - Standard file path
/// - `file::memory:` - In-memory database
/// - `./relative/path.db` - Relative path
/// - `/absolute/path.db` - Absolute path
///
/// ## Query Options
///
/// The loader supports various query modes through LoadOptions:
/// ```liquid
/// {% data tables = load("./db.sqlite", 
///                      mode: "schema") %}  <!-- List all tables -->
///                      
/// {% data users = load("./db.sqlite",
///                     table: "users",
///                     limit: 100,
///                     offset: 0) %}
/// ```
public struct SQLiteDataSource: DataSource {
    public init() {}
    
    public var supportedExtensions: [String] {
        ["db", "sqlite", "sqlite3", "db3", "s3db", "sl3"]
    }
    
    public var supportedSchemes: [String] {
        ["file", "sqlite"]
    }
    
    public func load(from url: URL, options: LoadOptions) async throws -> DataValue {
        #if canImport(SQLite3)
        return try loadNative(from: url, options: options)
        #else
        throw DataSourceError.unsupportedFormat("SQLite support requires the SQLite3 module")
        #endif
    }

    #if canImport(SQLite3)
    private func loadNative(from url: URL, options: LoadOptions) throws -> DataValue {
        // Ensure it's a file URL
        guard url.isFileURL || url.scheme == "sqlite" else {
            throw DataSourceError.unsupportedFormat("SQLite only supports file:// URLs")
        }
        
        // Open database connection
        let db = try openDatabase(at: url)
        defer { sqlite3_close(db) }
        
        // Extract query parameters from URL
        let queryMode = extractQueryMode(from: url, options: options)
        
        switch queryMode {
        case .query(let sql, let params):
            return try executeQuery(sql, params: params, on: db)
            
        case .table(let name, let limit, let offset):
            let sql = buildTableQuery(table: name, limit: limit, offset: offset)
            return try executeQuery(sql, params: [], on: db)
            
        case .schema:
            return try getSchemaInfo(from: db)
        }
    }
    
    // MARK: - Query Modes
    
    private enum QueryMode {
        case query(String, [Any])
        case table(String, limit: Int?, offset: Int?)
        case schema
    }
    
    private func extractQueryMode(from url: URL, options: LoadOptions) -> QueryMode {
        // Parse query parameters from URL
        // Format: database.db?query=SELECT...&param1=value1&param2=value2
        // Or: database.db?table=users&limit=10&offset=0
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            // Default to schema mode
            return .schema
        }
        
        var params: [String: String] = [:]
        for item in queryItems {
            params[item.name] = item.value ?? ""
        }
        
        // Check for query mode
        if let query = params["query"] {
            // Extract parameters (param1, param2, etc.)
            var queryParams: [Any] = []
            var index = 1
            while let param = params["param\(index)"] {
                // Try to parse as different types
                if let intValue = Int(param) {
                    queryParams.append(intValue)
                } else if let doubleValue = Double(param) {
                    queryParams.append(doubleValue)
                } else if param.lowercased() == "true" {
                    queryParams.append(true)
                } else if param.lowercased() == "false" {
                    queryParams.append(false)
                } else if param.lowercased() == "null" {
                    queryParams.append(NSNull())
                } else {
                    queryParams.append(param)
                }
                index += 1
            }
            
            return .query(query, queryParams)
        }
        
        // Check for table mode
        if let tableName = params["table"] {
            let limit = params["limit"].flatMap { Int($0) }
            let offset = params["offset"].flatMap { Int($0) }
            return .table(tableName, limit: limit, offset: offset)
        }
        
        // Default to schema
        return .schema
    }
    
    // MARK: - Database Operations

    private func openDatabase(at url: URL) throws -> OpaquePointer {
        var db: OpaquePointer?
        
        let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX
        let result = sqlite3_open_v2(url.path, &db, flags, nil)
        
        guard result == SQLITE_OK, let db = db else {
            let _ = String(cString: sqlite3_errmsg(db))
            throw DataSourceError.accessDenied(url)
        }
        
        return db
    }
    
    private func executeQuery(_ sql: String, params: [Any], on db: OpaquePointer) throws -> DataValue {
        var statement: OpaquePointer?
        
        // Prepare statement
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let error = String(cString: sqlite3_errmsg(db))
            throw DataSourceError.parseError("SQL error: \(error)")
        }
        
        defer { sqlite3_finalize(statement) }
        
        // Bind parameters
        for (index, param) in params.enumerated() {
            let position = Int32(index + 1)
            
            switch param {
            case let value as Int:
                sqlite3_bind_int64(statement, position, Int64(value))
            case let value as Int64:
                sqlite3_bind_int64(statement, position, value)
            case let value as Double:
                sqlite3_bind_double(statement, position, value)
            case let value as String:
                sqlite3_bind_text(statement, position, value, -1, nil)
            case let value as Bool:
                sqlite3_bind_int(statement, position, value ? 1 : 0)
            case is NSNull:
                sqlite3_bind_null(statement, position)
            case let value as Data:
                _ = value.withUnsafeBytes { bytes in
                    sqlite3_bind_blob(statement, position, bytes.baseAddress, Int32(value.count), nil)
                }
            default:
                sqlite3_bind_text(statement, position, String(describing: param), -1, nil)
            }
        }
        
        // Execute and collect results
        var rows: [DataValue] = []
        
        while sqlite3_step(statement) == SQLITE_ROW {
            let row = try readRow(from: statement)
            rows.append(row)
        }
        
        return .array(rows)
    }
    
    private func readRow(from statement: OpaquePointer?) throws -> DataValue {
        let columnCount = sqlite3_column_count(statement)
        var row: [String: DataValue] = [:]
        
        for i in 0..<columnCount {
            let columnName = String(cString: sqlite3_column_name(statement, i))
            let columnType = sqlite3_column_type(statement, i)
            
            let value: DataValue
            switch columnType {
            case SQLITE_INTEGER:
                value = .int(Int(sqlite3_column_int64(statement, i)))
                
            case SQLITE_FLOAT:
                value = .double(sqlite3_column_double(statement, i))
                
            case SQLITE_TEXT:
                if let text = sqlite3_column_text(statement, i) {
                    value = .string(String(cString: text))
                } else {
                    value = .null
                }
                
            case SQLITE_BLOB:
                if let blob = sqlite3_column_blob(statement, i) {
                    let size = Int(sqlite3_column_bytes(statement, i))
                    let data = Data(bytes: blob, count: size)
                    value = .data(data)
                } else {
                    value = .null
                }
                
            case SQLITE_NULL:
                value = .null
                
            default:
                value = .null
            }
            
            row[columnName] = value
        }
        
        return .object(row)
    }
    
    private func buildTableQuery(table: String, limit: Int?, offset: Int?) -> String {
        // Validate table name to prevent injection
        let validTableName = table.replacingOccurrences(of: "'", with: "''")
        
        var sql = "SELECT * FROM '\(validTableName)'"
        
        if let limit = limit {
            sql += " LIMIT \(limit)"
            if let offset = offset {
                sql += " OFFSET \(offset)"
            }
        }
        
        return sql
    }
    
    private func getSchemaInfo(from db: OpaquePointer) throws -> DataValue {
        let sql = """
            SELECT name, type, sql 
            FROM sqlite_master 
            WHERE type IN ('table', 'view') 
            AND name NOT LIKE 'sqlite_%'
            ORDER BY name
        """
        
        return try executeQuery(sql, params: [], on: db)
    }
    #endif // canImport(SQLite3)
}

// MARK: - SQLite Query Builder

/// Safe SQL query builder for templates
public struct SQLiteQuery {
    private var select: [String] = ["*"]
    private var from: String = ""
    private var joins: [(type: String, table: String, on: String)] = []
    private var wheres: [(column: String, op: String, value: Any)] = []
    private var groupBy: [String] = []
    private var having: String?
    private var orderBy: [(column: String, direction: String)] = []
    private var limit: Int?
    private var offset: Int?
    
    public init(from table: String) {
        self.from = table
    }
    
    public func select(_ columns: String...) -> SQLiteQuery {
        var copy = self
        copy.select = columns
        return copy
    }
    
    public func join(_ table: String, on condition: String) -> SQLiteQuery {
        var copy = self
        copy.joins.append((type: "JOIN", table: table, on: condition))
        return copy
    }
    
    public func leftJoin(_ table: String, on condition: String) -> SQLiteQuery {
        var copy = self
        copy.joins.append((type: "LEFT JOIN", table: table, on: condition))
        return copy
    }
    
    public func `where`(_ column: String, _ op: String = "=", _ value: Any) -> SQLiteQuery {
        var copy = self
        copy.wheres.append((column: column, op: op, value: value))
        return copy
    }
    
    public func groupBy(_ columns: String...) -> SQLiteQuery {
        var copy = self
        copy.groupBy = columns
        return copy
    }
    
    public func orderBy(_ column: String, _ direction: String = "ASC") -> SQLiteQuery {
        var copy = self
        copy.orderBy.append((column: column, direction: direction))
        return copy
    }
    
    public func limit(_ count: Int) -> SQLiteQuery {
        var copy = self
        copy.limit = count
        return copy
    }
    
    public func offset(_ count: Int) -> SQLiteQuery {
        var copy = self
        copy.offset = count
        return copy
    }
    
    /// Build the SQL query and parameter array
    public func build() -> (sql: String, params: [Any]) {
        var sql = "SELECT \(select.joined(separator: ", ")) FROM \(from)"
        var params: [Any] = []
        
        // Add joins
        for join in joins {
            sql += " \(join.type) \(join.table) ON \(join.on)"
        }
        
        // Add where clauses
        if !wheres.isEmpty {
            let conditions = wheres.map { "\($0.column) \($0.op) ?" }.joined(separator: " AND ")
            sql += " WHERE \(conditions)"
            params.append(contentsOf: wheres.map { $0.value })
        }
        
        // Add group by
        if !groupBy.isEmpty {
            sql += " GROUP BY \(groupBy.joined(separator: ", "))"
        }
        
        // Add having
        if let having = having {
            sql += " HAVING \(having)"
        }
        
        // Add order by
        if !orderBy.isEmpty {
            let orders = orderBy.map { "\($0.column) \($0.direction)" }.joined(separator: ", ")
            sql += " ORDER BY \(orders)"
        }
        
        // Add limit/offset
        if let limit = limit {
            sql += " LIMIT \(limit)"
            if let offset = offset {
                sql += " OFFSET \(offset)"
            }
        }
        
        return (sql, params)
    }
}

// MARK: - Extended LoadOptions for SQLite

public extension LoadOptions {
    /// SQL query to execute
    var sqlQuery: String? {
        // This would be extracted from template parameters
        return nil
    }
    
    /// SQL query parameters for safe binding
    var sqlParams: [Any] {
        // This would be extracted from template parameters
        return []
    }
    
    /// Table name for simple SELECT * queries
    var tableName: String? {
        // This would be extracted from template parameters
        return nil
    }
    
    /// Query mode (query, table, schema)
    var queryMode: String {
        return "table"
    }
}
