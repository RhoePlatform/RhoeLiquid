import Testing
@testable import LiquidCore

@Suite("Template Cache Tests")
struct TemplateCacheTests {
    @Test("Long template keys are stable and hashed")
    func longTemplateKeysAreStable() {
        let template = String(repeating: "Hello {{ user.name | upcase }}\n", count: 80)

        let keyA = CacheKeyGenerator.key(for: template)
        let keyB = CacheKeyGenerator.key(for: template)

        #expect(keyA == keyB)
        #expect(keyA != template)
    }

    @Test("Template fingerprints distinguish different templates")
    func templateFingerprintsDifferentiateTemplates() {
        let templateA = String(repeating: "alpha {{ value }}\n", count: 64)
        let templateB = String(repeating: "beta {{ value }}\n", count: 64)

        let fingerprintA = CacheKeyGenerator.fingerprint(for: templateA)
        let fingerprintB = CacheKeyGenerator.fingerprint(for: templateB)

        #expect(fingerprintA != fingerprintB)
        #expect(fingerprintA.utf8Count == templateA.utf8.count)
        #expect(fingerprintB.utf8Count == templateB.utf8.count)
    }

    @Test("Warning memory pressure trims least recently used cache entries")
    func warningMemoryPressureTrimsEntries() async {
        let cache = TemplateCache(maxSize: 1_024 * 1_024, maxEntries: 4)

        await cache.set(key: "one", value: .text("one"))
        await cache.set(key: "two", value: .text("two"))
        await cache.set(key: "three", value: .text("three"))
        await cache.set(key: "four", value: .text("four"))

        _ = await cache.get(key: "three")
        _ = await cache.get(key: "four")

        await cache.handleMemoryPressure(.warning)

        let stats = await cache.statistics()
        #expect(stats.entryCount == 2)
        #expect(await cache.get(key: "one") == nil)
        #expect(await cache.get(key: "two") == nil)
        #expect(await cache.get(key: "three") != nil)
        #expect(await cache.get(key: "four") != nil)
    }

    @Test("Critical memory pressure clears the cache")
    func criticalMemoryPressureClearsCache() async {
        let cache = TemplateCache(maxSize: 1_024 * 1_024, maxEntries: 4)

        await cache.set(key: "one", value: .text("one"))
        await cache.set(key: "two", value: .text("two"))
        await cache.handleMemoryPressure(.critical)

        let stats = await cache.statistics()
        #expect(stats.entryCount == 0)
        #expect(await cache.get(key: "one") == nil)
        #expect(await cache.get(key: "two") == nil)
    }
}
