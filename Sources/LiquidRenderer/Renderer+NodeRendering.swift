//
//  Renderer+NodeRendering.swift
//  LiquidRenderer
//
//  Created as part of RhoeLiquid
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import LiquidCore
import LiquidExtensions
import LiquidParser
import LiquidTags
import LiquidUtilities
import OrderedCollections

extension Renderer {
    // MARK: - Node Rendering
    
    /// Renders a specific AST node
    internal func renderNode(_ node: ASTNode) async throws -> String {
        guard let debugContext = configuration.debugContext else {
            return try await executeNode(node)
        }

        let startTime = Date().timeIntervalSinceReferenceDate
        let nodeType = String(describing: node)
        let location = LiquidSourceLocation(line: 1, column: 1, position: 0, templateName: nil)

        let shouldBreak = await debugContext.shouldBreak(at: location, node: node)
        if shouldBreak {
            if let breakpoint = await debugContext.getBreakpoints().first(where: { $0.matches(location: location) }) {
                let action = await debugContext.configuration.outputHandler?.handleBreakpoint(breakpoint, context: debugContext) ?? .continue

                switch action {
                case .abort:
                    throw RenderError.debugAborted(sourceLocation: location)
                case .evaluate(let expression):
                    do {
                        let result: Any
                        if expression == "true" || expression == "false" {
                            result = expression == "true"
                        } else if let intValue = Int(expression) {
                            result = intValue
                        } else if let doubleValue = Double(expression) {
                            result = doubleValue
                        } else {
                            result = context.getVariable(expression) ?? ""
                        }
                        await debugContext.configuration.outputHandler?.handleDebugOutput(.message("Debug evaluation result: \(result)", level: .info))
                    } catch {
                        await debugContext.configuration.outputHandler?.handleDebugOutput(.message("Debug evaluation failed: \(error)", level: .error))
                    }
                default:
                    break
                }
            }
        }

        await debugContext.recordTrace(DebugTraceEntry(
            location: location,
            nodeType: nodeType,
            operation: "execute",
            stackDepth: await debugContext.getCallStack().count
        ))

        do {
            let result = try await executeNode(node)
            let duration = Date().timeIntervalSinceReferenceDate - startTime

            await debugContext.recordNodeExecution(node, duration: duration)
            await debugContext.recordTrace(DebugTraceEntry(
                location: location,
                nodeType: nodeType,
                operation: "complete",
                duration: duration,
                output: SendableAnyValue(result),
                stackDepth: await debugContext.getCallStack().count
            ))

            if debugContext.configuration.profileExecution {
                debugContext.configuration.outputHandler?.handleDebugOutput(.profiling(
                    DebugProfilingData(
                        operation: "\(nodeType) execution",
                        duration: duration,
                        location: location
                    )
                ))
            }

            return result
        } catch let signal as LoopControlSignal {
            throw signal
        } catch {
            await debugContext.recordTrace(DebugTraceEntry(
                location: location,
                nodeType: nodeType,
                operation: "error",
                duration: Date().timeIntervalSinceReferenceDate - startTime,
                stackDepth: await debugContext.getCallStack().count,
                context: ["error": SendableAnyValue(error.localizedDescription)]
            ))

            let config = debugContext.configuration
            if config.breakOnErrors {
                let errorBreakpoint = DebugBreakpoint(location: location, condition: "error", enabled: true)
                let action = await config.outputHandler?.handleBreakpoint(errorBreakpoint, context: debugContext) ?? .continue

                if action == .abort {
                    throw RenderError.debugAborted(sourceLocation: location)
                }
            }

            throw error
        }
    }

