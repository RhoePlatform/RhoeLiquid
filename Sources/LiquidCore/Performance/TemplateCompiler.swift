//
//  TemplateCompiler.swift
//  LiquidCore
//
//  High-performance template compiler with advanced optimizations
//

import Foundation

/// Advanced template compiler that applies optimization passes
/// for maximum rendering performance
public struct TemplateCompiler: Sendable {
    
    /// Compilation options
    public struct Options: Sendable {
        public let enableConstantFolding: Bool
        public let enableDeadCodeElimination: Bool
        public let enableInlineOptimization: Bool
        public let enableVariableHoisting: Bool
        
        public init(
            enableConstantFolding: Bool = true,
            enableDeadCodeElimination: Bool = true,
            enableInlineOptimization: Bool = true,
            enableVariableHoisting: Bool = true
        ) {
            self.enableConstantFolding = enableConstantFolding
            self.enableDeadCodeElimination = enableDeadCodeElimination
            self.enableInlineOptimization = enableInlineOptimization
            self.enableVariableHoisting = enableVariableHoisting
        }
        
        public static let aggressive = Options(
            enableConstantFolding: true,
            enableDeadCodeElimination: true,
            enableInlineOptimization: true,
            enableVariableHoisting: true
        )
    }
    
    private let options: Options
    
    public init(options: Options = .aggressive) {
        self.options = options
    }
    
    /// Compiles a template AST into an optimized representation
    public func compile(_ ast: ASTNode) -> CompiledTemplate {
        var optimizedAST = ast
        var staticSegments: [String] = []
        var variableAccess: [String: AccessPattern] = [:]
        var filterUsage: [String: Int] = [:]
        var performanceHints = PerformanceHints()
        
        // Analysis Phase
        let analysis = analyzeAST(ast)
        variableAccess = analysis.variableAccess
        filterUsage = analysis.filterUsage
        performanceHints = analysis.performanceHints
        
        // Optimization Passes
        if options.enableConstantFolding {
            optimizedAST = constantFolding(optimizedAST)
        }
        
        if options.enableDeadCodeElimination {
            optimizedAST = eliminateDeadCode(optimizedAST)
        }
        
        if options.enableInlineOptimization {
            optimizedAST = inlineOptimization(optimizedAST)
        }
        
        if options.enableVariableHoisting {
            optimizedAST = hoistVariables(optimizedAST)
        }
        
        // Extract static segments
        staticSegments = extractStaticSegments(optimizedAST)
        
        return CompiledTemplate(
            optimizedAST: optimizedAST,
            staticSegments: staticSegments,
            variableAccess: variableAccess,
            filterUsage: filterUsage,
            performanceHints: performanceHints,
            complexityScore: analysis.complexityScore
        )
    }
    
    // MARK: - Analysis Phase
    
    private func analyzeAST(_ ast: ASTNode) -> AnalysisResult {
        var result = AnalysisResult()
        analyzeNode(
            ast,
            result: &result,
            depth: 0,
            insideForBody: false,
            insideTableRowBody: false
        )
        return result
    }
    
