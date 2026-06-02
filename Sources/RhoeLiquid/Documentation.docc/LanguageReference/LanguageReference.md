# RhoeLiquid Language Reference

The authoritative language reference for the RhoeLiquid `0.1.0` public foundation release.

## Overview

RhoeLiquid is a Swift implementation of Liquid with two documented authoring profiles:

| Profile | Purpose | Surface |
| --- | --- | --- |
| `shopify_compatible` | Portable Liquid templates | Standard objects, tags, filters, truthiness, whitespace control, includes, renders, and Shopify-compatible edge behavior covered by golden tests. |
| `extended` | Rhoe platform authoring | Template inheritance, macros, slots/fills, input contracts, data loading, XML/SQL/YAML/TOML/GraphQL helpers, and debug instrumentation. |

Every item in this reference carries a status label:

| Label | Meaning |
| --- | --- |
| `Liquid standard` | Core Liquid language behavior supported by RhoeLiquid. |
| `Shopify-compatible` | Shopify-compatible behavior or compatibility-only surface supported by RhoeLiquid. |
| `RhoeLiquid extension` | Rhoe-specific syntax, filter behavior, data helper, or authoring feature. |
| `Deprecated` | Supported for compatibility, but not preferred for new templates. |
| `Archived` | Historical Rhoe syntax that is recognized only to reject it clearly. |
| `Unsupported` | Known Liquid ecosystem feature that is not implemented in `0.1.0`. |
| `Deferred` | Publicly tracked future surface or metadata-only entry that is not active by default in `0.1.0`. |

This reference is intentionally self-contained. External Liquid references were used for compatibility alignment only; the source of truth here is the staged RhoeLiquid implementation and its Swift Testing suites.

## Topics

### Language Model

- <doc:Syntax>
- <doc:ValuesAndVariables>
- <doc:Expressions>
- <doc:Types>
- <doc:Operators>
- <doc:TruthyAndFalsy>
- <doc:RuntimeSemantics>

### Tags

- <doc:Tags-ControlFlow>
- <doc:Tags-Iteration>
- <doc:Tags-Variable>
- <doc:Tags-Template>
- <doc:Tags-MacrosAndContracts>
- <doc:Tags-DataAndDebug>

### Filters

- <doc:Filters-String>
- <doc:Filters-Math>
- <doc:Filters-Array>
- <doc:Filters-Utility>
- <doc:Filters-DateFormatting>
- <doc:Filters-EncodingEscaping>
- <doc:Filters-Data>

### Compatibility and Tooling

- <doc:CompatibilityAudit>
- <doc:UnsupportedAndDeferred>
- <doc:LanguageSurfaceManifest>
