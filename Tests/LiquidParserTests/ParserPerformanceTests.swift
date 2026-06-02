import Foundation
import Testing
import BenchmarkSupport
@testable import LiquidLexer
@testable import LiquidParser

@Suite("Parser Performance", .serialized)
struct ParserPerformanceTests {
    @Test("Large template parsing benchmark")
    func largeTemplateParsingBenchmark() throws {
        let lexer = Lexer(Self.largeTemplate)
        let tokens = try lexer.tokenize()
        let plan = BenchmarkPlan(iterations: 200, warmupIterations: 10, trials: 5)

        let summary = try BenchmarkRunner.measure(plan: plan) {
            let parser = Parser(consuming: tokens)
            let ast = try parser.parse()
            #expect(ast.nestingDepth() > 0)
        }

        print(summary.formatted(label: "Parser benchmark", iterations: plan.iterations))
    }

    @Test("Property-access parsing benchmark")
    func propertyAccessParsingBenchmark() throws {
        let lexer = Lexer(Self.propertyAccessTemplate)
        let tokens = try lexer.tokenize()
        let plan = BenchmarkPlan(iterations: 200, warmupIterations: 10, trials: 5)

        let summary = try BenchmarkRunner.measure(plan: plan) {
            let parser = Parser(consuming: tokens)
            let ast = try parser.parse()
            #expect(ast.nestingDepth() > 0)
        }

        print(summary.formatted(label: "Parser benchmark (property-access)", iterations: plan.iterations))
    }

    private static let largeTemplate: String = {
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

        return Array(repeating: section, count: 40).joined(separator: "\n")
    }()

    private static let propertyAccessTemplate: String = {
        let section = """
        {% if product.available %}
          {{ product.title }}
          {{ product.description }}
          {{ product.vendor.name }}
          {{ product.vendor.address.city }}
          {% for variant in product.variants %}
            {{ variant.name }}
            {{ variant.sku.code }}
            {{ variant.inventory.location.aisle }}
            {{ variant.inventory.location.bin }}
          {% endfor %}
        {% endif %}
        """

        return Array(repeating: section, count: 50).joined(separator: "\n")
    }()
}
