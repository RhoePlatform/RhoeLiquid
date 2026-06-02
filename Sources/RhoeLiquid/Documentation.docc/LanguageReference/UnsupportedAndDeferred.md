# Unsupported, Archived, and Deferred Surface

Known language items that are intentionally not active as normal template syntax in `0.1.0`.

## Tags

| Item | Status | Behavior |
| --- | --- | --- |
| `pipeline` / `endpipeline` | `Archived` | Recognized by the parser and rejected with an archived-feature error. |
| `ifchanged` | `Unsupported` | Present in disabled golden fixtures; not implemented. |
| `doc` | `Unsupported` | Present in disabled golden fixtures; not implemented. |
| Dynamic `extends` | `Unsupported` | `extends` must use a string literal and appear first. |

## Operators and Tests

| Item | Status | Behavior |
| --- | --- | --- |
| Arithmetic `+`, `-`, `*`, `/`, `%` | `Deferred` | AST/runtime enum cases exist, but parser exposure is not active. Use math filters. |
| `is` tests | `Deferred` | Token/AST/evaluator scaffolding exists, but parser exposure is not active. |
| Parenthesized condition grouping | `Unsupported` | Parentheses are for ranges and macro calls, not arbitrary condition grouping. |

## Filters

| Filter | Status | Recommended `0.1.0` path |
| --- | --- | --- |
| `clamp` | `Deferred` | Use `at_least` followed by `at_most`. |
| `date_to_string` | `Deferred` | Use `date`. |
| `date_to_rfc822` | `Deferred` | Use `date` with the desired format. |
| `date_to_iso8601` | `Deferred` | Use `date` with the desired format. |
| `now` | `Deferred` | Use `"now" | date: format`. |
| `parse_json` | `Deferred` | Load JSON through `{% data name = load("file.json") %}` or register the filter explicitly. |
| `url_param` | `Deferred` | Use `url_encode` for active default behavior. |
| `inspect`, `type`, `random`, `range`, `number_format`, `currency` | `Deferred` | Register explicitly in custom environments if needed. |

## Why This Page Exists

Public language references should make absence explicit. These entries prevent contributors and users from reading parser scaffolding, historical docs, or compatibility fixtures as active promises.
