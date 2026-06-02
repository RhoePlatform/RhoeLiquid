# Encoding and Escaping Filters

Filters for safe text output and encoded data.

## Reference

| Filter | Status | Signature | Returns | Nil/error behavior | Evidence |
| --- | --- | --- | --- | --- | --- |
| `escape` | `Liquid standard` | `value | escape` | Safe HTML string | Escapes raw HTML-sensitive characters. | `EscapeTests.swift` |
| `escape_once` | `Liquid standard` | `value | escape_once` | Safe HTML string | Avoids double-escaping existing entities. | `EscapeOnceTests.swift` |
| `raw` | `RhoeLiquid extension` | `value | raw` | Safe HTML string | Marks trusted content as safe. | `Renderer+Filters.swift` |
| `strip_html` | `Liquid standard` | `value | strip_html` | String | Removes HTML/script/style markup. | `StripHtmlTests.swift` |
| `strip_newlines` | `Liquid standard` | `value | strip_newlines` | String | Removes `\n` and `\r`. | `StripNewlinesTests.swift` |
| `newline_to_br` | `Liquid standard` | `value | newline_to_br` | String | Converts newlines to `<br />\n`. | `NewlineToBrTests.swift` |
| `url_encode` | `Liquid standard` | `value | url_encode` | String | Uses form-style encoding; spaces become `+`. | `UrlEncodeTests.swift` |
| `url_decode` | `Liquid standard` | `value | url_decode` | String | Decodes `%` escapes and `+` as space. | `UrlDecodeTests.swift` |
| `url_param` | `Deferred` | `value | url_param` | String | Filter type exists but is not active by default. | `UtilityFilters.swift` |
| `base64_encode` | `RhoeLiquid extension` | `value | base64_encode` | String | UTF-8 base64 output. | `Base64EncodeTests.swift` |
| `base64_decode` | `RhoeLiquid extension` | `value | base64_decode` | String | Non-string values throw typed errors. | `Base64DecodeTests.swift` |
| `base64_url_safe_encode` | `RhoeLiquid extension` | `value | base64_url_safe_encode` | String | URL-safe base64 output. | `Base64UrlSafeEncodeTests.swift` |
| `base64_url_safe_decode` | `RhoeLiquid extension` | `value | base64_url_safe_decode` | String | Adds padding and decodes URL-safe base64. | `Base64UrlSafeDecodeTests.swift` |

## Examples

```liquid
{{ user_input | escape_once }}
{{ "hello world" | url_encode }}
{{ "RhoeLiquid" | base64_encode }}
```