    private func analyzeNode(
        _ node: ASTNode,
        result: inout AnalysisResult,
        depth: Int,
        insideForBody: Bool,
        insideTableRowBody: Bool
    ) {
        result.maxDepth = max(result.maxDepth, depth)
        result.complexityScore += 1

        if insideForBody,
           !result.requiresForloopObjectAnalysis,
           (nodeRequiresImplicitLoopObject(node) || nodeReferencesVariable(node, named: "forloop")) {
            result.requiresForloopObjectAnalysis = true
        }

        if insideTableRowBody,
           !result.requiresTableRowLoopObjectAnalysis,
           (nodeRequiresImplicitLoopObject(node) || nodeReferencesVariable(node, named: "tablerowloop")) {
            result.requiresTableRowLoopObjectAnalysis = true
        }
        
        switch node {
        case .template(let nodes):
            for child in nodes {
                analyzeNode(
                    child,
                    result: &result,
                    depth: depth,
                    insideForBody: insideForBody,
                    insideTableRowBody: insideTableRowBody
                )
            }

        case .output(let expr):
            analyzeExpression(expr, result: &result)
            
        case .text(let content):
            result.staticContentLength += content.string.count
            
        case .if(let condition, let thenNodes, let elsifBranches, let elseNodes):
            analyzeExpression(condition, result: &result)
            for child in thenNodes {
                analyzeNode(
                    child,
                    result: &result,
                    depth: depth + 1,
                    insideForBody: insideForBody,
                    insideTableRowBody: insideTableRowBody
                )
            }
            for (cond, nodes) in elsifBranches {
                analyzeExpression(cond, result: &result)
                for child in nodes {
                    analyzeNode(
                        child,
                        result: &result,
                        depth: depth + 1,
                        insideForBody: insideForBody,
                        insideTableRowBody: insideTableRowBody
                    )
                }
            }
            if let elseNodes {
                for child in elseNodes {
                    analyzeNode(
                        child,
                        result: &result,
                        depth: depth + 1,
                        insideForBody: insideForBody,
                        insideTableRowBody: insideTableRowBody
                    )
                }
            }
            result.complexityScore += 5 // Control flow adds complexity
            
        case .for(_, let collection, let body, let empty, _):
            analyzeExpression(collection, result: &result)
            for child in body {
                analyzeNode(
                    child,
                    result: &result,
                    depth: depth + 1,
                    insideForBody: true,
                    insideTableRowBody: insideTableRowBody
                )
            }
            if let empty {
                for child in empty {
                    analyzeNode(
                        child,
                        result: &result,
                        depth: depth + 1,
                        insideForBody: insideForBody,
                        insideTableRowBody: insideTableRowBody
                    )
                }
            }
            result.hasLoops = true
            result.loopDepth = max(result.loopDepth, depth + 1)
            result.complexityScore += 10 // Loops are expensive
            
        case .case(let value, let whens, let elseBranch):
            analyzeExpression(value, result: &result)
            for (expr, nodes) in whens {
                analyzeExpression(expr, result: &result)
                for child in nodes {
                    analyzeNode(
                        child,
                        result: &result,
                        depth: depth + 1,
                        insideForBody: insideForBody,
                        insideTableRowBody: insideTableRowBody
                    )
                }
            }
            if let elseBranch {
                for child in elseBranch {
                    analyzeNode(
                        child,
                        result: &result,
                        depth: depth + 1,
                        insideForBody: insideForBody,
                        insideTableRowBody: insideTableRowBody
                    )
                }
            }
            result.complexityScore += 3

        case .unless(let condition, let thenNodes, let elseNodes):
            analyzeExpression(condition, result: &result)
            for child in thenNodes {
                analyzeNode(
                    child,
                    result: &result,
                    depth: depth + 1,
                    insideForBody: insideForBody,
                    insideTableRowBody: insideTableRowBody
                )
            }
            if let elseNodes {
                for child in elseNodes {
                    analyzeNode(
                        child,
                        result: &result,
                        depth: depth + 1,
                        insideForBody: insideForBody,
                        insideTableRowBody: insideTableRowBody
                    )
                }
            }
            result.complexityScore += 5

        case .tablerow(_, let collection, let body, _):
            analyzeExpression(collection, result: &result)
            for child in body {
                analyzeNode(
                    child,
                    result: &result,
                    depth: depth + 1,
                    insideForBody: insideForBody,
                    insideTableRowBody: true
                )
            }
            result.hasLoops = true
            result.loopDepth = max(result.loopDepth, depth + 1)
            result.complexityScore += 10

        case .assign(_, let value):
            analyzeExpression(value, result: &result)

        case .cycle(_, let items):
            for item in items {
                analyzeExpression(item, result: &result)
            }

        case .capture(_, let body), .block(_, let body), .liquid(let body):
            for child in body {
                analyzeNode(
                    child,
                    result: &result,
                    depth: depth + 1,
                    insideForBody: insideForBody,
                    insideTableRowBody: insideTableRowBody
                )
            }

        case .echo(let expression):
            analyzeExpression(expression, result: &result)

        case .debug(let expression):
            if let expression {
                analyzeExpression(expression, result: &result)
            }

        case .pipeline(let input, let operations):
            analyzeExpression(input, result: &result)
            for operation in operations {
                if case .filter(let filter) = operation.operation {
                    let filterName = filter.name.string
                    result.filterUsage[filterName] = (result.filterUsage[filterName] ?? 0) + 1
                    for argument in filter.arguments {
                        analyzeExpression(argument, result: &result)
                    }
                }
            }

        case .include(_, let withValues, _):
            if let withValues {
                for value in withValues.values {
                    analyzeExpression(value, result: &result)
                }
            }

        case .renderBlock(_, let params):
            for value in params.values {
                analyzeExpression(value, result: &result)
            }

        case .registeredCustomTag(_, _, let body):
            if let body {
                for child in body.nodes {
                    analyzeNode(
                        child,
                        result: &result,
                        depth: depth + 1,
                        insideForBody: insideForBody,
                        insideTableRowBody: insideTableRowBody
                    )
                }
            }
            
        default:
            // Handle other node types
            break
        }
    }
    
