import Testing
import Foundation
@testable import RhoeLiquid
import LiquidCore
import LiquidLexer
import LiquidParser
import LiquidRenderer
import LiquidTags

// MARK: - Lexer Tests
@Suite("Lexer Tests", .serialized)
struct LexerTests {
    @Test("Tokenize basic template")
    func tokenizeBasic() throws {
        let input = "Hello {{ name }}!"
        let lexer = Lexer(input)
        let tokens = try lexer.tokenize()
        
        #expect(tokens.count == 5)
        #expect(tokens[0].type == .text("Hello "))
        #expect(tokens[1].type == .variableStart)
        #expect(tokens[2].type == .identifier("name"))
        #expect(tokens[3].type == .variableEnd)
        #expect(tokens[4].type == .text("!"))
    }

    @Test("Tokenize Unicode identifiers")
    func tokenizeUnicodeIdentifiers() throws {
        let input = "{{ café }} {{ 用户 }}"
        let lexer = Lexer(input)
        let tokens = try lexer.tokenize()

        #expect(tokens.contains { $0.type == .identifier("café") })
        #expect(tokens.contains { $0.type == .identifier("用户") })
    }
    
    @Test("Tokenize with filters")
    func tokenizeFilters() throws {
        let input = "{{ name | upcase | append: '!' }}"
        let lexer = Lexer(input)
        let tokens = try lexer.tokenize()
        
        #expect(tokens.contains { $0.type == .filter })
        #expect(tokens.contains { $0.type == .colon })
        #expect(tokens.contains { $0.type == .string("!") })
    }
    
    @Test("Tokenize tags")
    func tokenizeTags() throws {
        let input = "{% if true %}yes{% endif %}"
        let lexer = Lexer(input)
        let tokens = try lexer.tokenize()
        
        #expect(tokens.contains { $0.type == .tagStart })
        #expect(tokens.contains { $0.type == .if })
        #expect(tokens.contains { $0.type == .endif })
        #expect(tokens.contains { $0.type == .tagEnd })
    }
    
    @Test("Tokenize operators")
    func tokenizeOperators() throws {
        let input = "{% if x == 5 and y != 10 %}"
        let lexer = Lexer(input)
        let tokens = try lexer.tokenize()
        
        #expect(tokens.contains { $0.type == .equals })
        #expect(tokens.contains { $0.type == .notEquals })
        #expect(tokens.contains { $0.type == .and })
    }
    
    @Test("Handle unterminated single-quoted string")
    func unterminatedSingleQuotedString() throws {
        let lexer = Lexer("{{ 'hello }}")
        #expect(throws: LexerError.self) {
            try lexer.tokenize()
        }
    }

    @Test("Handle unterminated double-quoted string")
    func unterminatedDoubleQuotedString() throws {
        let lexer = Lexer("{{ \"world }}")
        #expect(throws: LexerError.self) {
            try lexer.tokenize()
        }
    }

    @Test("Tokenize escaped quoted strings")
    func tokenizeEscapedQuotedStrings() throws {
        let input = #"{{ "Field \"Notes\"" | append: '!' }}"#
        let lexer = Lexer(input)
        let tokens = try lexer.tokenize()

        #expect(tokens.contains { $0.type == .string(#"Field "Notes""#) })
        #expect(tokens.contains { $0.type == .string("!") })
    }
}

// MARK: - Parser Tests
@Suite("Parser Tests", .serialized)
struct ParserTests {
    @Test("Parse variable output")
    func parseVariable() throws {
        let tokens: [Token] = [
            Token(type: .variableStart, position: 0, line: 1, column: 1),
            Token(type: .identifier("name"), position: 3, line: 1, column: 4),
            Token(type: .variableEnd, position: 7, line: 1, column: 8)
        ]
        
        let parser = Parser(consuming: tokens)
        let ast = try parser.parse()
        
        guard case .template(let nodes) = ast,
              nodes.count == 1,
              case .output(let expr) = nodes[0],
              case .variable(let name) = expr else {
            #expect(Bool(false), "Expected output node with variable expression")
            return
        }
        
        #expect(name == "name")
    }
    
