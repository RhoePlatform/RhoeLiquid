# Variable Tags

Tags that create or mutate values in the current render scope.

## `assign`

| Field | Value |
| --- | --- |
| Status | `Liquid standard` |
| Signature | `{% assign name = expression %}` |
| Returns | Empty output |
| Evidence | `Tests/GoldenLiquidTests/Tags/AssignTests.swift` |

```liquid
{% assign title = product.title | default: "Untitled" %}
{{ title }}
```

## `capture`, `endcapture`

| Field | Value |
| --- | --- |
| Status | `Liquid standard` |
| Signature | `{% capture name %}...{% endcapture %}` |
| Returns | Empty output; stores rendered body as a string |
| Evidence | `Tests/GoldenLiquidTests/Tags/CaptureTests.swift` |

```liquid
{% capture headline %}
  {{ product.title | strip }}
{% endcapture %}
{{ headline | upcase }}
```

## `increment` and `decrement`

| Field | Value |
| --- | --- |
| Status | `Liquid standard` |
| Signature | `{% increment counter %}`, `{% decrement counter %}` |
| Returns | Current counter value |
| Evidence | `Tests/GoldenLiquidTests/Tags/IncrementTests.swift`, `Tests/GoldenLiquidTests/Tags/DecrementTests.swift` |

Counters are independent from normal variables with the same name.

```liquid
{% increment section %} {% increment section %}
{% decrement reverse_section %}
```