    private func analyzeExpression(_ expr: LiquidCore.Expression, result: inout AnalysisResult) {
        if let staticPath = staticVariablePathInfo(for: expr) {
            let pattern = AccessPattern(
                path: staticPath.components,
                frequency: (result.variableAccess[staticPath.path]?.frequency ?? 0) + 1,
                isDeepAccess: staticPath.components.count > 2
            )
            result.variableAccess[staticPath.path] = pattern
            result.variableCount += 1
            result.complexityScore += max(0, staticPath.components.count - 1)
            return
        }

        switch expr {
        case .filtered(let expr, let filters):
            analyzeExpression(expr, result: &result)
            for filter in filters {
                let filterName = filter.name.string
                result.filterUsage[filterName] = (result.filterUsage[filterName] ?? 0) + 1

                for argument in filter.arguments {
                    analyzeExpression(argument, result: &result)
                }
                for argument in filter.namedArguments.values {
                    analyzeExpression(argument, result: &result)
                }
                
                // Check for complex filters
                if ["where", "map", "sort", "group_by", "sum"].contains(filterName) {
                    result.hasComplexFilters = true
                    result.complexityScore += 3
                }
            }
            
        case .binary(let left, _, let right):
            analyzeExpression(left, result: &result)
            analyzeExpression(right, result: &result)
            result.complexityScore += 1
            
        default:
            break
        }
    }

    private func nodeRequiresImplicitLoopObject(_ node: ASTNode) -> Bool {
        switch node {
        case .custom,
             .registeredCustomTag,
             .include,
             .renderBlock,
             .extends,
             .debug(expression: nil):
            return true
        default:
            return false
        }
    }

