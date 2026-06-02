import Testing
@testable import RhoeLiquid
@testable import LiquidUtilities

@Suite("Escape Once Filter Tests")
struct EscapeOnceFilterTests {
    @Test("escapeOnce handles basic dangerous characters")
    func escapeOnceBasicCharacters() {
        let input = "<script>alert('hello');</script>"
        let result = HTMLEscape.escapeOnce(input)
        let expected = "&lt;script&gt;alert(&#39;hello&#39;);&lt;/script&gt;"
        #expect(result == expected)
    }

    @Test("escapeOnce preserves existing entities")
    func escapeOnceAlreadyEscapedEntities() {
        let input = "Already &lt;escaped&gt; &amp; content"
        let result = HTMLEscape.escapeOnce(input)
        let expected = "Already &lt;escaped&gt; &amp; content"
        #expect(result == expected)
    }

    @Test("escapeOnce handles mixed escaped and raw HTML")
    func escapeOnceMixedContent() {
        let input = "&lt;b&gt;Already escaped&lt;/b&gt; and <i>not escaped</i>"
        let result = HTMLEscape.escapeOnce(input)
        let expected = "&lt;b&gt;Already escaped&lt;/b&gt; and &lt;i&gt;not escaped&lt;/i&gt;"
        #expect(result == expected)
    }

    @Test("escapeOnce preserves numeric entities")
    func escapeOnceNumericEntities() {
        let input = "Copyright &#169; 2023 & <script>alert()</script>"
        let result = HTMLEscape.escapeOnce(input)
        let expected = "Copyright &#169; 2023 &amp; &lt;script&gt;alert()&lt;/script&gt;"
        #expect(result == expected)
    }

    @Test("escapeOnce preserves hex entities")
    func escapeOnceHexEntities() {
        let input = "Unicode &#x00A9; symbol & <b>bold</b>"
        let result = HTMLEscape.escapeOnce(input)
        let expected = "Unicode &#x00A9; symbol &amp; &lt;b&gt;bold&lt;/b&gt;"
        #expect(result == expected)
    }

    @Test("escapeOnce escapes bare ampersands")
    func escapeOnceBareAmpersands() {
        let input = "Tom & Jerry & Mickey Mouse"
        let result = HTMLEscape.escapeOnce(input)
        let expected = "Tom &amp; Jerry &amp; Mickey Mouse"
        #expect(result == expected)
    }

    @Test("escapeOnce escapes partial entities")
    func escapeOncePartialEntities() {
        let input = "This is &notanentity and &lt;valid&gt;"
        let result = HTMLEscape.escapeOnce(input)
        let expected = "This is &amp;notanentity and &lt;valid&gt;"
        #expect(result == expected)
    }

    @Test("escapeOnce handles empty strings")
    func escapeOnceEmptyString() {
        let result = HTMLEscape.escapeOnce("")
        #expect(result.isEmpty)
    }

    @Test("escapeOnce preserves supported named entities")
    func escapeOnceAllValidEntities() {
        let input = "&amp; &lt; &gt; &quot; &apos; &nbsp; &copy;"
        let result = HTMLEscape.escapeOnce(input)
        let expected = "&amp; &lt; &gt; &quot; &apos; &nbsp; &copy;"
        #expect(result == expected)
    }

    @Test("escape_once filter avoids double-escaping entities")
    func escapeOnceFilterInTemplate() async throws {
        let engine = LiquidEngine()
        let template = "{{ text | escape_once }}"
        let context = ["text": "&lt;b&gt;Already escaped&lt;/b&gt; and <i>not escaped</i>"]
        let result = try await engine.render(template: template, context: context)

        #expect(result.contains("&lt;b&gt;"))
        #expect(result.contains("&lt;/b&gt;"))
        #expect(result.contains("&lt;i&gt;"))
        #expect(result.contains("&lt;/i&gt;"))
        #expect(!result.contains("&amp;lt;"))
    }

    @Test("escape_once filter escapes raw script tags")
    func escapeOnceFilterWithScriptTag() async throws {
        let engine = LiquidEngine()
        let template = "{{ script | escape_once }}"
        let context = ["script": "<script>alert('xss')</script>"]
        let result = try await engine.render(template: template, context: context)

        #expect(result == "&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;")
    }

    @Test("escape_once filter preserves already escaped script tags")
    func escapeOnceFilterWithAlreadyEscapedScript() async throws {
        let engine = LiquidEngine()
        let template = "{{ script | escape_once }}"
        let context = ["script": "&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;"]
        let result = try await engine.render(template: template, context: context)

        #expect(result == "&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;")
    }

    @Test("escape_once filter preserves escaped quotes and escapes raw ones")
    func escapeOnceFilterWithMixedQuotes() async throws {
        let engine = LiquidEngine()
        let template = "{{ text | escape_once }}"
        let context = ["text": "She said &quot;Hello&quot; and 'Goodbye'"]
        let result = try await engine.render(template: template, context: context)

        #expect(result == "She said &quot;Hello&quot; and &#39;Goodbye&#39;")
    }

    @Test("escape_once filter escapes incomplete trailing entities")
    func escapeOnceFilterEdgeCase() async throws {
        let engine = LiquidEngine()
        let template = "{{ text | escape_once }}"
        let context = ["text": "Valid &lt;tag&gt; and incomplete &"]
        let result = try await engine.render(template: template, context: context)

        #expect(result == "Valid &lt;tag&gt; and incomplete &amp;")
    }
}
