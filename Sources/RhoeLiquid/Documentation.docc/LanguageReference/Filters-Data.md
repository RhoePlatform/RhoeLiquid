# Data Source Filters

RhoeLiquid extension filters for structured data, XML/HTML selection, SQLite-shaped rows, YAML/TOML, and GraphQL responses.

## Collection Data Filters

| Filter | Status | Signature | Returns |
| --- | --- | --- | --- |
| `sort_by` | `RhoeLiquid extension` | `rows | sort_by: "field"` | Sorted rows |
| `group_by` | `RhoeLiquid extension` | `rows | group_by: "field"` | Grouped rows |
| `pluck` | `RhoeLiquid extension` | `rows | pluck: "field"` | Field values |
| `limit` | `RhoeLiquid extension` | `rows | limit: count` | Prefix rows |
| `offset` | `RhoeLiquid extension` | `rows | offset: count` | Rows after offset |

## XML and HTML Filters

| Filter | Status | Signature | Returns |
| --- | --- | --- | --- |
| `select` | `RhoeLiquid extension` | `node | select: "selector"` | First matching node |
| `select_all` | `RhoeLiquid extension` | `node | select_all: "selector"` | Matching nodes |
| `xpath` | `RhoeLiquid extension` | `node | xpath: "path"` | XPath subset result |
| `text` | `RhoeLiquid extension` | `node | text` | Text content |
| `attr` | `RhoeLiquid extension` | `node | attr: "name"` | Attribute value |
| `inner_html` | `RhoeLiquid extension` | `node | inner_html` | Inner markup |
| `tag_name` | `RhoeLiquid extension` | `node | tag_name` | Element name |
| `children` | `RhoeLiquid extension` | `node | children` | Child nodes |

## SQLite-Shaped Row Filters

| Filter | Status | Signature | Returns |
| --- | --- | --- | --- |
| `sql_query` | `RhoeLiquid extension` | `db | sql_query: "select ..."` | Rows |
| `sql_select` | `RhoeLiquid extension` | `rows | sql_select: "field"` | Projected rows |
| `sql_join` | `RhoeLiquid extension` | `left | sql_join: right, left_key, right_key` | Joined rows |
| `sql_count` | `RhoeLiquid extension` | `rows | sql_count` | Count |
| `sql_sum` | `RhoeLiquid extension` | `rows | sql_sum: "field"` | Sum |
| `sql_avg` | `RhoeLiquid extension` | `rows | sql_avg: "field"` | Average |
| `sql_min` | `RhoeLiquid extension` | `rows | sql_min: "field"` | Minimum |
| `sql_max` | `RhoeLiquid extension` | `rows | sql_max: "field"` | Maximum |
| `sql_distinct` | `RhoeLiquid extension` | `rows | sql_distinct: "field"` | Unique values |
| `sql_schema` | `RhoeLiquid extension` | `db | sql_schema` | Schema metadata |

## YAML, TOML, and GraphQL Filters

| Filter | Status | Signature | Returns |
| --- | --- | --- | --- |
| `yaml_merge` | `RhoeLiquid extension` | `left | yaml_merge: right` | Merged YAML-like value |
| `to_yaml` | `RhoeLiquid extension` | `value | to_yaml` | YAML string |
| `to_toml` | `RhoeLiquid extension` | `value | to_toml` | TOML string |
| `graphql_data` | `RhoeLiquid extension` | `response | graphql_data` | GraphQL data object |
| `graphql_errors` | `RhoeLiquid extension` | `response | graphql_errors` | GraphQL errors |
| `graphql_has_errors` | `RhoeLiquid extension` | `response | graphql_has_errors` | Boolean |

## Example

```liquid
{% data catalog = load("catalog.xml") %}
{{ catalog | select_all: "product" | map: "title" | join: ", " }}
```

See `Documentation/API/DataFilters-Reference.md` and `Documentation/Guides/DataSources/` for implementation-oriented details.