    @Test("Parse if statement")
    func parseIf() throws {
        let tokens = createTokens([
            .tagStart, .if, .identifier("condition"), .tagEnd,
            .text("yes"),
            .tagStart, .else, .tagEnd,
            .text("no"),
            .tagStart, .endif, .tagEnd
        ])
        
        let parser = Parser(consuming: tokens)
        let ast = try parser.parse()
        
        guard case .template(let nodes) = ast,
              nodes.count == 1,
              case .if = nodes[0] else {
            #expect(Bool(false), "Expected if node")
            return
        }
    }
    
    @Test("Parse for loop")
    func parseForLoop() throws {
        let tokens = createTokens([
            .tagStart, .for, .identifier("item"), .in, .identifier("items"), .tagEnd,
            .text("content"),
            .tagStart, .endfor, .tagEnd
        ])
        
        let parser = Parser(consuming: tokens)
        let ast = try parser.parse()
        
        guard case .template(let nodes) = ast,
              nodes.count == 1,
              case .for(variable: let variable, in: _, body: let body, empty: _, params: _) = nodes[0] else {
            #expect(Bool(false), "Expected for node")
            return
        }
        
        #expect(variable == "item")
        #expect(body.count == 1)
    }
    
    @Test("Parse filters")
    func parseFilters() throws {
        let tokens = createTokens([
            .variableStart, .identifier("text"), .filter, .identifier("upcase"),
            .filter, .identifier("append"), .colon, .string("!"), .variableEnd
        ])
        
        let parser = Parser(consuming: tokens)
        let ast = try parser.parse()
        
        guard case .template(let nodes) = ast,
              nodes.count == 1,
              case .output(let expr) = nodes[0],
              case .filtered(_, let filters) = expr else {
            #expect(Bool(false), "Expected filtered expression")
            return
        }
        
        #expect(filters.count == 2)
        #expect(filters[0].name == "upcase")
        #expect(filters[1].name == "append")
    }
    
    // Helper to create tokens
    private func createTokens(_ types: [TokenType]) -> [Token] {
        types.enumerated().map { index, type in
            Token(type: type, position: index, line: 1, column: index + 1)
        }
    }
}

// MARK: - Renderer Tests
@Suite("Renderer Tests", .serialized)
struct RendererTests {
    let engine = LiquidEngine()
    
    @Test("Render variables")
    func renderVariables() async throws {
        let template = "Hello {{ name }}!"
        let context = ["name": "World"]
        let result = try await engine.render(template: template, context: context)
        #expect(result == "Hello World!")
    }
    
    @Test("Render nested variables")
    func renderNestedVariables() async throws {
        let template = "{{ user.name }} - {{ user.email }}"
        let context = ["user": ["name": "John", "email": "john@example.com"]]
        let result = try await engine.render(template: template, context: context)
        #expect(result == "John - john@example.com")
    }
    
    @Test("Render undefined variables")
    func renderUndefinedVariables() async throws {
        let template = "Hello {{ missing }}!"
        let result = try await engine.render(template: template)
        #expect(result == "Hello !")
    }
    
    @Test("If statement truthy")
    func ifTruthy() async throws {
        let template = "{% if value %}yes{% else %}no{% endif %}"
        let values: [Any] = [true, 1, "text", ["item"]]
        for value in values {
            let result = try await engine.render(template: template, context: ["value": value])
            #expect(result == "yes")
        }
    }
    
    @Test("If statement falsy")
    func ifFalsy() async throws {
        let template = "{% if value %}yes{% else %}no{% endif %}"
        let values: [Any] = [false, NSNull()]
        for value in values {
            let result = try await engine.render(template: template, context: ["value": value])
            #expect(result == "no")
        }
    }
    
