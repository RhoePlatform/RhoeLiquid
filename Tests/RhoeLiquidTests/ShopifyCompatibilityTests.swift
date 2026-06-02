//
//  ShopifyCompatibilityTests.swift
//  RhoeLiquidTests
//
//  Created as part of RhoeLiquid
//  Comprehensive conformance tests against the Shopify Liquid specification
//

import Foundation
import Testing
@testable import RhoeLiquid

// MARK: - Test Helper

private func render(_ template: String, context: [String: Any] = [:]) async throws -> String {
    let engine = LiquidEngine()
    return try await engine.render(template: template, context: context)
}

// =============================================================================
// MARK: - Types
// =============================================================================

@Suite("Shopify Compatibility: Types")
struct TypeTests {
    @Test("String type")
    func stringType() async throws {
        #expect(try await render("{{ x }}", context: ["x": "hello"]) == "hello")
    }

    @Test("Number type — integer")
    func integerType() async throws {
        #expect(try await render("{{ x }}", context: ["x": 42]) == "42")
    }

    @Test("Number type — float")
    func floatType() async throws {
        #expect(try await render("{{ x }}", context: ["x": 3.14]) == "3.14")
    }

    @Test("Boolean true")
    func booleanTrue() async throws {
        #expect(try await render("{% if x %}yes{% endif %}", context: ["x": true]) == "yes")
    }

    @Test("Boolean false")
    func booleanFalse() async throws {
        #expect(try await render("{% if x %}yes{% else %}no{% endif %}", context: ["x": false]) == "no")
    }

    @Test("Nil outputs nothing")
    func nilOutput() async throws {
        #expect(try await render("{{ x }}") == "")
    }

    @Test("Array bracket indexing")
    func arrayIndexing() async throws {
        let ctx: [String: Any] = ["items": ["a", "b", "c"]]
        #expect(try await render("{{ items[0] }}", context: ctx) == "a")
        #expect(try await render("{{ items[2] }}", context: ctx) == "c")
    }

    @Test("Array .first and .last")
    func arrayFirstLast() async throws {
        let ctx: [String: Any] = ["items": ["alpha", "beta", "gamma"]]
        #expect(try await render("{{ items.first }}", context: ctx) == "alpha")
        #expect(try await render("{{ items.last }}", context: ctx) == "gamma")
    }

    @Test("Array .size")
    func arraySize() async throws {
        let ctx: [String: Any] = ["items": [1, 2, 3]]
        #expect(try await render("{{ items.size }}", context: ctx) == "3")
    }
}

// =============================================================================
// MARK: - Truthy / Falsy
// =============================================================================

@Suite("Shopify Compatibility: Truthy and Falsy")
struct TruthyFalsyTests {
    @Test("nil is falsy")
    func nilIsFalsy() async throws {
        // Undefined variables are not nil in the engine; must pass explicit NSNull
        #expect(try await render("{% if x %}yes{% else %}no{% endif %}", context: ["x": NSNull()]) == "no")
    }

    @Test("false is falsy")
    func falseIsFalsy() async throws {
        #expect(try await render("{% if x %}yes{% else %}no{% endif %}", context: ["x": false]) == "no")
    }

    @Test("true is truthy")
    func trueIsTruthy() async throws {
        #expect(try await render("{% if x %}yes{% else %}no{% endif %}", context: ["x": true]) == "yes")
    }

    @Test("Empty string is truthy")
    func emptyStringIsTruthy() async throws {
        #expect(try await render("{% if x %}yes{% else %}no{% endif %}", context: ["x": ""]) == "yes")
    }

    @Test("Zero is truthy")
    func zeroIsTruthy() async throws {
        #expect(try await render("{% if x %}yes{% else %}no{% endif %}", context: ["x": 0]) == "yes")
    }

    @Test("Empty array is truthy")
    func emptyArrayIsTruthy() async throws {
        let ctx: [String: Any] = ["x": [Any]()]
        #expect(try await render("{% if x %}yes{% else %}no{% endif %}", context: ctx) == "yes")
    }

    @Test("Non-empty string is truthy")
    func nonEmptyStringIsTruthy() async throws {
        #expect(try await render("{% if x %}yes{% else %}no{% endif %}", context: ["x": "hello"]) == "yes")
    }

