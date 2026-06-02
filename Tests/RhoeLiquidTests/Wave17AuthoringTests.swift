import Foundation
import Testing
@testable import LiquidCore
@testable import RhoeLiquid

@Suite("Wave 17 Authoring Tests")
struct Wave17AuthoringTests {
    @Test("Block-form macro calls render default slots and named fills")
    func blockMacroCallsRenderSlotsAndFills() async throws {
        let environment = LiquidEnvironment()
        let template = """
        {% macro card(title) %}
        <article>
          <h1>{{ title }}</h1>
          {% slot default %}<p>Fallback</p>{% endslot %}
          {% slot footer %}<footer>Default footer</footer>{% endslot %}
        </article>
        {% endmacro %}
        {% call card(title: product.title) %}
          <p>{{ product.description }}</p>
          {% fill footer %}<span>{{ product.price }}</span>{% endfill %}
        {% endcall %}
        """

        let rendered = try await environment.render(
            template: template,
            context: [
                "product": [
                    "title": "Wave 17",
                    "description": "Component body",
                    "price": "9.99"
                ]
            ]
        )

        #expect(rendered.contains("<h1>Wave 17</h1>"))
        #expect(rendered.contains("<p>Component body</p>"))
        #expect(rendered.contains("<span>9.99</span>"))
        #expect(!rendered.contains("Default footer"))
    }

    @Test("Default slot fallback renders when block call omits body")
    func defaultSlotFallbackRendersWhenBodyIsMissing() async throws {
        let environment = LiquidEnvironment()
        let template = """
        {% macro card(title) %}
        <article>
          <h1>{{ title }}</h1>
          {% slot default %}<p>Fallback body</p>{% endslot %}
        </article>
        {% endmacro %}
        {% call card(title: "Wave 17") %}{% endcall %}
        """

        let rendered = try await environment.render(template: template)

        #expect(rendered.contains("<h1>Wave 17</h1>"))
        #expect(rendered.contains("<p>Fallback body</p>"))
    }

    @Test("Unknown fills fail explicitly")
    func unknownFillsFailExplicitly() async throws {
        let environment = LiquidEnvironment()
        let template = """
        {% macro card() %}{% slot default %}Fallback{% endslot %}{% endmacro %}
        {% call card() %}
          {% fill footer %}Oops{% endfill %}
        {% endcall %}
        """

        do {
            _ = try await environment.render(template: template)
            Issue.record("Expected unknown fill to fail")
        } catch let error as LiquidEnvironmentError {
            guard case .validationFailure(let message) = error else {
                Issue.record("Expected validationFailure, got \(error)")
                return
            }
            #expect(message.contains("Unknown fill"))
            #expect(message.contains("footer"))
        }
    }

    @Test("Duplicate fills fail explicitly")
    func duplicateFillsFailExplicitly() async throws {
        let environment = LiquidEnvironment()
        let template = """
        {% macro card() %}{% slot footer %}Fallback{% endslot %}{% endmacro %}
        {% call card() %}
          {% fill footer %}First{% endfill %}
          {% fill footer %}Second{% endfill %}
        {% endcall %}
        """

        do {
            _ = try await environment.render(template: template)
            Issue.record("Expected duplicate fill to fail")
        } catch let error as LiquidEnvironmentError {
            guard case .validationFailure(let message) = error else {
                Issue.record("Expected validationFailure, got \(error)")
                return
            }
            #expect(message.contains("Duplicate fill"))
            #expect(message.contains("footer"))
        }
    }