    @Test("For loop")
    func forLoop() async throws {
        let template = "{% for item in items %}{{ forloop.index }}: {{ item }}\n{% endfor %}"
        let context = ["items": ["a", "b", "c"]]
        let result = try await engine.render(template: template, context: context)
        #expect(result == "1: a\n2: b\n3: c\n")
    }
    
    @Test("For loop with range")
    func forLoopRange() async throws {
        let template = "{% for i in (1..3) %}{{ i }}{% endfor %}"
        let result = try await engine.render(template: template)
        #expect(result == "123")
    }
    
    @Test("Case statement")
    func caseStatement() async throws {
        let template = """
        {% case type %}
        {% when "a" %}A
        {% when "b" %}B
        {% else %}Other
        {% endcase %}
        """
        
        let resultA = try await engine.render(template: template, context: ["type": "a"])
        #expect(resultA.trimmingCharacters(in: .whitespacesAndNewlines) == "A")
        
        let resultOther = try await engine.render(template: template, context: ["type": "c"])
        #expect(resultOther.trimmingCharacters(in: .whitespacesAndNewlines) == "Other")
    }
}

// MARK: - Filter Tests
@Suite("Filter Tests", .serialized)
struct FilterTests {
    let engine = LiquidEngine()
    
    // String Filters
    @Test("String filters")
    func stringFilters() async throws {
        let tests = [
            ("{{ 'hello' | upcase }}", "HELLO"),
            ("{{ 'HELLO' | downcase }}", "hello"),
            ("{{ 'hello world' | capitalize }}", "Hello World"),
            ("{{ '  hello  ' | strip }}", "hello"),
            ("{{ 'hello' | append: ' world' }}", "hello world"),
            ("{{ 'world' | prepend: 'hello ' }}", "hello world"),
            ("{{ 'hello world' | size }}", "11"),
            ("{{ 'a,b,c' | split: ',' | join: '-' }}", "a-b-c"),
            ("{{ 'Hello World!' | slugify }}", "hello-world"),
            ("{{ '<p>hello</p>' | strip_html }}", "hello"),
            ("{{ 'hello world' | truncate: 5 }}", "he..."),
            ("{{ 'one two three' | truncatewords: 2 }}", "one two...")
        ]
        
        for (template, expected) in tests {
            let result = try await engine.render(template: template)
            #expect(result == expected, "Template: \(template)")
        }
    }
    
    // Array Filters
    @Test("Array filters")
    func arrayFilters() async throws {
        
        let tests = [
            ("{{ items | first }}", "b"),
            ("{{ items | last }}", "c"),
            ("{{ items | sort | join: ',' }}", "a,b,c"),
            ("{{ items | size }}", "3"),
            ("{{ numbers | uniq | sort | join: ',' }}", "1,3,4,5"),
            ("{{ products | map: 'name' | join: ', ' }}", "Apple, Carrot, Banana"),
            ("{{ products | where: 'category', 'fruit' | size }}", "2")
        ]
        
        for (template, expected) in tests {
            let testContext: [String: Any] = [
                "items": ["b", "a", "c"],
                "numbers": [3, 1, 4, 1, 5],
                "products": [
                    ["name": "Apple", "price": 1.99, "category": "fruit"],
                    ["name": "Carrot", "price": 0.99, "category": "vegetable"],
                    ["name": "Banana", "price": 1.49, "category": "fruit"]
                ]
            ]
            let result = try await engine.render(template: template, context: testContext)
            #expect(result == expected, "Template: \(template)")
        }
    }
    
    // Math Filters
    @Test("Math filters")
    func mathFilters() async throws {
        let tests = [
            ("{{ 5 | plus: 3 }}", "8"),
            ("{{ 10 | minus: 3 }}", "7"),
            ("{{ 5 | times: 3 }}", "15"),
            ("{{ 20 | divided_by: 4 }}", "5"),
            ("{{ 3.14159 | round: 2 }}", "3.14"),
            ("{{ '3.14159' | round: 2 }}", "3.14"),
            ("{{ '<b>oops</b>' | round: 2 }}", "<b>oops</b>"),
            ("{{ 3.14 | ceil }}", "4"),
            ("{{ 3.14 | floor }}", "3"),
            ("{{ 5 | minus: 10 | abs }}", "5"),
            ("{{ 5 | at_least: 10 }}", "10"),
            ("{{ 15 | at_most: 10 }}", "10")
        ]
        
        for (template, expected) in tests {
            let result = try await engine.render(template: template)
            #expect(result == expected, "Template: \(template)")
        }
    }

