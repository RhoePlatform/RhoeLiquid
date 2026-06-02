import Testing
@testable import RhoeLiquid

@Suite("Empty Clause Integration Tests")
struct EmptyClauseIntegrationTest {
    @Test("For loops render their empty clause when collections are empty")
    func forLoopWithEmptyClause() async throws {
        let engine = LiquidEngine()
        let template = """
        <h1>Items</h1>
        <ul>
        {% for item in items %}
            <li>{{ item }}</li>
        {% empty %}
            <li>No items to display</li>
        {% endfor %}
        </ul>
        """
        
        let emptyContext = ["items": []]
        let emptyResult = try await engine.render(template: template, context: emptyContext)
        #expect(emptyResult.contains("No items to display"))
        #expect(!emptyResult.contains("<li>item"))

        let context = ["items": ["Apple", "Banana", "Orange"]]
        let result = try await engine.render(template: template, context: context)
        #expect(result.contains("Apple"))
        #expect(result.contains("Banana"))
        #expect(result.contains("Orange"))
        #expect(!result.contains("No items to display"))
    }

    @Test("For loops without empty clauses render nothing for empty collections")
    func forLoopWithoutEmptyClause() async throws {
        let engine = LiquidEngine()
        let template = """
        <h1>Items</h1>
        <ul>
        {% for item in items %}
            <li>{{ item }}</li>
        {% endfor %}
        </ul>
        """

        let emptyContext = ["items": []]
        let emptyResult = try await engine.render(template: template, context: emptyContext)
        #expect(!emptyResult.contains("No items"))
        #expect(!emptyResult.contains("<li>"))

        let context = ["items": ["Apple", "Banana"]]
        let result = try await engine.render(template: template, context: context)
        #expect(result.contains("Apple"))
        #expect(result.contains("Banana"))
    }

    @Test("Strings iterate once instead of triggering the empty clause")
    func emptyClauseWithNonIterableValue() async throws {
        let engine = LiquidEngine()
        let template = """
        {% for item in notAnArray %}
            <p>{{ item }}</p>
        {% empty %}
            <p>Nothing to iterate over</p>
        {% endfor %}
        """
        
        let context = ["notAnArray": "string"]
        let result = try await engine.render(template: template, context: context)

        #expect(result.contains("<p>string</p>"))
        #expect(!result.contains("Nothing to iterate over"))
    }

    @Test("Missing values trigger the empty clause")
    func emptyClauseWithNullValue() async throws {
        let engine = LiquidEngine()
        let template = """
        {% for item in nullValue %}
            <p>{{ item }}</p>
        {% empty %}
            <p>Value is null or empty</p>
        {% endfor %}
        """

        let context: [String: Any] = [:]
        let result = try await engine.render(template: template, context: context)

        #expect(result.contains("Value is null or empty"))
        #expect(!result.contains("<p>item"))
    }
}
