import Testing
@testable import LiquidTags
@testable import LiquidCore

@Suite("LiquidTags Module Tests")
struct TagTests {
    @Test("Tag registry creation")
    func tagRegistryCreation() async {
        let registry = TagRegistry()
        let tags = await registry.getAllTags()
        #expect(tags.isEmpty)
    }
}
