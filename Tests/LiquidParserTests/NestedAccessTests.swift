import Testing
@testable import LiquidParser
@testable import LiquidLexer
@testable import LiquidCore

@Suite("Nested Access Parser Tests")
struct NestedAccessTests {
    @Test("Single property access parses as one access node")
    func singlePropertyAccess() throws {
        let template = "{{ product.name }}"
        let lexer = Lexer(template)
        let tokens = try lexer.tokenize()
        let parser = Parser(consuming: tokens)
        
        let ast = try parser.parse()
        
        // Verify single level property access works
        guard case .template(let nodes) = ast,
              nodes.count == 1,
              case .output(let expr) = nodes[0],
              case .access(let baseExpr, let key) = expr,
              case .variable(let varName) = baseExpr,
              case .literal(.string(let propName)) = key else {
            #expect(Bool(false), "Expected access expression for product.name")
            return
        }

        #expect(varName.string == "product")
        #expect(propName.string == "name")
    }

    @Test("Nested property access now parses successfully")
    func nestedPropertyAccess() throws {
        let template = "{{ product.tags.size }}"
        let lexer = Lexer(template)
        let tokens = try lexer.tokenize()
        let parser = Parser(consuming: tokens)

        let ast = try parser.parse()

        guard case .template(let nodes) = ast,
              nodes.count == 1,
              case .output = nodes[0] else {
            #expect(Bool(false), "Expected nested access to parse into a single output node")
            return
        }
    }

    @Test("Multi-level nested access parses successfully")
    func multiLevelNestedAccess() throws {
        let template = "{{ user.profile.settings.theme.name }}"
        let lexer = Lexer(template)
        let tokens = try lexer.tokenize()
        let parser = Parser(consuming: tokens)

        let ast = try parser.parse()

        guard case .template(let nodes) = ast,
              nodes.count == 1,
              case .output = nodes[0] else {
            #expect(Bool(false), "Expected deep nested access to parse into a single output node")
            return
        }
    }

    @Test("Nested access followed by filters parses successfully")
    func nestedAccessWithFilters() throws {
        let template = "{{ product.tags.size | plus: 1 }}"
        let lexer = Lexer(template)
        let tokens = try lexer.tokenize()
        let parser = Parser(consuming: tokens)

        let ast = try parser.parse()

        guard case .template(let nodes) = ast,
              nodes.count == 1,
              case .output(let expression) = nodes[0],
              case .filtered = expression else {
            #expect(Bool(false), "Expected nested access with filters to parse into a filtered output")
            return
        }
    }
}