    internal func executeNode(_ node: ASTNode) async throws -> String {
        switch node {
        case .template(let nodes):
            return try await renderTemplate(nodes)

        case .text(let content):
            return content.string

        case .output(let expression):
            return try await renderExpression(expression)

        case .assign(let variable, let value):
            return try await renderAssign(variable: variable, value: value)

        case .echo(let expression):
            return try await renderExpression(expression)

        case .debug(let expression):
            return try await renderDebug(expression: expression)

        case .comment:
            return ""

        case .if(let condition, let thenNodes, let elsifBranches, let elseNodes):
            return try await renderIf(condition: condition, then: thenNodes, elsif: elsifBranches, else: elseNodes)

        case .unless(let condition, let thenNodes, let elseNodes):
            return try await renderUnless(condition: condition, then: thenNodes, else: elseNodes)

        case .case(let value, let whens, let elseBranch):
            return try await renderCase(value: value, whens: whens, else: elseBranch)

        case .for(let variable, let collection, let body, let empty, let params):
            return try await renderFor(variable: variable, collection: collection, body: body, empty: empty, params: params)

        case .tablerow(let variable, let collection, let body, let params):
            return try await renderTableRow(variable: variable, collection: collection, body: body, params: params)

        case .capture(let variable, let body):
            return try await renderCapture(variable: variable, body: body)

        case .increment(let name):
            return try await renderIncrement(name: name)

        case .decrement(let name):
            return try await renderDecrement(name: name)

        case .break:
            guard context.isInsideLoop else {
                throw RenderError.custom("The break tag is only valid inside for and tablerow loops")
            }
            throw LoopControlSignal.breakLoop

        case .continue:
            guard context.isInsideLoop else {
                throw RenderError.custom("The continue tag is only valid inside for and tablerow loops")
            }
            throw LoopControlSignal.continueLoop

        case .cycle(let group, let items):
            return try await renderCycle(group: group, items: items)

        case .raw(let content):
            return content.string

        case .liquid(let nodes):
            return try await renderTemplate(nodes)

        case .include(let template, let withVars, let asVar):
            return try await renderInclude(template: template, with: withVars, as: asVar)

        case .macro, .macroImport, .input:
            return ""

        case .call(let name, let arguments, let body):
            return try await renderMacroCall(name: name, arguments: arguments, body: body)

        case .slot(let name, let body):
            return try await renderMacroSlot(name: name, fallbackBody: body)

        case .fill:
            throw RenderError.custom("fill blocks are only valid as direct children of block-form call tags")

        case .block(let name, let body):
            return try await renderBlock(name: name, body: body)

        case .renderBlock(let name, let params):
            return try await renderBlockWithParams(name: name, params: params)

        case .extends(let template):
            return try await renderExtends(template: template)

        case .registeredCustomTag(let name, let markup, let body):
            return try await renderRegisteredCustomTag(name: name, markup: markup, body: body)

        case .pipeline:
            throw RenderError.custom("The pipeline tag is archived and not part of the active RhoeLiquid 1.x runtime.")

        default:
            throw RenderError.custom("Unsupported node type: \(node)")
        }
    }
    
    /// Renders a template (array of nodes)
    internal func renderTemplate(_ nodes: [ASTNode], staticCapacityHint: Int? = nil) async throws -> String {
        switch nodes.count {
        case 0:
            return ""
        case 1:
            return try await renderNode(nodes[0])
        default:
            break
        }

        var output = String()
        let staticCapacity = staticCapacityHint ?? estimatedStaticCapacity(for: nodes)
        if staticCapacity > 0 {
            output.reserveCapacity(staticCapacity)
        }

        for node in nodes {
            try Task.checkCancellation()
            let nodeOutput = try await renderNode(node)
            output.append(nodeOutput)
        }

        return output
    }

    internal func renderSimpleNodeListFast(_ nodes: [ASTNode], staticCapacityHint: Int) async throws -> String {
        guard configuration.debugContext == nil else {
            return try await renderTemplate(nodes, staticCapacityHint: staticCapacityHint)
        }

        switch nodes.count {
        case 0:
            return ""
        case 1:
            switch nodes[0] {
            case .text(let content), .raw(let content):
                return content.string
            case .output(let expression), .echo(let expression):
                return try await renderExpressionFast(expression)
            default:
                return try await renderNode(nodes[0])
            }
        case 2:
            var output = String()
            if staticCapacityHint > 0 {
                output.reserveCapacity(staticCapacityHint)
            }
            try await appendRenderedSimpleNodePairFast(nodes[0], nodes[1], to: &output)
            return output
        case 3:
            var output = String()
            if staticCapacityHint > 0 {
                output.reserveCapacity(staticCapacityHint)
            }
            try await appendRenderedSimpleNodeTripleFast(nodes[0], nodes[1], nodes[2], to: &output)
            return output
        default:
            break
        }

        var output = String()
        if staticCapacityHint > 0 {
            output.reserveCapacity(staticCapacityHint)
        }

        try await appendRenderedSimpleNodeListFast(nodes, to: &output)
        return output
    }

