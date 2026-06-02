# Compatibility Audit

Current compatibility state for the `0.1.0` public foundation release.

## Summary

RhoeLiquid targets practical Shopify-compatible Liquid behavior for the implemented core surface and documents Rhoe-specific extensions separately. Compatibility is proven by source inspection plus Swift Testing suites, not by broad claims unsupported by the compiler.

| Area | Status | Evidence |
| --- | --- | --- |
| Output, literals, ranges, whitespace | `Shopify-compatible` | `Tests/GoldenLiquidTests/Misc/`, `RhoeLiquidCompatibilityTests.swift` |
| Truthiness | `Liquid standard` | `ShopifyCompatibilityTests.swift` |
| Control flow | `Liquid standard` | `Tags/IfTests.swift`, `Tags/UnlessTests.swift`, `Tags/CaseTests.swift` |
| Iteration | `Liquid standard` | `Tags/ForTests.swift`, `Tags/TablerowTests.swift`, `Tags/CycleTests.swift` |
| Variables | `Liquid standard` | `Tags/AssignTests.swift`, `Tags/CaptureTests.swift`, `Tags/IncrementTests.swift`, `Tags/DecrementTests.swift` |
| Template composition | `Shopify-compatible` | `Tags/IncludeTests.swift`, `Tags/RenderTests.swift`, `Tags/LiquidTests.swift`, `Tags/RawTests.swift` |
| String/math/array filters | `Shopify-compatible` | `Tests/GoldenLiquidTests/Filters/` |
| Rhoe authoring extensions | `RhoeLiquid extension` | `Wave16AuthoringTests.swift`, `Wave17AuthoringTests.swift`, `LiquidEngineAnalysis.swift` |
| Data loading/filtering | `RhoeLiquid extension` | `LoadTag.swift`, `DataFilters-Reference.md`, data-source tests |

## Compatibility Labels

| Label | Use |
| --- | --- |
| `Liquid standard` | Core Liquid language construct supported by the active parser/renderer. |
| `Shopify-compatible` | Behavior aligned with Shopify-compatible golden coverage or compatibility mode. |
| `RhoeLiquid extension` | Additional Rhoe syntax, runtime feature, or data helper. |
| `Deprecated` | Supported but discouraged for new templates, such as `include`. |
| `Archived` | Historical Rhoe syntax rejected with clear diagnostics, such as `pipeline`. |
| `Unsupported` | Known ecosystem feature intentionally not implemented in `0.1.0`. |
| `Deferred` | Planned or metadata-only surface that is not active by default in `0.1.0`. |

## Known Deltas

| Feature | Status | Notes |
| --- | --- | --- |
| `ifchanged` | `Unsupported` | Golden fixtures mark it disabled/not implemented. |
| `doc` | `Unsupported` | Golden fixtures mark it disabled/not implemented. |
| `pipeline` | `Archived` | Parser recognizes and rejects it as archived. |
| Expression arithmetic | `Deferred` | AST enum cases exist; template parser exposure is not active. |
| `is` tests | `Deferred` | Token/AST/evaluator scaffolding exists; parser exposure is not active. |
| Dynamic `extends` | `Unsupported` | `extends` requires a string literal and first-node placement. |

## External Alignment

The language structure aligns with the public Liquid references at `https://shopify.github.io/liquid/` and `https://shopify.dev/docs/api/liquid`. RhoeLiquid-specific behavior is documented from local source and tests.
