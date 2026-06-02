import Testing
@testable import RhoeLiquid

@Suite("Wave 13 Platform Tests")
struct Wave13PlatformTests {
    @Test("Shopify-compatible fixtures render under the compatibility profile")
    func shopifyCompatibleFixturesRender() async throws {
        let environment = LiquidEnvironment(
            configuration: .default,
            profile: .shopifyCompatible,
            sandboxPolicy: .compatibilityStrict
        )

        let filterOutput = try await environment.render(
            template: "{{ product.title | upcase }}",
            context: ["product": ["title": "Wave 13"]]
        )
        #expect(filterOutput == "WAVE 13")

        let loopOutput = try await environment.render(
            template: "{% for item in items %}{{ item }}{% endfor %}",
            context: ["items": ["A", "B", "C"]]
        )
        #expect(loopOutput == "ABC")

        let assignOutput = try await environment.render(
            template: "{% assign total = price | round: 2 %}{{ total }}",
            context: ["price": 19.995]
        )
        #expect(assignOutput == "20.0")
    }

    @Test("Rhoe fixtures require the extended profile")
    func rhoeFixturesRequireExtendedProfile() async throws {
        let template = "{% liquid assign greeting = name %}Hello {% echo greeting %}"
        let strictEnvironment = LiquidEnvironment(
            configuration: .default,
            profile: .shopifyCompatible,
            sandboxPolicy: .trustedLocal
        )

        do {
            _ = try await strictEnvironment.render(template: template, context: ["name": "Wave 13"])
            Issue.record("Expected the shopify-compatible profile to reject rhoe-extended syntax")
        } catch let error as LiquidEnvironmentError {
            guard case .unsupportedProfileFeature = error else {
                Issue.record("Expected unsupportedProfileFeature, got \(error)")
                return
            }
        } catch {
            Issue.record("Expected LiquidEnvironmentError, got \(error)")
        }

        let extendedEnvironment = LiquidEnvironment(
            configuration: .default,
            profile: .extended,
            sandboxPolicy: .trustedLocal
        )
        let rendered = try await extendedEnvironment.render(
            template: template,
            context: ["name": "Wave 13"]
        )
        #expect(rendered == "Hello Wave 13")
    }

    @Test("Service-safe sandbox blocks debug tags")
    func serviceSafeSandboxBlocksDebugTags() async throws {
        let environment = LiquidEnvironment(
            configuration: .default,
            profile: .extended,
            sandboxPolicy: .serviceSafe
        )

        do {
            _ = try await environment.render(
                template: "{% debug customer %}",
                context: ["customer": ["name": "Wave 13"]]
            )
            Issue.record("Expected the service-safe sandbox to reject debug tags")
        } catch let error as LiquidEnvironmentError {
            guard case .sandboxViolation(let message) = error else {
                Issue.record("Expected sandboxViolation, got \(error)")
                return
            }
            #expect(message.contains("Debug"))
        } catch {
            Issue.record("Expected LiquidEnvironmentError, got \(error)")
        }
    }

    @Test("Template analysis exposes manifest dependencies and capabilities")
    func templateAnalysisExposesManifestDependencies() async {
        let environment = LiquidEnvironment(
            configuration: .default,
            profile: .extended,
            sandboxPolicy: .trustedLocal
        )

        let analysis = await environment.analyzeTemplate(
            "{% include 'shared.liquid' %}{{ customer.name | upcase }}"
        )

        #expect(analysis.isValid)
        #expect(analysis.manifest.referencedTemplates.contains("shared.liquid"))
        #expect(analysis.manifest.requiredVariables.contains("customer.name"))
        #expect(analysis.manifest.activeFilters.contains("upcase"))
        #expect(analysis.manifest.activeTags.contains("include"))
    }
}
