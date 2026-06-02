# Template Composition Tags

Tags for comments, raw content, partial rendering, and template inheritance.

## `comment`, `endcomment`

| Field | Value |
| --- | --- |
| Status | `Liquid standard` |
| Signature | `{% comment %}...{% endcomment %}` |
| Returns | Empty output |
| Evidence | `Tests/GoldenLiquidTests/Tags/CommentTests.swift` |

## Inline `#` Comment

| Field | Value |
| --- | --- |
| Status | `Shopify-compatible` |
| Signature | `{% # comment text %}` |
| Returns | Empty output |
| Evidence | `Tests/GoldenLiquidTests/Tags/InlineCommentTests.swift` |

## `raw`, `endraw`

| Field | Value |
| --- | --- |
| Status | `Liquid standard` |
| Signature | `{% raw %}{{ not evaluated }}{% endraw %}` |
| Returns | Body content exactly as text |
| Evidence | `Tests/GoldenLiquidTests/Tags/RawTests.swift` |

## `liquid`, `endliquid`

| Field | Value |
| --- | --- |
| Status | `Shopify-compatible` |
| Signature | `{% liquid ... %}` or `{% liquid %}...{% endliquid %}` |
| Returns | The rendered output of nested tag lines |
| Evidence | `Tests/GoldenLiquidTests/Tags/LiquidTests.swift` |

```liquid
{% liquid
  assign title = product.title
  echo title
%}
```

## `echo`

| Field | Value |
| --- | --- |
| Status | `Shopify-compatible` |
| Signature | `{% echo expression %}` |
| Returns | Rendered expression output |
| Evidence | `Tests/GoldenLiquidTests/Tags/EchoTests.swift` |

## `include`

| Field | Value |
| --- | --- |
| Status | `Deprecated` |
| Signature | `{% include "template", key: value %}` |
| Returns | Rendered included template |
| Scope | Shares caller scope and supports compatibility-style parameters. |
| Evidence | `Tests/GoldenLiquidTests/Tags/IncludeTests.swift` |

Prefer `render` for new portable templates.

## `render`

| Field | Value |
| --- | --- |
| Status | `Shopify-compatible` |
| Signature | `{% render "template", key: value %}` |
| Returns | Rendered partial template |
| Scope | Uses an isolated partial scope with explicit arguments. |
| Evidence | `Tests/GoldenLiquidTests/Tags/RenderTests.swift` |

## `extends`

| Field | Value |
| --- | --- |
| Status | `RhoeLiquid extension` |
| Signature | `{% extends "parent.liquid" %}` |
| Constraint | Must be the first significant node and must use a string literal. |
| Evidence | `Documentation/TemplateInheritance.md`, `Sources/LiquidParser/Parser.swift` |

## `block`, `endblock`

| Field | Value |
| --- | --- |
| Status | `RhoeLiquid extension` |
| Signature | `{% block name %}...{% endblock %}` |
| Returns | Child override or fallback body when rendering inheritance trees. |

## `render_block`

| Field | Value |
| --- | --- |
| Status | `RhoeLiquid extension` |
| Signature | `{% render_block name key:value %}` |
| Returns | Rendered block body with optional parameters. |

```liquid
{% extends "layout.liquid" %}
{% block body %}
  {{ content }}
{% endblock %}
```
