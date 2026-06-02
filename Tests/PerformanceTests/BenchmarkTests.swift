import Testing
import BenchmarkSupport
import LiquidCore
import LiquidLexer
import LiquidParser
@testable import RhoeLiquid

@Suite("Render Benchmark Tests", .serialized)
struct BenchmarkTests {
    @Test("Engine creation performance")
    func engineCreation() async {
        let engine = LiquidEngine()
        let info = await engine.engineInfo
        #expect(!info.version.isEmpty)
    }

    @Test("Warm render benchmark")
    func warmRenderBenchmark() async throws {
        let engine = LiquidEngine()
        let template = Self.benchmarkTemplate
        let context = Self.makeBenchmarkContext()
        let plan = BenchmarkPlan(iterations: 100, warmupIterations: 5, trials: 5)

        _ = try await engine.render(template: template, context: context)

        let summary = try await BenchmarkRunner.measure(plan: plan) {
            let output = try await engine.render(template: template, context: context)
            #expect(!output.isEmpty)
        }

        print(summary.formatted(label: "Render benchmark (warm cache)", iterations: plan.iterations))
    }

    @Test("Steady compiled warm render benchmark")
    func steadyCompiledWarmRenderBenchmark() async throws {
        let engine = LiquidEngine()
        let template = Self.benchmarkTemplate
        let context = Self.makeBenchmarkContext()
        let plan = BenchmarkPlan(iterations: 100, warmupIterations: 5, trials: 5)

        _ = try await engine.render(template: template, context: context)
        _ = try await engine.render(template: template, context: context)

        let summary = try await BenchmarkRunner.measure(plan: plan) {
            let output = try await engine.render(template: template, context: context)
            #expect(!output.isEmpty)
        }

        print(summary.formatted(label: "Render benchmark (steady compiled warm cache)", iterations: plan.iterations))
    }

    @Test("Uncached render benchmark")
    func uncachedRenderBenchmark() async throws {
        let engine = LiquidEngine()
        let template = Self.benchmarkTemplate
        let context = Self.makeBenchmarkContext()
        let plan = BenchmarkPlan(iterations: 40, warmupIterations: 2, trials: 5)

        let summary = try await BenchmarkRunner.measure(plan: plan) {
            await engine.clearPerformanceCaches()
            let output = try await engine.render(template: template, context: context)
            #expect(!output.isEmpty)
        }

        print(summary.formatted(label: "Render benchmark (uncached)", iterations: plan.iterations))
    }

    @Test("Benchmark template parse benchmark")
    func benchmarkTemplateParseBenchmark() async throws {
        let template = Self.benchmarkTemplate
        let plan = BenchmarkPlan(iterations: 80, warmupIterations: 3, trials: 5)

        let summary = try BenchmarkRunner.measure(plan: plan) {
            let ast = try Self.parseBenchmarkTemplate(template)
            #expect(!ast.children.isEmpty)
        }

        print(summary.formatted(label: "Benchmark template parse", iterations: plan.iterations))
    }

    @Test("Benchmark template compile benchmark")
    func benchmarkTemplateCompileBenchmark() async throws {
        let ast = try Self.parseBenchmarkTemplate(Self.benchmarkTemplate)
        let compiler = TemplateCompiler()
        let plan = BenchmarkPlan(iterations: 120, warmupIterations: 3, trials: 5)

        let summary = BenchmarkRunner.measure(plan: plan) {
            let compiled = compiler.compile(ast)
            #expect(!compiled.staticSegments.isEmpty)
        }

        print(summary.formatted(label: "Benchmark template compile", iterations: plan.iterations))
    }

    @Test("String output benchmark")
    func stringOutputBenchmark() async throws {
        let engine = LiquidEngine()
        let template = Self.stringOutputTemplate
        let context = Self.makeBenchmarkContext()
        let plan = BenchmarkPlan(iterations: 150, warmupIterations: 5, trials: 5)

        _ = try await engine.render(template: template, context: context)

        let summary = try await BenchmarkRunner.measure(plan: plan) {
            let output = try await engine.render(template: template, context: context)
            #expect(!output.isEmpty)
        }

        print(summary.formatted(label: "Render benchmark (string output)", iterations: plan.iterations))
    }

    @Test("Filtered output benchmark")
    func filteredOutputBenchmark() async throws {
        let engine = LiquidEngine()
        let template = Self.filteredOutputTemplate
        let context = Self.makeBenchmarkContext()
        let plan = BenchmarkPlan(iterations: 150, warmupIterations: 5, trials: 5)

        _ = try await engine.render(template: template, context: context)

        let summary = try await BenchmarkRunner.measure(plan: plan) {
            let output = try await engine.render(template: template, context: context)
            #expect(!output.isEmpty)
        }

        print(summary.formatted(label: "Render benchmark (filtered output)", iterations: plan.iterations))
    }

    @Test("Conditional section benchmark")
    func conditionalSectionBenchmark() async throws {
        let engine = LiquidEngine()
        let template = Self.conditionalSectionTemplate
        let context = Self.makeBenchmarkContext()
        let plan = BenchmarkPlan(iterations: 120, warmupIterations: 5, trials: 5)

        _ = try await engine.render(template: template, context: context)

        let summary = try await BenchmarkRunner.measure(plan: plan) {
            let output = try await engine.render(template: template, context: context)
            #expect(!output.isEmpty)
        }

        print(summary.formatted(label: "Render benchmark (conditional section)", iterations: plan.iterations))
    }

