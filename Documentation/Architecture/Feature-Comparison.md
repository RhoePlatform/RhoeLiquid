# Focused Release Surface Comparison

This comparison is intentionally about the current focused `RhoeLiquid` package, not the older monorepo.

## Core Template Surface

| Capability | Status |
| --- | --- |
| Variables, dot access, array indexing | Stable |
| Conditionals (`if`, `elsif`, `else`, `unless`, `case`) | Stable |
| Loops (`for`, `tablerow`, loop metadata) | Stable |
| Loop control (`break`, `continue`) | Stable |
| Core filters (`upcase`, `append`, `size`, math/date/string helpers) | Stable |
| Multiline `{% liquid %}` blocks | Stable |
| `echo`, `increment`, and `decrement` | Stable |
| `debug` tag | Development-only |
| Registry-backed custom filters | Stable |
| AST caching and compiled-template reuse | Stable |
| Programmatic data loading registry | Stable |
| File-backed `include` and `render` | Stable |
| Block inheritance in the normal render path | Stable |
| `renderWithMetrics` timing/cache/node-count observability | Stable |
| `renderWithMetrics` observed template memory stats | Stable |
| Runtime custom tags (`LiquidEngine.registerTag(_:)`) | Stable |
| Macros plus macro imports (`macro`, `call`, `import`, `from`) | Stable in `rhoeExtended` |
| Template input contracts (`input`) | Stable in `rhoeExtended` |
| Legacy parser-style custom tags | Compatibility-only |
| Function-call expressions | Macro-only in `rhoeExtended`; general registries deferred |
| `pipeline` tag | Retired / out of scope |

## Practical Takeaway

The current package is strongest when used as a high-performance Liquid renderer with filters, file-backed template composition, caching, metrics, and programmatic data access.

The active parser currently expects string-literal template names for `include`, `render`, `extends`, and macro imports.
Macro-style function-call expressions are now available in `rhoeExtended`, while arbitrary function registries remain deferred.

Wave 17 Sprint 1 and Sprint 2 are now in: block `call`, `slot`, and `fill` make macros usable as component-grade template primitives in `rhoeExtended`, and path-based input contracts make nested required/defaulted inputs analyzable without widening the core Liquid compatibility lane. General function registries and package distribution remain deferred.
