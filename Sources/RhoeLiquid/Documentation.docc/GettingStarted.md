# Getting Started

Learn how to integrate RhoeLiquid into your Swift project and start with the preferred `Rhoe` authoring surface.

## Installation

### Swift Package Manager

Add RhoeLiquid to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/RhoePlatform/RhoeLiquid.git", branch: "main")
]
```

Until the first public tag exists, prefer pinning a known branch or exact revision.

### Xcode Project Integration

1. Open your project in Xcode.
2. Choose File > Add Package Dependencies.
3. Enter `https://github.com/RhoePlatform/RhoeLiquid.git`.
4. Add the `RhoeLiquid` product to the target that needs Liquid rendering.

## Choose An Authoring Profile

`LiquidEngine` remains the convenience runtime, but `LiquidEnvironment` is the preferred integration surface for new authoring work:

```swift
import RhoeLiquid

let authoringEnvironment = LiquidEnvironment()
// Defaults to .extended

let strictCompatibilityEnvironment = LiquidEnvironment(
    profile: .shopifyCompatible
)
```

Use `extended` when you want the active Rhoe authoring features such as macros and template input contracts. Use `shopifyCompatible` when you need strict compatibility behavior and explicit rejection of Wave 16 syntax.

## Your First Template

```swift
import RhoeLiquid

let environment = LiquidEnvironment()

let template = """
Hello {{ user.name }}!
{% if user.premium %}
Welcome to our premium service.
{% endif %}
"""

let context: [String: Any] = [
    "user": [
        "name": "Alice",
        "premium": true
    ]
]

let result = try await environment.render(template: template, context: context)
print(result)
```

## Variables And Control Flow

Variables use the standard Liquid `{{ ... }}` syntax:

```swift
let template = "Welcome {{ name }}, you have {{ count }} items."
let context: [String: Any] = ["name": "Bob", "count": 42]
let result = try await engine.render(template: template, context: context)
```

## Macros And Input Contracts

Wave 16 plus Wave 17 make `extended` the preferred authoring layer. That means templates can declare both flat and nested required inputs and reuse markup with built-in macros:

```swift
let environment = LiquidEnvironment()

let template = """
{% input user: object %}
{% input user.name: string %}
{% input theme: string = "light" %}
{% input items[].title: string = "Untitled" %}

{% macro card(title, subtitle: nil) %}
<article class="card card-{{ theme }}">
  <h2>{{ title }}</h2>
  {% if subtitle %}<p>{{ subtitle }}</p>{% endif %}
</article>
{% endmacro %}

{{ card(title: user.name, subtitle: user.role) }}
"""

let output = try await environment.render(
    template: template,
    context: [
        "user": [
            "name": "Alice",
            "role": "Editor"
        ]
    ]
)
```

If a required input is missing, `LiquidEnvironment` reports that as a validation failure before the template finishes rendering.

Conditionals and loops follow the familiar Liquid tag syntax:

```swift
let template = """
{% for item in items %}
- {{ item | upcase }}
{% endfor %}
"""

let context: [String: Any] = ["items": ["bread", "milk", "eggs"]]
let result = try await engine.render(template: template, context: context)
```

## Built-In Metrics

Use `renderWithMetrics` when you want timing and cache information during development:

```swift
let (output, metrics) = try await engine.renderWithMetrics(
    template: template,
    context: context
)

print(output)
print("Total: \(metrics.totalTime)ms")
print("Cache hit: \(metrics.cacheHit)")
print("Observed template bytes: \(metrics.memoryStats.totalBytes)")
```

## Custom Filters

Custom filters can be registered at runtime:

```swift
struct DoubleFilter: CustomFilter {
    let name = "double"

    func apply(to value: Any, arguments: [Any], namedArguments: [String: Any]) async throws -> Any {
        if let int = value as? Int { return int * 2 }
        if let double = value as? Double { return double * 2 }
        return value
    }
}

let engine = LiquidEngine()
await engine.registerFilter(name: "double", filter: DoubleFilter())

let result = try await engine.render(template: "{{ value | double }}", context: ["value": 21])
```

## File-Backed Templates

Use `renderFile` when you want partials, relative includes, or block inheritance from the file system:

```swift
let output = try await engine.renderFile(
    at: "/tmp/templates/page.liquid",
    context: [
        "page": ["title": "Release Notes"],
        "site": ["name": "Rhoe"]
    ]
)
```

`include` shares the current render scope, while `render` uses an isolated local scope for its passed parameters. Both resolve relative template paths from the file that is currently being rendered.

Template names for `include`, `render`, and `extends` are currently string literals in the active parser surface.

## Current Scope Notes

The current platform surface centers on standalone template rendering, file-backed partial rendering, built-in filters, custom filters, runtime custom tags, caching, and both programmatic and tag-driven data loading. That core engine now also acts as the platform center for the sibling service, book, and Word integration repositories.

The preferred authoring surface is now `LiquidEnvironment(profile: .extended)`, which adds:

- built-in macros plus file-backed macro imports
- template input contracts with defaults and required-input validation
- analysis-time manifests for declared inputs, macro dependencies, and compatibility requirements

`shopifyCompatible` remains fully supported when you need a stricter compatibility lane without Wave 16 syntax.

Some adjacent surfaces remain compatibility-oriented rather than preferred for new extension work:

- the older `LiquidCore` custom-tag compatibility protocols
- the legacy-only `LiquidConfiguration.customTags` bootstrap path, which exists for older parser-style tags but is not the preferred extension API
- the archived optimizer/cache shims, where only the documented live subset affects the active runtime path

See the repository `README.md` for the current foundation scope, downstream integration notes, and validation commands.

## Next Steps

- Learn the syntax in <doc:TemplateBasics>
- Review the module layout in <doc:Architecture>
- Explore filter authoring in <doc:CustomFilters>
- Read <doc:PerformanceGuide> before doing performance-sensitive integration work
