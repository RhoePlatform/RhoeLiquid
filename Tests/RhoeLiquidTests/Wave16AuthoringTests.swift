import Foundation
import Testing
@testable import LiquidCore
@testable import RhoeLiquid

@Suite("Wave 16 Authoring Tests")
struct Wave16AuthoringTests {
    @Test("Macros render through expression calls with defaults")
    func macrosRenderThroughExpressionCallsWithDefaults() async throws {
        let environment = LiquidEnvironment()
        let template = """
        {% macro card(title, subtitle: "Default subtitle") %}<h1>{{ title }}</h1><p>{{ subtitle }}</p>{% endmacro %}
        {{ card(title: product.title) }}
        """

        let rendered = try await environment.render(
            template: template,
            context: ["product": ["title": "Wave 16"]]
        )

        #expect(rendered.contains("<h1>Wave 16</h1>"))
        #expect(rendered.contains("<p>Default subtitle</p>"))
    }

    @Test("Template input contracts apply defaults and validate missing required inputs")
    func templateInputContractsApplyDefaultsAndValidate() async throws {
        let environment = LiquidEnvironment()

        let defaulted = try await environment.render(
            template: "{% input theme: string = \"light\" %}{{ theme }}"
        )
        #expect(defaulted == "light")

        do {
            _ = try await environment.render(
                template: "{% input user: object %}{{ user.name }}",
                context: [:]
            )
            Issue.record("Expected missing required input validation to fail")
        } catch let error as LiquidEnvironmentError {
            guard case .validationFailure(let message) = error else {
                Issue.record("Expected validationFailure, got \(error)")
                return
            }
            #expect(message.contains("Missing required input 'user'"))
        } catch {
            Issue.record("Expected LiquidEnvironmentError, got \(error)")
        }
    }

    @Test("Shopify-compatible profile rejects Wave 16 authoring syntax")
    func shopifyCompatibleProfileRejectsWave16Syntax() async throws {
        let environment = LiquidEnvironment(profile: .shopifyCompatible, sandboxPolicy: .trustedLocal)

        do {
            _ = try await environment.render(
                template: "{% macro badge(label) %}{{ label }}{% endmacro %}{{ badge(label: \"x\") }}"
            )
            Issue.record("Expected the shopify-compatible profile to reject Wave 16 syntax")
        } catch let error as LiquidEnvironmentError {
            guard case .unsupportedProfileFeature = error else {
                Issue.record("Expected unsupportedProfileFeature, got \(error)")
                return
            }
        } catch {
            Issue.record("Expected LiquidEnvironmentError, got \(error)")
        }
    }

    @Test("File-backed macro imports render through the existing template loader")
    func fileBackedMacroImportsRender() async throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let macrosURL = tempDirectory.appendingPathComponent("macros.liquid")
        let mainURL = tempDirectory.appendingPathComponent("main.liquid")

        try """
        {% macro card(title) %}<h1>{{ title }}</h1>{% endmacro %}
        """.write(to: macrosURL, atomically: true, encoding: .utf8)

        try """
        {% import "macros.liquid" as ui %}
        {% call ui.card(title: product.title) %}
        """.write(to: mainURL, atomically: true, encoding: .utf8)

        let engine = LiquidEngine()
        let rendered = try await engine.renderFile(
            at: mainURL.path,
            context: ["product": ["title": "Imported"]]
        )

        #expect(rendered.contains("<h1>Imported</h1>"))
    }

    @Test("Recursive macro execution fails explicitly")
    func recursiveMacroExecutionFailsExplicitly() async throws {
        let environment = LiquidEnvironment()
        let template = """
        {% macro loop() %}{{ loop() }}{% endmacro %}
        {{ loop() }}
        """

        do {
            _ = try await environment.render(template: template)
            Issue.record("Expected recursive macro execution to fail")
        } catch let error as RenderError {
            guard case .custom(let message, _) = error else {
                Issue.record("Expected a custom render error, got \(error)")
                return
            }
            #expect(message.contains("Recursive or circular macro execution"))
        } catch {
            Issue.record("Expected RenderError, got \(error)")
        }
    }

    @Test("Template analysis exposes Wave 16 inputs, macros, and calls")
    func templateAnalysisExposesWave16InputsMacrosAndCalls() async {
        let environment = LiquidEnvironment()
        let analysis = await environment.analyzeTemplate(
            """
            {% input theme: string = "light" %}
            {% macro card(title) %}{{ title }}{% endmacro %}
            {{ card(title: product.title) }}
            """
        )

        #expect(analysis.manifest.requiresExtendedProfile)
        #expect(analysis.inputContract.fields.map(\.name) == ["theme"])
        #expect(analysis.manifest.contractDefaults == ["theme"])
        #expect(analysis.manifest.macroDefinitions.map(\.name) == ["card"])
        #expect(analysis.manifest.macroCalls.map(\.name) == ["card"])
    }
}