    private func nodeReferencesVariable(_ node: ASTNode, named variableName: String) -> Bool {
        switch node {
        case .output(let expression), .echo(let expression):
            return expressionReferencesVariable(expression, named: variableName)

        case .if(let condition, _, let elsifBranches, _):
            if expressionReferencesVariable(condition, named: variableName) {
                return true
            }
            for (condition, _) in elsifBranches where expressionReferencesVariable(condition, named: variableName) {
                return true
            }
            return false

        case .unless(let condition, _, _):
            return expressionReferencesVariable(condition, named: variableName)

        case .case(let value, let whens, _):
            if expressionReferencesVariable(value, named: variableName) {
                return true
            }
            for (expression, _) in whens where expressionReferencesVariable(expression, named: variableName) {
                return true
            }
            return false

        case .for(_, let collection, _, _, let params):
            if expressionReferencesVariable(collection, named: variableName) {
                return true
            }
            if let condition = params.condition {
                return expressionReferencesVariable(condition, named: variableName)
            }
            return false

        case .tablerow(_, let collection, _, _):
            return expressionReferencesVariable(collection, named: variableName)

        case .assign(_, let value):
            return expressionReferencesVariable(value, named: variableName)

        case .cycle(_, let items):
            for item in items where expressionReferencesVariable(item, named: variableName) {
                return true
            }
            return false

        case .debug(let expression):
            if let expression {
                return expressionReferencesVariable(expression, named: variableName)
            }
            return false

        case .pipeline(let input, let operations):
            if expressionReferencesVariable(input, named: variableName) {
                return true
            }
            for operation in operations {
                if case .filter(let filter) = operation.operation {
                    for argument in filter.arguments where expressionReferencesVariable(argument, named: variableName) {
                        return true
                    }
                    for argument in filter.namedArguments.values where expressionReferencesVariable(argument, named: variableName) {
                        return true
                    }
                }
            }
            return false

        case .include(_, let withValues, _):
            if let withValues {
                for value in withValues.values where expressionReferencesVariable(value, named: variableName) {
                    return true
                }
            }
            return false

        case .renderBlock(_, let params):
            for value in params.values where expressionReferencesVariable(value, named: variableName) {
                return true
            }
            return false

        case .macro(let signature, _):
            for parameter in signature.parameters {
                if let defaultValue = parameter.defaultValue,
                   expressionReferencesVariable(defaultValue, named: variableName) {
                    return true
                }
            }
            return false

        case .input(let contract):
            if let defaultValue = contract.defaultValue {
                return expressionReferencesVariable(defaultValue, named: variableName)
            }
            return false

        case .call(_, let arguments, _):
            for argument in arguments where expressionReferencesVariable(argument.value, named: variableName) {
                return true
            }
            return false

        case .slot, .fill:
            return false

        case .template, .text, .comment, .raw, .liquid, .break, .continue, .custom,
             .capture, .increment, .decrement, .block, .extends, .registeredCustomTag,
             .macroImport:
            return false
        }
    }

    private func expressionReferencesVariable(_ expression: LiquidCore.Expression, named variableName: String) -> Bool {
        switch expression {
        case .literal:
            return false

        case .variable(let name):
            let nameString = name.string
            return nameString == variableName || nameString.hasPrefix(variableName + ".")

        case .binary(let left, _, let right):
            return expressionReferencesVariable(left, named: variableName)
                || expressionReferencesVariable(right, named: variableName)

        case .unary(_, let expr):
            return expressionReferencesVariable(expr, named: variableName)

        case .range(let start, let end):
            return expressionReferencesVariable(start, named: variableName)
                || expressionReferencesVariable(end, named: variableName)

        case .filtered(let expr, let filters):
            if expressionReferencesVariable(expr, named: variableName) {
                return true
            }
            for filter in filters {
                for argument in filter.arguments where expressionReferencesVariable(argument, named: variableName) {
                    return true
                }
                for argument in filter.namedArguments.values where expressionReferencesVariable(argument, named: variableName) {
                    return true
                }
            }
            return false

        case .test(let expr, _):
            return expressionReferencesVariable(expr, named: variableName)

        case .access(let expr, let key):
            return expressionReferencesVariable(expr, named: variableName)
                || expressionReferencesVariable(key, named: variableName)

        case .call(_, let arguments):
            for argument in arguments where expressionReferencesVariable(argument.value, named: variableName) {
                return true
            }
            return false
        }
    }
    
    // MARK: - Optimization Passes
    
    /// Constant folding optimization
    private func constantFolding(_ ast: ASTNode) -> ASTNode {
        switch ast {
        case .output(let expr):
            return .output(foldConstants(expr))
            
        case .if(let condition, let thenNodes, let elsifBranches, let elseNodes):
            let foldedCondition = foldConstants(condition)
            
            // Try to evaluate condition at compile time
            if let constantValue = evaluateConstant(foldedCondition) {
                if isTruthy(constantValue) {
                    // Condition is always true - eliminate else branches
                    return .template(thenNodes.map { constantFolding($0) })
                } else if let elseNodes = elseNodes {
                    // Condition is always false - use else branch
                    return .template(elseNodes.map { constantFolding($0) })
                } else {
                    // Condition is always false, no else - eliminate entire if
                    return .template([])
                }
            }
            
            return .if(
                condition: foldedCondition,
                then: thenNodes.map { constantFolding($0) },
                elsif: elsifBranches.map { (cond, nodes) in (foldConstants(cond), nodes.map { constantFolding($0) }) },
                else: elseNodes?.map { constantFolding($0) }
            )
            
        case .for(let variable, let collection, let body, let empty, let params):
            return .for(
                variable: variable,
                in: foldConstants(collection),
                body: body.map { constantFolding($0) },
                empty: empty?.map { constantFolding($0) },
                params: params
            )
            
        default:
            return ast
        }
    }
    
