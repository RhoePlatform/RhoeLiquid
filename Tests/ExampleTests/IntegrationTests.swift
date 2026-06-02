import Testing
@testable import RhoeLiquid

@Suite("Integration Tests")
struct IntegrationTests {
    @Test("Basic integration test")
    func basicIntegration() async throws {
        let engine = LiquidEngine()
        let result = try await engine.render(template: "Hello World")
        #expect(result == "Hello World")
    }
}
