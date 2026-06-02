# ``RhoeLiquid``

Liquid rendering for Swift Package Manager projects.

## Overview

`RhoeLiquid` is the umbrella module for the package’s Liquid implementation. It pulls together the lexer, parser, renderer, filters, tags, utilities, and selected higher-level extensions behind a single public API.

The active package surface includes standalone rendering, file-backed `include` / `render`, block inheritance, custom filters, caching, and programmatic data loading.

The package is organized as small Swift modules:

- `LiquidCore` for shared types, errors, metrics, and data-loading helpers
- `LiquidLexer` for tokenization
- `LiquidParser` for AST construction
- `LiquidRenderer` for evaluation and rendering
- `LiquidFilters` for built-in filters
- `LiquidTags` for tag infrastructure and example tag implementations
- `LiquidExtensions` for secure template loading and inheritance helpers
- `LiquidUtilities` for supporting utilities such as HTML escaping

## Quick Start

```swift
import RhoeLiquid

let engine = LiquidEngine()

let output = try await engine.render(
    template: "Hello {{ user.name }}!",
    context: ["user": ["name": "Alice"]]
)

print(output)
```

If you want timing and cache information during development:

```swift
let (output, metrics) = try await engine.renderWithMetrics(
    template: "Hello {{ user.name }}!",
    context: ["user": ["name": "Alice"]]
)

print(output)
print(metrics.totalTime)
print(metrics.memoryStats.totalBytes)
```

## Scope

This repository is the greenfield `RhoeLiquid` foundation line. It carries the Swift-side Liquid engine, DOCX package, service, CLI, and WASM surfaces together so the downstream platform repos can depend on one canonical foundation package.

The completed Word add-in shell now lives in `RhoePublishStudio` and is intentionally not part of this foundation seed.

## Topics

### Start Here

- <doc:GettingStarted>
- <doc:TemplateBasics>
- <doc:LanguageReference>
- <doc:Architecture>

### Customization

- <doc:CustomFilters>
- <doc:DataSourceArchitecture>

### Performance and Operations

- <doc:PerformanceGuide>
- ``PerformanceMetrics``
- ``LiquidConfiguration``

### Primary API

- ``LiquidEngine``