    @Test("Math filters accept integer context values")
    func mathFiltersWithIntegerContext() async throws {
        let context: [String: Any] = [
            "count": 5,
            "total": NSNumber(value: 20),
            "threshold": NSNumber(value: 15)
        ]

        let tests = [
            ("{{ count | plus: 3 }}", "8"),
            ("{{ total | divided_by: 4 }}", "5"),
            ("{{ threshold | at_most: 10 }}", "10")
        ]

        for (template, expected) in tests {
            let result = try await engine.render(template: template, context: context)
            #expect(result == expected, "Template: \(template)")
        }
    }

    @Test("Math filters respect secure auto-escaping for non-numeric round inputs")
    func mathFiltersRespectSecureAutoEscaping() async throws {
        let secureEngine = LiquidEngine(configuration: .secure)
        let result = try await secureEngine.render(template: "{{ '<b>oops</b>' | round: 2 }}")
        #expect(result == "&lt;b&gt;oops&lt;/b&gt;")
    }

    @Test("Math filters accept nested access arguments")
    func mathFiltersWithNestedAccessArguments() async throws {
        let context: [String: Any] = [
            "subtotal": 5,
            "pricing": [
                "tax": ["amount": 3],
                "precision": 2
            ]
        ]

        let tests = [
            ("{{ subtotal | plus: pricing.tax.amount }}", "8"),
            ("{{ 3.14159 | round: pricing.precision }}", "3.14")
        ]

        for (template, expected) in tests {
            let result = try await engine.render(template: template, context: context)
            #expect(result == expected, "Template: \(template)")
        }
    }

    @Test("Collection filters accept integer context arguments")
    func collectionFiltersWithIntegerContextArguments() async throws {
        let context: [String: Any] = [
            "items": ["a", "b", "c", "d"],
            "maxItems": 2,
            "skipItems": NSNumber(value: 1)
        ]

        let tests = [
            ("{{ items | limit: maxItems | join: ',' }}", "a,b"),
            ("{{ items | offset: skipItems | join: ',' }}", "b,c,d")
        ]

        for (template, expected) in tests {
            let result = try await engine.render(template: template, context: context)
            #expect(result == expected, "Template: \(template)")
        }
    }
    
    // Date Filters
    @Test("Date filters")
    func dateFilters() async throws {
        let date = Date(timeIntervalSince1970: 1609459200) // 2021-01-01 00:00:00 UTC
        let context = ["date": date]
        
        let template = "{{ date | date: '%Y-%m-%d' }}"
        let result = try await engine.render(template: template, context: context)
        #expect(result.contains("2021") || result.contains("2020")) // Timezone dependent
    }
    
    // Lookup Filters
    @Test("Projection filters can reshape collection data")
    func lookupFilters() async throws {
        let groupContext: [String: Any] = [
            "users": [
                ["id": 1, "name": "Alice", "role": "admin"],
                ["id": 2, "name": "Bob", "role": "user"],
                ["id": 3, "name": "Charlie", "role": "user"]
            ]
        ]
        let groupResult = try await engine.render(
            template: "{{ users | map: 'role' | uniq | sort | join: ',' }}",
            context: groupContext
        )
        #expect(groupResult == "admin,user")
    }
    
    // Chained Filters
    @Test("Chained filters")
    func chainedFilters() async throws {
        let template = "{{ '  hello world  ' | strip | upcase | append: '!' | size }}"
        let result = try await engine.render(template: template)
        #expect(result == "12")
    }
}

