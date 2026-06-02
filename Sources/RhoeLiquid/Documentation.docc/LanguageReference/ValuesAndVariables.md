# Values and Variables

How values are represented, looked up, scoped, and rendered.

## Runtime Values

| Type | Status | Template examples | Render behavior |
| --- | --- | --- | --- |
| String | `Liquid standard` | `"hello"`, `user.name` | Rendered as text, with escaping controlled by renderer configuration and filters. |
| Number | `Liquid standard` | `42`, `3.14` | Rendered without quotes; math filters coerce compatible numeric inputs. |
| Boolean | `Liquid standard` | `true`, `false` | Rendered as `true` or `false`; only `false` is falsy. |
| Nil/null | `Liquid standard` | `nil`, `null`, missing path | Renders as empty output in lax mode. |
| Array | `Liquid standard` | `items`, `(1..3)` | Iterable by `for`, addressable by index, transformable by array filters. |
| Object/dictionary | `RhoeLiquid extension` | `user.name`, `row["id"]` | Represents Swift dictionaries and loaded structured data. |
| Date | `RhoeLiquid extension` | loaded data or Swift context | Formatted with `date`. |
| Data/binary | `RhoeLiquid extension` | loaded data source values | Exposed through `DataValue` and data-source helpers. |

## Lookup

Variable lookup starts in the current scope and falls back through the render context. Missing variables evaluate to nil-like empty output unless strict error handling is enabled.

```liquid
{{ user.name }}
{{ user["name"] }}
{{ rows[0].title }}
```

## Scope

| Construct | Status | Scope behavior |
| --- | --- | --- |
| `assign` | `Liquid standard` | Writes a value into the current render scope. |
| `capture` | `Liquid standard` | Renders a body and stores the resulting string. |
| `for` | `Liquid standard` | Introduces the loop variable and `forloop` helper object for each iteration. |
| `include` | `Deprecated` | Shares caller scope and can pass additional variables. |
| `render` | `Shopify-compatible` | Uses an isolated partial scope with explicit parameters. |
| `macro` / `call` | `RhoeLiquid extension` | Binds declared parameters and slot content for the macro invocation. |
| `data` | `RhoeLiquid extension` | Loads a data source and stores it under the target name. |

## Undefined Values

Undefined values render as an empty string in lax/default rendering. Strict mode can surface undefined variables, type mismatches, missing templates, and invalid filter arguments as typed render errors.

## Examples

```liquid
{% assign title = article.title | default: "Untitled" %}
{{ title }}

{% for row in rows %}
  {{ forloop.index }}. {{ row.name }}
{% else %}
  No rows.
{% endfor %}
```
