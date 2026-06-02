import Testing
@testable import LiquidCore

@Suite("Expression Analysis Tests")
struct ExpressionAnalysisTests {
    @Test("Static variable path captures nested access chains")
    func staticVariablePathCapturesNestedAccess() {
        let expression = Expression.access(
            expr: .access(
                expr: .variable("product"),
                key: .literal(.string("variants"))
            ),
            key: .literal(.string("size"))
        )

        #expect(expression.staticVariablePath == "product.variants.size")
        #expect(expression.staticVariablePathComponents == ["product", "variants", "size"])
    }

    @Test("Template compiler records full static access paths")
    func templateCompilerRecordsFullStaticAccessPaths() {
        let expression = Expression.access(
            expr: .variable("product"),
            key: .literal(.string("title"))
        )
        let ast = ASTNode.template([.output(expression)])
        let compiled = TemplateCompiler().compile(ast)

        let pattern = compiled.variableAccess["product.title"]
        #expect(pattern?.path == ["product", "title"])
        #expect(pattern?.frequency == 1)
    }

    @Test("Template compiler records static filter argument paths")
    func templateCompilerRecordsStaticFilterArgumentPaths() {
        let expression = Expression.filtered(
            expr: .variable("subtotal"),
            filters: [
                Filter(
                    name: "plus",
                    arguments: [
                        .access(
                            expr: .access(
                                expr: .variable("pricing"),
                                key: .literal(.string("tax"))
                            ),
                            key: .literal(.string("amount"))
                        )
                    ]
                )
            ]
        )
        let compiled = TemplateCompiler().compile(.template([.output(expression)]))

        #expect(compiled.variableAccess["subtotal"]?.path == ["subtotal"])
        #expect(compiled.variableAccess["pricing.tax.amount"]?.path == ["pricing", "tax", "amount"])
    }

    @Test("Compiled templates cache static capacity hints")
    func compiledTemplatesCacheStaticCapacityHints() {
        let compiled = CompiledTemplate(
            optimizedAST: .template([]),
            staticSegments: ["Hello", " ", "world"]
        )

        #expect(compiled.staticCapacityHint == "Hello world".utf8.count)
    }

    @Test("Filters capture single integer literal arguments for hot-path reuse")
    func filtersCaptureSingleIntegerLiteralArguments() {
        let filter = Filter(
            name: "round",
            arguments: [.literal(.number(2))]
        )

        #expect(filter.singleLiteralIntegerArgument == 2)
    }

    @Test("Built-in filter dispatch hints stay available for hot parser paths")
    func builtinFilterDispatchHintsRemainAvailable() {
        let round = Filter(name: "round", arguments: [.literal(.number(2))])
        let upcase = Filter(name: "upcase")
        let custom = Filter(name: "custom_transform")

        #expect(round.builtinKind == .round)
        #expect(upcase.builtinKind == .upcase)
        #expect(custom.builtinKind == nil)
    }

    @Test("Template compiler inlines static access chains into dotted variable expressions")
    func templateCompilerInlinesStaticAccessChains() {
        let expression = Expression.access(
            expr: .access(
                expr: .variable("product"),
                key: .literal(.string("pricing"))
            ),
            key: .literal(.string("amount"))
        )
        let compiled = TemplateCompiler().compile(.template([.output(expression)]))

        guard case .template(let nodes) = compiled.optimizedAST,
              case .output(let optimizedExpression) = nodes[0],
              case .variable(let name) = optimizedExpression else {
            Issue.record("Expected the optimized AST to rewrite the static access chain into a dotted variable")
            return
        }

        #expect(name.string == "product.pricing.amount")
    }

    @Test("Template compiler can skip loop object analysis when loop bodies cannot observe loop metadata")
    func templateCompilerCanSkipLoopObjectAnalysis() {
        let ast = ASTNode.template([
            .for(
                variable: "variant",
                in: .access(expr: .variable("product"), key: .literal(.string("variants"))),
                body: [
                    .output(
                        .access(expr: .variable("variant"), key: .literal(.string("name")))
                    )
                ],
                empty: nil,
                params: ForParams()
            ),
            .tablerow(
                variable: "cell",
                in: .variable("items"),
                body: [
                    .output(.variable("cell"))
                ],
                params: TableRowParams(cols: 2)
            )
        ])

        let compiled = TemplateCompiler().compile(ast)

        #expect(compiled.performanceHints.canSkipForloopObjectAnalysis)
        #expect(compiled.performanceHints.canSkipTableRowLoopObjectAnalysis)
    }