    private func foldConstants(_ expr: LiquidCore.Expression) -> LiquidCore.Expression {
        switch expr {
        case .binary(let left, let op, let right):
            let foldedLeft = foldConstants(left)
            let foldedRight = foldConstants(right)
            
            // Try to evaluate at compile time
            if let leftValue = evaluateConstant(foldedLeft),
               let rightValue = evaluateConstant(foldedRight) {
                if let result = evaluateBinaryOp(leftValue, op, rightValue) {
                    return literalExpression(for: result)
                }
            }
            
            return .binary(left: foldedLeft, op: op, right: foldedRight)
            
        case .filtered(let expr, let filters):
            return .filtered(expr: foldConstants(expr), filters: filters)
            
        default:
            return expr
        }
    }
    
    /// Dead code elimination
    private func eliminateDeadCode(_ ast: ASTNode) -> ASTNode {
        switch ast {
        case .template(let nodes):
            let liveNodes = nodes.compactMap { node -> ASTNode? in
                let optimized = eliminateDeadCode(node)
                // Remove empty templates
                if case .template(let subNodes) = optimized, subNodes.isEmpty {
                    return nil
                }
                return optimized
            }
            return .template(liveNodes)
            
        case .if(let condition, let thenNodes, let elsifBranches, let elseNodes):
            return .if(
                condition: condition,
                then: thenNodes.map { eliminateDeadCode($0) },
                elsif: elsifBranches.compactMap { (cond, nodes) in
                    let optimizedNodes = nodes.map { eliminateDeadCode($0) }
                    return optimizedNodes.isEmpty ? nil : (cond, optimizedNodes)
                },
                else: elseNodes?.map { eliminateDeadCode($0) }
            )
            
        default:
            return ast
        }
    }
    
