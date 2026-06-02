# Iteration Tags

Tags that repeat content or control loop execution.

## `for`, `else`, `empty`, `endfor`

| Field | Value |
| --- | --- |
| Status | `Liquid standard` |
| Signature | `{% for item in collection limit:n offset:n reversed %}...{% else %}...{% endfor %}` |
| Parameters | `limit`, `offset`, and `reversed` |
| Iterables | Arrays, ranges, and compatible data values |
| Evidence | `Tests/GoldenLiquidTests/Tags/ForTests.swift` |

```liquid
{% for product in products limit: 3 %}
  {{ forloop.index }}. {{ product.title }}
{% else %}
  No products.
{% endfor %}
```

`empty` is accepted as an empty-collection branch for compatibility with the parser surface:

```liquid
{% for row in rows %}
  {{ row.name }}
{% empty %}
  No rows.
{% endfor %}
```

## `forloop`

| Property | Status | Meaning |
| --- | --- | --- |
| `forloop.index` | `Liquid standard` | 1-based index. |
| `forloop.index0` | `Liquid standard` | 0-based index. |
| `forloop.first` | `Liquid standard` | True on the first iteration. |
| `forloop.last` | `Liquid standard` | True on the last iteration. |
| `forloop.length` | `Liquid standard` | Number of iterations. |
| `forloop.rindex` | `Liquid standard` | 1-based reverse index. |
| `forloop.rindex0` | `Liquid standard` | 0-based reverse index. |

## `break` and `continue`

| Field | Value |
| --- | --- |
| Status | `Liquid standard` |
| Signature | `{% break %}`, `{% continue %}` |
| Scope | Valid inside `for` and `tablerow` bodies. |
| Evidence | `Tests/GoldenLiquidTests/Tags/ForTests.swift` |

## `cycle`

| Field | Value |
| --- | --- |
| Status | `Liquid standard` |
| Signature | `{% cycle "odd", "even" %}` |
| Returns | Alternating values each time the cycle is reached. |
| Evidence | `Tests/GoldenLiquidTests/Tags/CycleTests.swift` |

```liquid
{% for row in rows %}
  <tr class="{% cycle 'odd', 'even' %}">{{ row.name }}</tr>
{% endfor %}
```

## `tablerow`, `endtablerow`

| Field | Value |
| --- | --- |
| Status | `Liquid standard` |
| Signature | `{% tablerow item in collection cols:n limit:n offset:n %}...{% endtablerow %}` |
| Returns | HTML table row/cell output. |
| Evidence | `Tests/GoldenLiquidTests/Tags/TablerowTests.swift` |