// MARK: - Tag Tests
@Suite("Tag Tests", .serialized)
struct TagTests {
    let engine = LiquidEngine()
    
    @Test("Assign tag")
    func assignTag() async throws {
        let template = """
        {% assign name = "John" %}
        {% assign greeting = "Hello " | append: name %}
        {{ greeting }}
        """
        let result = try await engine.render(template: template)
        #expect(result.trimmingCharacters(in: .whitespacesAndNewlines) == "Hello John")
    }
    
    @Test("Capture tag")
    func captureTag() async throws {
        let template = """
        {% capture greeting %}
        Hello {{ name }}!
        {% endcapture %}
        {{ greeting | strip }}
        """
        let context = ["name": "World"]
        let result = try await engine.render(template: template, context: context)
        #expect(result.trimmingCharacters(in: .whitespacesAndNewlines) == "Hello World!")
    }
    
    @Test("Cycle tag")
    func cycleTag() async throws {
        let template = """
        {% for i in (1..4) %}
        {% cycle 'odd', 'even' %}
        {% endfor %}
        """
        let result = try await engine.render(template: template)
        #expect(result.replacingOccurrences(of: "\n", with: "") == "oddevenoddeven")
    }
    
    @Test("Cycle tag with group")
    func cycleTagWithGroup() async throws {
        let template = """
        {% for i in (1..4) %}
        {% cycle 'red', 'green' %}
        {% endfor %}
        """
        let result = try await engine.render(template: template)
        #expect(result.replacingOccurrences(of: "\n", with: "") == "redgreenredgreen")
    }
    
    @Test("Table row tag")
    func tableRowTag() async throws {
        let template = """
        <table>
        {% tablerow product in products cols: 2 %}
        {{ product }}
        {% endtablerow %}
        </table>
        """
        let context = ["products": ["A", "B", "C", "D"]]
        let result = try await engine.render(template: template, context: context)
        
        #expect(result.contains("<tr"))
        #expect(result.contains("<td"))
        #expect(result.contains("</tr>"))
        #expect(result.contains("</td>"))
        #expect(result.contains("A") && result.contains("D"))
    }

    @Test("Table row loop context")
    func tableRowLoopContext() async throws {
        let template = """
        {% tablerow product in products cols: 2 %}
        {{ tablerowloop.row }}-{{ tablerowloop.col }}:{{ product }}
        {% endtablerow %}
        """
        let context = ["products": ["A", "B", "C"]]
        let result = try await engine.render(template: template, context: context)

        #expect(result.contains("1-1:A"))
        #expect(result.contains("1-2:B"))
        #expect(result.contains("2-1:C"))
    }
    
    @Test("Raw tag")
    func rawTag() async throws {
        let result = try await engine.render(template: "{% raw %}literal text{% endraw %}")
        #expect(result.contains("literal text"))
    }
}

// MARK: - Custom Extension Tests
@Suite("Custom Extension Tests", .serialized)
struct CustomExtensionTests {
    @Test("Custom filter")
    func customFilter() async throws {
        let engine = LiquidEngine()
        
        struct DoubleFilter: CustomFilter {
            let name = "double"
            
            func apply(to value: Any, arguments: [Any], namedArguments: [String: Any]) async throws -> Any {
                if let num = value as? Double { return num * 2 }
                if let num = value as? Int { return num * 2 }
                return value
            }
        }
        
        await engine.registerFilter(name: "double", filter: DoubleFilter())

        let rendered = try await engine.render(template: "{{ value | double }}", context: ["value": 21])
        #expect(rendered == "42")
    }
    
    @Test("Custom tag")
    func customTag() async throws {
        let engine = LiquidEngine()
        
        struct EchoTag: LiquidTags.CustomTag {
            let name = "announce"
            let type: TagType = .simple

            func parse(_ parameters: String, context: TagParsingContext) async throws -> TagParameters {
                TagParameters(["value": parameters])
            }

            func execute(parameters: TagParameters, content: String?, context: TagExecutionContext) async throws -> String {
                let value = parameters.get("value", as: String.self) ?? ""
                return "ECHO: \(value)"
            }
        }
        
        try await engine.registerTag(EchoTag())

        let rendered = try await engine.render(template: "Value: {% announce hello world %}")
        let stats = await engine.getTagRegistryStats()
        #expect(rendered == "Value: ECHO: hello world")
        #expect(await engine.hasTag("announce"))
        #expect(stats.customTagCount >= 1)
    }

