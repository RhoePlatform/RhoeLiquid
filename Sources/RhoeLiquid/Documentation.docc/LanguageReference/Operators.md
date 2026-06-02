# Operators

Operators available in conditions, ranges, and filter pipelines.

## Active Operators

| Operator | Status | Syntax | Meaning |
| --- | --- | --- | --- |
| Equality | `Liquid standard` | `left == right` | True when values are equal using Liquid-compatible equality. |
| Inequality | `Liquid standard` | `left != right` | True when values are not equal. |
| Less than | `Liquid standard` | `left < right` | Numeric/string/date-style comparison for compatible types. |
| Greater than | `Liquid standard` | `left > right` | Numeric/string/date-style comparison for compatible types. |
| Less/equal | `Liquid standard` | `left <= right` | Inclusive comparison. |
| Greater/equal | `Liquid standard` | `left >= right` | Inclusive comparison. |
| Contains | `Liquid standard` | `collection contains value` | Checks substring membership for strings and element membership for arrays. |
| And | `Liquid standard` | `a and b` | Logical conjunction using Liquid truthiness. |
| Or | `Liquid standard` | `a or b` | Logical disjunction using Liquid truthiness. |
| Range | `Liquid standard` | `(start..end)` | Inclusive range expression. |
| Filter pipe | `Liquid standard` | `value | filter` | Applies one filter stage. |

## Deferred Operators

| Operator | Status | Notes |
| --- | --- | --- |
| Arithmetic `+`, `-`, `*`, `/`, `%` | `Deferred` | AST/runtime enum cases exist, but template parser exposure is not active in `0.1.0`. Use math filters instead. |
| `is` tests | `Deferred` | Token/AST/evaluator scaffolding exists for tests such as `present` and `number`, but parser exposure is not active in `0.1.0`. |
| Parenthesized grouping | `Unsupported` | Parentheses are used for ranges and macro calls, not arbitrary condition grouping. |

## Precedence

Liquid conditions should be written without relying on grouped arithmetic-style precedence. Prefer explicit, readable condition chains:

```liquid
{% if product.available and product.price > 0 %}
  Available
{% endif %}
```
