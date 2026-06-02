import Testing
import Foundation
@testable import RhoeLiquid
import LiquidCore
import LiquidLexer
import LiquidParser

@Suite("Wave 9 Syntax Runtime Tests")
struct Wave9SyntaxRuntimeTests {
    @Test("Pipeline tag is explicitly out of scope for 1.x")
    func pipelineTagIsExplicitlyOutOfScope() throws {
        let template = "{% pipeline products %}"
        let lexer = Lexer(template)
        let tokens = try lexer.tokenize()
        let parser = Parser(consuming: tokens, source: template)

        do {
            _ = try parser.parse()
            Issue.record("Expected the archived pipeline tag to fail explicitly during parsing")
        } catch {
            guard case .unsupportedFeature(let message) = error else {
                Issue.record("Expected ParserError.unsupportedFeature, got \(error)")
                return
            }
            #expect(message.contains("pipeline"))
            #expect(message.contains("1.x"))
        }
    }

    @Test("Liquid tag supports multiline control flow")
    func liquidTagSupportsMultilineControlFlow() throws {
        let template = """
        {% liquid
          assign current = product.title
          if product.available
            echo current | upcase
          else
            echo 'sold out'
          endif
        %}
        """

        let lexer = Lexer(template)
        let tokens = try lexer.tokenize()
        let parser = Parser(consuming: tokens, source: template)
        let ast = try parser.parse()

        guard case .template(let nodes) = ast,
              nodes.count == 1,
              case .liquid(let body) = nodes[0] else {
            Issue.record("Expected one liquid node at the template root")
            return
        }

        #expect(body.count == 2)

        guard case .assign(variable: let assignedName, value: _) = body[0] else {
            Issue.record("Expected the first liquid body node to be an assign")
            return
        }
        #expect(assignedName == "current")

        guard case .if(condition: _, then: let thenNodes, elsif: let elsifBranches, else: let elseNodes) = body[1] else {
            Issue.record("Expected the second liquid body node to be an if")
            return
        }

        #expect(thenNodes.count == 1)
        #expect(elsifBranches.isEmpty)
        #expect(elseNodes?.count == 1)
    }

    @Test("Break exits loops")
    func breakExitsLoops() async throws {
        let engine = LiquidEngine()
        let template = "{% for item in items %}{{ item }}{% if item == 3 %}{% break %}{% endif %}{% endfor %}"
        let result = try await engine.render(template: template, context: ["items": [1, 2, 3, 4]])

        #expect(result == "123")
    }

    @Test("Continue skips the current loop iteration")
    func continueSkipsCurrentLoopIteration() async throws {
        let engine = LiquidEngine()
        let template = "{% for item in items %}{% if item == 2 %}{% continue %}{% endif %}{{ item }}{% endfor %}"
        let result = try await engine.render(template: template, context: ["items": [1, 2, 3]])

        #expect(result == "13")
    }

    @Test("Break outside loops fails explicitly")
    func breakOutsideLoopsFailsExplicitly() async throws {
        let engine = LiquidEngine()

        do {
            _ = try await engine.render(template: "{% break %}")
            Issue.record("Expected break outside a loop to fail explicitly")
        } catch let error as RenderError {
            guard case .custom(let message, _) = error else {
                Issue.record("Expected a custom render error, got \(error)")
                return
            }
            #expect(message.contains("only valid inside"))
            #expect(message.contains("break"))
        }
    }

    @Test("Liquid tag supports loop control statements")
    func liquidTagSupportsLoopControlStatements() async throws {
        let engine = LiquidEngine()
        let template = """
        {% for item in items %}{% liquid
          if item == 2
            continue
          endif
          echo item
        %}{% endfor %}
        """

        let result = try await engine.render(template: template, context: ["items": [1, 2, 3]])
        #expect(result == "13")
    }

    @Test("Debug tag is a no-op without debug configuration")
    func debugTagIsNoOpWithoutDebugConfiguration() async throws {
        let engine = LiquidEngine()
        let result = try await engine.render(
            template: "A{% debug name %}B",
            context: ["name": "Ada"]
        )

        #expect(result == "AB")
    }

    @Test("Debug tag emits messages through the configured debug handler")
    func debugTagEmitsMessagesThroughConfiguredDebugHandler() async throws {
        let handler = RecordingDebugHandler()
        let configuration = LiquidConfiguration(
            debug: DebugConfiguration(
                enabled: true,
                outputHandler: handler
            )
        )
        let engine = LiquidEngine(configuration: configuration)

        let result = try await engine.render(
            template: "A{% debug name %}B",
            context: ["name": "Ada"]
        )

        #expect(result == "AB")
        #expect(handler.recordedMessages().contains("debug: Ada"))
    }
}

private final class RecordingDebugHandler: DebugOutputHandler, @unchecked Sendable {
    private let lock = NSLock()
    private var messages: [String] = []

    func handleDebugOutput(_ output: DebugOutput) {
        guard case .message(let message, _) = output else {
            return
        }

        lock.lock()
        messages.append(message)
        lock.unlock()
    }

    func handleBreakpoint(_ breakpoint: DebugBreakpoint, context: DebugContext) async -> DebugAction {
        .continue
    }

    func handleDebugError(_ error: Error, context: DebugContext) {}

    func recordedMessages() -> [String] {
        lock.lock()
        let snapshot = messages
        lock.unlock()
        return snapshot
    }
}