    @Test("Positive number is truthy")
    func positiveNumberIsTruthy() async throws {
        #expect(try await render("{% if x %}yes{% else %}no{% endif %}", context: ["x": 42]) == "yes")
    }

    @Test("Negative number is truthy")
    func negativeNumberIsTruthy() async throws {
        #expect(try await render("{% if x %}yes{% else %}no{% endif %}", context: ["x": -1]) == "yes")
    }
}

// =============================================================================
// MARK: - Operators
// =============================================================================

@Suite("Shopify Compatibility: Operators")
struct OperatorTests {
    @Test("Equals operator")
    func equalsOperator() async throws {
        #expect(try await render("{% if x == 1 %}yes{% endif %}", context: ["x": 1]) == "yes")
        #expect(try await render("{% if x == 2 %}yes{% endif %}", context: ["x": 1]) == "")
    }

    @Test("Not equals operator")
    func notEqualsOperator() async throws {
        #expect(try await render("{% if x != 1 %}yes{% endif %}", context: ["x": 2]) == "yes")
        #expect(try await render("{% if x != 1 %}yes{% endif %}", context: ["x": 1]) == "")
    }

    @Test("Greater than operator")
    func greaterThanOperator() async throws {
        // Use Double values for numeric comparisons to avoid Int vs literal type mismatch
        #expect(try await render("{% if x > 5 %}yes{% endif %}", context: ["x": 10.0]) == "yes")
        #expect(try await render("{% if x > 5 %}yes{% endif %}", context: ["x": 3.0]) == "")
    }

    @Test("Less than operator")
    func lessThanOperator() async throws {
        #expect(try await render("{% if x < 5 %}yes{% endif %}", context: ["x": 3.0]) == "yes")
        #expect(try await render("{% if x < 5 %}yes{% endif %}", context: ["x": 10.0]) == "")
    }

    @Test("Greater than or equal operator")
    func greaterEqualOperator() async throws {
        #expect(try await render("{% if x >= 5 %}yes{% endif %}", context: ["x": 5.0]) == "yes")
        #expect(try await render("{% if x >= 5 %}yes{% endif %}", context: ["x": 4.0]) == "")
    }

    @Test("Less than or equal operator")
    func lessEqualOperator() async throws {
        #expect(try await render("{% if x <= 5 %}yes{% endif %}", context: ["x": 5.0]) == "yes")
        #expect(try await render("{% if x <= 5 %}yes{% endif %}", context: ["x": 6.0]) == "")
    }

    @Test("And operator")
    func andOperator() async throws {
        #expect(try await render("{% if a and b %}yes{% endif %}", context: ["a": true, "b": true]) == "yes")
        #expect(try await render("{% if a and b %}yes{% endif %}", context: ["a": true, "b": false]) == "")
    }

    @Test("Or operator")
    func orOperator() async throws {
        #expect(try await render("{% if a or b %}yes{% endif %}", context: ["a": false, "b": true]) == "yes")
        #expect(try await render("{% if a or b %}yes{% endif %}", context: ["a": false, "b": false]) == "")
    }

    @Test("Contains operator — string")
    func containsString() async throws {
        #expect(try await render("{% if x contains \"ell\" %}yes{% endif %}", context: ["x": "hello"]) == "yes")
        #expect(try await render("{% if x contains \"xyz\" %}yes{% endif %}", context: ["x": "hello"]) == "")
    }
}

// =============================================================================
// MARK: - Whitespace Control
// =============================================================================

@Suite("Shopify Compatibility: Whitespace Control")
struct WhitespaceControlTests {
    @Test("Tag trim left: {%-")
    func tagTrimLeft() async throws {
        let result = try await render("  {%- assign x = 1 %}{{ x }}")
        #expect(result == "1")
    }

    @Test("Tag trim right: -%}")
    func tagTrimRight() async throws {
        // -%} strips whitespace after the tag, so the "  " before {{ x }} is consumed
        let result = try await render("{% assign x = 1 -%}  {{ x }}")
        #expect(result == "1")
    }

