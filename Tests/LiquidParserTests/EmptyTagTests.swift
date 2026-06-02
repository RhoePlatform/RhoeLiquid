import Testing
@testable import LiquidParser
@testable import LiquidLexer
@testable import LiquidCore

@Suite("Empty Tag Parser Tests")
struct EmptyTagTests {
    @Test("For loops retain empty branches in the AST")
    func forLoopWithEmpty() throws {
        let template = """
{% for item in items %}
    <p>{{ item }}</p>
{% empty %}
    <p>No items found</p>
{% endfor %}
"""
        
        let lexer = Lexer(template)
        let tokens = try lexer.tokenize()
        
        let parser = Parser(consuming: tokens)
        let ast = try parser.parse()

        guard case .template(let nodes) = ast else {
            #expect(Bool(false), "Expected template node")
            return
        }

        guard let forNode = nodes.first(where: {
            if case .for = $0 { return true } else { return false }
        }) else {
            #expect(Bool(false), "Expected for loop in AST")
            return
        }

        guard case .for(let variable, _, let body, let empty, _) = forNode else {
            #expect(Bool(false), "Unexpected for loop structure")
            return
        }

        #expect(variable.string == "item")
        #expect(empty != nil)
        #expect(!body.isEmpty)
        #expect(!(empty ?? []).isEmpty)

        let bodyContent = body.compactMap { node in
            if case .text(let text) = node { return text.string }
            else if case .output = node { return "{{ item }}" }
            else { return nil }
        }.joined()
        #expect(bodyContent.contains("item"))

        let emptyContent = (empty ?? []).compactMap { node in
            if case .text(let text) = node { return text.string }
            else { return nil }
        }.joined()
        #expect(emptyContent.contains("No items found"))
    }

    @Test("For loops without an empty clause keep that slot nil")
    func forLoopWithoutEmpty() throws {
        let template = """
{% for item in items %}
    <p>{{ item }}</p>
{% endfor %}
"""
        
        let lexer = Lexer(template)
        let tokens = try lexer.tokenize()
        
        let parser = Parser(consuming: tokens)
        let ast = try parser.parse()

        guard case .template(let nodes) = ast else {
            #expect(Bool(false), "Expected template node")
            return
        }

        guard let forNode = nodes.first(where: {
            if case .for = $0 { return true } else { return false }
        }) else {
            #expect(Bool(false), "Expected for loop in AST")
            return
        }

        guard case .for(let variable, _, let body, let empty, _) = forNode else {
            #expect(Bool(false), "Unexpected for loop structure")
            return
        }

        #expect(variable.string == "item")
        #expect(empty == nil)
        #expect(!body.isEmpty)
    }

    @Test("Lexer recognizes the empty tag")
    func emptyTokenRecognition() throws {
        let template = "{% empty %}"

        let lexer = Lexer(template)
        let tokens = try lexer.tokenize()

        #expect(tokens.count == 3)
        #expect(tokens[0].type == .tagStart)
        #expect(tokens[1].type == .empty)
        #expect(tokens[2].type == .tagEnd)
    }
}
