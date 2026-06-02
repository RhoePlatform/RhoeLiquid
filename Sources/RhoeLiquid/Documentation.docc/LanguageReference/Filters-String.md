# String Filters

Filters for text transformation, splitting, replacement, slicing, and slugs.

## Reference

| Filter | Status | Signature | Returns | Nil/error behavior | Evidence |
| --- | --- | --- | --- | --- | --- |
| `append` | `Liquid standard` | `value | append: suffix` | String | Missing suffix behaves like empty string. | `AppendTests.swift` |
| `prepend` | `Liquid standard` | `value | prepend: prefix` | String | Missing prefix behaves like empty string. | `PrependTests.swift` |
| `capitalize` | `Liquid standard` | `value | capitalize` | String | Stringifies input. | `CapitalizeTests.swift` |
| `upcase` | `Liquid standard` | `value | upcase` | String | Stringifies input. | `UpcaseTests.swift` |
| `downcase` | `Liquid standard` | `value | downcase` | String | Stringifies input. | `DowncaseTests.swift` |
| `strip` | `Liquid standard` | `value | strip` | String | Trims leading/trailing whitespace. | `StripTests.swift` |
| `lstrip` | `Liquid standard` | `value | lstrip` | String | Trims leading whitespace. | `LstripTests.swift` |
| `rstrip` | `Liquid standard` | `value | rstrip` | String | Trims trailing whitespace. | `RstripTests.swift` |
| `remove` | `Liquid standard` | `value | remove: search` | String | Missing search leaves value unchanged. | `RemoveTests.swift` |
| `remove_first` | `Liquid standard` | `value | remove_first: search` | String | Removes first occurrence only. | `RemoveFirstTests.swift` |
| `remove_last` | `Shopify-compatible` | `value | remove_last: search` | String | Registered default filter. | `RemoveLastTests.swift` |
| `replace` | `Liquid standard` | `value | replace: search, replacement` | String | Missing replacement uses empty string. | `ReplaceTests.swift` |
| `replace_first` | `Liquid standard` | `value | replace_first: search, replacement` | String | Replaces first occurrence only. | `ReplaceFirstTests.swift` |
| `replace_last` | `Shopify-compatible` | `value | replace_last: search, replacement` | String | Registered default filter. | `ReplaceLastTests.swift` |
| `slice` | `Shopify-compatible` | `value | slice: offset, length` | String or array | Float/nil offsets throw typed errors. | `SliceTests.swift` |
| `split` | `Liquid standard` | `value | split: separator` | Array | Nil separator follows renderer compatibility behavior. | `SplitTests.swift` |
| `truncate` | `Liquid standard` | `value | truncate: length, ending` | String | Nil length is a typed error. | `TruncateTests.swift` |
| `truncatewords` | `Liquid standard` | `value | truncatewords: count, ending` | String | Count is clamped to at least one word. | `TruncatewordsTests.swift` |
| `size` | `Liquid standard` | `value | size` | Number | Counts strings, arrays, dictionaries, and compatible values. | `SizeTests.swift` |
| `slugify` | `RhoeLiquid extension` | `value | slugify` | String | Lowercases, hyphenates spaces/underscores, removes unsupported characters. | `Renderer+Filters.swift` |

## Examples

```liquid
{{ "  Rhoe Liquid  " | strip | downcase | replace: " ", "-" }}
```

Output:

```text
rhoe-liquid
```

```liquid
{{ "alpha,beta,gamma" | split: "," | first }}
{{ "release-candidate" | slice: 0, 7 }}
```

Output:

```text
alpha
release
```
