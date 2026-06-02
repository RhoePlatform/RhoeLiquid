# Date Formatting Filters

Filters that turn date-like values into strings.

## Reference

| Filter | Status | Signature | Returns | Nil/error behavior | Evidence |
| --- | --- | --- | --- | --- | --- |
| `date` | `Liquid standard` | `value | date: format` | String | Accepts Swift dates, known date strings, `"now"`, and `"today"`; nil format is handled by compatibility rules. | `DateTests.swift` |
| `date_to_string` | `Deferred` | `value | date_to_string` | String | Filter type exists but is not active in the default `0.1.0` renderer registry. | `MathFilters.swift` |
| `date_to_rfc822` | `Deferred` | `value | date_to_rfc822` | String | Filter type exists but is not active by default. | `MathFilters.swift` |
| `date_to_iso8601` | `Deferred` | `value | date_to_iso8601` | String | Filter type exists but is not active by default. | `MathFilters.swift` |
| `now` | `Deferred` | `value | now` | Date/string | Metadata entry exists; use `"now" | date: format` in `0.1.0`. | `LiquidCore.swift` |

## Examples

```liquid
{{ "now" | date: "%Y-%m-%d" }}
{{ "2026-05-31" | date: "%B %-d, %Y" }}
```

Date format strings follow the active formatter behavior in `Renderer+FilterHelpers.swift`.