    @Test("Template analysis exposes slot definitions and block call fill metadata")
    func templateAnalysisExposesSlotsAndBlockCalls() async {
        let environment = LiquidEnvironment()
        let analysis = await environment.analyzeTemplate(
            """
            {% macro card(title) %}
            {% slot default %}Fallback{% endslot %}
            {% slot footer %}Footer{% endslot %}
            {% endmacro %}
            {% call card(title: product.title) %}
            Body
            {% fill footer %}Price{% endfill %}
            {% endcall %}
            """
        )

        #expect(analysis.manifest.requiresExtendedProfile)
        #expect(analysis.manifest.activeTags.contains("slot"))
        #expect(analysis.manifest.activeTags.contains("fill"))
        #expect(analysis.manifest.macroDefinitions.first?.slots.map(\.name) == ["default", "footer"])
        #expect(analysis.manifest.macroCalls.first?.filledSlots == ["footer"])
        #expect(analysis.manifest.macroCalls.first?.hasBlockBody == true)
    }

    @Test("Shopify-compatible profile rejects Wave 17 block call syntax")
    func shopifyCompatibleProfileRejectsWave17Syntax() async throws {
        let environment = LiquidEnvironment(profile: .shopifyCompatible, sandboxPolicy: .trustedLocal)

        do {
            _ = try await environment.render(
                template: """
                {% macro card() %}{% slot default %}Fallback{% endslot %}{% endmacro %}
                {% call card() %}Body{% endcall %}
                """
            )
            Issue.record("Expected the shopify-compatible profile to reject Wave 17 syntax")
        } catch let error as LiquidEnvironmentError {
            guard case .unsupportedProfileFeature = error else {
                Issue.record("Expected unsupportedProfileFeature, got \(error)")
                return
            }
        } catch {
            Issue.record("Expected LiquidEnvironmentError, got \(error)")
        }
    }

    @Test("Path-based input contracts inject nested defaults into objects and arrays")
    func pathBasedInputContractsInjectNestedDefaults() async throws {
        let environment = LiquidEnvironment()
        let template = """
        {% input user.name: string = "Guest" %}
        {% input items[].title: string = "Untitled" %}
        {{ user.name }}|
        {% for item in items %}{{ item.title }}|{% endfor %}
        """

        let rendered = try await environment.render(
            template: template,
            context: [
                "items": [
                    ["id": 1],
                    ["title": "Ready"]
                ]
            ]
        )

        #expect(rendered.contains("Guest|"))
        #expect(rendered.contains("Untitled|"))
        #expect(rendered.contains("Ready|"))
    }

    @Test("Path-based input contracts report missing nested fields")
    func pathBasedInputContractsReportMissingNestedFields() async throws {
        let environment = LiquidEnvironment()
        let template = """
        {% input user.name: string %}
        {% input items[].title: string %}
        {{ user.name }}
        """

        do {
            _ = try await environment.render(
                template: template,
                context: [
                    "user": [:],
                    "items": [
                        ["title": "One"],
                        [:]
                    ]
                ]
            )
            Issue.record("Expected nested required input validation to fail")
        } catch let error as LiquidEnvironmentError {
            guard case .validationFailure(let message) = error else {
                Issue.record("Expected validationFailure, got \(error)")
                return
            }
            #expect(message.contains("user.name"))
            #expect(message.contains("items[1].title"))
        } catch {
            Issue.record("Expected LiquidEnvironmentError, got \(error)")
        }
    }

    @Test("Template analysis reports indexed missing paths for array contracts")
    func templateAnalysisReportsIndexedMissingPathsForArrayContracts() async {
        let environment = LiquidEnvironment()
        let analysis = await environment.analyzeTemplate(
            """
            {% input items[].title: string %}
            """,
            context: [
                "items": [
                    ["title": "One"],
                    [:]
                ]
            ]
        )

        #expect(analysis.missingRequiredInputs == ["items[1].title"])
        #expect(analysis.validationErrors.contains("Missing required input 'items[1].title'."))
    }