    internal func appendRenderedSimpleNodeListFast(_ nodes: [ASTNode], to output: inout String) async throws {
        guard configuration.debugContext == nil else {
            output.append(try await renderTemplate(nodes))
            return
        }

        switch nodes.count {
        case 0:
            return
        case 1:
            try await appendRenderedSimpleNodeFast(nodes[0], to: &output)
            return
        case 2:
            try await appendRenderedSimpleNodePairFast(nodes[0], nodes[1], to: &output)
            return
        case 3:
            try await appendRenderedSimpleNodeTripleFast(nodes[0], nodes[1], nodes[2], to: &output)
            return
        default:
            break
        }

        for node in nodes {
            try Task.checkCancellation()
            try await appendRenderedSimpleNodeFast(node, to: &output)
        }
    }

    @inline(__always)
    internal func appendRenderedSimpleNodeFast(_ node: ASTNode, to output: inout String) async throws {
        switch node {
        case .text(let content), .raw(let content):
            output.append(content.string)
        case .output(let expression), .echo(let expression):
            try await appendRenderedExpressionFast(expression, to: &output)
        default:
            output.append(try await renderNode(node))
        }
    }

    @inline(__always)
    internal func appendRenderedSimpleNodePairFast(
        _ first: ASTNode,
        _ second: ASTNode,
        to output: inout String
    ) async throws {
        switch (first, second) {
        case (.text(let leading), .text(let trailing)),
             (.text(let leading), .raw(let trailing)),
             (.raw(let leading), .text(let trailing)),
             (.raw(let leading), .raw(let trailing)):
            output.append(leading.string)
            output.append(trailing.string)
            return

        case (.text(let leading), .output(let expression)),
             (.text(let leading), .echo(let expression)),
             (.raw(let leading), .output(let expression)),
             (.raw(let leading), .echo(let expression)):
            output.append(leading.string)
            try await appendRenderedExpressionFast(expression, to: &output)
            return

        case (.output(let expression), .text(let trailing)),
             (.output(let expression), .raw(let trailing)),
             (.echo(let expression), .text(let trailing)),
             (.echo(let expression), .raw(let trailing)):
            try await appendRenderedExpressionFast(expression, to: &output)
            output.append(trailing.string)
            return

        default:
            break
        }

        try await appendRenderedSimpleNodeFast(first, to: &output)
        try await appendRenderedSimpleNodeFast(second, to: &output)
    }

    @inline(__always)
    internal func appendRenderedSimpleNodeTripleFast(
        _ first: ASTNode,
        _ second: ASTNode,
        _ third: ASTNode,
        to output: inout String
    ) async throws {
        switch (first, second, third) {
        case (.text(let leading), .output(let expression), .text(let trailing)),
             (.text(let leading), .output(let expression), .raw(let trailing)),
             (.text(let leading), .echo(let expression), .text(let trailing)),
             (.text(let leading), .echo(let expression), .raw(let trailing)),
             (.raw(let leading), .output(let expression), .text(let trailing)),
             (.raw(let leading), .output(let expression), .raw(let trailing)),
             (.raw(let leading), .echo(let expression), .text(let trailing)),
             (.raw(let leading), .echo(let expression), .raw(let trailing)):
            output.append(leading.string)
            try await appendRenderedExpressionFast(expression, to: &output)
            output.append(trailing.string)
            return

        default:
            break
        }

        try await appendRenderedSimpleNodeFast(first, to: &output)
        try await appendRenderedSimpleNodeFast(second, to: &output)
        try await appendRenderedSimpleNodeFast(third, to: &output)
    }

