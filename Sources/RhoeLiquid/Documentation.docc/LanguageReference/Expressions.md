# Expressions

Expressions produce values for output tags, conditions, filters, assignments, macro calls, and data-loading options.

## Expression Forms

| Form | Status | Syntax | Returns |
| --- | --- | --- | --- |
| Literal | `Liquid standard` | `"x"`, `1`, `true`, `nil` | The literal value. |
| Variable | `Liquid standard` | `user`, `user.name` | Context value or nil-like missing value. |
| Access | `Liquid standard` | `items[0]`, `row[key]` | Array/object member. |
| Range | `Liquid standard` | `(1..5)` | Inclusive range object. |
| Filtered expression | `Liquid standard` | `title | strip | upcase` | Filter result. |
| Binary comparison | `Liquid standard` | `price > 10` | Boolean. |
| Logical expression | `Liquid standard` | `a and b`, `a or b` | Boolean using Liquid truthiness. |
| Macro call expression | `RhoeLiquid extension` | `card(title: "Hi")` | Rendered macro output in the extended profile. |
| Test expression | `Deferred` | `value is present` | AST/evaluator scaffold exists, but parser exposure is not active in `0.1.0`. |

## Operators

See <doc:Operators> for the full operator table. In `0.1.0`, arithmetic inside template expressions is deferred; use math filters such as `plus`, `minus`, `times`, `divided_by`, and `modulo`.

## Filter Arguments

Filters accept positional arguments and selected named arguments:

```liquid
{{ title | truncate: 20, "..." }}
{{ value | default: "fallback", allow_false: true }}
```

Named arguments are represented in the parser and are active for documented filters such as `default`.

## Evaluation Notes

RhoeLiquid preserves Shopify-compatible behavior where it is covered by the golden tests: only `nil`/`null` and `false` are falsy, comparisons are type-aware, and parentheses are not a general grouping operator in conditions. Conditions should be written as explicit chained expressions rather than relying on arithmetic or grouped subexpressions.