    /// Inline optimization
    private func inlineOptimization(_ ast: ASTNode) -> ASTNode {
        switch ast {
        case .template(let nodes):
            return .template(nodes.map { inlineOptimization($0) })

        case .output(let expr):
            return .output(optimizeExpression(expr))

        case .if(let condition, let thenNodes, let elsifBranches, let elseNodes):
            return .if(
                condition: optimizeExpression(condition),
                then: thenNodes.map { inlineOptimization($0) },
                elsif: elsifBranches.map { (condition, nodes) in
                    (optimizeExpression(condition), nodes.map { inlineOptimization($0) })
                },
                else: elseNodes?.map { inlineOptimization($0) }
            )

        case .unless(let condition, let thenNodes, let elseNodes):
            return .unless(
                condition: optimizeExpression(condition),
                then: thenNodes.map { inlineOptimization($0) },
                else: elseNodes?.map { inlineOptimization($0) }
            )

        case .case(let value, let whens, let elseBranch):
            return .case(
                value: optimizeExpression(value),
                whens: whens.map { (expr, nodes) in
                    (optimizeExpression(expr), nodes.map { inlineOptimization($0) })
                },
                else: elseBranch?.map { inlineOptimization($0) }
            )

        case .for(let variable, let collection, let body, let empty, let params):
            let optimizedBody = body.map { inlineOptimization($0) }
            let loopBodyArtifacts = analyzeLoopBodyArtifacts(for: optimizedBody)
            return .for(
                variable: variable,
                in: optimizeExpression(collection),
                body: optimizedBody,
                empty: empty?.map { inlineOptimization($0) },
                params: ForParams(
                    limit: params.limit,
                    offset: params.offset,
                    reversed: params.reversed,
                    condition: params.condition.map { optimizeExpression($0) },
                    recursive: params.recursive,
                    staticBodySegment: loopBodyArtifacts.staticBodySegment,
                    renderPlan: loopBodyArtifacts.renderPlan
                )
            )

        case .tablerow(let variable, let collection, let body, let params):
            let optimizedBody = body.map { inlineOptimization($0) }
            let loopBodyArtifacts = analyzeLoopBodyArtifacts(for: optimizedBody)
            return .tablerow(
                variable: variable,
                in: optimizeExpression(collection),
                body: optimizedBody,
                params: TableRowParams(
                    cols: params.cols,
                    limit: params.limit,
                    offset: params.offset,
                    staticBodySegment: loopBodyArtifacts.staticBodySegment,
                    renderPlan: loopBodyArtifacts.renderPlan
                )
            )

        case .cycle(let group, let items):
            return .cycle(group: group, items: items.map { optimizeExpression($0) })

        case .assign(let variable, let value):
            return .assign(variable: variable, value: optimizeExpression(value))

        case .capture(let variable, let body):
            return .capture(variable: variable, body: body.map { inlineOptimization($0) })

        case .include(let template, let withVars, let asVar):
            return .include(
                template: template,
                with: withVars.map { dictionary in
                    Dictionary(uniqueKeysWithValues: dictionary.map { key, value in
                        (key, optimizeExpression(value))
                    })
                },
                as: asVar
            )

        case .macro(let signature, let body):
            return .macro(
                signature: MacroSignatureNode(
                    name: signature.name,
                    parameters: signature.parameters.map { parameter in
                        MacroParameterNode(
                            name: parameter.name,
                            defaultValue: parameter.defaultValue.map { optimizeExpression($0) }
                        )
                    }
                ),
                body: body.map { inlineOptimization($0) }
            )

        case .macroImport:
            return ast

        case .input(let contract):
            return .input(
                InputContractNode(
                    name: contract.name,
                    type: contract.type,
                    strict: contract.strict,
                    defaultValue: contract.defaultValue.map { optimizeExpression($0) }
                )
            )

        case .call(let name, let arguments, let body):
            return .call(
                name: name,
                arguments: arguments.map {
                    CallArgument(label: $0.label, value: optimizeExpression($0.value))
                },
                body: body?.map { inlineOptimization($0) }
            )

        case .slot(let name, let body):
            return .slot(name: name, body: body.map { inlineOptimization($0) })

        case .fill(let name, let body):
            return .fill(name: name, body: body.map { inlineOptimization($0) })

        case .block(let name, let body):
            return .block(name: name, body: body.map { inlineOptimization($0) })

        case .renderBlock(let name, let params):
            return .renderBlock(
                name: name,
                params: Dictionary(uniqueKeysWithValues: params.map { key, value in
                    (key, optimizeExpression(value))
                })
            )

        case .liquid(let body):
            return .liquid(body: body.map { inlineOptimization($0) })

        case .echo(let expression):
            return .echo(expression: optimizeExpression(expression))

        case .debug(let expression):
            return .debug(expression: expression.map { optimizeExpression($0) })

        case .pipeline(let input, let operations):
            return .pipeline(
                input: optimizeExpression(input),
                operations: operations.map { operation in
                    switch operation.operation {
                    case .filter(let filter):
                        return PipelineOp(
                            operation: .filter(
                                Filter(
                                    name: filter.name,
                                    arguments: filter.arguments.map { optimizeExpression($0) },
                                    namedArguments: Dictionary(uniqueKeysWithValues: filter.namedArguments.map { key, value in
                                        (key, optimizeExpression(value))
                                    })
                                )
                            )
                        )
                    case .assign:
                        return operation
                    }
                }
            )

        case .registeredCustomTag(let name, let markup, let body):
            guard let body else {
                return ast
            }
            return .registeredCustomTag(
                name: name,
                markup: markup,
                body: RuntimeCustomTagBody(
                    source: body.source,
                    nodes: body.nodes.map { inlineOptimization($0) }
                )
            )

        case .text, .comment, .raw, .increment, .decrement, .custom,
             .break, .continue, .extends:
            return ast
        }
    }
    
