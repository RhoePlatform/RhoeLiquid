#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

python3 - <<'PY'
import json
import re
import sys
from pathlib import Path

root = Path.cwd()
manifest_path = root / "Documentation/LanguageReference/rhoe-liquid-language-surface.json"
doc_root = root / "Sources/RhoeLiquid/Documentation.docc/LanguageReference"
catalog_root = root / "Sources/RhoeLiquid/Documentation.docc/RhoeLiquid.md"
core_path = root / "Sources/LiquidCore/LiquidCore.swift"

errors = []

def fail(message: str) -> None:
    errors.append(message)

if not manifest_path.is_file():
    fail(f"missing manifest: {manifest_path}")
else:
    manifest = json.loads(manifest_path.read_text())

if not doc_root.is_dir():
    fail(f"missing DocC language-reference directory: {doc_root}")

if not catalog_root.is_file() or "<doc:LanguageReference>" not in catalog_root.read_text():
    fail("root RhoeLiquid DocC page must link <doc:LanguageReference>")

if errors:
    for error in errors:
        print(f"error: {error}", file=sys.stderr)
    sys.exit(1)

allowed_statuses = set(manifest.get("badge_vocabulary", []))
expected_statuses = {
    "Liquid standard",
    "Shopify-compatible",
    "RhoeLiquid extension",
    "Deprecated",
    "Archived",
    "Unsupported",
    "Deferred",
}
if allowed_statuses != expected_statuses:
    fail(f"badge vocabulary mismatch: {sorted(allowed_statuses)}")

entry_groups = ["profiles", "types", "operators", "tags", "filters"]
entries = []
for group in entry_groups:
    group_entries = manifest.get(group)
    if not isinstance(group_entries, list) or not group_entries:
        fail(f"manifest group '{group}' must be a non-empty list")
        continue
    for item in group_entries:
        item = dict(item)
        item["kind"] = group
        entries.append(item)

for item in entries:
    name = item.get("name")
    status = item.get("status")
    doc = item.get("doc")
    kind = item.get("kind")
    if not name:
        fail(f"{kind} entry missing name: {item}")
        continue
    if status not in allowed_statuses:
        fail(f"{kind} '{name}' has unknown status '{status}'")
    if not doc:
        fail(f"{kind} '{name}' missing doc")
        continue
    doc_path = doc_root / f"{doc}.md"
    if not doc_path.is_file():
        fail(f"{kind} '{name}' points at missing DocC page {doc}.md")

def source_string_set(constant_name: str) -> set[str]:
    text = core_path.read_text()
    pattern = rf"public let {re.escape(constant_name)}: Set<String> = \[(.*?)\]"
    match = re.search(pattern, text, re.DOTALL)
    if not match:
        fail(f"could not locate {constant_name} in {core_path}")
        return set()
    return set(re.findall(r'"([^"]+)"', match.group(1)))

manifest_tags = {item["name"] for item in manifest["tags"]}
manifest_filters = {item["name"] for item in manifest["filters"]}

required_tags = source_string_set("builtInTagNames") | {
    "#",
    "extends",
    "slot",
    "endslot",
    "fill",
    "endfill",
    "data",
    "load",
    "empty",
    "with",
    "recursive",
    "loop",
    "custom_tag",
    "ifchanged",
    "doc",
}
required_filters = source_string_set("builtInFilterNames") | {
    "escape_once",
    "raw",
    "concat",
    "remove_first",
    "remove_last",
    "replace_first",
    "replace_last",
    "slice",
    "sort_natural",
    "sum",
    "find_index",
    "has",
    "reject",
    "base64_url_safe_encode",
    "base64_url_safe_decode",
    "select",
    "select_all",
    "xpath",
    "text",
    "attr",
    "inner_html",
    "tag_name",
    "children",
    "sql_query",
    "sql_select",
    "sql_join",
    "sql_count",
    "sql_sum",
    "sql_avg",
    "sql_min",
    "sql_max",
    "sql_distinct",
    "sql_schema",
    "yaml_merge",
    "to_yaml",
    "to_toml",
    "graphql_data",
    "graphql_errors",
    "graphql_has_errors",
    "inspect",
    "type",
    "random",
    "range",
    "number_format",
    "currency",
}

missing_tags = sorted(required_tags - manifest_tags)
missing_filters = sorted(required_filters - manifest_filters)
if missing_tags:
    fail(f"manifest missing required tags: {', '.join(missing_tags)}")
if missing_filters:
    fail(f"manifest missing required filters: {', '.join(missing_filters)}")

orphan_manifest_tags = sorted(manifest_tags - required_tags)
if "custom_tag" in orphan_manifest_tags:
    orphan_manifest_tags.remove("custom_tag")

docs_by_name = {path.stem: path.read_text() for path in doc_root.glob("*.md")}
hub = docs_by_name.get("LanguageReference", "")
for required_doc in [
    "Syntax",
    "ValuesAndVariables",
    "Expressions",
    "RuntimeSemantics",
    "Tags-MacrosAndContracts",
    "Tags-DataAndDebug",
    "Filters-DateFormatting",
    "Filters-EncodingEscaping",
    "Filters-Data",
    "CompatibilityAudit",
    "UnsupportedAndDeferred",
    "LanguageSurfaceManifest",
]:
    if f"<doc:{required_doc}>" not in hub:
        fail(f"LanguageReference hub missing <doc:{required_doc}>")

doc_coverage_skip = {"#", "|", "==", "!=", "<", ">", "<=", ">=", "+", "-", "*", "/", "%", ".."}
for item in entries:
    name = item.get("name")
    doc = item.get("doc")
    if not name or not doc or name in doc_coverage_skip:
        continue
    content = docs_by_name.get(doc)
    if content is None:
        continue
    literal = f"`{name}`"
    if literal not in content and name not in content:
        fail(f"{item['kind']} '{name}' is listed in manifest but not mentioned in {doc}.md")

if errors:
    for error in errors:
        print(f"error: {error}", file=sys.stderr)
    sys.exit(1)

print("Language reference validation passed.")
PY
