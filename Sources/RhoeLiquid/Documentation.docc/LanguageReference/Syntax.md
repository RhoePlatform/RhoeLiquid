# Syntax

Lexical and document-level syntax for RhoeLiquid templates.

## Markup

| Form | Status | Syntax | Meaning |
| --- | --- | --- | --- |
| Object output | `Liquid standard` | `{{ expression }}` | Evaluate an expression and write the rendered value. |
| Tag | `Liquid standard` | `{% tag arguments %}` | Execute control flow, assignment, composition, or extension behavior. |
| Filter | `Liquid standard` | `{{ value | filter: arg }}` | Transform an expression result before output. |
| Comment block | `Liquid standard` | `{% comment %}...{% endcomment %}` | Ignore a template block. |
| Inline comment | `Shopify-compatible` | `{% # text %}` | Ignore a single tag body. |

Whitespace trimming is available on both output and tag delimiters:

```liquid
{{- title -}}
{%- if title -%}
```

Use trimming when the template itself controls layout, especially in generated DOCX/XML/HTML output.

## Literals

| Literal | Status | Examples | Notes |
| --- | --- | --- | --- |
| String | `Liquid standard` | `"Alice"`, `'Alice'` | Quotes are removed by the lexer. |
| Number | `Liquid standard` | `42`, `3.14` | Integer and floating-point source forms are preserved for compatibility-sensitive filters. |
| Boolean | `Liquid standard` | `true`, `false` | Only `false` is falsy. |
| Nil/null | `Liquid standard` | `nil`, `null` | Renders as empty output in lax mode. |
| Range | `Liquid standard` | `(1..5)`, `(start..stop)` | Used most commonly by `for`. |
| Array/object literals | `RhoeLiquid extension` | `[1, 2]`, `{ "a": 1 }` | Available through the AST/value layer and data loading surface. |

## Identifiers and Paths

Identifiers may contain Unicode letters and are case-sensitive. Paths use dot access for static keys and bracket access for dynamic or numeric keys:

```liquid
{{ user.name }}
{{ users[0].name }}
{{ article[dynamic_key] }}
```

Static paths are also used by analysis tooling to report variable dependencies and input contracts.

## Blocks and End Tags

Block tags own a body and must be closed by the matching end tag:

| Opening | Closing | Status |
| --- | --- | --- |
| `if` | `endif` | `Liquid standard` |
| `unless` | `endunless` | `Liquid standard` |
| `case` | `endcase` | `Liquid standard` |
| `for` | `endfor` | `Liquid standard` |
| `tablerow` | `endtablerow` | `Liquid standard` |
| `capture` | `endcapture` | `Liquid standard` |
| `comment` | `endcomment` | `Liquid standard` |
| `raw` | `endraw` | `Liquid standard` |
| `liquid` | `endliquid` | `Shopify-compatible` |
| `block` | `endblock` | `RhoeLiquid extension` |
| `macro` | `endmacro` | `RhoeLiquid extension` |
| `call` | `endcall` | `RhoeLiquid extension` |
| `slot` | `endslot` | `RhoeLiquid extension` |
| `fill` | `endfill` | `RhoeLiquid extension` |

## Reference Inputs

The syntax categories align with the public Liquid references at `https://shopify.github.io/liquid/` and `https://shopify.dev/docs/api/liquid`, but this page is written from the RhoeLiquid lexer, parser, renderer, and tests.