    /// Variable hoisting
    private func hoistVariables(_ ast: ASTNode) -> ASTNode {
        // For now, just return the input
        // Could implement hoisting of loop-invariant expressions
        return ast
    }

    private func optimizeExpression(_ expression: LiquidCore.Expression) -> LiquidCore.Expression {
        switch expression {
        case .access(let expr, let key):
            let optimizedExpr = optimizeExpression(expr)
            let optimizedKey = optimizeExpression(key)
            let optimizedAccess = LiquidCore.Expression.access(expr: optimizedExpr, key: optimizedKey)
            if let staticPath = staticVariablePathInfo(for: optimizedAccess) {
                return .variable(InlineString(staticPath.path))
            }
            return optimizedAccess

        case .binary(let left, let op, let right):
            return .binary(
                left: optimizeExpression(left),
                op: op,
                right: optimizeExpression(right)
            )

        case .unary(let op, let expr):
            return .unary(op: op, expr: optimizeExpression(expr))

        case .range(let start, let end):
            return .range(
                start: optimizeExpression(start),
                end: optimizeExpression(end)
            )

        case .filtered(let expr, let filters):
            return .filtered(
                expr: optimizeExpression(expr),
                filters: filters.map { filter in
                    Filter(
                        name: filter.name,
                        arguments: filter.arguments.map { optimizeExpression($0) },
                        namedArguments: Dictionary(uniqueKeysWithValues: filter.namedArguments.map { key, value in
                            (key, optimizeExpression(value))
                        })
                    )
                }
            )

        case .test(let expr, let test):
            return .test(expr: optimizeExpression(expr), test: test)

        case .call(let name, let arguments):
            return .call(
                name: name,
                arguments: arguments.map { CallArgument(label: $0.label, value: optimizeExpression($0.value)) }
            )

        case .literal, .variable:
            return expression
        }
    }

    private func analyzeLoopBodyArtifacts(for nodes: [ASTNode]) -> LoopBodyArtifacts {
        guard !nodes.isEmpty else {
            return .empty
        }

        var expressions: [Expression] = []
        expressions.reserveCapacity(2)

        var segments = [String]()
        segments.reserveCapacity(3)
        segments.append("")
        var isStaticOnly = true

        for node in nodes {
            switch node {
            case .text(let content), .raw(let content):
                segments[segments.count - 1].append(content.string)

            case .output(let expression), .echo(let expression):
                isStaticOnly = false
                guard expressions.count < 2 else {
                    return .empty
                }
                expressions.append(expression)
                segments.append("")

            default:
                return .empty
            }
        }

        if isStaticOnly {
            return LoopBodyArtifacts(
                staticBodySegment: InlineString(segments[0]),
                renderPlan: nil
            )
        }

        switch expressions.count {
        case 1:
            return LoopBodyArtifacts(
                staticBodySegment: nil,
                renderPlan: .single(
                    prefix: InlineString(segments[0]),
                    expression: expressions[0],
                    suffix: InlineString(segments[1])
                )
            )

        case 2:
            return LoopBodyArtifacts(
                staticBodySegment: nil,
                renderPlan: .double(
                    prefix: InlineString(segments[0]),
                    first: expressions[0],
                    middle: InlineString(segments[1]),
                    second: expressions[1],
                    suffix: InlineString(segments[2])
                )
            )

        default:
            return .empty
        }
    }

    private func staticVariablePathInfo(for expression: LiquidCore.Expression) -> StaticVariablePathInfo? {
        switch expression {
        case .variable(let name):
            let component = name.string
            return StaticVariablePathInfo(path: component, components: [component])

        case .access(let expr, let key):
            guard var info = staticVariablePathInfo(for: expr) else {
                return nil
            }

            let component: String
            switch key {
            case .literal(.string(let keyName)):
                component = keyName.string
            case .literal(.number(let number, _)):
                guard number.rounded(.towardZero) == number else {
                    return nil
                }
                component = String(Int(number))
            default:
                return nil
            }

            info.path += "."
            info.path += component
            info.components.append(component)
            return info

        default:
            return nil
        }
    }

