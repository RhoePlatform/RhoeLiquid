import Testing
@testable import LiquidRenderer
@testable import LiquidCore

@Suite("LiquidRenderer Module Tests")
struct RendererTests {
    @Test("Empty rendering")
    func emptyRendering() async throws {
        let renderer = Renderer()
        let result = try await renderer.render(.template([]))
        #expect(result == "")
    }

    @Test("Compiled templates preserve forloop access after static access inlining")
    func compiledTemplatesPreserveForloopAccess() async throws {
        let compiled = TemplateCompiler().compile(
            .template([
                .for(
                    variable: "item",
                    in: .variable("items"),
                    body: [
                        .output(
                            .access(
                                expr: .variable("forloop"),
                                key: .literal(.string("index"))
                            )
                        ),
                        .text(":"),
                        .output(.variable("item"))
                    ],
                    empty: nil,
                    params: ForParams()
                )
            ])
        )

        let renderer = Renderer()
        let result = try await renderer.render(compiled, with: [
            "items": ["A", "B", "C"]
        ])

        #expect(result == "1:A2:B3:C")
    }

    @Test("Compiled templates reuse static loop body segments")
    func compiledTemplatesReuseStaticLoopBodySegments() async throws {
        let compiled = TemplateCompiler().compile(
            .template([
                .for(
                    variable: "item",
                    in: .variable("items"),
                    body: [
                        .text("<li>"),
                        .raw("Variant"),
                        .text("</li>")
                    ],
                    empty: nil,
                    params: ForParams()
                )
            ])
        )

        let renderer = Renderer()
        let result = try await renderer.render(compiled, with: [
            "items": ["A", "B", "C"]
        ])

        #expect(result == "<li>Variant</li><li>Variant</li><li>Variant</li>")
    }

    @Test("Compiled templates reuse double-output loop render plans")
    func compiledTemplatesReuseDoubleOutputLoopRenderPlans() async throws {
        let compiled = TemplateCompiler().compile(
            .template([
                .for(
                    variable: "variant",
                    in: .variable("variants"),
                    body: [
                        .text("<li>"),
                        .output(
                            .access(
                                expr: .variable("variant"),
                                key: .literal(.string("name"))
                            )
                        ),
                        .text(" - "),
                        .output(
                            .filtered(
                                expr: .access(
                                    expr: .variable("variant"),
                                    key: .literal(.string("price"))
                                ),
                                filters: [
                                    Filter(name: "round", arguments: [.literal(.number(2))])
                                ]
                            )
                        ),
                        .text("</li>")
                    ],
                    empty: nil,
                    params: ForParams()
                )
            ])
        )

        let renderer = Renderer()
        let result = try await renderer.render(compiled, with: [
            "variants": [
                ["name": "Alpha", "price": 9.995],
                ["name": "Beta", "price": 12.345]
            ]
        ])

        #expect(result == "<li>Alpha - 9.99</li><li>Beta - 12.35</li>")
    }

    @Test("OptimizedRenderer enforces configured cache memory budgets")
    func optimizedRendererEnforcesCacheMemoryBudgets() async throws {
        let renderer = OptimizedRenderer(
            cacheConfiguration: CompiledTemplateCache.CacheConfiguration.active(
                maxCacheSize: 10,
                maxMemoryUsage: 1,
                compilationThreshold: 2
            )
        )

        _ = try await renderer.render(source: "Hello {{ name }}", with: ["name": "Ada"])
        _ = try await renderer.render(source: "Bye {{ name }}", with: ["name": "Ada"])

        let stats = renderer.statistics
        let cacheStats = try #require(stats.cacheStats)

        #expect(cacheStats.cachedTemplates == 1)
        #expect(cacheStats.evictions >= 1)
    }

    @Test("Balanced optimizer profile changes active runtime settings")
    func balancedOptimizerProfileChangesActiveRuntimeSettings() {
        #expect(ASTOptimizer.OptimizationOptions.aggressive.enableTemplateInlining)
        #expect(!ASTOptimizer.OptimizationOptions.balanced.enableTemplateInlining)
        #expect(!ASTOptimizer.OptimizationOptions.conservative.enableTemplateInlining)
        #expect(ASTOptimizer.OptimizationOptions.balanced.enableDeadCodeElimination)
        #expect(ASTOptimizer.OptimizationOptions.balanced.enableLoopOptimization)
    }

    @Test("Active cache configuration factory keeps live fields configurable")
    func activeCacheConfigurationFactoryKeepsLiveFieldsConfigurable() {
        let configuration = CompiledTemplateCache.CacheConfiguration.active(
            maxCacheSize: 42,
            maxMemoryUsage: 2_048,
            compilationThreshold: 3
        )

        #expect(configuration.maxCacheSize == 42)
        #expect(configuration.maxMemoryUsage == 2_048)
        #expect(configuration.compilationThreshold == 3)
    }

    @Test("Unknown macro call expressions fail explicitly")
    func unknownMacroCallExpressionsFailExplicitly() async throws {
        let renderer = Renderer()
        let ast = ASTNode.template([
            .output(
                .call(
                    name: "sum",
                    arguments: [
                        CallArgument(value: .literal(.number(1))),
                        CallArgument(value: .literal(.number(2)))
                    ]
                )
            )
        ])

        do {
            _ = try await renderer.render(ast)
            Issue.record("Expected unknown macro call expressions to fail explicitly")
        } catch let error as RenderError {
            guard case .custom(let message, _) = error else {
                Issue.record("Expected a custom render error for unknown macro call expressions")
                return
            }
            #expect(message.contains("Undefined macro"))
            #expect(message.contains("sum"))
        } catch {
            Issue.record("Expected a RenderError, got \(error)")
        }
    }

    @Test("Macro call expressions render against AST-defined macros")
    func macroCallExpressionsRenderAgainstASTDefinedMacros() async throws {
        let renderer = Renderer()
        let ast = ASTNode.template([
            .macro(
                signature: MacroSignatureNode(
                    name: "card",
                    parameters: [
                        MacroParameterNode(name: "title")
                    ]
                ),
                body: [
                    .text("<h1>"),
                    .output(.variable("title")),
                    .text("</h1>")
                ]
            ),
            .output(
                .call(
                    name: "card",
                    arguments: [
                        CallArgument(label: "title", value: .literal(.string("Wave 16")))
                    ]
                )
            )
        ])

        let result = try await renderer.render(ast)
        #expect(result == "<h1>Wave 16</h1>")
    }
}
