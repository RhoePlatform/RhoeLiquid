# Math Filters

Numeric filters for arithmetic, rounding, and bounds.

## Reference

| Filter | Status | Signature | Returns | Nil/error behavior | Evidence |
| --- | --- | --- | --- | --- | --- |
| `plus` | `Liquid standard` | `value | plus: number` | Number or string-concatenated compatible value | Missing argument defaults to `0`. | `PlusTests.swift` |
| `minus` | `Liquid standard` | `value | minus: number` | Number | Missing argument defaults to `0`. | `MinusTests.swift` |
| `times` | `Liquid standard` | `value | times: number` | Number | Missing argument defaults to `1`. | `TimesTests.swift` |
| `divided_by` | `Liquid standard` | `value | divided_by: number` | Number | Division-by-zero is a render arithmetic error. | `DividedByTests.swift` |
| `modulo` | `Shopify-compatible` | `value | modulo: number` | Number | Division-by-zero is a render arithmetic error. | `ModuloTests.swift` |
| `abs` | `Liquid standard` | `value | abs` | Number | Non-numeric values coerce through numeric conversion rules. | `AbsTests.swift` |
| `ceil` | `Liquid standard` | `value | ceil` | Number | Integer input is preserved as integer. | `CeilTests.swift` |
| `floor` | `Liquid standard` | `value | floor` | Number | Integer input is preserved as integer. | `FloorTests.swift` |
| `round` | `Liquid standard` | `value | round: precision` | Number | Missing precision defaults to `0`. | `RoundTests.swift` |
| `at_least` | `Liquid standard` | `value | at_least: minimum` | Number | Returns the larger of input and minimum. | `AtLeastTests.swift` |
| `at_most` | `Liquid standard` | `value | at_most: maximum` | Number | Returns the smaller of input and maximum. | `AtMostTests.swift` |
| `sum` | `Shopify-compatible` | `array | sum: property` | Number | Property argument is optional; hash mismatches can error. | `SumTests.swift` |
| `clamp` | `Deferred` | `value | clamp: minimum, maximum` | Number | Filter type exists but is not active in the default `0.1.0` renderer registry. | `LiquidFilters/MathFilters.swift` |

## Examples

```liquid
{{ 4 | plus: 2 | times: 3 }}
{{ -4.6 | abs | round }}
{{ 12 | at_most: 10 }}
```

Output:

```text
18
5
10
```

## Expression Arithmetic

Template expression operators such as `+`, `-`, `*`, `/`, and `%` are deferred in `0.1.0`; use math filters for portable templates.