    @inline(__always)
    internal func appendLoopBodyRenderPlanFast(
        _ plan: LoopBodyRenderPlan,
        to output: inout String
    ) async throws {
        switch plan {
        case .single(let prefix, let expression, let suffix):
            output.append(prefix.string)
            try await appendRenderedExpressionFast(expression, to: &output)
            output.append(suffix.string)

        case .double(let prefix, let first, let middle, let second, let suffix):
            output.append(prefix.string)
            try await appendRenderedExpressionFast(first, to: &output)
            output.append(middle.string)
            try await appendRenderedExpressionFast(second, to: &output)
            output.append(suffix.string)
        }
    }

    @inline(__always)
    internal func appendRenderedExpressionFast(
        _ expression: LiquidCore.Expression,
        to output: inout String
    ) async throws {
        guard !autoEscapeEnabled else {
            output.append(try await renderExpressionFast(expression))
            return
        }

        switch expression {
        case .literal(let value):
            appendStringifiedUnescapedValueFast(try evaluateValue(value), to: &output)

        case .variable(let name):
            appendStringifiedUnescapedValueFast(context.getVariable(name.string) ?? NSNull(), to: &output)

        case .access:
            if let path = expression.staticVariablePath {
                appendStringifiedUnescapedValueFast(context.getVariable(path) ?? NSNull(), to: &output)
            } else {
                output.append(try await renderExpressionFast(expression))
            }

        case .filtered(let expr, let filters):
            if filters.count == 1,
               try await appendSingleBuiltinFilteredExpressionFast(
                    baseExpression: expr,
                    filter: filters[0],
                    to: &output
               ) {
                return
            }
            output.append(try await renderExpressionFast(expression))

        default:
            output.append(try await renderExpressionFast(expression))
        }
    }

    @inline(__always)
    internal func appendSingleBuiltinFilteredExpressionFast(
        baseExpression: LiquidCore.Expression,
        filter: Filter,
        to output: inout String
    ) async throws -> Bool {
        guard filter.namedArguments.isEmpty,
              let builtinKind = filter.builtinKind else {
            return false
        }

        switch builtinKind {
        case .upcase:
            guard filter.arguments.isEmpty else {
                return false
            }
            let baseValue = try await evaluateFilteredBaseValueFast(baseExpression)
            if let string = baseValue as? String {
                output.append(string.uppercased())
            } else {
                output.append(stringify(baseValue).uppercased())
            }
            return true

        case .round:
            guard filter.arguments.count == 1 else {
                return false
            }
            let baseValue = try await evaluateFilteredBaseValueFast(baseExpression)
            let precision: Int
            if let literalArgument = filter.singleLiteralIntegerArgument {
                precision = literalArgument
            } else {
                let argument = try await evaluateFilterArgumentFast(filter.arguments[0])
                precision = integerValue(argument) ?? 0
            }
            appendRoundedValueFast(baseValue, precision: precision, to: &output)
            return true

        default:
            return false
        }
    }

    @inline(__always)
    internal func appendStringifiedUnescapedValueFast(_ value: Any, to output: inout String) {
        switch value {
        case let str as String:
            output.append(str)
        case let inline as InlineString:
            output.append(inline.string)
        case let safeHTML as SafeHTML:
            output.append(safeHTML.value)
        case let num as Double:
            output.append(formatDouble(num))
        case let num as Int:
            output.append(String(num))
        case let bool as Bool:
            output.append(bool ? "true" : "false")
        case let number as NSNumber:
            output.append(
                number.doubleValue == floor(number.doubleValue)
                    ? String(number.intValue)
                    : String(number.doubleValue)
            )
        case is NSNull:
            return
        case let array as [Any]:
            output.append(joinedStringifiedValues(array, separator: "", escapeElements: false))
        default:
            output.append(String(describing: value))
        }
    }

