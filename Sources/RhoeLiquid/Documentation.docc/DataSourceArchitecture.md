# Data Source Architecture

RhoeLiquid includes a unified data loading layer for applications that want to feed structured external data into Liquid rendering.

## Stable Center

The stable part of the data story today includes both programmatic loading and the built-in `{% data %}` tag:

- `DataLoaderRegistry` chooses a loader based on file extension or URL scheme
- `{% data name = load(...) %}` uses the same loader registry through the active `LoadTag`
- loaders convert source data into the unified `DataValue` model
- templates can then consume the loaded values through the normal render context

## Built-In Loaders

The active package includes loaders for:

- JSON
- YAML
- TOML
- CSV
- Markdown
- XML / HTML
- SQLite
- GraphQL

## Unified Data Model

All loaders produce `DataValue`, which gives the engine one consistent shape for nested objects, arrays, strings, booleans, numbers, and dates.

That unified representation is what makes the data-oriented filters and loader APIs line up cleanly.

## Programmatic Example

```swift
let registry = DataLoaderRegistry()
await registry.register(JSONDataSource())

let users = try await registry.load(from: "/tmp/users.json")

let engine = LiquidEngine()
let output = try await engine.render(
    template: "{{ users[0].name }}",
    context: ["users": users.liquidValue]
)
```

## Data-Oriented Filters

The package also ships a set of registry-backed filters for loaded data, including helpers such as:

- `group_by`
- `sort_by`
- `find`
- `pluck`
- XML / HTML selection helpers
- SQLite query helpers

These filters are most useful once data has already been loaded into the render context by application code.

For XML / HTML in particular, the same shared query engine is also exposed programmatically on `DataValue` through `select(_:)`, `selectAll(_:)`, and `xpath(_:)`, so programmatic callers and template filters now use the same supported selector / XPath subset.

For SQLite-shaped row arrays, `sql_join` is now part of the active helper surface as an in-memory join that preserves the left row and nests the matched right row under an alias instead of flattening field collisions.

## Current Scope Notes

Programmatic loading remains the richest integration surface, especially if you need custom schemas or more orchestration around data refresh.

- programmatic loading is part of the active release surface
- the built-in `{% data %}` tag is also active for straightforward `load(...)` assignments
- more advanced authoring conventions around tag-driven data workflows are still evolving in docs and examples
