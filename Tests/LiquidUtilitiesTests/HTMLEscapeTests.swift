import Testing
@testable import LiquidUtilities

@Suite("HTML Escape Utility Tests")
struct HTMLEscapeTests {
    @Test("HTMLEscape escapes raw script tags")
    func escapeOnceBasic() {
        let input = "<script>alert('hello');</script>"
        let result = HTMLEscape.escapeOnce(input)
        let expected = "&lt;script&gt;alert(&#39;hello&#39;);&lt;/script&gt;"
        #expect(result == expected)
    }

    @Test("HTMLEscape preserves existing entities")
    func escapeOnceAlreadyEscaped() {
        let input = "Already &lt;escaped&gt; &amp; content"
        let result = HTMLEscape.escapeOnce(input)
        let expected = "Already &lt;escaped&gt; &amp; content"
        #expect(result == expected)
    }

    @Test("HTMLEscape handles mixed escaped and raw HTML")
    func escapeOnceMixed() {
        let input = "&lt;b&gt;Already escaped&lt;/b&gt; and <i>not escaped</i>"
        let result = HTMLEscape.escapeOnce(input)
        let expected = "&lt;b&gt;Already escaped&lt;/b&gt; and &lt;i&gt;not escaped&lt;/i&gt;"
        #expect(result == expected)
    }

    @Test("HTMLEscape preserves numeric entities")
    func escapeOnceNumeric() {
        let input = "Copyright &#169; 2023 & <script>alert()</script>"
        let result = HTMLEscape.escapeOnce(input)
        let expected = "Copyright &#169; 2023 &amp; &lt;script&gt;alert()&lt;/script&gt;"
        #expect(result == expected)
    }

    @Test("HTMLEscape escapes bare ampersands")
    func escapeOnceBareAmpersands() {
        let input = "Tom & Jerry & Mickey Mouse"
        let result = HTMLEscape.escapeOnce(input)
        let expected = "Tom &amp; Jerry &amp; Mickey Mouse"
        #expect(result == expected)
    }
}
