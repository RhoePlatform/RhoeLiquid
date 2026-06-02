import Testing
@testable import LiquidFilters
@testable import LiquidCore

@Suite("LiquidFilters Module Tests")
struct FilterTests {
    @Test("Filter registry creation")
    func filterRegistryCreation() async {
        let registry = FilterRegistry()
        let filters = await registry.getAllFilters()
        #expect(filters.isEmpty)
    }

    @Test("Filter registry stores custom filters")
    func filterRegistryStoresCustomFilters() async {
        struct EchoFilter: CustomFilter {
            let name = "echo"

            func apply(to value: Any, arguments: [Any], namedArguments: [String: Any]) async throws -> Any {
                value
            }
        }

        let registry = FilterRegistry()
        await registry.register(name: "echo", filter: EchoFilter())

        #expect(await registry.hasFilter("echo"))
        #expect(await registry.getAllFilters().keys.contains("echo"))

        await registry.unregister(name: "echo")
        #expect(await !registry.hasFilter("echo"))
    }
}
