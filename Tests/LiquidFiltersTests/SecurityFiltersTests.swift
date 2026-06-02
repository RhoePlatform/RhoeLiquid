import Foundation
import Testing
@testable import RhoeLiquid
@testable import LiquidCore

@Suite("Security Filter Tests")
struct SecurityFiltersTests {
    @Test("Escape filter escapes HTML-sensitive characters")
    func escapeFilter() async throws {
        let engine = LiquidEngine()
        let template = "{{ text | escape }}"

        let htmlContext = ["text": "<script>alert('xss')</script>"]
        let htmlResult = try await engine.render(template: template, context: htmlContext)
        #expect(htmlResult == "&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;")

        let quotesContext = ["text": "She said \"Hello\" and 'Goodbye'"]
        let quotesResult = try await engine.render(template: template, context: quotesContext)
        #expect(quotesResult == "She said &quot;Hello&quot; and &#39;Goodbye&#39;")

        let ampContext = ["text": "Tom & Jerry"]
        let ampResult = try await engine.render(template: template, context: ampContext)
        #expect(ampResult == "Tom &amp; Jerry")
    }

    @Test("Escape filter still works in secure mode")
    func escapeFilterWithSafeString() async throws {
        let secureEngine = LiquidEngine(configuration: .secure)
        let result = try await secureEngine.render(
            template: "{{ text | escape }}",
            context: ["text": "<b>Bold</b>"]
        )

        #expect(result == "&lt;b&gt;Bold&lt;/b&gt;")
    }

    @Test("Escape once filter avoids double-escaping entities")
    func escapeOnceFilter() async throws {
        let engine = LiquidEngine()
        let result = try await engine.render(
            template: "{{ text | escape_once }}",
            context: ["text": "Normal <b>bold</b> text"]
        )

        #expect(result.contains("&lt;b&gt;"))
        #expect(result.contains("&lt;/b&gt;"))
    }

    @Test("Raw filter preserves HTML content when explicitly requested")
    func rawFilter() async throws {
        let engine = LiquidEngine(configuration: .secure)
        let result = try await engine.render(
            template: "{{ text | raw }}",
            context: ["text": "<b>Bold</b>"]
        )

        #expect(result == "<b>Bold</b>")
    }

    @Test("JSON filter handles simple scalar types")
    func jsonFilterWithSimpleTypes() async throws {
        let engine = LiquidEngine()

        var template = "{{ text | json }}"
        var context: [String: Any] = ["text": "Hello \"World\""]
        var result = try await engine.render(template: template, context: context)
        #expect(result == "\"Hello \\\"World\\\"\"")

        template = "{{ number | json }}"
        context = ["number": 42.5]
        result = try await engine.render(template: template, context: context)
        #expect(result == "42.5")

        template = "{{ flag | json }}"
        context = ["flag": true]
        result = try await engine.render(template: template, context: context)
        #expect(result == "true")

        template = "{{ nothing | json }}"
        context = ["nothing": NSNull()]
        result = try await engine.render(template: template, context: context)
        #expect(result == "null")
    }

    @Test("JSON filter emits arrays as valid JSON")
    func jsonFilterWithArray() async throws {
        let engine = LiquidEngine()
        let result = try await engine.render(
            template: "{{ items | json }}",
            context: ["items": ["apple", "banana", 123, true]]
        )

        #expect(result.contains("["))
        #expect(result.contains("]"))
        #expect(result.contains("\"apple\""))
        #expect(result.contains("\"banana\""))
        #expect(result.contains("123"))
        #expect(result.contains("true"))
    }

    @Test("JSON filter emits dictionaries as valid JSON")
    func jsonFilterWithDictionary() async throws {
        let engine = LiquidEngine()
        let result = try await engine.render(
            template: "{{ user | json }}",
            context: [
                "user": [
                    "name": "John Doe",
                    "age": 30,
                    "active": true,
                    "tags": ["developer", "swift"]
                ]
            ]
        )

        guard let data = result.data(using: .utf8) else {
            #expect(Bool(false), "Result should be valid UTF-8")
            return
        }

        do {
            let parsed = try JSONSerialization.jsonObject(with: data)
            guard let dict = parsed as? [String: Any] else {
                #expect(Bool(false), "JSON should parse to a dictionary")
                return
            }

            #expect(dict["name"] as? String == "John Doe")
            #expect(dict["age"] as? Int == 30)
            #expect(dict["active"] as? Bool == true)
            #expect(dict["tags"] as? [String] == ["developer", "swift"])
        } catch {
            #expect(Bool(false), "JSON should be valid: \(error)")
        }
    }

    @Test("JSON filter serializes dates as quoted strings")
    func jsonFilterWithDate() async throws {
        let engine = LiquidEngine()
        let result = try await engine.render(
            template: "{{ date | json }}",
            context: ["date": Date(timeIntervalSince1970: 1609459200)]
        )

        #expect(result.contains("2021-01-01"))
        #expect(result.contains("\""))
    }

    @Test("JSON filter preserves JSON escaping for HTML-like strings")
    func jsonFilterEscapesHTML() async throws {
        let engine = LiquidEngine()
        let result = try await engine.render(
            template: "{{ html | json }}",
            context: ["html": "<script>alert('xss')</script>"]
        )

        #expect(result.hasPrefix("\""))
        #expect(result.hasSuffix("\""))
        #expect(result.contains("<\\/script>"))
        #expect(result.contains("alert('xss')"))
    }

    @Test("JSON filter handles nested objects")
    func jsonFilterWithComplexObject() async throws {
        let engine = LiquidEngine()
        let result = try await engine.render(
            template: "{{ data | json }}",
            context: [
                "data": [
                    "users": [
                        ["name": "Alice", "role": "admin"],
                        ["name": "Bob", "role": "user"]
                    ],
                    "settings": [
                        "theme": "dark",
                        "notifications": true
                    ],
                    "count": 42,
                    "lastUpdate": NSNull()
                ]
            ]
        )

        guard let data = result.data(using: .utf8) else {
            #expect(Bool(false), "Result should be valid UTF-8")
            return
        }

        do {
            let parsed = try JSONSerialization.jsonObject(with: data)
            #expect(parsed is [String: Any])
        } catch {
            #expect(Bool(false), "Complex object should produce valid JSON: \(error)")
        }
    }

    @Test("Escape and JSON filters compose predictably")
    func combiningEscapeAndJsonFilters() async throws {
        let engine = LiquidEngine()
        let result = try await engine.render(
            template: "{{ text | escape | json }}",
            context: ["text": "<b>Bold</b>"]
        )

        #expect(result == "\"&lt;b&gt;Bold&lt;\\/b&gt;\"")
    }

    @Test("JSON filter remains safe in secure mode")
    func jsonFilterInSecureMode() async throws {
        let secureEngine = LiquidEngine(configuration: .secure)
        let result = try await secureEngine.render(
            template: "Script tag: {{ data | json }}",
            context: ["data": ["html": "<script>alert('xss')</script>"]]
        )

        #expect(result.contains("{"))
        #expect(result.contains("}"))
        #expect(!result.contains("&lt;"))
    }
}
