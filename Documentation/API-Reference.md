# API Reference Notes

The primary API reference for the focused package should come from DocC and inline Swift documentation.

## Use These First

- `Sources/RhoeLiquid/Documentation.docc/RhoeLiquid.md`
- `Sources/RhoeLiquid/Documentation.docc/GettingStarted.md`
- symbol docs generated from the active Swift modules

## Key Public Entry Points

- `LiquidEnvironment`
- `CompatibilityProfile`
- `LiquidEngine`
- `LiquidConfiguration`
- `TemplateAnalysis`
- `TemplateManifest`
- `PerformanceMetrics`
- `CustomFilter`
- `DataLoaderRegistry`
- `TemplateLoader`

## Product Surface Policy

The `0.1.x` public foundation line intentionally publishes the full Swift-side foundation surface:

- `RhoeLiquid`: primary engine API for most integrators.
- `RhoeDOCX`: DOCX templating and package-processing surface.
- `liquid`: command-line executable for rendering, validation, analysis, batch rendering, benchmarking, and project scaffolding.
- `RhoeLiquidService`: local HTTP service executable for service-mode rendering and analysis.
- `RhoeLiquidWasm`: WebAssembly integration target.
- `LiquidCore` and `LiquidUtilities`: low-level types and utilities needed by advanced extension authors.
- `ServiceCore`, `HTTPService`, and `ServiceContractGenerator`: service-layer contract and localhost runtime surfaces.

Contributor guidance: prefer `RhoeLiquid` unless you are extending the parser/runtime, integrating DOCX, embedding the service layer, or building WASM/service tooling. Public symbols in these products are source-stable within the `0.1.x` line unless explicitly marked deprecated, archived, or compatibility-only.

## Important Status Notes

- custom filters are part of the active runtime surface
- runtime custom tags registered through `LiquidEngine.registerTag(_:)` are part of the active runtime surface
- macros, macro imports, and template input contracts are part of the active `rhoeExtended` authoring surface
- `shopifyCompatible` remains explicit and rejects Wave 16 authoring syntax such as macros and input declarations
- the older `LiquidCore.CustomTag` / `TagNode` compatibility layer is still a legacy surface and should not be treated as the preferred extension API
- `LiquidConfiguration.customTags` is a narrow compatibility bootstrap for legacy parser-style tags and auto-installs through the same runtime bridge at engine initialization
- `ASTOptimizer` and `CompiledTemplateCache` are compatibility shims; only their documented live fields are active in today’s runtime, and the archived-only knobs are now formally deprecated for removal in the next major release
- file-backed `include`, `render`, and inheritance are part of the active runtime surface
- function-call expressions are active only for macro invocation in `rhoeExtended`; general function registries remain deferred
- `renderWithMetrics` now reports timing, cache state, AST node counts, and observed template memory stats
- multiline `{% liquid %}` blocks plus loop control tags (`break` / `continue`) are part of the active syntax surface
- the `debug` tag is part of the active development surface when a `DebugConfiguration` with an output handler is enabled; it never writes to template output
- the archived `pipeline` tag is retired and out of scope for the current package surface

This file is intentionally lightweight so it does not drift ahead of the generated API docs again.