    @Test("Loop section benchmark")
    func loopSectionBenchmark() async throws {
        let engine = LiquidEngine()
        let template = Self.loopSectionTemplate
        let context = Self.makeBenchmarkContext()
        let plan = BenchmarkPlan(iterations: 120, warmupIterations: 5, trials: 5)

        _ = try await engine.render(template: template, context: context)

        let summary = try await BenchmarkRunner.measure(plan: plan) {
            let output = try await engine.render(template: template, context: context)
            #expect(!output.isEmpty)
        }

        print(summary.formatted(label: "Render benchmark (loop section)", iterations: plan.iterations))
    }

    @Test("Loop section simple output benchmark")
    func loopSectionSimpleOutputBenchmark() async throws {
        let engine = LiquidEngine()
        let template = Self.loopSectionSimpleOutputTemplate
        let context = Self.makeBenchmarkContext()
        let plan = BenchmarkPlan(iterations: 120, warmupIterations: 5, trials: 5)

        _ = try await engine.render(template: template, context: context)

        let summary = try await BenchmarkRunner.measure(plan: plan) {
            let output = try await engine.render(template: template, context: context)
            #expect(!output.isEmpty)
        }

        print(summary.formatted(label: "Render benchmark (loop section simple output)", iterations: plan.iterations))
    }

    @Test("Loop section static text benchmark")
    func loopSectionStaticTextBenchmark() async throws {
        let engine = LiquidEngine()
        let template = Self.loopSectionStaticTextTemplate
        let context = Self.makeBenchmarkContext()
        let plan = BenchmarkPlan(iterations: 120, warmupIterations: 5, trials: 5)

        _ = try await engine.render(template: template, context: context)

        let summary = try await BenchmarkRunner.measure(plan: plan) {
            let output = try await engine.render(template: template, context: context)
            #expect(!output.isEmpty)
        }

        print(summary.formatted(label: "Render benchmark (loop section static text)", iterations: plan.iterations))
    }

    @Test("Loop section filtered output benchmark")
    func loopSectionFilteredOutputBenchmark() async throws {
        let engine = LiquidEngine()
        let template = Self.loopSectionFilteredOutputTemplate
        let context = Self.makeBenchmarkContext()
        let plan = BenchmarkPlan(iterations: 120, warmupIterations: 5, trials: 5)

        _ = try await engine.render(template: template, context: context)

        let summary = try await BenchmarkRunner.measure(plan: plan) {
            let output = try await engine.render(template: template, context: context)
            #expect(!output.isEmpty)
        }

        print(summary.formatted(label: "Render benchmark (loop section filtered output)", iterations: plan.iterations))
    }

    private static let benchmarkTemplate: String = {
        let section = """
        <section class="product">
          <h2>{{ product.title | upcase }}</h2>
          {% if product.available %}
            <p>{{ product.description }}</p>
            <ul>
            {% for variant in product.variants %}
              <li>{{ variant.name }} - {{ variant.price | round: 2 }}</li>
            {% endfor %}
            </ul>
          {% else %}
            <p>Sold out</p>
          {% endif %}
        </section>
        """

        return Array(repeating: section, count: 25).joined(separator: "\n")
    }()

    private static let stringOutputTemplate = Array(
        repeating: "{{ product.description }}",
        count: 80
    ).joined(separator: "\n")

    private static let filteredOutputTemplate = Array(
        repeating: "{{ variant.price | round: 2 }}",
        count: 80
    ).joined(separator: "\n")

    private static let conditionalSectionTemplate: String = {
        let section = """
        {% if product.available %}
          <p>{{ product.description }}</p>
        {% else %}
          <p>Sold out</p>
        {% endif %}
        """

        return Array(repeating: section, count: 50).joined(separator: "\n")
    }()

    private static let loopSectionTemplate: String = {
        let section = """
        <ul>
        {% for variant in product.variants %}
          <li>{{ variant.name }} - {{ variant.price | round: 2 }}</li>
        {% endfor %}
        </ul>
        """

        return Array(repeating: section, count: 35).joined(separator: "\n")
    }()

    private static let loopSectionSimpleOutputTemplate: String = {
        let section = """
        <ul>
        {% for variant in product.variants %}
          <li>{{ variant.name }}</li>
        {% endfor %}
        </ul>
        """

        return Array(repeating: section, count: 35).joined(separator: "\n")
    }()

    private static let loopSectionStaticTextTemplate: String = {
        let section = """
        <ul>
        {% for variant in product.variants %}
          <li>Variant</li>
        {% endfor %}
        </ul>
        """

        return Array(repeating: section, count: 35).joined(separator: "\n")
    }()

    private static let loopSectionFilteredOutputTemplate: String = {
        let section = """
        <ul>
        {% for variant in product.variants %}
          <li>{{ variant.price | round: 2 }}</li>
        {% endfor %}
        </ul>
        """

        return Array(repeating: section, count: 35).joined(separator: "\n")
    }()

    private static func makeBenchmarkContext() -> [String: Any] {
        [
            "product": [
                "title": "Field Notes",
                "available": true,
                "description": "A durable notebook for heavy use.",
                "variants": [
                    ["name": "Pocket", "price": 9.99],
                    ["name": "A5", "price": 12.49],
                    ["name": "Hardcover", "price": 19.95]
                ]
            ],
            "variant": ["name": "Pocket", "price": 9.99]
        ]
    }

    private static func parseBenchmarkTemplate(_ template: String) throws -> ASTNode {
        let lexer = Lexer(template)
        let tokens = try lexer.tokenize()
        let parser = Parser(consuming: tokens, source: template)
        return try parser.parse()
    }
}