    @Test("Path-based input contracts report indexed type mismatches")
    func pathBasedInputContractsReportIndexedTypeMismatches() async throws {
        let environment = LiquidEnvironment()
        let template = """
        {% input items[].title: string %}
        """

        do {
            _ = try await environment.render(
                template: template,
                context: [
                    "items": [
                        ["title": "One"],
                        ["title": 7]
                    ]
                ]
            )
            Issue.record("Expected indexed type mismatch validation to fail")
        } catch let error as LiquidEnvironmentError {
            guard case .validationFailure(let message) = error else {
                Issue.record("Expected validationFailure, got \(error)")
                return
            }
            #expect(message.contains("Input 'items[1].title' expected string but received number."))
        } catch {
            Issue.record("Expected LiquidEnvironmentError, got \(error)")
        }
    }

    @Test("Path-based input contracts report container mismatches at the failing path")
    func pathBasedInputContractsReportContainerMismatchesAtFailingPath() async throws {
        let environment = LiquidEnvironment()
        let template = """
        {% input user.name: string %}
        """

        do {
            _ = try await environment.render(
                template: template,
                context: [
                    "user": "Ada"
                ]
            )
            Issue.record("Expected container mismatch validation to fail")
        } catch let error as LiquidEnvironmentError {
            guard case .validationFailure(let message) = error else {
                Issue.record("Expected validationFailure, got \(error)")
                return
            }
            #expect(message.contains("Input 'user' expected object but received string."))
        } catch {
            Issue.record("Expected LiquidEnvironmentError, got \(error)")
        }
    }

    @Test("Strict object contracts reject undeclared keys at concrete paths")
    func strictObjectContractsRejectUndeclaredKeysAtConcretePaths() async throws {
        let environment = LiquidEnvironment()
        let template = """
        {% input user: object strict %}
        {% input user.name: string %}
        {{ user.name }}
        """

        do {
            _ = try await environment.render(
                template: template,
                context: [
                    "user": [
                        "name": "Ada",
                        "role": "admin"
                    ]
                ]
            )
            Issue.record("Expected strict object contract validation to fail")
        } catch let error as LiquidEnvironmentError {
            guard case .validationFailure(let message) = error else {
                Issue.record("Expected validationFailure, got \(error)")
                return
            }
            #expect(message.contains("Input 'user.role' is not declared by strict contract 'user'."))
        } catch {
            Issue.record("Expected LiquidEnvironmentError, got \(error)")
        }
    }

    @Test("Strict array-element object contracts reject indexed undeclared keys")
    func strictArrayElementObjectContractsRejectIndexedUndeclaredKeys() async {
        let environment = LiquidEnvironment()
        let analysis = await environment.analyzeTemplate(
            """
            {% input items[]: object strict %}
            {% input items[].title: string %}
            """,
            context: [
                "items": [
                    [
                        "title": "Ready",
                        "price": "9.99"
                    ],
                    [
                        "title": "Done"
                    ]
                ]
            ]
        )

        #expect(analysis.missingRequiredInputs.isEmpty)
        #expect(analysis.validationErrors.contains("Input 'items[0].price' is not declared by strict contract 'items[]'."))
    }

    @Test("Open-by-default object contracts still allow undeclared keys")
    func openByDefaultObjectContractsStillAllowUndeclaredKeys() async throws {
        let environment = LiquidEnvironment()
        let template = """
        {% input user: object %}
        {% input user.name: string %}
        {{ user.name }}
        """

        let rendered = try await environment.render(
            template: template,
            context: [
                "user": [
                    "name": "Ada",
                    "role": "admin"
                ]
            ]
        )

        #expect(rendered.contains("Ada"))
    }

    @Test("Template analysis reports indexed type mismatches for array contracts")
    func templateAnalysisReportsIndexedTypeMismatchesForArrayContracts() async {
        let environment = LiquidEnvironment()
        let analysis = await environment.analyzeTemplate(
            """
            {% input items[].title: string %}
            """,
            context: [
                "items": [
                    ["title": "One"],
                    ["title": 7]
                ]
            ]
        )

        #expect(analysis.missingRequiredInputs.isEmpty)
        #expect(analysis.validationErrors.contains("Input 'items[1].title' expected string but received number."))
    }