    @Test("Block custom tag receives raw body source")
    func blockCustomTagUsesRawBody() async throws {
        let engine = LiquidEngine()

        struct SourceEchoTag: LiquidTags.CustomTag {
            let name = "source_echo"
            let type: TagType = .block

            func parse(_ parameters: String, context: TagParsingContext) async throws -> TagParameters {
                TagParameters()
            }

            func execute(parameters: TagParameters, content: String?, context: TagExecutionContext) async throws -> String {
                content ?? ""
            }
        }

        try await engine.registerTag(SourceEchoTag())

        let rendered = try await engine.render(
            template: "{% source_echo %}Hello {{ name }}{% endsource_echo %}",
            context: ["name": "World"]
        )

        #expect(rendered == "Hello {{ name }}")
    }

    @Test("Custom tags can assign variables into the active render context")
    func customTagCanAssignVariablesIntoRenderContext() async throws {
        let engine = LiquidEngine()

        struct AssignValueTag: LiquidTags.CustomTag {
            let name = "assign_value"
            let type: TagType = .simple

            func parse(_ parameters: String, context: TagParsingContext) async throws -> TagParameters {
                TagParameters([
                    "target": "message",
                    "value": "ready"
                ])
            }

            func execute(parameters: TagParameters, content: String?, context: TagExecutionContext) async throws -> String {
                context.setVariable("ready", for: "message")
                return ""
            }
        }

        try await engine.registerTag(AssignValueTag())

        let rendered = try await engine.render(template: "{% assign_value %}{{ message }}")

        #expect(rendered == "ready")
    }

