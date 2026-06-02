# Types

The value types available to RhoeLiquid templates.

## Type Table

| Type | Status | Examples | Notes |
| --- | --- | --- | --- |
| String | `Liquid standard` | `"hello"`, `'hello'` | Supports string filters, equality checks, `contains`, slicing, and output. |
| Number | `Liquid standard` | `42`, `3.14` | Supports comparison and math filters. Integer-vs-float source shape is preserved where compatibility requires it. |
| Boolean (`boolean`) | `Liquid standard` | `true`, `false` | Only `false` is falsy. |
| Nil/null | `Liquid standard` | `nil`, `null`, missing values | Renders empty by default and is falsy. |
| Array | `Liquid standard` | `["a", "b"]`, `(1..3)` | Iterable and transformable by array/data filters. |
| Object/dictionary | `RhoeLiquid extension` | `user.name`, `row["id"]` | Backed by Swift dictionaries, ordered dictionaries, reflected values, or `DataValue`. |
| Range (`range`) | `Liquid standard` | `(1..5)` | Inclusive and primarily used by `for`, `join`, `first`, and `last`. |
| Date | `RhoeLiquid extension` | Swift `Date`, date-shaped strings | Formatted by `date`; strings such as `"now"` and `"today"` are accepted by the date formatter. |
| Data value (`data_value`) | `RhoeLiquid extension` | Loaded JSON/XML/SQL/YAML/TOML/GraphQL values | Provides structured access and data-source-specific helper filters. |

## Coercion

RhoeLiquid follows Shopify-compatible coercion where the test suite covers it. Filters may coerce compatible values; comparisons are intentionally stricter and can reject incompatible pairs such as nil-vs-number or string-vs-number comparisons.

## Rendering

Values are rendered by converting to text unless a node or filter has a specialized output mode. Arrays and objects are normally transformed or iterated rather than printed directly.