    @inline(__always)
    internal func appendRoundedValueFast(_ value: Any, precision: Int, to output: inout String) {
        switch value {
        case let num as Double:
            output.append(stringifyRoundedDouble(roundedDouble(num, precision: precision)))
        case let num as Int:
            if precision >= 0 {
                output.append(String(num))
            } else {
                output.append(stringifyRoundedDouble(roundedDouble(Double(num), precision: precision)))
            }
        case let number as NSNumber:
            let doubleValue = number.doubleValue
            if precision >= 0, doubleValue.rounded(.towardZero) == doubleValue {
                output.append(String(number.intValue))
            } else {
                output.append(stringifyRoundedDouble(roundedDouble(doubleValue, precision: precision)))
            }
        case let string as String:
            guard let num = Double(string) else {
                appendStringifiedUnescapedValueFast(string, to: &output)
                return
            }
            output.append(stringifyRoundedDouble(roundedDouble(num, precision: precision)))
        case let inline as InlineString:
            guard let num = Double(inline.string) else {
                appendStringifiedUnescapedValueFast(inline, to: &output)
                return
            }
            output.append(stringifyRoundedDouble(roundedDouble(num, precision: precision)))
        case let safeHTML as SafeHTML:
            guard let num = Double(safeHTML.value) else {
                appendStringifiedUnescapedValueFast(safeHTML, to: &output)
                return
            }
            output.append(stringifyRoundedDouble(roundedDouble(num, precision: precision)))
        default:
            output.append(renderRoundedValueFast(value, precision: precision))
        }
    }

    internal func renderCompiledTemplateNodes(_ nodes: [ASTNode], staticCapacityHint: Int) async throws -> String {
        guard configuration.debugContext == nil else {
            return try await renderTemplate(nodes, staticCapacityHint: staticCapacityHint)
        }

        return try await renderSimpleNodeListFast(nodes, staticCapacityHint: staticCapacityHint)
    }

    @inline(__always)
    internal func renderNodeListFast(_ nodes: [ASTNode], staticCapacityHint: Int? = nil) async throws -> String {
        let staticCapacity = staticCapacityHint ?? estimatedStaticCapacity(for: nodes)
        return try await renderSimpleNodeListFast(nodes, staticCapacityHint: staticCapacity)
    }

    @inline(__always)
    internal func estimatedStaticCapacity(for nodes: [ASTNode]) -> Int {
        var total = 0
        for node in nodes {
            switch node {
            case .text(let content), .raw(let content):
                total += content.utf8Count
            default:
                continue
            }
        }
        return total
    }

    internal func bodyNeedsImplicitLoopObject(named variableName: String, nodes: [ASTNode]) -> Bool {
        var stack = nodes

        while let node = stack.popLast() {
            switch node {
            case .custom,
                 .registeredCustomTag,
                 .include,
                 .renderBlock,
                 .extends,
                 .debug(expression: nil):
                return true

            default:
                break
            }

            for expression in node.expressions {
                if expressionReferencesVariable(expression, named: variableName) {
                    return true
                }
            }

            stack.append(contentsOf: node.children)
        }

        return false
    }

