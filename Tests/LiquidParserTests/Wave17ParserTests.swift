import Testing
@testable import LiquidCore
@testable import LiquidLexer
@testable import LiquidParser

@Suite("Wave 17 Parser Tests")
struct Wave17ParserTests {
    @Test("Parser captures slot definitions and block-form call fills")
    func parserCapturesSlotsAndBlockCalls() throws {
        let source = """
        {% macro card(title) %}
        <article>
          {% slot default %}<p>Fallback</p>{% endslot %}
          {% slot footer %}<footer>Default footer</footer>{% endslot %}
        </article>
        {% endmacro %}
        {% call card(title: product.title) %}
          <p>{{ product.description }}</p>
          {% fill footer %}<span>{{ product.price }}</span>{% endfill %}
        {% endcall %}
        """

        let tokens = try Lexer(source).tokenize()
        let ast = try Parser(consuming: tokens, source: source).parse()

        guard case .template(let nodes) = ast else {
            Issue.record("Expected template root")
            return
        }

        let significantNodes = nodes.filter { node in
            if case .text(let text) = node {
                return !text.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            return true
        }

        #expect(significantNodes.count == 2)

        guard case .macro(let signature, let body) = significantNodes[0] else {
            Issue.record("Expected macro definition as first node")
            return
        }
        #expect(signature.name.string == "card")
        #expect(body.contains {
            if case .slot(let name, _) = $0 {
                return name.string == "default"
            }
            return false
        })
        #expect(body.contains {
            if case .slot(let name, _) = $0 {
                return name.string == "footer"
            }
            return false
        })

        guard case .call(let name, let arguments, let body?) = significantNodes[1] else {
            Issue.record("Expected block-form call as second node")
            return
        }
        #expect(name.string == "card")
        #expect(arguments.count == 1)
        #expect(arguments[0].label?.string == "title")
        #expect(body.contains {
            if case .fill(let slotName, _) = $0 {
                return slotName.string == "footer"
            }
            return false
        })
    }

    @Test("Parser rejects slot outside macro bodies")
    func parserRejectsSlotOutsideMacroBodies() throws {
        let source = "{% slot default %}Hello{% endslot %}"

        let tokens = try Lexer(source).tokenize()

        do {
            _ = try Parser(consuming: tokens, source: source).parse()
            Issue.record("Expected slot outside macro bodies to fail")
        } catch {
            guard case .unsupportedFeature(let message) = error else {
                Issue.record("Expected unsupportedFeature, got \(error)")
                return
            }
            #expect(message.contains("slot"))
        }
    }

    @Test("Parser rejects fill outside block-form calls")
    func parserRejectsFillOutsideBlockCalls() throws {
        let source = "{% fill footer %}Hello{% endfill %}"

        let tokens = try Lexer(source).tokenize()

        do {
            _ = try Parser(consuming: tokens, source: source).parse()
            Issue.record("Expected fill outside block-form calls to fail")
        } catch {
            guard case .unsupportedFeature(let message) = error else {
                Issue.record("Expected unsupportedFeature, got \(error)")
                return
            }
            #expect(message.contains("fill"))
        }
    }

    @Test("Parser captures path-based input declarations")
    func parserCapturesPathBasedInputDeclarations() throws {
        let source = """
        {% input user.name: string %}
        {% input items[].title: string = "Untitled" %}
        """

        let tokens = try Lexer(source).tokenize()
        let ast = try Parser(consuming: tokens, source: source).parse()

        guard case .template(let nodes) = ast else {
            Issue.record("Expected template root")
            return
        }

        let significantNodes = nodes.filter { node in
            if case .text(let text) = node {
                return !text.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            return true
        }

        #expect(significantNodes.count == 2)

        guard case .input(let requiredField) = significantNodes[0] else {
            Issue.record("Expected first input declaration")
            return
        }
        #expect(requiredField.name.string == "user.name")
        #expect(requiredField.path == [.key("user"), .key("name")])
        #expect(requiredField.required)

        guard case .input(let defaultedField) = significantNodes[1] else {
            Issue.record("Expected second input declaration")
            return
        }
        #expect(defaultedField.name.string == "items[].title")
        #expect(defaultedField.path == [.key("items"), .arrayElement, .key("title")])
        #expect(!defaultedField.required)
    }

    @Test("Parser captures strict object input declarations")
    func parserCapturesStrictObjectInputDeclarations() throws {
        let source = """
        {% input user: object strict %}
        {% input items[]: object strict %}
        """

        let tokens = try Lexer(source).tokenize()
        let ast = try Parser(consuming: tokens, source: source).parse()

        guard case .template(let nodes) = ast else {
            Issue.record("Expected template root")
            return
        }

        let significantNodes = nodes.filter { node in
            if case .text(let text) = node {
                return !text.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            return true
        }

        #expect(significantNodes.count == 2)

        guard case .input(let userField) = significantNodes[0] else {
            Issue.record("Expected first strict input declaration")
            return
        }
        #expect(userField.name.string == "user")
        #expect(userField.strict)

        guard case .input(let itemsField) = significantNodes[1] else {
            Issue.record("Expected second strict input declaration")
            return
        }
        #expect(itemsField.name.string == "items[]")
        #expect(itemsField.strict)
    }

    @Test("Parser rejects strict modifier on non-object inputs")
    func parserRejectsStrictModifierOnNonObjectInputs() throws {
        let source = "{% input user.name: string strict %}"
        let tokens = try Lexer(source).tokenize()

        do {
            _ = try Parser(consuming: tokens, source: source).parse()
            Issue.record("Expected non-object strict input declaration to fail")
        } catch {
            guard case .unsupportedFeature(let message) = error else {
                Issue.record("Expected unsupportedFeature, got \(error)")
                return
            }
            #expect(message.contains("strict input contracts"))
        }
    }
}
