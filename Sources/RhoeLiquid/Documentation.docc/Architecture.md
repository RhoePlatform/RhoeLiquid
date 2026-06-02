# Architecture Guide

Understand the active architecture of RhoeLiquid and where the current package surface begins and ends.

## Overview

RhoeLiquid is built as a focused, modular Liquid engine. The package is optimized around the core render pipeline and keeps higher-level extension surfaces clearly separated so performance work can stay concentrated on the hot path.

## Module Layout

- `LiquidCore`: shared AST, tokens, errors, metrics, caches, data values, and runtime tuning helpers
- `LiquidLexer`: template tokenization
- `LiquidParser`: AST construction
- `LiquidRenderer`: AST execution, compiled-template reuse, and renderer pooling
- `LiquidFilters`: registry-backed supplemental filters
- `LiquidTags`: tag protocols and registry
- `LiquidExtensions`: template loading and inheritance helpers
- `LiquidUtilities`: helpers such as HTML escaping
- `RhoeLiquid`: umbrella API and DocC catalog

## Core Pipeline

The main render path is still the simple one:

1. `Lexer` tokenizes template source.
2. `Parser` builds an `ASTNode` tree.
3. `Renderer` executes the AST.

The optimized engine path layers extra reuse on top of that pipeline:

1. `TemplateCache` keeps parsed ASTs for repeated templates.
2. `OptimizedRenderer` promotes hot templates into `CompiledTemplate` entries.
3. pooled `Renderer` instances reuse prewarmed variable-access state.

## Runtime Tuning

`LiquidEngine` uses `RuntimePerformanceProfile` to tune defaults at startup:

- cache entry count
- cache memory budget
- renderer pool size

Those defaults adapt to the current machine rather than assuming one static profile for all environments.

## Memory Pressure Handling

Long-lived engines wire a `MemoryPressureObserver` so caches can react before the system is in trouble.

- `TemplateCache` trims or clears entries depending on pressure level
- `OptimizedRenderer` trims compiled-template storage and reduces pooled renderers when necessary

## Extension Surface

### Stable Today

- custom filters registered through `LiquidEngine`
- runtime custom tags registered through `LiquidEngine.registerTag(_:)`
- basic `{% data name = load(...) %}` loading through the built-in `LoadTag`
- programmatic data loading through `DataLoaderRegistry`
- file-backed `include`, `render`, and block inheritance through the normal render path
- loader and filter authoring at the protocol level

### Compatibility And Archived Surfaces

- the older `LiquidCore.CustomTag` / `TagNode` compatibility surface, now bridged through `LegacyCustomTagAdapter` and `LiquidEngine.registerLegacyTag(...)`
- the archived `ASTOptimizer` / `CompiledTemplateCache` compatibility surface, where only the documented live subset still affects the runtime and the archived-only knobs are now on a formal deprecation path
- historical planning material outside the active package surface

Those surfaces remain intentionally visible so older integrations have a narrow compatibility path, but they are not the preferred direction for new work.

## Design Priorities

The current architecture favors:

- predictable performance over broad speculative abstraction
- explicit module boundaries over monolithic helper layers
- benchmark-driven optimization rather than anecdotal tuning
- a small, publishable core before future expansion work
