import Foundation
import Testing
@testable import RhoeLiquid
import LiquidTags

@Suite("Advanced Feature Smoke Tests")
struct AdvancedFeatureSmokeTests {
    private func makeTemporaryTemplateDirectory(prefix: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(prefix)_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    @Test("Template caching reports cache hits on repeat renders")
    func cacheHitMetrics() async throws {
        let engine = LiquidEngine(configuration: LiquidConfiguration(cacheEnabled: true))
        let template = "Hello {{ name }}!"

        _ = try await engine.renderWithMetrics(template: template, context: ["name": "World"])
        let (result, metrics) = try await engine.renderWithMetrics(template: template, context: ["name": "World"])

        #expect(result == "Hello World!")
        #expect(metrics.cacheHit)
        #expect(metrics.lexingTime == 0)
        #expect(metrics.parsingTime == 0)
    }

    @Test("Secure configuration escapes script tags by default")
    func secureConfigurationEscapesHTML() async throws {
        let engine = LiquidEngine(configuration: .secure)
        let result = try await engine.render(
            template: "{{ content }}",
            context: ["content": "<script>alert('XSS')</script>"]
        )

        #expect(result.contains("&lt;script&gt;"))
        #expect(!result.contains("<script>"))
    }

    @Test("Template inheritance overrides child blocks while keeping parent structure")
    func templateInheritance() async throws {
        let engine = LiquidEngine()
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("rhoe_liquid_inheritance_\(UUID().uuidString)")

        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        try """
        <html>
        <body>
        {% block content %}Parent Content{% endblock %}
        </body>
        </html>
        """.write(
            to: tempDirectory.appendingPathComponent("base.liquid"),
            atomically: true,
            encoding: .utf8
        )

        try """
        {% extends "base.liquid" %}
        {% block content %}<p>Child Content</p>{% endblock %}
        """.write(
            to: tempDirectory.appendingPathComponent("child.liquid"),
            atomically: true,
            encoding: .utf8
        )

        let result = try await engine.renderWithInheritance(
            templatePath: "child.liquid",
            baseDirectory: tempDirectory
        )

        #expect(result.contains("<p>Child Content</p>"))
        #expect(result.contains("<html>"))
        #expect(!result.contains("Parent Content"))
    }

    @Test("renderFile resolves nested includes relative to the current template")
    func renderFileResolvesNestedRelativeIncludes() async throws {
        let engine = LiquidEngine()
        let tempDirectory = try makeTemporaryTemplateDirectory(prefix: "rhoe_liquid_nested_include")
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let partialsDirectory = tempDirectory.appendingPathComponent("partials", isDirectory: true)
        try FileManager.default.createDirectory(at: partialsDirectory, withIntermediateDirectories: true)

        try """
        <article>
        {% include "partials/card.liquid" title: page.title %}
        </article>
        """.write(
            to: tempDirectory.appendingPathComponent("page.liquid"),
            atomically: true,
            encoding: .utf8
        )

        try """
        <section class="card">
        <h1>{{ title }}</h1>
        {% include "badge.liquid" label: page.badge %}
        </section>
        """.write(
            to: partialsDirectory.appendingPathComponent("card.liquid"),
            atomically: true,
            encoding: .utf8
        )

        try "<span class=\"badge\">{{ label }}</span>".write(
            to: partialsDirectory.appendingPathComponent("badge.liquid"),
            atomically: true,
            encoding: .utf8
        )

        let result = try await engine.renderFile(
            at: tempDirectory.appendingPathComponent("page.liquid").path,
            context: [
                "page": [
                    "title": "Release Notes",
                    "badge": "Stable"
                ]
            ]
        )

        #expect(result.contains("<h1>Release Notes</h1>"))
        #expect(result.contains("<span class=\"badge\">Stable</span>"))
    }

    @Test("renderFile recognizes registered custom tags in included templates")
    func renderFileParsesCustomTagsInIncludedTemplates() async throws {
        let engine = LiquidEngine()
        let tempDirectory = try makeTemporaryTemplateDirectory(prefix: "rhoe_liquid_custom_tag_include")
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        struct AnnounceTag: LiquidTags.CustomTag {
            let name = "announce"
            let type: TagType = .simple

            func parse(_ parameters: String, context: TagParsingContext) async throws -> TagParameters {
                TagParameters(["value": parameters.trimmingCharacters(in: .whitespacesAndNewlines)])
            }

            func execute(parameters: TagParameters, content: String?, context: TagExecutionContext) async throws -> String {
                let value = parameters.get("value", as: String.self) ?? ""
                return "ANNOUNCE:\(value)"
            }
        }

        try await engine.registerTag(AnnounceTag())

        try """
        <main>{% include "partials/custom.liquid" %}</main>
        """.write(
            to: tempDirectory.appendingPathComponent("page.liquid"),
            atomically: true,
            encoding: .utf8
        )

        let partialsDirectory = tempDirectory.appendingPathComponent("partials", isDirectory: true)
        try FileManager.default.createDirectory(at: partialsDirectory, withIntermediateDirectories: true)

        try "{% announce shipped %}".write(
            to: partialsDirectory.appendingPathComponent("custom.liquid"),
            atomically: true,
            encoding: .utf8
        )

        let result = try await engine.renderFile(
            at: tempDirectory.appendingPathComponent("page.liquid").path
        )

        #expect(result.contains("ANNOUNCE:shipped"))
    }

    @Test("render tag keeps an isolated local scope")
    func renderTagUsesIsolatedScope() async throws {
        let engine = LiquidEngine()
        let tempDirectory = try makeTemporaryTemplateDirectory(prefix: "rhoe_liquid_render_scope")
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        try """
        {% assign local = "inside" %}
        render:{{ local }}|{{ shared }}
        """.write(
            to: tempDirectory.appendingPathComponent("snippet.liquid"),
            atomically: true,
            encoding: .utf8
        )

        try """
        {% assign local = "outside" %}
        before={{ local }}
        {% render "snippet.liquid" shared: site.name %}
        after={{ local }}
        """.write(
            to: tempDirectory.appendingPathComponent("page.liquid"),
            atomically: true,
            encoding: .utf8
        )

        let result = try await engine.renderFile(
            at: tempDirectory.appendingPathComponent("page.liquid").path,
            context: ["site": ["name": "Rhoe"]]
        )

        #expect(result.contains("before=outside"))
        #expect(result.contains("render:inside|Rhoe"))
        #expect(result.contains("after=outside"))
    }

    @Test("include with alias binds the with-value under the provided name")
    func includeWithAliasBindsScopedValue() async throws {
        let engine = LiquidEngine()
        let tempDirectory = try makeTemporaryTemplateDirectory(prefix: "rhoe_liquid_include_alias")
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        try "<p>{{ item.name }} - {{ item.price }}</p>".write(
            to: tempDirectory.appendingPathComponent("card.liquid"),
            atomically: true,
            encoding: .utf8
        )

        try "{% include \"card.liquid\" with product as item %}".write(
            to: tempDirectory.appendingPathComponent("page.liquid"),
            atomically: true,
            encoding: .utf8
        )

        let result = try await engine.renderFile(
            at: tempDirectory.appendingPathComponent("page.liquid").path,
            context: ["product": ["name": "Notebook", "price": 9]]
        )

        #expect(result.contains("Notebook"))
        #expect(result.contains("9"))
    }

    @Test("renderFile processes inheritance without a separate preprocessing pass")
    func renderFileProcessesInheritance() async throws {
        let engine = LiquidEngine()
        let tempDirectory = try makeTemporaryTemplateDirectory(prefix: "rhoe_liquid_render_file_inheritance")
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        try """
        <html><body>{% block content %}Parent{% endblock %}</body></html>
        """.write(
            to: tempDirectory.appendingPathComponent("base.liquid"),
            atomically: true,
            encoding: .utf8
        )

        try """
        {% extends "base.liquid" %}
        {% block content %}Child {{ page.title }}{% endblock %}
        """.write(
            to: tempDirectory.appendingPathComponent("child.liquid"),
            atomically: true,
            encoding: .utf8
        )

        let result = try await engine.renderFile(
            at: tempDirectory.appendingPathComponent("child.liquid").path,
            context: ["page": ["title": "Content"]]
        )

        #expect(result.contains("Child Content"))
        #expect(!result.contains(">Parent<"))
        #expect(result.contains("<html><body>"))
    }
}
