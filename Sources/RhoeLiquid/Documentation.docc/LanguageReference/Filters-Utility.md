# Utility and Serialization Filters

General-purpose filters for defaults, JSON output, and developer inspection.

## Reference

| Filter | Status | Signature | Returns | Nil/error behavior | Evidence |
| --- | --- | --- | --- | --- | --- |
| `default` | `Liquid standard` | `value | default: fallback, allow_false: true` | Original value or fallback | Replaces nil/empty/false unless `allow_false: true`. | `DefaultTests.swift` |
| `json` | `RhoeLiquid extension` | `value | json` | JSON string | Encoding failures are render errors. | `LiquidFiltersTests/SecurityFiltersTests.swift` |
| `parse_json` | `Deferred` | `value | parse_json` | Object/array | Filter type exists but is not active in the default `0.1.0` renderer registry. | `UtilityFilters.swift` |
| `inspect` | `Deferred` | `value | inspect` | Debug string | Filter type exists but is not active by default. | `UtilityFilters.swift` |
| `type` | `Deferred` | `value | type` | Type name | Filter type exists but is not active by default. | `UtilityFilters.swift` |
| `random` | `Deferred` | `value | random` | Number/value | Filter type exists but is not active by default. | `UtilityFilters.swift` |
| `range` | `Deferred` | `value | range: end` | Array/range | Filter type exists but is not active by default; use `(start..end)` ranges. | `UtilityFilters.swift` |
| `number_format` | `Deferred` | `value | number_format` | String | Filter type exists but is not active by default. | `UtilityFilters.swift` |
| `currency` | `Deferred` | `value | currency` | String | Filter type exists but is not active by default. | `UtilityFilters.swift` |

## Examples

```liquid
{{ title | default: "Untitled" }}
{{ metadata | json }}
{{ published | default: true, allow_false: true }}
```

## Guidance

Use `json` when emitting machine-readable data from trusted values. Use `inspect`-style diagnostics only when explicitly registered in development tooling.