    @Test("Custom tags can load data through the execution context")
    func customTagCanLoadDataThroughExecutionContext() async throws {
        let engine = LiquidEngine()
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("rhoe_liquid_probe_data_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let dataFile = tempDirectory.appendingPathComponent("payload.json")
        try #"{"name":"Ada","count":2}"#.write(to: dataFile, atomically: true, encoding: .utf8)

        struct ProbeLoadTag: LiquidTags.CustomTag {
            let name = "probe_load"
            let type: TagType = .simple

            func parse(_ parameters: String, context: TagParsingContext) async throws -> TagParameters {
                TagParameters(["path": parameters.trimmingCharacters(in: .whitespacesAndNewlines)])
            }

            func execute(parameters: TagParameters, content: String?, context: TagExecutionContext) async throws -> String {
                var path: String = try parameters.require("path")
                if (path.hasPrefix("\"") && path.hasSuffix("\"")) || (path.hasPrefix("'") && path.hasSuffix("'")) {
                    path = String(path.dropFirst().dropLast())
                }
                let data = try await context.loadData(from: path)
                return String(describing: data.liquidValue)
            }
        }

        try await engine.registerTag(ProbeLoadTag())

        let rendered = try await engine.render(
            template: #"{% probe_load "\#(dataFile.path)" %}"#
        )

        #expect(rendered.contains("Ada"))
        #expect(rendered.contains("count"))
    }

    @Test("Custom tags inside loops can read loop variables from the execution context")
    func customTagInsideLoopCanReadLoopVariable() async throws {
        let engine = LiquidEngine()

        struct ProbeVariantTag: LiquidTags.CustomTag {
            let name = "probe_variant"
            let type: TagType = .simple

            func parse(_ parameters: String, context: TagParsingContext) async throws -> TagParameters {
                TagParameters()
            }

            func execute(parameters: TagParameters, content: String?, context: TagExecutionContext) async throws -> String {
                let value = try context.getValue(for: "variant.name")
                return String(describing: value)
            }
        }

        try await engine.registerTag(ProbeVariantTag())

        let rendered = try await engine.render(
            template: "{% for variant in product.variants %}{% probe_variant %} {% endfor %}",
            context: [
                "product": [
                    "variants": [
                        ["name": "Pocket"],
                        ["name": "A5"]
                    ]
                ]
            ]
        )

        #expect(rendered == "Pocket A5 ")
    }

    @Test("Built-in data tag loads structured data into the render context")
    func dataTagLoadsDataIntoContext() async throws {
        let engine = LiquidEngine()
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("rhoe_liquid_data_tag_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let dataFile = tempDirectory.appendingPathComponent("payload.json")
        try #"{"name":"Ada","count":2}"#.write(to: dataFile, atomically: true, encoding: .utf8)

        let rendered = try await engine.render(
            template: #"{% data payload = load("\#(dataFile.path)") %}{{ payload.name }}:{{ payload.count }}"#
        )

        #expect(rendered == "Ada:2")
    }

    @Test("Legacy parser-style tags can bridge into the runtime registry")
    func legacyCustomTagCompatibilityBridge() async throws {
        let engine = LiquidEngine()

        struct LegacyUppercaseTag: LiquidCore.CustomTag {
            func parse(parser: any LiquidCore.TagParser) throws -> any LiquidCore.TagNode {
                let expression = try parser.parseExpression()
                guard case .variable(let variableName) = expression else {
                    throw TagParsingError.invalidSyntax("Expected a variable expression")
                }
                return Node(variableName: variableName.string)
            }

            struct Node: LiquidCore.TagNode {
                let variableName: String

                func render(context: borrowing any LiquidCore.RenderContext) async throws -> String {
                    let value = try context.getValue(for: variableName)
                    let uppercased = try await context.applyFilter(
                        name: "upcase",
                        to: value,
                        arguments: [],
                        namedArguments: [:]
                    )
                    return String(describing: uppercased)
                }
            }
        }

        try await engine.registerLegacyTag(
            named: "legacy_upcase",
            type: .simple,
            tag: LegacyUppercaseTag()
        )

        let rendered = try await engine.render(
            template: "Value: {% legacy_upcase name %}",
            context: ["name": "Ada"]
        )

        #expect(rendered == "Value: ADA")
    }

    @Test("Legacy block tags receive parsed body nodes through the compatibility layer")
    func legacyBlockTagCompatibilityBridge() async throws {
        let engine = LiquidEngine()

        struct LegacyBodyCountTag: LiquidCore.CustomTag {
            func parse(parser: any LiquidCore.TagParser) throws -> any LiquidCore.TagNode {
                let body = try parser.parseUntilEnd(tagName: "legacy_body_count")
                try parser.expectEndTag("legacy_body_count")
                return Node(nodeCount: body.count)
            }

            struct Node: LiquidCore.TagNode {
                let nodeCount: Int

                func render(context: borrowing any LiquidCore.RenderContext) async throws -> String {
                    String(nodeCount)
                }
            }
        }

        try await engine.registerLegacyTag(
            named: "legacy_body_count",
            type: .block,
            tag: LegacyBodyCountTag()
        )

        let rendered = try await engine.render(
            template: "{% legacy_body_count %}Hello {{ name }}{% endlegacy_body_count %}",
            context: ["name": "Ada"]
        )

        #expect(rendered == "2")
    }

    @Test("LiquidConfiguration customTags auto-install simple legacy tags")
    func configurationCustomTagsAutoInstallSimpleLegacyTags() async throws {
        struct LegacyEchoTag: LiquidCore.CustomTag {
            func parse(parser: any LiquidCore.TagParser) throws -> any LiquidCore.TagNode {
                let expression = try parser.parseExpression()
                guard case .variable(let variableName) = expression else {
                    throw TagParsingError.invalidSyntax("Expected a variable expression")
                }
                return Node(variableName: variableName.string)
            }

            struct Node: LiquidCore.TagNode {
                let variableName: String

                func render(context: borrowing any LiquidCore.RenderContext) async throws -> String {
                    let value = try context.getValue(for: variableName)
                    return String(describing: value)
                }
            }
        }

        let engine = LiquidEngine(
            configuration: LiquidConfiguration(
                customTags: [
                    "legacy_echo": LegacyEchoTag()
                ]
            )
        )

        let rendered = try await engine.render(
            template: "Value: {% legacy_echo name %}",
            context: ["name": "Ada"]
        )

        #expect(rendered == "Value: Ada")
        #expect(await engine.hasTag("legacy_echo"))
    }

    @Test("LiquidConfiguration customTags honor explicit legacy block metadata")
    func configurationCustomTagsHonorLegacyBlockMetadata() async throws {
        struct LegacyBodyCountTag: LiquidCore.CustomTag {
            func parse(parser: any LiquidCore.TagParser) throws -> any LiquidCore.TagNode {
                let body = try parser.parseUntilEnd(tagName: "legacy_config_block")
                try parser.expectEndTag("legacy_config_block")
                return Node(nodeCount: body.count)
            }

            struct Node: LiquidCore.TagNode {
                let nodeCount: Int

                func render(context: borrowing any LiquidCore.RenderContext) async throws -> String {
                    String(nodeCount)
                }
            }
        }

        let engine = LiquidEngine(
            configuration: LiquidConfiguration(
                customTags: [
                    "legacy_config_block": ConfiguredLegacyCustomTag(
                        LegacyBodyCountTag(),
                        kind: .block
                    )
                ]
            )
        )

        let rendered = try await engine.render(
            template: "{% legacy_config_block %}Hello {{ name }}{% endlegacy_config_block %}",
            context: ["name": "Ada"]
        )

        #expect(rendered == "2")
        #expect(await engine.hasTag("legacy_config_block"))
    }
}

// MARK: - Edge Case Tests
@Suite("Edge Case Tests", .serialized)
struct EdgeCaseTests {
    let engine = LiquidEngine()
    
    @Test("Empty template")
    func emptyTemplate() async throws {
        let result = try await engine.render(template: "")
        #expect(result == "")
    }
    
    @Test("Only text")
    func onlyText() async throws {
        let result = try await engine.render(template: "Just plain text")
        #expect(result == "Just plain text")
    }
    
    @Test("Nested loops")
    func nestedLoops() async throws {
        let template = "{% for item in items %}{{ item.value }}{% endfor %}"
        let context = ["items": [["value": "A"], ["value": "B"]]]
        let result = try await engine.render(template: template, context: context)
        #expect(result == "AB")
    }
    
    @Test("Complex expressions")
    func complexExpressions() async throws {
        let template = "{% if x > 5 %}yes{% endif %}"
        let context = ["x": 6.0]
        let result = try await engine.render(template: template, context: context)
        #expect(result == "yes")
    }
    
    @Test("Unicode support")
    func unicodeSupport() async throws {
        let template = "{{ greeting }} 🌍"
        let context = ["greeting": "Hello 世界"]
        let result = try await engine.render(template: template, context: context)
        #expect(result == "Hello 世界 🌍")
    }
}

// MARK: - Stress Tests
@Suite("Stress Tests", .serialized)
struct StressTests {
    let engine = LiquidEngine()
    
    @Test("Large loop renders complete range")
    func largeLoop() async throws {
        let template = "{% for i in (1..1000) %}{{ i }}{% endfor %}"
        let result = try await engine.render(template: template)

        #expect(result.hasPrefix("12345678910"))
        #expect(result.hasSuffix("9989991000"))
    }
    
    @Test("Deep nesting resolves property path")
    func deepNesting() async throws {
        let data = [
            "a": ["b": ["c": ["d": ["e": "value"]]]]
        ]
        let template = "{{ a.b.c.d.e }}"
        let result = try await engine.render(template: template, context: data)
        
        #expect(result == "value")
    }
}
