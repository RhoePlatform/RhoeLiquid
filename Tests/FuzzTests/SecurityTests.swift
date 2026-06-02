import Testing
@testable import RhoeLiquid

@Suite("Security Tests")
struct SecurityTests {
    @Test("Basic security test")
    func basicSecurity() async throws {
        let engine = LiquidEngine()
        let result = try await engine.render(template: "Hello World")
        #expect(result == "Hello World")
    }
}
