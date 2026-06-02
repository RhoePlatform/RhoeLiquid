# Data and Debug Tags

Rhoe extensions for loading external data and inspecting render execution.

## `data` with `load(...)`

| Field | Value |
| --- | --- |
| Status | `RhoeLiquid extension` |
| Signature | `{% data name = load(source, cache:n, watch:bool, timeout:n) %}` |
| Returns | Empty output; assigns loaded data to `name`. |
| Loaders | JSON, Markdown, CSV, XML/HTML, SQLite-shaped data, YAML, TOML, GraphQL. |
| Evidence | `Sources/LiquidTags/DataSource/LoadTag.swift`, `Documentation/Guides/DataSources/` |

```liquid
{% data catalog = load("catalog.json", cache: 60, timeout: 10) %}

{% for product in catalog.products %}
  {{ product.title }}
{% endfor %}
```

Options are resolved from literals or variables. `watch` accepts booleans and common boolean-like strings. `cache` and `timeout` resolve as time intervals.

## `debug`

| Field | Value |
| --- | --- |
| Status | `RhoeLiquid extension` |
| Signature | `{% debug %}` or `{% debug expression %}` |
| Returns | Debug instrumentation output/side effects according to active debug configuration. |
| Evidence | `Sources/LiquidCore/Debug/`, `Sources/LiquidParser/Parser.swift` |

`debug` belongs to development and diagnostic workflows. Production profiles should disable or restrict it through sandbox policy.

## Custom Tags

| Field | Value |
| --- | --- |
| Status | `RhoeLiquid extension` |
| Registration | `LiquidEngine.registerTag(_:)` |
| Scope | Parser and renderer recognize registered tags, including block tags. |

The manifest name for this surface is `custom_tag`. The older `LiquidCore.CustomTag` / `TagNode` compatibility path is still bridgeable through the legacy adapter, but new tags should use the active `LiquidTags.CustomTag` surface.

## Archived `pipeline`

| Field | Value |
| --- | --- |
| Status | `Archived` |
| Signature | `{% pipeline %}...{% endpipeline %}` |
| Behavior | Parser recognizes the tag and rejects it with an archived-feature error. |
| Evidence | `Tests/RhoeLiquidTests/Wave9SyntaxRuntimeTests.swift` |
