//
//  Renderer+ControlFlow.swift
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
    // MARK: - Control Flow Rendering

    /// Renders an if statement with complex conditions
    internal func renderIf(condition: LiquidCore.Expression, then thenNodes: [ASTNode], elsif elsifBranches: [(LiquidCore.Expression, [ASTNode])], else elseNodes: [ASTNode]?) async throws -> String {
        if elsifBranches.isEmpty {
            let conditionValue = try await evaluateExpression(condition)
            if isTruthy(conditionValue) {
                let result = try await renderNodeListFast(thenNodes)
                if result.allSatisfy(\.isWhitespace), RenderingContext.isStaticallyBlankBlock(thenNodes),
                   (elseNodes == nil || RenderingContext.isStaticallyBlankBlock(elseNodes!)) {
                    return ""
                }
                return result
            }

            if let elseNodes = elseNodes {
                let result = try await renderNodeListFast(elseNodes)
                if result.allSatisfy(\.isWhitespace), RenderingContext.isStaticallyBlankBlock(elseNodes),
                   RenderingContext.isStaticallyBlankBlock(thenNodes) {
                    return ""
                }
                return result
            }

            return ""
        }

        let conditionValue = try await evaluateExpression(condition)
        if isTruthy(conditionValue) {
            let result = try await renderNodeListFast(thenNodes)
            if result.allSatisfy(\.isWhitespace), RenderingContext.isStaticallyBlankBlock(thenNodes),
               (elseNodes == nil || RenderingContext.isStaticallyBlankBlock(elseNodes!)),
               elsifBranches.allSatisfy({ RenderingContext.isStaticallyBlankBlock($0.1) }) {
                return ""
            }
            return result
        }

        // Check elsif branches
        for (elsifCondition, elsifNodes) in elsifBranches {
            let elsifValue = try await evaluateExpression(elsifCondition)
            if isTruthy(elsifValue) {
                let result = try await renderNodeListFast(elsifNodes)
                if result.allSatisfy(\.isWhitespace), RenderingContext.isStaticallyBlankBlock(elsifNodes),
                   RenderingContext.isStaticallyBlankBlock(thenNodes),
                   (elseNodes == nil || RenderingContext.isStaticallyBlankBlock(elseNodes!)),
                   elsifBranches.allSatisfy({ RenderingContext.isStaticallyBlankBlock($0.1) }) {
                    return ""
                }
                return result
            }
        }

        // Render else branch if present
        if let elseNodes = elseNodes {
            let result = try await renderNodeListFast(elseNodes)
            if result.allSatisfy(\.isWhitespace), RenderingContext.isStaticallyBlankBlock(elseNodes),
               RenderingContext.isStaticallyBlankBlock(thenNodes),
               elsifBranches.allSatisfy({ RenderingContext.isStaticallyBlankBlock($0.1) }) {
                return ""
            }
            return result
        }

        return ""
    }

    /// Renders an unless statement
    internal func renderUnless(condition: LiquidCore.Expression, then thenNodes: [ASTNode], else elseNodes: [ASTNode]?) async throws -> String {
        let conditionValue = try await evaluateExpression(condition)

        if !isTruthy(conditionValue) {
            let result = try await renderNodeListFast(thenNodes)
            if result.allSatisfy(\.isWhitespace), RenderingContext.isStaticallyBlankBlock(thenNodes),
               (elseNodes == nil || RenderingContext.isStaticallyBlankBlock(elseNodes!)) {
                return ""
            }
            return result
        }

        if let elseNodes = elseNodes {
            let result = try await renderNodeListFast(elseNodes)
            if result.allSatisfy(\.isWhitespace), RenderingContext.isStaticallyBlankBlock(elseNodes),
               RenderingContext.isStaticallyBlankBlock(thenNodes) {
                return ""
            }
            return result
        }

        return ""
    }

    /// Renders a for loop
    // MARK: - Forloop Object Builder

    /// Builds the `forloop` context object for for/tablerow loops.
    /// Shared by `renderFor` and `renderTableRow` to avoid duplication.
    @inline(__always)
    internal func buildForloopObject(
        index: Int, lastIndex: Int, itemCount: Int,
        name: String, parentForloop: Any?
    ) -> [String: Any] {
        var forloop: [String: Any] = [
            "index": index + 1,
            "index0": index,
            "first": index == 0,
            "last": index == lastIndex,
            "length": itemCount,
            "rindex": itemCount - index,
            "rindex0": lastIndex - index,
            "name": name,
        ]
        if let parentForloop {
            forloop["parentloop"] = parentForloop
        }
        return forloop
    }

    /// Captures the parent forloop for nested loop support.
    /// Returns nil for render-isolated contexts (Shopify: render has no parentloop).
    @inline(__always)
    internal func captureParentForloop(needsForloopObject: Bool) -> Any? {
        guard needsForloopObject else { return nil }
        if context.getVariable("__render_forloop__") != nil { return nil }
        return context.getVariable("forloop")
    }

    /// Builds the `tablerowloop` context object for tablerow loops.
    @inline(__always)
    internal func buildTablerowloopObject(
        index: Int, lastIndex: Int, itemCount: Int,
        colIndex: Int, columnCount: Int, rowIndex: Int
    ) -> [String: Any] {
        [
            "col": colIndex + 1,
            "col0": colIndex,
            "col_first": colIndex == 0,
            "col_last": colIndex == columnCount - 1 || index == lastIndex,
            "first": index == 0,
            "last": index == lastIndex,
            "index": index + 1,
            "index0": index,
            "length": itemCount,
            "rindex": itemCount - index,
            "rindex0": lastIndex - index,
            "row": rowIndex + 1,
        ]
    }

    // MARK: - For Loop Rendering

    internal func renderFor(variable: InlineString, collection: LiquidCore.Expression, body: [ASTNode], empty: [ASTNode]?, params: ForParams) async throws -> String {
        let collectionValue = try await evaluateExpression(collection)
        let forloopName = "\(variable.string)-\(expressionToPath(collection))"

        // Build collection key for offset:continue tracking
        // Include variable name so different loop vars have separate counters
        let collectionKey = "__for_continue_\(variable.string)_\(String(describing: collection))"

        // Convert collection to array (full, unsliced)
        var fullItems: [Any] = []
        if let array = collectionValue as? [Any] {
            fullItems = array
        } else if let pairs = orderedDictPairs(collectionValue) {
            fullItems = pairs.map { [$0.key, $0.value] as [Any] }
        } else if let str = collectionValue as? String {
            // Shopify Liquid: non-empty strings iterate as a single item
            fullItems = str.isEmpty ? [] : [str]
        } else {
            // Not iterable - treat as empty collection
            fullItems = []
        }

        // Determine offset
        var offset = 0
        if params.offsetContinue {
            offset = context.getCounter(collectionKey) ?? 0
        } else if let paramOffset = params.offset, paramOffset > 0 {
            offset = paramOffset
        } else if let offsetExpr = params.offsetExpression {
            // Runtime evaluation of offset expression (e.g., limit: my_var)
            let offsetValue = try await evaluateExpression(offsetExpr)
            if let intVal = offsetValue as? Int { offset = intVal }
            else if let dblVal = offsetValue as? Double { offset = Int(dblVal) }
            else if let strVal = offsetValue as? String, let intVal = Int(strVal) { offset = intVal }
            else if !(offsetValue is NSNull) {
                throw RenderError.typeError(expected: "integer", actual: "\(type(of: offsetValue))", operation: "for offset")
            }
        }

        // Apply offset
        var items = offset > 0 ? Array(fullItems.dropFirst(offset)) : fullItems

        // Determine limit (static or from expression)
        var resolvedLimit = params.limit
        if resolvedLimit == nil, let limitExpr = params.limitExpression {
            let limitValue = try await evaluateExpression(limitExpr)
            if let intVal = limitValue as? Int { resolvedLimit = intVal }
            else if let dblVal = limitValue as? Double { resolvedLimit = Int(dblVal) }
            else if let strVal = limitValue as? String, let intVal = Int(strVal) { resolvedLimit = intVal }
            else if !(limitValue is NSNull) {
                throw RenderError.typeError(expected: "integer", actual: "\(type(of: limitValue))", operation: "for limit")
            }
        }

        // Apply limit
        if let limit = resolvedLimit, limit > 0 {
            items = Array(items.prefix(limit))
        }

        // Store the continue offset for future loops (offset + items actually iterated)
        context.setCounter(collectionKey, value: offset + items.count)

        // Apply reversed
        if params.reversed {
            items = items.reversed()
        }
        
        // Check if collection is empty and render empty clause if present
        if items.isEmpty {
            if let emptyNodes = empty {
                context.pushScope()
                let emptyOutput = try await renderNodeListFast(
                    emptyNodes,
                    staticCapacityHint: estimatedStaticCapacity(for: emptyNodes)
                )
                context.popScope()
                return emptyOutput
            } else {
                return ""
            }
        }

        let itemCount = items.count
        let lastIndex = itemCount - 1
        let itemCountInt = itemCount

        if configuration.debugContext == nil, let staticBodySegment = params.staticBodySegment {
            let segment = staticBodySegment.string
            guard !segment.isEmpty else {
                return ""
            }

            var output = String()
            output.reserveCapacity(staticBodySegment.utf8Count * items.count)

            for _ in items {
                output.append(segment)
            }

            return output
        }

        if configuration.debugContext == nil, let renderPlan = params.renderPlan {
            var output = String()
            let staticPlanCapacity = renderPlan.staticUTF8Count
            if staticPlanCapacity > 0 {
                output.reserveCapacity(staticPlanCapacity * items.count)
            }

            let needsForloopObject = canSkipForloopObjectAnalysis
                ? false
                : bodyNeedsImplicitLoopObject(named: "forloop", nodes: body)
            let variableName = variable.string

            // Capture parent forloop before pushing scope (for nested loop parentloop access)
            // Don't use render-for's forloop as parentloop (Shopify: render is isolated)
            let parentForloop = captureParentForloop(needsForloopObject: needsForloopObject)

            context.pushScope()
            context.enterLoop()
            defer {
                context.popScope()
                context.leaveLoop()
            }

            forLoop: for (index, item) in items.enumerated() {
                try Task.checkCancellation()
                context.setVariable(variableName, value: item)

                if needsForloopObject {
                    let forloop = buildForloopObject(
                        index: index, lastIndex: lastIndex, itemCount: itemCountInt,
                        name: forloopName, parentForloop: parentForloop
                    )
                    context.setVariable("forloop", value: forloop)
                }

                do {
                    try await appendLoopBodyRenderPlanFast(renderPlan, to: &output)
                } catch let signal as LoopControlSignal {
                    switch signal {
                    case .continueLoop:
                        continue forLoop
                    case .breakLoop:
                        break forLoop
                    case .breakLoopWithOutput(let partialOutput):
                        output += partialOutput
                        break forLoop
                    }
                }
            }

            return output
        }

        // Render loop
        var output = ""
        let bodyStaticCapacity = estimatedStaticCapacity(for: body)
        if bodyStaticCapacity > 0 {
            output.reserveCapacity(bodyStaticCapacity * itemCount)
        }
        let needsForloopObject = canSkipForloopObjectAnalysis
            ? false
            : bodyNeedsImplicitLoopObject(named: "forloop", nodes: body)
        let variableName = variable.string

        // Capture parent forloop before pushing scope (for nested loop parentloop access)
        // Don't use render-for's forloop as parentloop (Shopify: render is isolated)
        let parentForloop = captureParentForloop(needsForloopObject: needsForloopObject)

        context.pushScope()
        context.enterLoop()
        defer {
            context.popScope()
            context.leaveLoop()
        }

        forLoop: for (index, item) in items.enumerated() {
            try Task.checkCancellation()
            context.setVariable(variableName, value: item)

            if needsForloopObject {
                let forloop = buildForloopObject(
                    index: index, lastIndex: lastIndex, itemCount: itemCountInt,
                    name: forloopName, parentForloop: parentForloop
                )
                context.setVariable("forloop", value: forloop)
            }

            // Render body
            do {
                try await appendRenderedSimpleNodeListFast(body, to: &output)
            } catch let signal as LoopControlSignal {
                switch signal {
                case .continueLoop:
                    continue forLoop
                case .breakLoop:
                    break forLoop
                case .breakLoopWithOutput(let partialOutput):
                    output += partialOutput
                    break forLoop
                }
            }
        }

        // Blank suppression for for loops
        if output.allSatisfy(\.isWhitespace), RenderingContext.isStaticallyBlankBlock(body) {
            return ""
        }

        return output
    }

    /// Renders a tablerow block
    internal func renderTableRow(variable: InlineString, collection: LiquidCore.Expression, body: [ASTNode], params: TableRowParams) async throws -> String {
        let collectionValue = try await evaluateExpression(collection)
        
        // Convert collection to array
        var items: [Any] = []
        if let array = collectionValue as? [Any] {
            items = array
        } else if let pairs = orderedDictPairs(collectionValue) {
            items = pairs.map { [$0.key, $0.value] as [Any] }
        } else if let str = collectionValue as? String {
            // Shopify Liquid: non-empty strings iterate as a single item
            items = str.isEmpty ? [] : [str]
        } else {
            // Empty collection
            return ""
        }
        
        // Apply offset
        if let offset = params.offset, offset > 0 {
            items = Array(items.dropFirst(offset))
        }
        
        // Apply limit
        if let limit = params.limit, limit > 0 {
            items = Array(items.prefix(limit))
        }
        
        // Get column count (default to items.count if not specified)
        let columnCount = params.cols ?? items.count
        let itemCount = items.count
        let lastIndex = itemCount - 1

        if configuration.debugContext == nil, let staticBodySegment = params.staticBodySegment {
            let segment = staticBodySegment.string
            var output = String()
            output.reserveCapacity((staticBodySegment.utf8Count + 32) * itemCount)

            for index in items.indices {
                let rowIndex = index / columnCount
                let colIndex = index % columnCount

                if colIndex == 0 {
                    output.append("<tr class=\"row\(rowIndex + 1)\">"  + (rowIndex == 0 ? "\n" : ""))
                }

                output.append("<td class=\"col\(colIndex + 1)\">")
                output.append(segment)
                output.append("</td>")

                if colIndex == columnCount - 1 || index == lastIndex {
                    output.append("</tr>\n")
                }
            }

            return output
        }

        if configuration.debugContext == nil, let renderPlan = params.renderPlan {
            var output = String()
            output.reserveCapacity((renderPlan.staticUTF8Count + 32) * itemCount)

            let needsTableRowLoopObject = canSkipTableRowLoopObjectAnalysis
                ? false
                : bodyNeedsImplicitLoopObject(named: "tablerowloop", nodes: body)
            let itemCountInt = itemCount
            let variableName = variable.string

            context.pushScope()
            context.enterLoop()
            defer {
                context.popScope()
                context.leaveLoop()
            }

            for (index, item) in items.enumerated() {
                let rowIndex = index / columnCount
                let colIndex = index % columnCount

                if colIndex == 0 {
                    output.append("<tr class=\"row\(rowIndex + 1)\">"  + (rowIndex == 0 ? "\n" : ""))
                }

                context.setVariable(variableName, value: item)

                if needsTableRowLoopObject {
                    let tablerowloop = buildTablerowloopObject(
                        index: index, lastIndex: lastIndex, itemCount: itemCountInt,
                        colIndex: colIndex, columnCount: columnCount, rowIndex: rowIndex
                    )
                    context.setVariable("tablerowloop", value: tablerowloop)
                }

                output.append("<td class=\"col\(colIndex + 1)\">")
                do {
                    try await appendLoopBodyRenderPlanFast(renderPlan, to: &output)
                } catch let signal as LoopControlSignal {
                    output.append("</td>")

                    switch signal {
                    case .continueLoop:
                        if colIndex == columnCount - 1 || index == lastIndex {
                            output.append("</tr>\n")
                        }
                        continue
                    case .breakLoop:
                        output.append("</tr>\n")
                        return output
                    case .breakLoopWithOutput(let partialOutput):
                        output.append(partialOutput)
                        output.append("</tr>\n")
                        return output
                    }
                }
                output.append("</td>")

                if colIndex == columnCount - 1 || index == lastIndex {
                    output.append("</tr>\n")
                }
            }

            return output
        }

        let itemCountInt = itemCount
        
        var output = ""
        let bodyStaticCapacity = estimatedStaticCapacity(for: body)
        if bodyStaticCapacity > 0 {
            output.reserveCapacity((bodyStaticCapacity + 32) * itemCount)
        }
        let needsTableRowLoopObject = canSkipTableRowLoopObjectAnalysis
            ? false
            : bodyNeedsImplicitLoopObject(named: "tablerowloop", nodes: body)
        let variableName = variable.string
        context.pushScope()
        context.enterLoop()
        defer {
            context.popScope()
            context.leaveLoop()
        }
        
        // Generate table rows
        for (index, item) in items.enumerated() {
            let rowIndex = index / columnCount
            let colIndex = index % columnCount
            
            // Start new row
            if colIndex == 0 {
                output.append("<tr class=\"row\(rowIndex + 1)\">"  + (rowIndex == 0 ? "\n" : ""))
            }

            // Set loop variable
            context.setVariable(variableName, value: item)

            // Set tablerowloop object
            if needsTableRowLoopObject {
                let tablerowloop = buildTablerowloopObject(
                    index: index, lastIndex: lastIndex, itemCount: itemCountInt,
                    colIndex: colIndex, columnCount: columnCount, rowIndex: rowIndex
                )
                context.setVariable("tablerowloop", value: tablerowloop)
            }

            // Render cell content
            let cellClass = "col\(colIndex + 1)"
            output.append("<td class=\"\(cellClass)\">")
            do {
                try await appendRenderedSimpleNodeListFast(body, to: &output)
            } catch let signal as LoopControlSignal {
                output.append("</td>")

                switch signal {
                case .continueLoop:
                    if colIndex == columnCount - 1 || index == lastIndex {
                        output.append("</tr>\n")
                    }
                    continue
                case .breakLoop:
                    output.append("</tr>\n")
                    return output
                case .breakLoopWithOutput(let partialOutput):
                    output.append(partialOutput)
                    output.append("</tr>\n")
                    return output
                }
            }
            output.append("</td>")

            // End row
            if colIndex == columnCount - 1 || index == lastIndex {
                output.append("</tr>\n")
            }
        }

        return output
    }
    
    /// Renders a capture block
    internal func renderCapture(variable: InlineString, body: [ASTNode]) async throws -> String {
        let capturedOutput = try await renderNodeListFast(body)
        context.setVariable(variable.string, value: capturedOutput)
        return "" // Capture produces no output
    }
    
    /// Renders increment tag
    internal func renderIncrement(name: InlineString) async throws -> String {
        // Increment/decrement use a separate counter namespace (Shopify behavior)
        // They do NOT interfere with assigned variables
        let currentValue = context.getCounter(name.string) ?? 0
        context.setCounter(name.string, value: currentValue + 1)
        return String(currentValue) // Return current value before increment
    }

    /// Renders decrement tag
    internal func renderDecrement(name: InlineString) async throws -> String {
        // Increment/decrement use a separate counter namespace (Shopify behavior)
        let currentValue = context.getCounter(name.string) ?? 0
        let newValue = currentValue - 1
        context.setCounter(name.string, value: newValue)
        return String(newValue) // Return decremented value
    }

    /// Renders debug tag output into the configured debug channel without affecting template output.
    internal func renderDebug(expression: LiquidCore.Expression?) async throws -> String {
        guard let debugContext = configuration.debugContext else {
            return ""
        }

        let message: String
        if let expression {
            let value = try await evaluateExpression(expression)
            message = "debug: \(stringify(value, escape: false))"
        } else {
            let keys = context.visibleVariables().keys.sorted()
            if keys.isEmpty {
                message = "debug checkpoint"
            } else {
                message = "debug checkpoint: \(keys.joined(separator: ", "))"
            }
        }

        debugContext.configuration.outputHandler?.handleDebugOutput(.message(message, level: .info))
        return ""
    }
    
    /// Renders cycle tag
    internal func renderCycle(group: LiquidCore.Expression?, items: [LiquidCore.Expression]) async throws -> String {
        guard !items.isEmpty else { return "" }

        // Build cycle key from group expression (evaluated to get dynamic group names)
        let cycleKey: String
        if let group {
            let groupValue = try await evaluateExpression(group)
            cycleKey = stringify(groupValue)
        } else {
            // No group name: use items as the key (Shopify behavior: different items = different cycle)
            cycleKey = items.map { String(describing: $0) }.joined(separator: ",")
        }

        let counterKey = "__cycle_\(cycleKey)"
        let currentIndex = context.getCounter(counterKey) ?? 0

        // Ruby Liquid behavior: use counter as direct index into CURRENT items array
        // If out of bounds → output nothing. Reset to 0 when counter >= items.count.
        let result: String
        if currentIndex < items.count {
            let value = try await evaluateExpression(items[currentIndex])
            result = stringify(value)
        } else {
            result = ""  // Out of bounds → no output
        }

        // Advance counter, reset to 0 when it reaches current items count
        var nextIndex = currentIndex + 1
        if nextIndex >= items.count {
            nextIndex = 0
        }
        context.setCounter(counterKey, value: nextIndex)

        return result
    }
    
    /// Renders include tag
    internal func renderInclude(template: InlineString, with withVars: [String: LiquidCore.Expression]?, as asVar: InlineString?) async throws -> String {
        guard let templateLoader else {
            throw RenderError.includeError(
                template.string,
                reason: "No TemplateLoader configured for include/render operations"
            )
        }

        let isRender = withVars?["__render_isolated__"] != nil
        let hasForIteration = withVars?["_for"] != nil
        let evaluatedVariables = try await evaluateIncludeBindings(
            template: template,
            with: withVars,
            as: asVar
        )

        var templateName = template.string

        var resolvedPath: String
        var ast: ASTNode

        do {
            // Try literal template name first
            resolvedPath = try await templateLoader.resolvedTemplatePath(
                for: templateName,
                relativeTo: currentTemplatePath
            )
            ast = try await templateLoader.loadTemplateAST(
                templateName,
                relativeTo: currentTemplatePath,
                customTagDescriptors: customTagDescriptors
            )
        } catch {
            // If literal name fails, try resolving as a variable reference
            if let variableValue = context.getVariable(templateName) as? String {
                templateName = variableValue
                do {
                    resolvedPath = try await templateLoader.resolvedTemplatePath(
                        for: templateName,
                        relativeTo: currentTemplatePath
                    )
                    ast = try await templateLoader.loadTemplateAST(
                        templateName,
                        relativeTo: currentTemplatePath,
                        customTagDescriptors: customTagDescriptors
                    )
                } catch let innerError as TemplateLoaderError {
                    throw mapTemplateLoaderError(innerError, template: templateName)
                } catch {
                    throw RenderError.includeError(templateName, reason: error.localizedDescription)
                }
            } else if let loadError = error as? TemplateLoaderError {
                throw mapTemplateLoaderError(loadError, template: templateName)
            } else {
                throw RenderError.includeError(templateName, reason: error.localizedDescription)
            }
        }

        // Handle {% render "template" for collection %} — iterate and render for each item
        if isRender, hasForIteration, let forExpr = withVars?["_for"] {
            let collection = try await evaluateExpression(forExpr)
            guard let items = collection as? [Any] else {
                return ""
            }
            let alias = asVar?.string ?? defaultTemplateAlias(for: template.string)
            let itemCount = items.count
            let lastIndex = itemCount - 1
            let forloopName = "\(alias)-\(template.string)"
            var output = ""
            output.reserveCapacity(items.count * 64)
            for (index, item) in items.enumerated() {
                var itemVars = evaluatedVariables
                itemVars[alias] = item
                let forloop = buildForloopObject(
                    index: index, lastIndex: lastIndex, itemCount: itemCount,
                    name: forloopName, parentForloop: nil
                )
                // Use saveState/isolateScope/restoreState for render isolation
                // Set forloop in isolated scope. Mark it as render-forloop so nested loops
                // don't use it as parentloop.
                itemVars["forloop"] = forloop
                itemVars["__render_forloop__"] = true  // Flag for parentloop suppression
                let savedState = context.saveState()
                context.isolateScope(with: itemVars)
                templatePathStack.append(resolvedPath)
                defer {
                    _ = templatePathStack.popLast()
                    context.restoreState(savedState)
                }
                let preparedAST = try await prepareASTForRendering(ast)
                output += try await withAuthoringScope(for: preparedAST, templatePath: resolvedPath) {
                    try await renderNode(preparedAST)
                }
            }
            return output
        }

        // Handle {% include "template" for collection %} (non-render mode)
        if !isRender, hasForIteration, let forExpr = withVars?["_for"] {
            let collection = try await evaluateExpression(forExpr)
            guard let items = collection as? [Any] else {
                return ""
            }
            let alias = asVar?.string ?? defaultTemplateAlias(for: templateName)
            var output = ""
            output.reserveCapacity(items.count * 64)
            for item in items {
                let snapshots = context.snapshotVariables(named: [alias])
                context.setVariable(alias, value: item)
                templatePathStack.append(resolvedPath)
                let preparedAST = try await prepareASTForRendering(ast)
                output += try await withAuthoringScope(for: preparedAST, templatePath: resolvedPath) {
                    try await renderNode(preparedAST)
                }
                _ = templatePathStack.popLast()
                context.restoreVariables(snapshots)
            }
            return output
        }

        if isRender {
            let savedState = context.saveState()
            context.isolateScope(with: evaluatedVariables)
            templatePathStack.append(resolvedPath)
            defer {
                _ = templatePathStack.popLast()
                context.restoreState(savedState)
            }
            let preparedAST = try await prepareASTForRendering(ast)
            return try await withAuthoringScope(for: preparedAST, templatePath: resolvedPath) {
                try await renderNode(preparedAST)
            }
        } else {
            // Push keyword args in a scope so they're protected from assigns
            // (assigns use setRootVariable which writes to root, keyword args shadow them)
            if !evaluatedVariables.isEmpty {
                context.pushScope(evaluatedVariables)
            }

            templatePathStack.append(resolvedPath)
            defer {
                _ = templatePathStack.popLast()
                if !evaluatedVariables.isEmpty {
                    context.popScope()
                }
            }

            let preparedAST = try await prepareASTForRendering(ast)
            // Set up authoring scope manually (instead of withAuthoringScope closure)
            let scope = try await buildAuthoringScope(from: preparedAST, templatePath: resolvedPath)
            macroScopes.append(scope.macros)
            inputContractScopes.append(scope.inputContracts)
            try await applyInputDefaults(scope.inputContracts)

            // Render node-by-node so break inside include preserves partial output
            var includeOutput = ""
            do {
                switch preparedAST {
                case .block(_, let nodes), .template(let nodes):
                    try await appendRenderedSimpleNodeListFast(nodes, to: &includeOutput)
                default:
                    includeOutput = try await renderNode(preparedAST)
                }
            } catch let signal as LoopControlSignal {
                // Re-throw with COMBINED partial output (our output + nested include's output)
                _ = inputContractScopes.popLast()
                _ = macroScopes.popLast()
                if case .breakLoopWithOutput(let nestedOutput) = signal {
                    throw LoopControlSignal.breakLoopWithOutput(includeOutput + nestedOutput)
                }
                throw LoopControlSignal.breakLoopWithOutput(includeOutput)
            }

            _ = inputContractScopes.popLast()
            _ = macroScopes.popLast()
            return includeOutput
        }
    }

    internal func evaluateIncludeBindings(
        template: InlineString,
        with withVars: [String: LiquidCore.Expression]?,
        as asVar: InlineString?
    ) async throws -> [String: Any] {
        guard let withVars else {
            return [:]
        }

        var evaluatedVariables: [String: Any] = [:]
        evaluatedVariables.reserveCapacity(withVars.count)

        for (key, expression) in withVars {
            switch key {
            case "__render_isolated__", "_with", "_for":
                continue
            default:
                evaluatedVariables[key] = try await evaluateExpression(expression)
            }
        }

        if let withExpression = withVars["_with"] {
            let alias = asVar?.string ?? defaultTemplateAlias(for: template.string)
            evaluatedVariables[alias] = try await evaluateExpression(withExpression)
        }

        return evaluatedVariables
    }

    internal func defaultTemplateAlias(for templatePath: String) -> String {
        let candidate = URL(fileURLWithPath: templatePath)
            .deletingPathExtension()
            .lastPathComponent
        return candidate.isEmpty ? "item" : candidate
    }

    internal func renderMacroCall(
        name: InlineString,
        arguments: [CallArgument],
        body: [ASTNode]?
    ) async throws -> String {
        var evaluatedArguments: [EvaluatedCallArgument] = []
        evaluatedArguments.reserveCapacity(arguments.count)
        for argument in arguments {
            evaluatedArguments.append(
                EvaluatedCallArgument(
                    label: argument.label?.string,
                    value: try await evaluateExpression(argument.value)
                )
            )
        }
        return try await renderMacroCall(name: name, argumentValues: evaluatedArguments, body: body)
    }

    internal func renderMacroCall(
        name: InlineString,
        argumentValues: [EvaluatedCallArgument],
        body: [ASTNode]?
    ) async throws -> String {
        guard let macro = macroDefinition(named: name.string) else {
            throw RenderError.custom("Undefined macro: \(name.string)")
        }
        if macroCallStack.contains(macro.identity) {
            throw RenderError.custom("Recursive or circular macro execution is not supported in Wave 17 Sprint 1: \(name.string)")
        }

        let invocationFrame = try macroInvocationFrame(
            for: macro,
            callBody: body,
            macroName: name.string
        )
        let bindings = try await bindMacroArguments(
            signature: macro.signature,
            arguments: argumentValues,
            macroName: name.string
        )

        macroCallStack.append(macro.identity)
        macroInvocationStack.append(invocationFrame)
        context.pushScope(bindings)
        defer {
            context.popScope()
            _ = macroInvocationStack.popLast()
            _ = macroCallStack.popLast()
        }

        return try await renderTemplate(macro.body)
    }

    internal func macroInvocationFrame(
        for macro: MacroDefinition,
        callBody: [ASTNode]?,
        macroName: String
    ) throws -> MacroInvocationFrame {
        guard let callBody else {
            return MacroInvocationFrame(defaultBody: [], namedFills: [:])
        }

        var defaultBody: [ASTNode] = []
        defaultBody.reserveCapacity(callBody.count)
        var namedFills: [String: [ASTNode]] = [:]
        namedFills.reserveCapacity(callBody.count)

        for node in callBody {
            if case .fill(let fillName, let fillBody) = node {
                let name = fillName.string
                if namedFills[name] != nil {
                    throw RenderError.custom("Duplicate fill '\(name)' for macro \(macroName)")
                }
                namedFills[name] = fillBody
                continue
            }

            if containsNestedFill(node) {
                throw RenderError.custom(
                    "fill blocks must be top-level children of a block-form call: \(macroName)"
                )
            }

            defaultBody.append(node)
        }

        if !defaultBody.isEmpty && !macro.declaredSlots.contains("default") {
            throw RenderError.custom("Macro \(macroName) does not declare a default slot")
        }

        for fillName in namedFills.keys where !macro.declaredSlots.contains(fillName) {
            throw RenderError.custom("Unknown fill '\(fillName)' for macro \(macroName)")
        }

        return MacroInvocationFrame(defaultBody: defaultBody, namedFills: namedFills)
    }

    internal func containsNestedFill(_ node: ASTNode) -> Bool {
        var stack = node.children

        while let current = stack.popLast() {
            if case .fill = current {
                return true
            }
            stack.append(contentsOf: current.children)
        }

        return false
    }

    internal func renderMacroSlot(name: InlineString, fallbackBody: [ASTNode]) async throws -> String {
        guard let frame = macroInvocationStack.last else {
            return try await renderNodeListFast(
                fallbackBody,
                staticCapacityHint: estimatedStaticCapacity(for: fallbackBody)
            )
        }

        if name.equals("default"), !frame.defaultBody.isEmpty {
            return try await renderNodeListFast(
                frame.defaultBody,
                staticCapacityHint: estimatedStaticCapacity(for: frame.defaultBody)
            )
        }

        if let fillBody = frame.namedFills[name.string] {
            return try await renderNodeListFast(
                fillBody,
                staticCapacityHint: estimatedStaticCapacity(for: fillBody)
            )
        }

        return try await renderNodeListFast(
            fallbackBody,
            staticCapacityHint: estimatedStaticCapacity(for: fallbackBody)
        )
    }

    internal func macroDefinition(named name: String) -> MacroDefinition? {
        for scope in macroScopes.reversed() {
            if let definition = scope[name] {
                return definition
            }
        }
        return nil
    }

    internal func bindMacroArguments(
        signature: MacroSignatureNode,
        arguments: [EvaluatedCallArgument],
        macroName: String
    ) async throws -> [String: Any] {
        var bindings: [String: Any] = [:]
        bindings.reserveCapacity(signature.parameters.count)
        var nextPositionalIndex = 0
        let parameterOrder = signature.parameters.map(\.name.string)
        let validNames = Set(parameterOrder)

        for argument in arguments {
            if let label = argument.label {
                guard validNames.contains(label) else {
                    throw RenderError.custom("Unknown macro parameter '\(label)' for \(macroName)")
                }
                bindings[label] = argument.value
                continue
            }

            while nextPositionalIndex < parameterOrder.count,
                  bindings[parameterOrder[nextPositionalIndex]] != nil {
                nextPositionalIndex += 1
            }

            guard nextPositionalIndex < parameterOrder.count else {
                throw RenderError.custom("Too many positional arguments for macro \(macroName)")
            }

            bindings[parameterOrder[nextPositionalIndex]] = argument.value
            nextPositionalIndex += 1
        }

        for parameter in signature.parameters {
            let parameterName = parameter.name.string
            guard bindings[parameterName] == nil else {
                continue
            }

            if let defaultValue = parameter.defaultValue {
                bindings[parameterName] = try await evaluateExpression(defaultValue)
            } else {
                throw RenderError.custom("Missing required macro parameter '\(parameterName)' for \(macroName)")
            }
        }

        return bindings
    }
    
    /// Renders a case statement
    internal func renderCase(value: LiquidCore.Expression, whens: [(LiquidCore.Expression, [ASTNode])], else elseBranch: [ASTNode]?) async throws -> String {
        let caseValue = try await evaluateExpression(value)

        // Process sequentially. Else branches (sentinel .literal(.null)) render when
        // no PRECEDING when matched. Regular when branches match against case value.
        var output = ""
        var anyPrecedingWhenMatched = false

        for (whenExpr, whenNodes) in whens {
            // Sentinel .literal(.null) means else branch
            if case .literal(.null) = whenExpr {
                // Else renders when no preceding when matched
                if !anyPrecedingWhenMatched {
                    output += try await renderNodeListFast(whenNodes)
                }
                continue
            }

            let whenValue = try await evaluateExpression(whenExpr)
            if isEqual(caseValue, whenValue) {
                anyPrecedingWhenMatched = true
                output += try await renderNodeListFast(whenNodes)
            }
        }

        // If no when matched at all, render the legacy else branch
        if !anyPrecedingWhenMatched, let elseBranch = elseBranch {
            output += try await renderNodeListFast(elseBranch)
        }

        // Blank suppression: if output is whitespace-only and all branches are statically blank, suppress
        if output.allSatisfy(\.isWhitespace),
           whens.allSatisfy({ RenderingContext.isStaticallyBlankBlock($0.1) }),
           (elseBranch == nil || RenderingContext.isStaticallyBlankBlock(elseBranch!)) {
            return ""
        }

        return output
    }

    /// Renders a block definition
    internal func renderBlock(name: InlineString, body: [ASTNode]) async throws -> String {
        // Store the block definition for later use
        context.defineBlock(name.string, body: body)
        return "" // Block definitions produce no output
    }
    
    /// Renders a block with parameters
    internal func renderBlockWithParams(name: InlineString, params: [String: LiquidCore.Expression]) async throws -> String {
        guard let body = context.getBlockDefinition(name.string) else {
            throw RenderError.custom("Undefined block: \(name.string)")
        }
        
        // Create new scope for block parameters
        context.pushScope()
        
        // Evaluate and set block parameters
        for (key, expr) in params {
            let value = try await evaluateExpression(expr)
            context.setVariable(key, value: value)
        }
        
        // Render the block body
        let result = try await renderTemplate(body)
        
        // Restore scope
        context.popScope()
        
        return result
    }
    
    /// Renders template inheritance with extends
    internal func renderExtends(template: InlineString) async throws -> String {
        // Template inheritance is handled at a higher level by processing the entire AST
        // This method should not be called directly during normal rendering
        throw RenderError.custom("Template inheritance must be processed before rendering")
    }

    internal func renderRegisteredCustomTag(
        name: InlineString,
        markup: InlineString,
        body: RuntimeCustomTagBody?
    ) async throws -> String {
        guard let tag = customTags[name.string] else {
            throw RenderError.tagError(name.string, underlying: "Tag is not registered")
        }

        let parsingContext = LiquidTags.TagParsingContext(
            templateName: currentTemplatePath ?? rootTemplatePath,
            lineNumber: 0,
            staticContext: context.visibleVariables(),
            configuration: liquidConfiguration
        )
        let renderingContext = context
        let activeDataLoaderRegistry = dataLoaderRegistry

        do {
            let parsedParameters = try await tag.parse(markup.string, context: parsingContext)
            let executionContext = LiquidTags.TagExecutionContext(
                variables: renderingContext.visibleVariables(),
                renderContext: LiquidTags.RenderContext(
                    templateName: currentTemplatePath ?? rootTemplatePath,
                    configuration: liquidConfiguration,
                    nestingDepth: max(templatePathStack.count, 1),
                    strictMode: configuration.strictMode
                ),
                loopContext: renderingContext.currentLoopContext(),
                scopedVariables: renderingContext.currentScopeVariables(),
                bodyNodes: body?.nodes,
                variableSetter: { key, value in
                    renderingContext.setVariable(key, value: value)
                },
                valueGetter: { key in
                    if let value = renderingContext.getVariable(key) {
                        return value
                    }
                    if self.configuration.strictMode {
                        throw RenderError.undefinedVariable(key)
                    }
                    return ""
                },
                scopePusher: { scope in
                    renderingContext.pushScope(scope)
                },
                scopePopper: {
                    renderingContext.popScope()
                },
                filterApplier: { name, value, arguments, _ in
                    try await self.applyFilterInternal(
                        filterName: InlineString(name),
                        to: value,
                        args: arguments
                    )
                },
                dataLoaderRegistry: activeDataLoaderRegistry
            )

            return try await tag.execute(
                parameters: parsedParameters,
                content: body?.source.string,
                context: executionContext
            )
        } catch let error as RenderError {
            throw error
        } catch let error as TagParsingError {
            throw RenderError.tagError(name.string, underlying: error.localizedDescription)
        } catch let error as TagExecutionError {
            throw RenderError.tagError(name.string, underlying: error.localizedDescription)
        } catch {
            throw RenderError.tagError(name.string, underlying: error.localizedDescription)
        }
    }

    internal var liquidConfiguration: LiquidConfiguration {
        LiquidConfiguration(
            strictMode: configuration.strictMode,
            maxNestingDepth: configuration.maxNestingDepth,
            maxLoopIterations: configuration.maxLoopIterations,
            autoEscape: configuration.autoEscape
        )
    }
}
