import Testing
@testable import LiquidCore
@testable import LiquidLexer
@testable import LiquidParser

@Suite("Wave 16 Parser Tests")
struct Wave16ParserTests {
    @Test("Parser captures macro definitions and expression-call syntax")
    func parserCapturesMacroDefinitionsAndExpressionCalls() throws {
        let source = """
        {% macro card(title, subtitle: nil) %}<h1>{{ title }}</h1>{% endmacro %}
        {{ card(title: product.title, subtitle: product.subtitle) }}
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

        guard case .macro(let signature, _) = significantNodes[0] else {
            Issue.record("Expected macro definition as first node")
            return
        }
        #expect(signature.name.string == "card")
        #expect(signature.parameters.count == 2)
        #expect(signature.parameters[1].defaultValue != nil)

        guard case .output(.call(let name, let arguments)) = significantNodes[1] else {
            Issue.record("Expected output call expression as final node")
            return
        }
        #expect(name.string == "card")
        #expect(arguments.count == 2)
        #expect(arguments[0].label?.string == "title")
        #expect(arguments[1].label?.string == "subtitle")
    }

    @Test("Parser captures imports, input contracts, and tag-driven macro calls")
    func parserCapturesImportsInputsAndTagCalls() throws {
        let source = """
        {% import "macros.liquid" as ui %}
        {% from "shared.liquid" import badge, chip %}
        {% input theme: string = "light" %}
        {% call ui.card(title: product.title) %}
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

        #expect(significantNodes.count == 4)

        guard case .macroImport(let namespacedImport) = significantNodes[0] else {
            Issue.record("Expected namespaced import")
            return
        }
        #expect(namespacedImport.template.string == "macros.liquid")
        #expect(namespacedImport.namespace?.string == "ui")

        guard case .macroImport(let selectiveImport) = significantNodes[1] else {
            Issue.record("Expected selective import")
            return
        }
        #expect(selectiveImport.importedMacros.map(\.string) == ["badge", "chip"])

        guard case .input(let contract) = significantNodes[2] else {
            Issue.record("Expected input declaration")
            return
        }
        #expect(contract.name.string == "theme")
        #expect(contract.required == false)

        guard case .call(let name, let arguments, let body) = significantNodes[3] else {
            Issue.record("Expected tag-driven macro call")
            return
        }
        #expect(name.string == "ui.card")
        #expect(arguments.count == 1)
        #expect(arguments[0].label?.string == "title")
        #expect(body == nil)
    }
}
