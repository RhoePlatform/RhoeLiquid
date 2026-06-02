# Array and Collection Filters

Filters for selecting, ordering, reshaping, and inspecting arrays and collection-like values.

## Reference

| Filter | Status | Signature | Returns | Nil/error behavior | Evidence |
| --- | --- | --- | --- | --- | --- |
| `first` | `Liquid standard` | `array | first` | First element or nil | Works on strings/ranges where tested. | `FirstTests.swift` |
| `last` | `Liquid standard` | `array | last` | Last element or nil | Works on strings/ranges where tested. | `LastTests.swift` |
| `size` | `Liquid standard` | `value | size` | Number | Counts supported collection/string types. | `SizeTests.swift` |
| `join` | `Liquid standard` | `array | join: separator` | String | Default separator is a space. | `JoinTests.swift` |
| `reverse` | `Liquid standard` | `array | reverse` | Array/string/range-compatible value | Preserves compatible collection semantics. | `ReverseTests.swift` |
| `sort` | `Liquid standard` | `array | sort: property` | Array | Mixed incompatible types can error. | `SortTests.swift` |
| `sort_natural` | `Shopify-compatible` | `array | sort_natural: property` | Array | Case-insensitive natural sort. | `SortNaturalTests.swift` |
| `uniq` | `Liquid standard` | `array | uniq: property` | Array | Optional property key. | `UniqTests.swift` |
| `compact` | `Liquid standard` | `array | compact: property` | Array | Removes nil/missing values. | `CompactTests.swift` |
| `concat` | `Liquid standard` | `array | concat: other_array` | Array | Requires an array argument. | `ConcatTests.swift` |
| `map` | `Liquid standard` | `array | map: property` | Array | Non-hash items can error for property maps. | `MapTests.swift` |
| `where` | `Liquid standard` | `array | where: property, value` | Array | Property required; value optional. | `WhereTests.swift` |
| `find` | `RhoeLiquid extension` | `array | find: property, value` | Element or nil | Supports string and hash-aware search. | `FindTests.swift` |
| `find_index` | `RhoeLiquid extension` | `array | find_index: property, value` | Number or nil | Returns first matching index. | `FindIndexTests.swift` |
| `has` | `RhoeLiquid extension` | `array | has: property, value` | Boolean or nil | Mixed arrays can return nil or typed errors. | `HasTests.swift` |
| `reject` | `RhoeLiquid extension` | `array | reject: property, value` | Array | Excludes matching/truthy entries. | `RejectTests.swift` |
| `sort_by` | `RhoeLiquid extension` | `array | sort_by: property` | Array | Data-oriented stable property sort. | `DataFilters.swift` |
| `group_by` | `RhoeLiquid extension` | `array | group_by: property` | Array/object grouping | Groups rows by property. | `DataFilters.swift` |
| `pluck` | `RhoeLiquid extension` | `array | pluck: property` | Array | Extracts property values. | `DataFilters.swift` |
| `limit` | `RhoeLiquid extension` | `array | limit: count` | Array | Non-array input is returned unchanged. | `DataFilters.swift` |
| `offset` | `RhoeLiquid extension` | `array | offset: count` | Array | Non-array input is returned unchanged. | `DataFilters.swift` |

## Examples

```liquid
{{ products | where: "available", true | map: "title" | join: ", " }}
{{ products | find: "sku", "ABC-123" | json }}
```

For pagination-style transforms:

```liquid
{% for item in products | offset: 20 | limit: 10 %}
  {{ item.title }}
{% endfor %}
```
