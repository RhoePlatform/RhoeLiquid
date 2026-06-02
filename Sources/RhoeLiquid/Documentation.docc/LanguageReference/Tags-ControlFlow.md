# Control Flow Tags

Conditional branching tags.

## `if`, `elsif`, `else`, `endif`

| Field | Value |
| --- | --- |
| Status | `Liquid standard` |
| Signature | `{% if condition %}...{% elsif condition %}...{% else %}...{% endif %}` |
| Returns | Rendered body content |
| Errors | Missing `endif`, malformed condition, or incompatible comparison types can fail parsing/rendering. |
| Evidence | `Tests/GoldenLiquidTests/Tags/IfTests.swift`, `Tests/RhoeLiquidTests/ShopifyCompatibilityTests.swift` |

```liquid
{% if product.available and product.price > 0 %}
  Available
{% elsif product.incoming %}
  Coming soon
{% else %}
  Sold out
{% endif %}
```

`else` ignores trailing expressions for Shopify compatibility.

## `unless`, `else`, `endunless`

| Field | Value |
| --- | --- |
| Status | `Liquid standard` |
| Signature | `{% unless condition %}...{% else %}...{% endunless %}` |
| Returns | First body when the condition is falsy; otherwise the optional `else` body. |
| Evidence | `Tests/GoldenLiquidTests/Tags/UnlessTests.swift` |

```liquid
{% unless user.admin %}
  Read-only access
{% else %}
  Admin access
{% endunless %}
```

## `case`, `when`, `else`, `endcase`

| Field | Value |
| --- | --- |
| Status | `Liquid standard` |
| Signature | `{% case value %}{% when a, b %}...{% else %}...{% endcase %}` |
| Returns | First matching branch body, or `else` body. |
| Evidence | `Tests/GoldenLiquidTests/Tags/CaseTests.swift` |

```liquid
{% case plan %}
{% when "free" %}
  Community
{% when "pro", "team" %}
  Professional
{% else %}
  Enterprise
{% endcase %}
```

## Condition Rules

| Rule | Status | Notes |
| --- | --- | --- |
| Truthiness | `Liquid standard` | Only `nil`/`null` and `false` are falsy. |
| `contains` | `Liquid standard` | Works for strings and arrays. |
| `and` / `or` | `Liquid standard` | Supported in conditions. |
| Parenthesized grouping | `Unsupported` | Parentheses are used for ranges and macro calls, not condition grouping. |
| `is` tests | `Deferred` | Token/AST support exists, but parser exposure is not active in `0.1.0`. |
