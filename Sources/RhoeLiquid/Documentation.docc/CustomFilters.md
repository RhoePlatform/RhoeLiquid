# Custom Filters

Custom filters are the primary stable extension point in the current RhoeLiquid package surface.

## Overview

Implement the `CustomFilter` protocol to add domain-specific value transforms, then register the filter with `LiquidEngine`.

Registry-backed filters run after the renderer's built-in hot-path filters. That means core filters such as `upcase`, `append`, `size`, and similar primitives stay fast, while custom behavior remains easy to extend.

## Basic Example

```swift
import RhoeLiquid

struct DoubleFilter: CustomFilter {
    let name = "double"

    func apply(
        to value: Any,
        arguments: [Any],
        namedArguments: [String: Any]
    ) async throws -> Any {
        if let int = value as? Int { return int * 2 }
        if let double = value as? Double { return double * 2 }
        return value
    }
}
```

Register the filter and use it in a template:

```swift
let engine = LiquidEngine()
await engine.registerFilter(name: "double", filter: DoubleFilter())

let result = try await engine.render(
    template: "{{ value | double }}",
    context: ["value": 21]
)
```

## Registration At Construction Time

You can also provide custom filters through `LiquidConfiguration`:

```swift
let configuration = LiquidConfiguration(
    customFilters: [
        "double": DoubleFilter()
    ]
)

let engine = LiquidEngine(configuration: configuration)
```

Those configuration filters are loaded into the engine registry during initialization.

## Filters With Arguments

```swift
struct WrapFilter: CustomFilter {
    let name = "wrap"

    func apply(
        to value: Any,
        arguments: [Any],
        namedArguments: [String: Any]
    ) async throws -> Any {
        let prefix = arguments.first as? String ?? ""
        let suffix = arguments.dropFirst().first as? String ?? prefix
        return prefix + String(describing: value) + suffix
    }
}
```

Template use:

```liquid
{{ title | wrap: "[", "]" }}
```

## Guidance

- Prefer filters for value transformation.
- Keep filters deterministic unless the use case genuinely needs side effects.
- Use normal Swift primitives in arguments and return values whenever possible.
- Add a focused test whenever a filter changes behavior.

## Scope Notes

Custom filters are a stable part of the active runtime surface.

Custom tags now use the same active runtime surface: register them through `LiquidEngine.registerTag(_:)`, and the parser/renderer will execute them through the `LiquidTags` registry. Older parser-style tags can be bridged with `LegacyCustomTagAdapter` or `LiquidEngine.registerLegacyTag(...)`.
