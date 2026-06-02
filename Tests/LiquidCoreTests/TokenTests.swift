import Testing
@testable import LiquidCore

@Suite("Token Tests")
struct TokenTests {
    @Test("Token creation")
    func tokenCreation() {
        let token = Token(
            type: .text(InlineString("hello")),
            position: 0,
            line: 1,
            column: 1
        )
        
        #expect(token.isText == true)
        #expect(token.stringValue == "hello")
    }
}