    internal func expressionReferencesVariable(_ expression: LiquidCore.Expression, named variableName: String) -> Bool {
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

    internal func expressionToPath(_ expression: LiquidCore.Expression) -> String {
        switch expression {
        case .variable(let name):
            return name.string
        case .access(let base, let key):
            let basePath = expressionToPath(base)
            switch key {
            case .literal(.string(let keyName)):
                return basePath.isEmpty ? keyName.string : "\(basePath).\(keyName.string)"
            case .literal(.number(let num, _)):
                return "\(basePath)[\(Int(num))]"
            default:
                return basePath
            }
        case .range(let start, let end):
            let startStr = expressionToPathForRange(start)
            let endStr = expressionToPathForRange(end)
            return "(\(startStr)..\(endStr))"
        case .literal(.number(let num, _)):
            return num == num.rounded(.towardZero) ? String(Int(num)) : String(num)
        case .literal(.string(let s)):
            return s.string
        default:
            return String(describing: expression)
        }
    }

    /// For range expressions, format numbers as integers
    internal func expressionToPathForRange(_ expression: LiquidCore.Expression) -> String {
        if case .literal(.number(let num, _)) = expression {
            return num == num.rounded(.towardZero) ? String(Int(num)) : String(num)
        }
        return expressionToPath(expression)
    }

    @inline(__always)
    internal func requiresInheritanceProcessing(_ node: ASTNode) -> Bool {
        guard case .template(let nodes) = node,
              let firstNode = nodes.first,
              case .extends = firstNode else {
            return false
        }

        return true
    }

    internal func prepareASTForRendering(_ node: ASTNode) async throws -> ASTNode {
        guard requiresInheritanceProcessing(node) else {
            return node
        }

        guard let templateLoader else {
            throw RenderError.includeError(
                currentTemplatePath ?? "<template>",
                reason: "Template inheritance requires a configured TemplateLoader"
            )
        }

        let processor = TemplateInheritanceProcessor(
            templateLoader: templateLoader,
            customTagDescriptors: customTagDescriptors
        )

        do {
            return try await processor.processInheritance(
                ast: node,
                templatePath: currentTemplatePath
            )
        } catch let error as TemplateLoaderError {
            throw mapTemplateLoaderError(error, template: currentTemplatePath ?? "<template>")
        } catch {
            throw RenderError.includeError(
                currentTemplatePath ?? "<template>",
                reason: error.localizedDescription
            )
        }
    }

    internal var currentTemplatePath: String? {
        templatePathStack.last
    }

    internal func resetTemplatePathStack() {
        if !templatePathStack.isEmpty {
            templatePathStack.removeAll(keepingCapacity: true)
        }

        if let rootTemplatePath {
            templatePathStack.append(rootTemplatePath)
        }
    }

    internal func resetAuthoringState() {
        if !macroScopes.isEmpty {
            macroScopes.removeAll(keepingCapacity: true)
        }
        if !inputContractScopes.isEmpty {
            inputContractScopes.removeAll(keepingCapacity: true)
        }
        if !macroCallStack.isEmpty {
            macroCallStack.removeAll(keepingCapacity: true)
        }
        if !macroInvocationStack.isEmpty {
            macroInvocationStack.removeAll(keepingCapacity: true)
        }
        if !macroImportPathStack.isEmpty {
            macroImportPathStack.removeAll(keepingCapacity: true)
        }
    }

    internal func mapTemplateLoaderError(_ error: TemplateLoaderError, template: String) -> RenderError {
        switch error {
        case .templateNotFound(let path):
            return .templateNotFound(path)
        case .pathTraversal(let detail), .absolutePathNotAllowed(let detail):
            return .accessDenied(detail)
        case .invalidPath(let detail), .invalidExtension(let detail), .ioError(let detail):
            return .includeError(template, reason: detail)
        }
    }

    internal func withAuthoringScope<T>(
        for node: ASTNode,
        templatePath: String?,
        operation: () async throws -> T
    ) async throws -> T {
        let scope = try await buildAuthoringScope(from: node, templatePath: templatePath)
        macroScopes.append(scope.macros)
        inputContractScopes.append(scope.inputContracts)
        defer {
            _ = inputContractScopes.popLast()
            _ = macroScopes.popLast()
        }

        try await applyInputDefaults(scope.inputContracts)
        return try await operation()
    }

    internal func buildAuthoringScope(from node: ASTNode, templatePath: String?) async throws -> AuthoringScope {
        var macros: [String: MacroDefinition] = [:]
        var inputContracts: [InputContractNode] = []
        try await collectAuthoringDeclarations(
            from: node,
            templatePath: templatePath,
            macros: &macros,
            inputContracts: &inputContracts
        )
        return AuthoringScope(macros: macros, inputContracts: inputContracts)
    }

    internal func collectAuthoringDeclarations(
        from node: ASTNode,
        templatePath: String?,
        macros: inout [String: MacroDefinition],
        inputContracts: inout [InputContractNode]
    ) async throws {
        switch node {
        case .template(let nodes), .liquid(let nodes):
            for child in nodes {
                try await collectAuthoringDeclarations(
                    from: child,
                    templatePath: templatePath,
                    macros: &macros,
                    inputContracts: &inputContracts
                )
            }
        case .macro(let signature, let body):
            try registerMacro(
                MacroDefinition(
                    exportedName: signature.name.string,
                    signature: signature,
                    body: body,
                    templatePath: templatePath
                ),
                as: signature.name.string,
                into: &macros
            )
        case .macroImport(let macroImport):
            let importedMacros = try await resolveImportedMacros(macroImport, relativeTo: templatePath)
            for (name, definition) in importedMacros {
                if macros[name] == nil {
                    macros[name] = definition
                }
            }
        case .input(let contract):
            inputContracts.append(contract)
        default:
            for child in node.children {
                try await collectAuthoringDeclarations(
                    from: child,
                    templatePath: templatePath,
                    macros: &macros,
                    inputContracts: &inputContracts
                )
            }
        }
    }

    internal func registerMacro(
        _ definition: MacroDefinition,
        as exportedName: String,
        into macros: inout [String: MacroDefinition]
    ) throws {
        if macros[exportedName] != nil {
            throw RenderError.custom("Duplicate macro definition: \(exportedName)")
        }
        macros[exportedName] = MacroDefinition(
            exportedName: exportedName,
            signature: definition.signature,
            body: definition.body,
            templatePath: definition.templatePath
        )
    }

    internal func resolveImportedMacros(
        _ macroImport: MacroImportNode,
        relativeTo templatePath: String?
    ) async throws -> [String: MacroDefinition] {
        guard let templateLoader else {
            throw RenderError.includeError(
                macroImport.template.string,
                reason: "No TemplateLoader configured for macro imports"
            )
        }

        let resolvedPath: String
        let importedAST: ASTNode

        do {
            resolvedPath = try await templateLoader.resolvedTemplatePath(
                for: macroImport.template.string,
                relativeTo: templatePath
            )
            if macroImportPathStack.contains(resolvedPath) {
                throw RenderError.custom("Circular macro import detected for \(resolvedPath)")
            }
            macroImportPathStack.append(resolvedPath)
            defer { _ = macroImportPathStack.popLast() }
            importedAST = try await templateLoader.loadTemplateAST(
                macroImport.template.string,
                relativeTo: templatePath,
                customTagDescriptors: customTagDescriptors
            )
        } catch let error as TemplateLoaderError {
            throw mapTemplateLoaderError(error, template: macroImport.template.string)
        } catch {
            if let renderError = error as? RenderError {
                throw renderError
            }
            throw RenderError.includeError(macroImport.template.string, reason: error.localizedDescription)
        }

        let preparedAST = try await prepareASTForRendering(importedAST)
        let importedScope = try await buildAuthoringScope(from: preparedAST, templatePath: resolvedPath)
        var bindings = importedScope.macros

        if !macroImport.importedMacros.isEmpty {
            for importedName in macroImport.importedMacros {
                guard bindings[importedName.string] != nil else {
                    throw RenderError.custom(
                        "Imported template \(macroImport.template.string) does not define macro \(importedName.string)"
                    )
                }
            }
        }

        if let namespace = macroImport.namespace?.string {
            let originalBindings = bindings
            for (name, definition) in originalBindings {
                bindings["\(namespace).\(name)"] = MacroDefinition(
                    exportedName: "\(namespace).\(name)",
                    signature: definition.signature,
                    body: definition.body,
                    templatePath: definition.templatePath
                )
            }
        }

        return bindings
    }

    internal func applyInputDefaults(_ inputContracts: [InputContractNode]) async throws {
        for contract in inputContracts {
            guard let defaultValue = contract.defaultValue,
                  !context.hasCompleteInputContractValue(at: contract.path) else {
                continue
            }
            let evaluatedDefault = try await evaluateExpression(defaultValue)
            context.applyInputContractDefault(evaluatedDefault, at: contract.path)
        }
    }
    
    /// Renders an assign statement
    internal func renderAssign(variable: InlineString, value: LiquidCore.Expression) async throws -> String {
        let evaluatedValue = try await evaluateExpression(value)
        // Shopify Liquid: assign always sets at root scope so variables persist after loops/blocks
        context.setRootVariable(variable.string, value: evaluatedValue)
        return "" // Assign produces no output
    }
}