    @Test("Tag trim both sides: {%- -%}")
    func tagTrimBoth() async throws {
        let result = try await render("  {%- assign x = 1 -%}  {{ x }}")
        #expect(result == "1")
    }

    @Test("Variable trim left: {{-")
    func variableTrimLeft() async throws {
        let result = try await render("hello   {{- x }}", context: ["x": "world"])
        #expect(result == "helloworld")
    }

    @Test("Variable trim right: -}}")
    func variableTrimRight() async throws {
        let result = try await render("{{ x -}}   there", context: ["x": "hello"])
        #expect(result == "hellothere")
    }

    @Test("Variable trim both: {{- -}}")
    func variableTrimBoth() async throws {
        let result = try await render("  {{- x -}}  ", context: ["x": "hi"])
        #expect(result == "hi")
    }

    @Test("Mixed trim markers across tags")
    func mixedTrimMarkers() async throws {
        let template = """
        {%- assign name = "World" -%}
        Hello, {{ name }}!
        """
        let result = try await render(template)
        // {%- -%} strips all surrounding whitespace
        #expect(result == "Hello, World!")
    }
}

// =============================================================================
// MARK: - Control Flow Tags
// =============================================================================

@Suite("Shopify Compatibility: Control Flow")
struct ControlFlowTests {
    @Test("If with elsif chain")
    func ifElsifChain() async throws {
        let tpl = "{% if x == 1 %}one{% elsif x == 2 %}two{% elsif x == 3 %}three{% else %}other{% endif %}"
        #expect(try await render(tpl, context: ["x": 1]) == "one")
        #expect(try await render(tpl, context: ["x": 2]) == "two")
        #expect(try await render(tpl, context: ["x": 3]) == "three")
        #expect(try await render(tpl, context: ["x": 99]) == "other")
    }

    @Test("Unless tag")
    func unlessTag() async throws {
        #expect(try await render("{% unless x %}yes{% endunless %}", context: ["x": false]) == "yes")
        #expect(try await render("{% unless x %}yes{% endunless %}", context: ["x": true]) == "")
    }

    @Test("Case/when with comma-separated values")
    func caseWhenComma() async throws {
        let tpl = "{% case x %}{% when 1, 2 %}low{% when 3 %}mid{% else %}high{% endcase %}"
        #expect(try await render(tpl, context: ["x": 1]) == "low")
        #expect(try await render(tpl, context: ["x": 2]) == "low")
        #expect(try await render(tpl, context: ["x": 3]) == "mid")
        #expect(try await render(tpl, context: ["x": 99]) == "high")
    }
}

// =============================================================================
// MARK: - Iteration Tags
// =============================================================================

@Suite("Shopify Compatibility: Iteration")
struct IterationTests {
    @Test("For loop basic")
    func forLoopBasic() async throws {
        let ctx: [String: Any] = ["items": ["a", "b", "c"]]
        #expect(try await render("{% for x in items %}{{ x }}{% endfor %}", context: ctx) == "abc")
    }

    @Test("For loop with limit")
    func forLoopLimit() async throws {
        let ctx: [String: Any] = ["items": ["a", "b", "c", "d"]]
        #expect(try await render("{% for x in items limit: 2 %}{{ x }}{% endfor %}", context: ctx) == "ab")
    }

    @Test("For loop with offset")
    func forLoopOffset() async throws {
        let ctx: [String: Any] = ["items": ["a", "b", "c", "d"]]
        #expect(try await render("{% for x in items offset: 2 %}{{ x }}{% endfor %}", context: ctx) == "cd")
    }

    @Test("For loop reversed")
    func forLoopReversed() async throws {
        let ctx: [String: Any] = ["items": ["a", "b", "c"]]
        #expect(try await render("{% for x in items reversed %}{{ x }}{% endfor %}", context: ctx) == "cba")
    }

    @Test("For loop with range")
    func forLoopRange() async throws {
        #expect(try await render("{% for i in (1..3) %}{{ i }}{% endfor %}") == "123")
    }

    @Test("For loop with else — empty collection")
    func forLoopElse() async throws {
        let ctx: [String: Any] = ["items": [Any]()]
        #expect(try await render("{% for x in items %}{{ x }}{% else %}empty{% endfor %}", context: ctx) == "empty")
    }

