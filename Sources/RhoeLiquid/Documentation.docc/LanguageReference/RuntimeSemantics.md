# Runtime Semantics

Execution behavior that affects portability, safety, and diagnostics.

## Profiles

| Profile | Status | Behavior |
| --- | --- | --- |
| `shopify_compatible` | `Shopify-compatible` | Rejects Rhoe authoring extensions such as macros and input declarations; keeps the portable Liquid subset. |
| `extended` | `RhoeLiquid extension` | Enables inheritance, macros, input contracts, data capabilities, custom tags/filters, and debug features according to sandbox policy. |

## Error Handling

| Situation | Default behavior | Strict/error behavior |
| --- | --- | --- |
| Missing variable | Empty output | Undefined-variable render error. |
| Missing filter | Render error | Render error with suggestion when possible. |
| Bad filter argument | Render error or compatible fallback, depending on filter | Typed render error. |
| Missing template | Template-not-found render error | Same, with template path context. |
| Archived syntax | Parser error | Parser error. |

## Escaping and Safety

HTML escaping is controlled by renderer configuration and explicit filters. Use `escape` or `escape_once` for user-provided HTML contexts. Use `raw` only for trusted strings that should bypass escaping.

## File and Data Access

File-backed `include`, `render`, inheritance, and `{% data ... = load(...) %}` require the active loader/registry and sandbox policy to allow the requested operation. The data loading tag supports JSON, Markdown, CSV, XML/HTML, SQLite-shaped data, YAML, TOML, and GraphQL through registered data loaders.

## Analysis and Diagnostics

The platform analysis surface reports variables, tags, filters, referenced templates, data capabilities, macro definitions/imports/calls, input contracts, and security findings. This is the same surface used by the HTTP service and contributor-facing release evidence tooling.
