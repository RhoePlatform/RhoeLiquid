import Testing
@testable import LiquidParser
@testable import LiquidLexer
@testable import LiquidCore

@Suite("Multi-Parameter Filter Parser Tests")
struct MultiParameterFilterTests {
    @Test("Where filter captures both parameters")
    func whereFilterWithTwoParameters() throws {
        let template = "{{ items | where: 'active', true }}"

        let lexer = Lexer(template)
        let tokens = try lexer.tokenize()

        let parser = Parser(consuming: tokens)
        let ast = try parser.parse()

        guard case .template(let nodes) = ast,
              nodes.count == 1,
              case .output(let expr) = nodes[0] else {
            #expect(Bool(false), "Unexpected AST structure")
            return
        }

        guard case .filtered(_, let filters) = expr,
              filters.count == 1 else {
            #expect(Bool(false), "Expected filtered expression with one filter")
            return
        }

        let filter = filters[0]
        #expect(filter.name == "where")
        #expect(filter.arguments.count == 2)

        guard case .literal(.string(let firstArg)) = filter.arguments[0] else {
            #expect(Bool(false), "First argument should be string literal")
            return
        }
        #expect(firstArg == "active")

        guard case .literal(.boolean(let secondArg)) = filter.arguments[1] else {
            #expect(Bool(false), "Second argument should be boolean literal")
            return
        }
        #expect(secondArg)
    }

    @Test("Replace filter keeps both string arguments")
    func replaceFilterWithTwoParameters() throws {
        let template = "{{ text | replace: 'old', 'new' }}"

        let lexer = Lexer(template)
        let tokens = try lexer.tokenize()

        let parser = Parser(consuming: tokens)
        let ast = try parser.parse()

        guard case .template(let nodes) = ast,
              nodes.count == 1,
              case .output(let expr) = nodes[0],
              case .filtered(_, let filters) = expr,
              filters.count == 1 else {
            #expect(Bool(false), "Unexpected AST structure")
            return
        }

        let filter = filters[0]
        #expect(filter.name == "replace")
        #expect(filter.arguments.count == 2)

        guard case .literal(.string(let arg1)) = filter.arguments[0],
              case .literal(.string(let arg2)) = filter.arguments[1] else {
            #expect(Bool(false), "Arguments should be string literals")
            return
        }

        #expect(arg1 == "old")
        #expect(arg2 == "new")
    }

    @Test("Truncate filter keeps count and suffix")
    func truncateFilterWithTwoParameters() throws {
        let template = "{{ content | truncate: 50, '...' }}"

        let lexer = Lexer(template)
        let tokens = try lexer.tokenize()

        let parser = Parser(consuming: tokens)
        let ast = try parser.parse()

        guard case .template(let nodes) = ast,
              nodes.count == 1,
              case .output(let expr) = nodes[0],
              case .filtered(_, let filters) = expr,
              filters.count == 1 else {
            #expect(Bool(false), "Unexpected AST structure")
            return
        }

        let filter = filters[0]
        #expect(filter.name == "truncate")
        #expect(filter.arguments.count == 2)

        guard case .literal(.number(let length, _)) = filter.arguments[0],
              case .literal(.string(let ending)) = filter.arguments[1] else {
            #expect(Bool(false), "Arguments should be number and string literals")
            return
        }

        #expect(length == 50)
        #expect(ending == "...")
    }

    @Test("Chained filters preserve their argument lists")
    func chainedFiltersWithMultipleParameters() throws {
        let template = "{{ items | where: 'active', true | map: 'name' | join: ', ' }}"

        let lexer = Lexer(template)
        let tokens = try lexer.tokenize()

        let parser = Parser(consuming: tokens)
        let ast = try parser.parse()

        guard case .template(let nodes) = ast,
              nodes.count == 1,
              case .output(let expr) = nodes[0],
              case .filtered(_, let filters) = expr else {
            #expect(Bool(false), "Unexpected AST structure")
            return
        }

        #expect(filters.count == 3)

        let whereFilter = filters[0]
        #expect(whereFilter.name == "where")
        #expect(whereFilter.arguments.count == 2)

        let mapFilter = filters[1]
        #expect(mapFilter.name == "map")
        #expect(mapFilter.arguments.count == 1)

        let joinFilter = filters[2]
        #expect(joinFilter.name == "join")
        #expect(joinFilter.arguments.count == 1)
    }

    @Test("Zero-argument filters still parse correctly")
    func singleParameterFilterStillWorks() throws {
        let template = "{{ text | upcase }}"

        let lexer = Lexer(template)
        let tokens = try lexer.tokenize()

        let parser = Parser(consuming: tokens)
        let ast = try parser.parse()

        guard case .template(let nodes) = ast,
              nodes.count == 1,
              case .output(let expr) = nodes[0],
              case .filtered(_, let filters) = expr,
              filters.count == 1 else {
            #expect(Bool(false), "Unexpected AST structure")
            return
        }

        let filter = filters[0]
        #expect(filter.name == "upcase")
        #expect(filter.arguments.isEmpty)
    }

    @Test("Single-argument filters still parse correctly")
    func filterWithOneParameter() throws {
        let template = "{{ items | limit: 5 }}"

        let lexer = Lexer(template)
        let tokens = try lexer.tokenize()

        let parser = Parser(consuming: tokens)
        let ast = try parser.parse()

        guard case .template(let nodes) = ast,
              nodes.count == 1,
              case .output(let expr) = nodes[0],
              case .filtered(_, let filters) = expr,
              filters.count == 1 else {
            #expect(Bool(false), "Unexpected AST structure")
            return
        }

        let filter = filters[0]
        #expect(filter.name == "limit")
        #expect(filter.arguments.count == 1)

        guard case .literal(.number(let limit, _)) = filter.arguments[0] else {
            #expect(Bool(false), "Argument should be number literal")
            return
        }

        #expect(limit == 5)
    }
}