    /// Extract static segments for fast rendering
    private func extractStaticSegments(_ ast: ASTNode) -> [String] {
        var segments: [String] = []
        extractStaticFromNode(ast, segments: &segments)
        return segments
    }
    
    private func extractStaticFromNode(_ node: ASTNode, segments: inout [String]) {
        switch node {
        case .text(let content):
            segments.append(content.string)
            
        case .template(let nodes):
            for child in nodes {
                extractStaticFromNode(child, segments: &segments)
            }
            
        case .if(_, let thenNodes, let elsifBranches, let elseNodes):
            for child in thenNodes {
                extractStaticFromNode(child, segments: &segments)
            }
            for (_, nodes) in elsifBranches {
                for child in nodes {
                    extractStaticFromNode(child, segments: &segments)
                }
            }
            if let elseNodes {
                for child in elseNodes {
                    extractStaticFromNode(child, segments: &segments)
                }
            }
            
        default:
            break
        }
    }

    // MARK: - Helper Functions
    
    private func evaluateConstant(_ expr: LiquidCore.Expression) -> Any? {
        switch expr {
        case .literal(let value):
            switch value {
            case .string(let s): return s
            case .number(let n, _): return n
            case .boolean(let b): return b
            case .null: return NSNull()
            default: return nil
            }
        default:
            return nil
        }
    }
    
    private func evaluateBinaryOp(_ left: Any, _ op: BinaryOp, _ right: Any) -> Any? {
        switch op {
        case .plus:
            if let l = left as? Double, let r = right as? Double {
                return l + r
            }
        case .minus:
            if let l = left as? Double, let r = right as? Double {
                return l - r
            }
        case .multiply:
            if let l = left as? Double, let r = right as? Double {
                return l * r
            }
        case .divide:
            if let l = left as? Double, let r = right as? Double, r != 0 {
                return l / r
            }
        default:
            break
        }
        return nil
    }
    
    private func literalExpression(for value: Any) -> LiquidCore.Expression {
        switch value {
        case let s as String:
            return .literal(.string(InlineString(s)))
        case let n as Double:
            return .literal(.number(n))
        case let b as Bool:
            return .literal(.boolean(b))
        case is NSNull:
            return .literal(.null)
        default:
            return .literal(.string(InlineString(String(describing: value))))
        }
    }
    
    private func isTruthy(_ value: Any) -> Bool {
        switch value {
        case let b as Bool:
            return b
        case is NSNull:
            return false
        case let s as String:
            return !s.isEmpty
        case let n as Double:
            return n != 0
        default:
            return true
        }
    }
}

// MARK: - Analysis Result

private struct AnalysisResult {
    var variableAccess: [String: AccessPattern] = [:]
    var filterUsage: [String: Int] = [:]
    var hasLoops = false
    var loopDepth = 0
    var hasComplexFilters = false
    var variableCount = 0
    var staticContentLength = 0
    var maxDepth = 0
    var complexityScore = 0
    var requiresForloopObjectAnalysis = false
    var requiresTableRowLoopObjectAnalysis = false
    
    var performanceHints: PerformanceHints {
        PerformanceHints(
            hasNestedLoops: loopDepth > 1,
            maxLoopDepth: loopDepth,
            hasComplexFilters: hasComplexFilters,
            staticContentRatio: staticContentLength > 0 ? Double(staticContentLength) / Double(staticContentLength + variableCount * 10) : 0.0,
            estimatedVariableCount: variableCount,
            canSkipForloopObjectAnalysis: !requiresForloopObjectAnalysis,
            canSkipTableRowLoopObjectAnalysis: !requiresTableRowLoopObjectAnalysis
        )
    }
}

private struct LoopBodyArtifacts {
    let staticBodySegment: InlineString?
    let renderPlan: LoopBodyRenderPlan?

    static let empty = LoopBodyArtifacts(staticBodySegment: nil, renderPlan: nil)
}

private struct StaticVariablePathInfo {
    var path: String
    var components: [String]
}