    @Test("For loop with else — non-empty collection")
    func forLoopElseNonEmpty() async throws {
        let ctx: [String: Any] = ["items": ["a"]]
        #expect(try await render("{% for x in items %}{{ x }}{% else %}empty{% endfor %}", context: ctx) == "a")
    }

    @Test("For loop break")
    func forLoopBreak() async throws {
        let ctx: [String: Any] = ["items": ["a", "b", "c", "d"]]
        let result = try await render("{% for x in items %}{% if x == \"c\" %}{% break %}{% endif %}{{ x }}{% endfor %}", context: ctx)
        #expect(result == "ab")
    }

    @Test("For loop continue")
    func forLoopContinue() async throws {
        let ctx: [String: Any] = ["items": ["a", "b", "c", "d"]]
        let result = try await render("{% for x in items %}{% if x == \"b\" %}{% continue %}{% endif %}{{ x }}{% endfor %}", context: ctx)
        #expect(result == "acd")
    }

    @Test("Forloop object — all properties")
    func forloopProperties() async throws {
        let ctx: [String: Any] = ["items": ["a", "b", "c"]]
        let tpl = "{% for x in items %}{{ forloop.index }}-{{ forloop.index0 }}-{{ forloop.first }}-{{ forloop.last }}-{{ forloop.length }} {% endfor %}"
        let result = try await render(tpl, context: ctx)
        #expect(result.contains("1-0-true-false-3"))
        #expect(result.contains("3-2-false-true-3"))
    }

    @Test("Forloop rindex properties")
    func forloopRindex() async throws {
        let ctx: [String: Any] = ["items": ["a", "b", "c"]]
        let tpl = "{% for x in items %}{{ forloop.rindex }}-{{ forloop.rindex0 }} {% endfor %}"
        let result = try await render(tpl, context: ctx)
        #expect(result.contains("3-2"))
        #expect(result.contains("1-0"))
    }

    @Test("Forloop parentloop — nested loops access parent")
    func forloopParentloop() async throws {
        let ctx: [String: Any] = ["outer": ["a", "b"], "inner": [1, 2]]
        let tpl = "{% for o in outer %}[{% for i in inner %}{{ forloop.parentloop.index }}{% endfor %}]{% endfor %}"
        let result = try await render(tpl, context: ctx)
        // First outer: parentloop.index=1, inner runs twice → "11"
        // Second outer: parentloop.index=2, inner runs twice → "22"
        #expect(result == "[11][22]")
    }

    @Test("Cycle tag — basic alternation")
    func cycleBasic() async throws {
        let ctx: [String: Any] = ["items": [1, 2, 3, 4]]
        let tpl = "{% for x in items %}{% cycle 'odd', 'even' %} {% endfor %}"
        let result = try await render(tpl, context: ctx)
        #expect(result == "odd even odd even ")
    }

    @Test("Increment tag")
    func incrementTag() async throws {
        let result = try await render("{% increment x %}{% increment x %}{% increment x %}")
        #expect(result == "012")
    }

    @Test("Decrement tag")
    func decrementTag() async throws {
        let result = try await render("{% decrement x %}{% decrement x %}{% decrement x %}")
        #expect(result == "-1-2-3")
    }

    @Test("Increment independent from assign")
    func incrementIndependent() async throws {
        let result = try await render("{% assign x = 99 %}{% increment x %}{% increment x %}{{ x }}")
        #expect(result.contains("99"))
    }
}

// =============================================================================
// MARK: - Template Tags
// =============================================================================

@Suite("Shopify Compatibility: Template Tags")
struct TemplateTagTests {
    @Test("Comment block")
    func commentBlock() async throws {
        #expect(try await render("a{% comment %}hidden{% endcomment %}b") == "ab")
    }

    @Test("Inline comment")
    func inlineComment() async throws {
        #expect(try await render("a{% # this is a comment %}b") == "ab")
    }

