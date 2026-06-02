import Foundation

/// Builds development-time metrics about template memory and AST shape.
public enum TemplateMetricsAnalyzer {
    public static func memoryStats(
        source: String,
        tokens: [Token]? = nil,
        ast: ASTNode
    ) -> MemoryStats {
        var observedStrings: [InlineString] = []
        observedStrings.reserveCapacity(1 + (tokens?.count ?? 0) * 2)
        observedStrings.append(InlineString(source))

        if let tokens {
            for token in tokens {
                token.type.appendInlineStrings(to: &observedStrings)
            }
        }

        ast.visit { node in
            node.appendShallowInlineStrings(to: &observedStrings)

            for expression in node.expressions {
                expression.appendInlineStrings(to: &observedStrings)
            }
        }

        return InlineString.memoryStats(for: observedStrings)
    }
}

private extension TokenType {
    func appendInlineStrings(to observedStrings: inout [InlineString]) {
        switch self {
        case .text(let value), .identifier(let value), .string(let value):
            observedStrings.append(value)
        default:
            break
        }
    }
}

private extension ASTNode {
    func appendShallowInlineStrings(to observedStrings: inout [InlineString]) {
        switch self {
        case .text(let value),
             .raw(let value),
             .extends(template: let value),
             .increment(name: let value),
             .decrement(name: let value):
            observedStrings.append(value)
        case .assign(variable: let variable, value: _),
             .capture(variable: let variable, body: _),
             .for(variable: let variable, in: _, body: _, empty: _, params: _),
             .tablerow(variable: let variable, in: _, body: _, params: _):
            observedStrings.append(variable)
        case .macro(signature: let signature, body: _):
            observedStrings.append(signature.name)
            for parameter in signature.parameters {
                observedStrings.append(parameter.name)
            }
        case .include(template: let template, with: _, as: let alias):
            observedStrings.append(template)
            if let alias {
                observedStrings.append(alias)
            }
        case .macroImport(let macroImport):
            observedStrings.append(macroImport.template)
            if let namespace = macroImport.namespace {
                observedStrings.append(namespace)
            }
            observedStrings.append(contentsOf: macroImport.importedMacros)
        case .input(let contract):
            observedStrings.append(contract.name)
        case .block(name: let name, body: _),
             .renderBlock(name: let name, params: _):
            observedStrings.append(name)
        case .call(name: let name, arguments: _, body: _),
             .slot(name: let name, body: _),
             .fill(name: let name, body: _):
            observedStrings.append(name)
        case .registeredCustomTag(name: let name, markup: let markup, body: let body):
            observedStrings.append(name)
            observedStrings.append(markup)
            if let body {
                observedStrings.append(body.source)
            }
        case .cycle(group: let group, items: _):
            if let group, case .literal(.string(let str)) = group {
                observedStrings.append(str)
            }
        case .template, .output, .if, .unless, .case, .comment, .liquid, .echo, .debug,
             .break, .continue, .pipeline, .custom:
            break
        }
    }
}

private extension Expression {
    func appendInlineStrings(to observedStrings: inout [InlineString]) {
        switch self {
        case .literal(let value):
            value.appendInlineStrings(to: &observedStrings)
        case .variable(let name):
            observedStrings.append(name)
        case .binary(left: let left, op: _, right: let right):
            left.appendInlineStrings(to: &observedStrings)
            right.appendInlineStrings(to: &observedStrings)
        case .unary(op: _, expr: let expression),
             .test(expr: let expression, test: _):
            expression.appendInlineStrings(to: &observedStrings)
        case .range(start: let start, end: let end):
            start.appendInlineStrings(to: &observedStrings)
            end.appendInlineStrings(to: &observedStrings)
        case .filtered(expr: let expression, filters: let filters):
            expression.appendInlineStrings(to: &observedStrings)
            for filter in filters {
                filter.appendInlineStrings(to: &observedStrings)
            }
        case .access(expr: let expression, key: let key):
            expression.appendInlineStrings(to: &observedStrings)
            key.appendInlineStrings(to: &observedStrings)
        case .call(name: let name, arguments: let arguments):
            observedStrings.append(name)
            for argument in arguments {
                argument.value.appendInlineStrings(to: &observedStrings)
            }
        }
    }
}

private extension Filter {
    func appendInlineStrings(to observedStrings: inout [InlineString]) {
        observedStrings.append(name)
        for argument in arguments {
            argument.appendInlineStrings(to: &observedStrings)
        }
        for argument in namedArguments.values {
            argument.appendInlineStrings(to: &observedStrings)
        }
    }
}

private extension Value {
    func appendInlineStrings(to observedStrings: inout [InlineString]) {
        switch self {
        case .string(let value):
            observedStrings.append(value)
        case .array(let values):
            for value in values {
                value.appendInlineStrings(to: &observedStrings)
            }
        case .dictionary(let values):
            for value in values.values {
                value.appendInlineStrings(to: &observedStrings)
            }
        case .number, .boolean, .null:
            break
        }
    }
}
