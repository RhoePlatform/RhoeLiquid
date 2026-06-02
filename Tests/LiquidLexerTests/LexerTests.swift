import Testing
@testable import LiquidLexer
@testable import LiquidCore

@Suite("LiquidLexer Module Tests")
struct LexerTests {
    @Test("Empty tokenization")
    func emptyTokenization() throws {
        let lexer = Lexer("")
        let tokens = try lexer.tokenize()
        #expect(tokens.isEmpty)
    }
}