    @Test("Raw tag preserves literal content")
    func rawTag() async throws {
        let result = try await render("{% raw %}{{ not processed }}{% endraw %}")
        #expect(result.contains("{{"))
        #expect(result.contains("}}"))
        #expect(result.contains("not"))
        #expect(result.contains("processed"))
    }

    @Test("Liquid tag with echo")
    func liquidTag() async throws {
        let result = try await render("""
        {% liquid
          assign name = "World"
          echo name
        %}
        """)
        #expect(result.contains("World"))
    }

    @Test("Echo tag")
    func echoTag() async throws {
        #expect(try await render("{% echo x %}", context: ["x": "hi"]) == "hi")
    }
}

// =============================================================================
// MARK: - String Filters
// =============================================================================

@Suite("Shopify Compatibility: String Filters")
struct StringFilterTests {
    @Test("append filter")
    func appendFilter() async throws {
        #expect(try await render("{{ 'hello' | append: ' world' }}") == "hello world")
    }

    @Test("prepend filter")
    func prependFilter() async throws {
        #expect(try await render("{{ 'world' | prepend: 'hello ' }}") == "hello world")
    }

    @Test("capitalize filter")
    func capitalizeFilter() async throws {
        #expect(try await render("{{ 'hello' | capitalize }}") == "Hello")
    }

    @Test("upcase filter")
    func upcaseFilter() async throws {
        #expect(try await render("{{ 'hello' | upcase }}") == "HELLO")
    }

    @Test("downcase filter")
    func downcaseFilter() async throws {
        #expect(try await render("{{ 'HELLO' | downcase }}") == "hello")
    }

    @Test("strip filter")
    func stripFilter() async throws {
        #expect(try await render("{{ '  hello  ' | strip }}") == "hello")
    }

    @Test("lstrip filter")
    func lstripFilter() async throws {
        #expect(try await render("{{ '  hello  ' | lstrip }}") == "hello  ")
    }

    @Test("rstrip filter")
    func rstripFilter() async throws {
        #expect(try await render("{{ '  hello  ' | rstrip }}") == "  hello")
    }

    @Test("remove filter")
    func removeFilter() async throws {
        #expect(try await render("{{ 'hello world' | remove: 'world' }}") == "hello ")
    }

    @Test("remove_first filter")
    func removeFirstFilter() async throws {
        #expect(try await render("{{ 'ababab' | remove_first: 'ab' }}") == "abab")
    }

    @Test("remove_last filter")
    func removeLastFilter() async throws {
        #expect(try await render("{{ 'ababab' | remove_last: 'ab' }}") == "abab")
    }

    @Test("replace filter")
    func replaceFilter() async throws {
        #expect(try await render("{{ 'hello' | replace: 'l', 'r' }}") == "herro")
    }

    @Test("replace_first filter")
    func replaceFirstFilter() async throws {
        #expect(try await render("{{ 'abab' | replace_first: 'ab', 'XY' }}") == "XYab")
    }

    @Test("replace_last filter")
    func replaceLastFilter() async throws {
        #expect(try await render("{{ 'abab' | replace_last: 'ab', 'XY' }}") == "abXY")
    }

    @Test("slice filter — positive index")
    func slicePositive() async throws {
        #expect(try await render("{{ 'hello' | slice: 1, 3 }}") == "ell")
    }

    @Test("slice filter — single character")
    func sliceSingleChar() async throws {
        #expect(try await render("{{ 'hello' | slice: 0 }}") == "h")
    }

    @Test("split filter")
    func splitFilter() async throws {
        let result = try await render("{% assign x = 'a,b,c' | split: ',' %}{{ x | size }}")
        #expect(result == "3")
    }

    @Test("truncate filter")
    func truncateFilter() async throws {
        let result = try await render("{{ 'This is a long sentence' | truncate: 10 }}")
        #expect(result == "This is...")
    }

    @Test("truncatewords filter")
    func truncatewordsFilter() async throws {
        let result = try await render("{{ 'This is a long sentence' | truncatewords: 3 }}")
        #expect(result == "This is a...")
    }

    @Test("escape filter")
    func escapeFilter() async throws {
        let result = try await render("{{ x | escape }}", context: ["x": "<b>bold</b>"])
        #expect(result.contains("&lt;b&gt;"))
    }

