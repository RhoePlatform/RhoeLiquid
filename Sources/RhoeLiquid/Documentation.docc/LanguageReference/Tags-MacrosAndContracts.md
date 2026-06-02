# Macros and Contracts

Rhoe authoring extensions for reusable template components and declared input contracts.

## `macro`, `endmacro`

| Field | Value |
| --- | --- |
| Status | `RhoeLiquid extension` |
| Signature | `{% macro name(param, optional: default) %}...{% endmacro %}` |
| Returns | Empty output at declaration time |
| Evidence | `Tests/RhoeLiquidTests/Wave16AuthoringTests.swift`, `Tests/RhoeLiquidTests/Wave17AuthoringTests.swift` |

```liquid
{% macro badge(label, tone: "neutral") %}
  <span class="badge badge-{{ tone }}">{{ label }}</span>
{% endmacro %}

{{ badge("Ready", tone: "success") }}
```

## `call`, `endcall`

| Field | Value |
| --- | --- |
| Status | `RhoeLiquid extension` |
| Signature | `{% call macro_name(args) %}...{% endcall %}` |
| Returns | Rendered macro output |
| Errors | Unknown macros, unknown parameters, and invalid fills fail explicitly. |

```liquid
{% call card(title: "Release") %}
  Ship the candidate.
{% endcall %}
```

## `slot`, `endslot`

| Field | Value |
| --- | --- |
| Status | `RhoeLiquid extension` |
| Signature | `{% slot name %}fallback{% endslot %}` |
| Scope | Valid inside macro bodies. |

## `fill`, `endfill`

| Field | Value |
| --- | --- |
| Status | `RhoeLiquid extension` |
| Signature | `{% fill name %}content{% endfill %}` |
| Scope | Valid as top-level children of block-form `call` bodies. |

```liquid
{% macro layout(title) %}
  <h1>{{ title }}</h1>
  {% slot body %}No body.{% endslot %}
{% endmacro %}

{% call layout(title: "Report") %}
  {% fill body %}Ready for review.{% endfill %}
{% endcall %}
```

## `import`

| Field | Value |
| --- | --- |
| Status | `RhoeLiquid extension` |
| Signature | `{% import "components.liquid" as ui %}` |
| Returns | Empty output; imports macros under a namespace. |

## `from ... import`

| Field | Value |
| --- | --- |
| Status | `RhoeLiquid extension` |
| Signature | `{% from "components.liquid" import card, badge %}` |
| Returns | Empty output; imports selected macros. |

## `input`

| Field | Value |
| --- | --- |
| Status | `RhoeLiquid extension` |
| Signature | `{% input path: type = default %}` |
| Returns | Empty output; declares template input expectations. |
| Types | Narrow authoring types exposed through template analysis. |

Input contracts are used by platform analysis and service consumers to validate required context before rendering.

## `with`, `recursive`, and `loop`

| Field | Value |
| --- | --- |
| Status | `RhoeLiquid extension` |
| Role | Keywords/modifiers in composition and recursive-render parsing surfaces. |
| Notes | Documented as keywords rather than standalone tags. |