    @Test("Template compiler captures static loop body segments")
    func templateCompilerCapturesStaticLoopBodySegments() {
        let ast = ASTNode.template([
            .for(
                variable: "variant",
                in: .variable("variants"),
                body: [
                    .text("<li>"),
                    .raw("Variant"),
                    .text("</li>")
                ],
                empty: nil,
                params: ForParams()
            ),
            .tablerow(
                variable: "cell",
                in: .variable("items"),
                body: [
                    .text("<span>"),
                    .raw("Value"),
                    .text("</span>")
                ],
                params: TableRowParams(cols: 2)
            )
        ])

        let compiled = TemplateCompiler().compile(ast)

        guard case .template(let nodes) = compiled.optimizedAST,
              case .for(variable: _, in: _, body: _, empty: _, params: let forParams) = nodes[0],
              case .tablerow(variable: _, in: _, body: _, params: let tableRowParams) = nodes[1] else {
            Issue.record("Expected optimized loop nodes with captured static body segments")
            return
        }

        #expect(forParams.staticBodySegment?.string == "<li>Variant</li>")
        #expect(tableRowParams.staticBodySegment?.string == "<span>Value</span>")
    }

    @Test("Template compiler avoids static loop body segments for dynamic loop bodies")
    func templateCompilerAvoidsStaticLoopBodySegmentsForDynamicBodies() {
        let ast = ASTNode.template([
            .for(
                variable: "variant",
                in: .variable("variants"),
                body: [
                    .text("<li>"),
                    .output(.variable("variant")),
                    .text("</li>")
                ],
                empty: nil,
                params: ForParams()
            )
        ])

        let compiled = TemplateCompiler().compile(ast)

        guard case .template(let nodes) = compiled.optimizedAST,
              case .for(variable: _, in: _, body: _, empty: _, params: let params) = nodes[0] else {
            Issue.record("Expected optimized for node")
            return
        }

        #expect(params.staticBodySegment == nil)
    }

    @Test("Template compiler captures single-output loop render plans")
    func templateCompilerCapturesSingleOutputLoopRenderPlans() {
        let ast = ASTNode.template([
            .for(
                variable: "variant",
                in: .variable("variants"),
                body: [
                    .text("<li>"),
                    .output(.variable("variant")),
                    .text("</li>")
                ],
                empty: nil,
                params: ForParams()
            )
        ])

        let compiled = TemplateCompiler().compile(ast)

        guard case .template(let nodes) = compiled.optimizedAST,
              case .for(variable: _, in: _, body: _, empty: _, params: let params) = nodes[0],
              case .single(let prefix, let expression, let suffix)? = params.renderPlan else {
            Issue.record("Expected a single-output render plan on the compiled loop")
            return
        }

        #expect(prefix.string == "<li>")
        #expect(expression == .variable("variant"))
        #expect(suffix.string == "</li>")
    }

    @Test("Template compiler captures double-output loop render plans")
    func templateCompilerCapturesDoubleOutputLoopRenderPlans() {
        let ast = ASTNode.template([
            .for(
                variable: "variant",
                in: .variable("variants"),
                body: [
                    .text("<li>"),
                    .output(.access(expr: .variable("variant"), key: .literal(.string("name")))),
                    .text(" - "),
                    .output(.access(expr: .variable("variant"), key: .literal(.string("price")))),
                    .text("</li>")
                ],
                empty: nil,
                params: ForParams()
            )
        ])

        let compiled = TemplateCompiler().compile(ast)

        guard case .template(let nodes) = compiled.optimizedAST,
              case .for(variable: _, in: _, body: _, empty: _, params: let params) = nodes[0],
              case .double(let prefix, let first, let middle, let second, let suffix)? = params.renderPlan else {
            Issue.record("Expected a double-output render plan on the compiled loop")
            return
        }

        #expect(prefix.string == "<li>")
        #expect(first == .variable("variant.name"))
        #expect(middle.string == " - ")
        #expect(second == .variable("variant.price"))
        #expect(suffix.string == "</li>")
    }

    @Test("Template compiler keeps loop object analysis when loop bodies may need implicit loop metadata")
    func templateCompilerKeepsLoopObjectAnalysisWhenNeeded() {
        let ast = ASTNode.template([
            .for(
                variable: "variant",
                in: .variable("variants"),
                body: [
                    .include(template: "snippet", with: nil, as: nil)
                ],
                empty: nil,
                params: ForParams()
            ),
            .tablerow(
                variable: "cell",
                in: .variable("items"),
                body: [
                    .output(
                        .access(
                            expr: .variable("tablerowloop"),
                            key: .literal(.string("index"))
                        )
                    )
                ],
                params: TableRowParams(cols: 2)
            )
        ])

        let compiled = TemplateCompiler().compile(ast)

        #expect(!compiled.performanceHints.canSkipForloopObjectAnalysis)
        #expect(!compiled.performanceHints.canSkipTableRowLoopObjectAnalysis)
    }
}
