import Foundation
import Testing
@testable import LiquidFilters

@Suite("SQLite Filter Tests")
struct SQLiteFiltersTests {
    @Test("sql_join nests matching right rows under the inferred right alias")
    func sqlJoinNestsMatchesUnderRightAlias() async throws {
        let users: [[String: Any]] = [
            ["id": 1, "name": "Ada"],
            ["id": 2, "name": "Linus"],
        ]
        let orders: [[String: Any]] = [
            ["id": 100, "user_id": 1, "total": 42.5],
            ["id": 101, "user_id": 1, "total": 13.0],
            ["id": 102, "user_id": 2, "total": 99.0],
        ]

        let joined = try await SQLJoinFilter().apply(
            to: users,
            arguments: [orders, "users.id = orders.user_id"],
            namedArguments: [:]
        )

        guard let rows = joined as? [[String: Any]] else {
            Issue.record("Expected sql_join to return an array of joined row dictionaries")
            return
        }

        #expect(rows.count == 3)
        #expect(rows[0]["name"] as? String == "Ada")

        let firstOrder = rows[0]["orders"] as? [String: Any]
        #expect(firstOrder?["user_id"] as? Int == 1)
        #expect(firstOrder?["total"] as? Double == 42.5)
    }

    @Test("sql_join supports left joins and explicit aliases")
    func sqlJoinSupportsLeftJoinsAndAliases() async throws {
        let users: [[String: Any]] = [
            ["id": 1, "name": "Ada"],
            ["id": 2, "name": "Linus"],
            ["id": 3, "name": "Grace"],
        ]
        let orders: [[String: Any]] = [
            ["id": 100, "user_id": 1, "total": 42.5]
        ]

        let joined = try await SQLJoinFilter().apply(
            to: users,
            arguments: [orders, "users.id = orders.user_id"],
            namedArguments: ["type": "left", "as": "order"]
        )

        guard let rows = joined as? [[String: Any]] else {
            Issue.record("Expected sql_join to return an array of joined row dictionaries")
            return
        }

        #expect(rows.count == 3)
        #expect(rows[0]["order"] as? [String: Any] != nil)
        #expect(rows[2]["order"] is NSNull)
    }
}