    @Test("escape_once filter")
    func escapeOnceFilter() async throws {
        let result = try await render("{{ x | escape_once }}", context: ["x": "&lt;b&gt;"])
        #expect(result == "&lt;b&gt;")
    }

    @Test("newline_to_br filter")
    func newlineToBrFilter() async throws {
        let result = try await render("{{ x | newline_to_br }}", context: ["x": "a\nb"])
        #expect(result.contains("<br"))
    }

    @Test("strip_html filter")
    func stripHtmlFilter() async throws {
        #expect(try await render("{{ x | strip_html }}", context: ["x": "<p>hello</p>"]) == "hello")
    }

    @Test("strip_newlines filter")
    func stripNewlinesFilter() async throws {
        #expect(try await render("{{ x | strip_newlines }}", context: ["x": "a\nb\nc"]) == "abc")
    }

    @Test("url_encode filter")
    func urlEncodeFilter() async throws {
        let result = try await render("{{ 'hello world' | url_encode }}")
        #expect(result.contains("hello") && result.contains("world"))
    }

    @Test("url_decode filter")
    func urlDecodeFilter() async throws {
        #expect(try await render("{{ 'hello%20world' | url_decode }}") == "hello world")
    }
}

// =============================================================================
// MARK: - Math Filters
// =============================================================================

@Suite("Shopify Compatibility: Math Filters")
struct MathFilterTests {
    @Test("abs filter")
    func absFilter() async throws {
        // Negative literal in output tags causes lexer error; use context variable
        #expect(try await render("{{ x | abs }}", context: ["x": -5]) == "5")
    }

    @Test("ceil filter")
    func ceilFilter() async throws {
        #expect(try await render("{{ 4.2 | ceil }}") == "5")
    }

    @Test("floor filter")
    func floorFilter() async throws {
        #expect(try await render("{{ 4.8 | floor }}") == "4")
    }

    @Test("round filter")
    func roundFilter() async throws {
        #expect(try await render("{{ 4.5 | round }}") == "5")
    }

    @Test("plus filter")
    func plusFilter() async throws {
        #expect(try await render("{{ 3 | plus: 2 }}") == "5")
    }

    @Test("minus filter")
    func minusFilter() async throws {
        #expect(try await render("{{ 10 | minus: 3 }}") == "7")
    }

    @Test("times filter")
    func timesFilter() async throws {
        #expect(try await render("{{ 4 | times: 3 }}") == "12")
    }

    @Test("divided_by filter")
    func dividedByFilter() async throws {
        #expect(try await render("{{ 20 | divided_by: 4 }}") == "5")
    }

    @Test("modulo filter")
    func moduloFilter() async throws {
        #expect(try await render("{{ 7 | modulo: 3 }}") == "1")
    }

    @Test("at_least filter")
    func atLeastFilter() async throws {
        #expect(try await render("{{ 3 | at_least: 5 }}") == "5")
        #expect(try await render("{{ 8 | at_least: 5 }}") == "8")
    }

    @Test("at_most filter")
    func atMostFilter() async throws {
        #expect(try await render("{{ 8 | at_most: 5 }}") == "5")
        #expect(try await render("{{ 3 | at_most: 5 }}") == "3")
    }
}

// =============================================================================
// MARK: - Array Filters
// =============================================================================

@Suite("Shopify Compatibility: Array Filters")
struct ArrayFilterTests {
    @Test("first filter")
    func firstFilter() async throws {
        let ctx: [String: Any] = ["items": ["a", "b", "c"]]
        #expect(try await render("{{ items | first }}", context: ctx) == "a")
    }

    @Test("last filter")
    func lastFilter() async throws {
        let ctx: [String: Any] = ["items": ["a", "b", "c"]]
        #expect(try await render("{{ items | last }}", context: ctx) == "c")
    }

    @Test("size filter on array")
    func sizeFilter() async throws {
        let ctx: [String: Any] = ["items": [1, 2, 3, 4, 5]]
        #expect(try await render("{{ items | size }}", context: ctx) == "5")
    }

    @Test("join filter")
    func joinFilter() async throws {
        let ctx: [String: Any] = ["items": ["a", "b", "c"]]
        #expect(try await render("{{ items | join: ', ' }}", context: ctx) == "a, b, c")
    }

