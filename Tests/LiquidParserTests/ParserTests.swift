import Testing
@testable import LiquidParser
@testable import LiquidCore

@Suite("LiquidParser Module Tests")
struct ParserTests {
    @Test("Empty parsing")
    func emptyParsing() throws {
        let parser = Parser(consuming: [])
        let ast = try parser.parse()
        if case .template(let nodes) = ast {
            #expect(nodes.isEmpty)
        } else {
            #expect(Bool(false), "Expected template node")
        }
    }
}
