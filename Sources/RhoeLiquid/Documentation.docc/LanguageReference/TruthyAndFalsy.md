# Truthy and Falsy

RhoeLiquid follows Liquid truthiness: only `nil`/`null` and `false` are falsy.

## Truthiness Table

| Value | Status | Truthiness |
| --- | --- | --- |
| `nil` / `null` | `Liquid standard` | Falsy |
| `false` | `Liquid standard` | Falsy |
| `true` | `Liquid standard` | Truthy |
| Empty string `""` | `Liquid standard` | Truthy |
| Empty array `[]` | `Liquid standard` | Truthy |
| Empty object `{}` | `RhoeLiquid extension` | Truthy |
| Number `0` | `Liquid standard` | Truthy |

## Empty and Blank

`empty`, `blank`, and `present` appear in the value/test model, but parser-exposed `is` tests are deferred in `0.1.0`. Use filters and explicit comparisons for portable templates:

```liquid
{% if items.size == 0 %}
  No items.
{% endif %}

{{ title | default: "Untitled" }}
```

## Default Filter

The `default` filter treats nil, empty, and false-like inputs as replaceable unless `allow_false: true` is passed:

```liquid
{{ published | default: true, allow_false: true }}
```