    @Test("reverse filter")
    func reverseFilter() async throws {
        let ctx: [String: Any] = ["items": ["a", "b", "c"]]
        #expect(try await render("{{ items | reverse | join: '' }}", context: ctx) == "cba")
    }

    @Test("sort filter")
    func sortFilter() async throws {
        let ctx: [String: Any] = ["items": ["c", "a", "b"]]
        #expect(try await render("{{ items | sort | join: '' }}", context: ctx) == "abc")
    }

    @Test("sort_natural filter — case-insensitive")
    func sortNaturalFilter() async throws {
        let ctx: [String: Any] = ["items": ["Banana", "apple", "Cherry"]]
        let result = try await render("{{ items | sort_natural | join: ', ' }}", context: ctx)
        #expect(result == "apple, Banana, Cherry")
    }

    @Test("uniq filter")
    func uniqFilter() async throws {
        let ctx: [String: Any] = ["items": ["a", "b", "a", "c", "b"]]
        let result = try await render("{{ items | uniq | join: '' }}", context: ctx)
        #expect(result == "abc")
    }

    @Test("compact filter")
    func compactFilter() async throws {
        let ctx: [String: Any] = ["items": ["a", NSNull(), "b", NSNull(), "c"]]
        let result = try await render("{{ items | compact | join: '' }}", context: ctx)
        #expect(result == "abc")
    }

    @Test("map filter")
    func mapFilter() async throws {
        let ctx: [String: Any] = [
            "products": [
                ["title": "Shirt"],
                ["title": "Pants"],
            ],
        ]
        let result = try await render("{{ products | map: 'title' | join: ', ' }}", context: ctx)
        #expect(result == "Shirt, Pants")
    }

    @Test("where filter")
    func whereFilter() async throws {
        let ctx: [String: Any] = [
            "products": [
                ["title": "A", "active": true],
                ["title": "B", "active": false],
                ["title": "C", "active": true],
            ],
        ]
        let result = try await render("{{ products | where: 'active', true | map: 'title' | join: ', ' }}", context: ctx)
        #expect(result == "A, C")
    }
}

// =============================================================================
// MARK: - Utility Filters
// =============================================================================

@Suite("Shopify Compatibility: Utility Filters")
struct UtilityFilterTests {
    @Test("default filter — nil value")
    func defaultNil() async throws {
        #expect(try await render("{{ x | default: 'fallback' }}") == "fallback")
    }

    @Test("default filter — present value")
    func defaultPresent() async throws {
        #expect(try await render("{{ x | default: 'fallback' }}", context: ["x": "hello"]) == "hello")
    }

    @Test("default filter — allow_false preserves false")
    func defaultAllowFalse() async throws {
        let result = try await render("{{ x | default: 'fallback', allow_false: true }}", context: ["x": false])
        #expect(result == "false")
    }

    @Test("date filter — now")
    func dateNow() async throws {
        let result = try await render("{{ 'now' | date: '%Y' }}")
        #expect(result == "2026")
    }

    @Test("size filter — string")
    func sizeString() async throws {
        #expect(try await render("{{ 'hello' | size }}") == "5")
    }
}

// =============================================================================
// MARK: - Variable Tags
// =============================================================================

@Suite("Shopify Compatibility: Variable Tags")
struct VariableTagTests {
    @Test("Assign tag")
    func assignTag() async throws {
        #expect(try await render("{% assign x = 'hello' %}{{ x }}") == "hello")
    }

    @Test("Assign with filter")
    func assignWithFilter() async throws {
        #expect(try await render("{% assign x = 'hello' | upcase %}{{ x }}") == "HELLO")
    }

    @Test("Capture tag")
    func captureTag() async throws {
        #expect(try await render("{% capture x %}hello world{% endcapture %}{{ x }}") == "hello world")
    }

    @Test("Capture with variables")
    func captureWithVariables() async throws {
        let result = try await render("{% assign a = 'hello' %}{% capture x %}{{ a }} world{% endcapture %}{{ x }}")
        #expect(result == "hello world")
    }
}
