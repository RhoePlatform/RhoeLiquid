import Foundation
import Testing
import BenchmarkSupport
@testable import LiquidLexer

@Suite("Lexer Performance", .serialized)
struct LexerPerformanceTests {
    @Test("Large template tokenization benchmark")
    func largeTemplateTokenizationBenchmark() throws {
        let template = Self.largeTemplate
        let plan = BenchmarkPlan(iterations: 200, warmupIterations: 10, trials: 5)

        let summary = try BenchmarkRunner.measure(plan: plan) {
            let lexer = Lexer(template)
            let tokens = try lexer.tokenize()
            #expect(!tokens.isEmpty)
        }

        print(summary.formatted(label: "Lexer benchmark", iterations: plan.iterations))
    }

    @Test("String-heavy tokenization benchmark")
    func stringHeavyTokenizationBenchmark() throws {
        let template = Self.stringHeavyTemplate
        let plan = BenchmarkPlan(iterations: 200, warmupIterations: 10, trials: 5)

        let summary = try BenchmarkRunner.measure(plan: plan) {
            let lexer = Lexer(template)
            let tokens = try lexer.tokenize()
            #expect(!tokens.isEmpty)
        }

        print(summary.formatted(label: "Lexer benchmark (string-heavy)", iterations: plan.iterations))
    }

    @Test("Operator-heavy tokenization benchmark")
    func operatorHeavyTokenizationBenchmark() throws {
        let template = Self.operatorHeavyTemplate
        let plan = BenchmarkPlan(iterations: 200, warmupIterations: 10, trials: 5)

        let summary = try BenchmarkRunner.measure(plan: plan) {
            let lexer = Lexer(template)
            let tokens = try lexer.tokenize()
            #expect(!tokens.isEmpty)
        }

        print(summary.formatted(label: "Lexer benchmark (operator-heavy)", iterations: plan.iterations))
    }

    @Test("Number-heavy tokenization benchmark")
    func numberHeavyTokenizationBenchmark() throws {
        let template = Self.numberHeavyTemplate
        let plan = BenchmarkPlan(iterations: 200, warmupIterations: 10, trials: 5)

        let summary = try BenchmarkRunner.measure(plan: plan) {
            let lexer = Lexer(template)
            let tokens = try lexer.tokenize()
            #expect(!tokens.isEmpty)
        }

        print(summary.formatted(label: "Lexer benchmark (number-heavy)", iterations: plan.iterations))
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

    private static let stringHeavyTemplate: String = {
        let section = """
        {% assign title = "Field Notes" %}
        {% assign subtitle = 'Heavy-duty notebook' %}
        {{ items | where: 'category', 'paper goods' | map: 'name' | join: ', ' }}
        {% render "card", title: "Field Notes", subtitle: 'Heavy-duty notebook' %}
        """

        return Array(repeating: section, count: 50).joined(separator: "\n")
    }()

    private static let operatorHeavyTemplate: String = {
        let section = """
        {% if product.price >= 10 and product.price <= 99 and product.title != "Draft" %}
          {% assign labels = items | where: 'category', 'paper' | map: 'name' | join: ', ' %}
          {% for variant in product.variants limit: 5, offset: 1 %}
            {% if variant.stock > 0 and variant.price < 100 %}
              {{ variant.title | append: " (" | append: variant.sku | append: ")" }}
            {% endif %}
          {% endfor %}
          {% for i in (1..12) %}
            {% assign slot = i %}
          {% endfor %}
        {% endif %}
        """

        return Array(repeating: section, count: 40).joined(separator: "\n")
    }()

    private static let numberHeavyTemplate: String = {
        let section = """
        {% if 12 >= 10 and 12 <= 99 and 12 != 42 %}
          {% assign ratio = 12.5 %}
          {% assign lower = 1.25 %}
          {% assign upper = 99.75 %}
          {% for i in (1..250) %}
            {% if i > 10 and i < 200 %}
              {{ i | plus: 1 | minus: 2 | times: 3 | divided_by: 4 | round: 2 }}
              {{ ratio | round: 2 }}
            {% endif %}
          {% endfor %}
        {% endif %}
        """

        return Array(repeating: section, count: 40).joined(separator: "\n")
    }()
}