    @Test("Template analysis exposes path-based input declarations")
    func templateAnalysisExposesPathBasedInputDeclarations() async {
        let environment = LiquidEnvironment()
        let analysis = await environment.analyzeTemplate(
            """
            {% input user.name: string %}
            {% input items[].title: string = "Untitled" %}
            """,
            context: [
                "items": [
                    ["title": "One"],
                    [:]
                ]
            ]
        )

        #expect(analysis.manifest.declaredInputs.map(\.name) == ["items[].title", "user.name"])
        #expect(analysis.manifest.contractDefaults == ["items[].title"])
        #expect(analysis.missingRequiredInputs == ["user.name"])
    }

    @Test("Template analysis exposes strict declared input metadata")
    func templateAnalysisExposesStrictDeclaredInputMetadata() async {
        let environment = LiquidEnvironment()
        let analysis = await environment.analyzeTemplate(
            """
            {% input user: object strict %}
            {% input user.name: string %}
            """
        )

        let userField = analysis.manifest.declaredInputs.first { $0.name == "user" }
        let nameField = analysis.manifest.declaredInputs.first { $0.name == "user.name" }

        #expect(userField?.strict == true)
        #expect(nameField?.strict == false)
    }

    @Test("Template analysis exposes unresolved slot diagnostics")
    func templateAnalysisExposesUnresolvedSlotDiagnostics() async {
        let environment = LiquidEnvironment()
        let analysis = await environment.analyzeTemplate(
            """
            {% macro card(title) %}
            <article>
              <h1>{{ title }}</h1>
              {% slot default %}Fallback body{% endslot %}
              {% slot footer %}{% endslot %}
            </article>
            {% endmacro %}
            {% call card(title: "Wave 17") %}
            Body
            {% endcall %}
            {{ card(title: "Wave 17") }}
            """
        )

        #expect(analysis.validationErrors.isEmpty)
        #expect(
            analysis.macroDiagnostics.contains(
                "Macro call 'card' leaves required slot 'footer' unresolved."
            )
        )
        #expect(
            analysis.macroDiagnostics.contains(
                "Expression-call macro 'card' cannot satisfy required slot 'footer'."
            )
        )
    }

    @Test("File-backed imported macros participate in static slot diagnostics")
    func fileBackedImportedMacrosParticipateInStaticSlotDiagnostics() async throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let macrosURL = tempDirectory.appendingPathComponent("macros.liquid")
        try """
        {% macro card(title) %}
        <article>
          <h1>{{ title }}</h1>
          {% slot default %}Fallback{% endslot %}
          {% slot footer %}{% endslot %}
        </article>
        {% endmacro %}
        """.write(to: macrosURL, atomically: true, encoding: .utf8)

        let environment = LiquidEnvironment()
        let analysis = await environment.analyzeTemplate(
            """
            {% import "macros.liquid" as ui %}
            {% call ui.card(title: "Wave 17") %}Body{% endcall %}
            {{ ui.card(title: "Wave 17") }}
            """,
            templatePath: tempDirectory.appendingPathComponent("main.liquid").path,
            baseDirectory: tempDirectory
        )

        #expect(analysis.validationErrors.isEmpty)
        #expect(
            analysis.macroDiagnostics.contains(
                "Macro call 'ui.card' leaves required slot 'footer' unresolved."
            )
        )
        #expect(
            analysis.macroDiagnostics.contains(
                "Expression-call macro 'ui.card' cannot satisfy required slot 'footer'."
            )
        )
    }

    @Test("File-backed imported macros validate parameters and unresolved imports")
    func fileBackedImportedMacrosValidateParametersAndUnresolvedImports() async throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let macrosURL = tempDirectory.appendingPathComponent("macros.liquid")
        try """
        {% macro badge(label) %}<span>{{ label }}</span>{% endmacro %}
        """.write(to: macrosURL, atomically: true, encoding: .utf8)

        let environment = LiquidEnvironment()
        let importedAnalysis = await environment.analyzeTemplate(
            """
            {% from "macros.liquid" import badge %}
            {{ badge(title: "Wave 17") }}
            """,
            templatePath: tempDirectory.appendingPathComponent("main.liquid").path,
            baseDirectory: tempDirectory
        )
        #expect(importedAnalysis.validationErrors.contains("Unknown macro parameter 'title' for badge"))

        let missingImportAnalysis = await environment.analyzeTemplate(
            """
            {% import "missing-macros.liquid" as ui %}
            {{ ui.card(title: "Wave 17") }}
            """,
            templatePath: tempDirectory.appendingPathComponent("missing-main.liquid").path,
            baseDirectory: tempDirectory
        )
        #expect(
            missingImportAnalysis.macroDiagnostics.contains(
                "Macro import 'missing-macros.liquid' could not be resolved."
            )
        )
        #expect(!missingImportAnalysis.validationErrors.contains("Undefined macro: ui.card"))
    }

    @Test("Transitive imported macros participate in static diagnostics")
    func transitiveImportedMacrosParticipateInStaticDiagnostics() async throws {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let sharedURL = tempDirectory.appendingPathComponent("shared.liquid")
        try """
        {% macro card(title) %}
        <article>
          <h1>{{ title }}</h1>
          {% slot footer %}{% endslot %}
        </article>
        {% endmacro %}
        """.write(to: sharedURL, atomically: true, encoding: .utf8)

        let macrosURL = tempDirectory.appendingPathComponent("macros.liquid")
        try """
        {% import "shared.liquid" as shared %}
        """.write(to: macrosURL, atomically: true, encoding: .utf8)

        let environment = LiquidEnvironment()
        let analysis = await environment.analyzeTemplate(
            """
            {% import "macros.liquid" as ui %}
            {% call ui.shared.card(title: "Wave 17") %}{% endcall %}
            {{ ui.shared.card(title: "Wave 17") }}
            """,
            templatePath: tempDirectory.appendingPathComponent("main.liquid").path,
            baseDirectory: tempDirectory
        )

        #expect(analysis.validationErrors.isEmpty)
        #expect(
            analysis.macroDiagnostics.contains(
                "Macro call 'ui.shared.card' leaves required slot 'footer' unresolved."
            )
        )
        #expect(
            analysis.macroDiagnostics.contains(
                "Expression-call macro 'ui.shared.card' cannot satisfy required slot 'footer'."
            )
        )
    }

    @Test("Template analysis validates statically provable block-call errors early")
    func templateAnalysisValidatesProvableBlockCallErrorsEarly() async throws {
        let environment = LiquidEnvironment()
        let analysis = await environment.analyzeTemplate(
            """
            {% macro card(title) %}
            <article>
              <h1>{{ title }}</h1>
              {% slot footer %}Footer{% endslot %}
            </article>
            {% endmacro %}
            {% call card(title: "Wave 17") %}
            Body
            {% fill aside %}Oops{% endfill %}
            {% endcall %}
            """
        )

        #expect(
            analysis.validationErrors.contains("Macro card does not declare a default slot")
        )
        #expect(
            analysis.validationErrors.contains("Unknown fill 'aside' for macro card")
        )

        do {
            _ = try await environment.render(
                template: """
                {% macro card(title) %}
                <article>
                  <h1>{{ title }}</h1>
                  {% slot footer %}Footer{% endslot %}
                </article>
                {% endmacro %}
                {% call card(title: "Wave 17") %}
                Body
                {% fill aside %}Oops{% endfill %}
                {% endcall %}
                """
            )
            Issue.record("Expected early validation failure for invalid block call")
        } catch let error as LiquidEnvironmentError {
            guard case .validationFailure(let message) = error else {
                Issue.record("Expected validationFailure, got \(error)")
                return
            }
            #expect(message.contains("does not declare a default slot"))
            #expect(message.contains("Unknown fill 'aside'"))
        } catch {
            Issue.record("Expected LiquidEnvironmentError, got \(error)")
        }
    }
}
