#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

fail() {
  echo "error: $*" >&2
  exit 1
}

assert_file() {
  local path="$1"
  [[ -f "$path" ]] || fail "Missing example artifact: $path"
}

assert_contains() {
  local path="$1"
  local expected="$2"
  grep -Fq -- "$expected" "$path" || fail "Expected '$expected' in rendered example $path"
}

assert_matches() {
  local actual="$1"
  local expected="$2"
  if ! cmp -s "$actual" "$expected"; then
    diff -u "$expected" "$actual" || true
    fail "Rendered output drifted from canonical example output: $expected"
  fi
}

required_files=(
  "Examples/README.md"
  "Examples/COMMANDS.md"
  "Examples/gallery-manifest.json"
  "Examples/render-all.sh"
  "Examples/render-product-launch.sh"
  "Examples/render-invoice.sh"
  "Examples/render-release-notes.sh"
  "Examples/render-component-gallery.sh"
  "Examples/render-config-audit.sh"
  "Examples/render-board-brief.sh"
  "Examples/render-research-abstract.sh"
  "Examples/render-lab-report.sh"
  "Examples/templates/product-launch.html.liquid"
  "Examples/templates/invoice.html.liquid"
  "Examples/templates/release-notes.html.liquid"
  "Examples/templates/component-gallery.html.liquid"
  "Examples/templates/config-audit.html.liquid"
  "Examples/templates/board-brief.md.liquid"
  "Examples/templates/research-abstract.md.liquid"
  "Examples/templates/lab-report.tex.liquid"
  "Examples/data/product-launch.json"
  "Examples/data/invoice.json"
  "Examples/data/release-notes.json"
  "Examples/data/component-gallery.json"
  "Examples/data/config-audit.json"
  "Examples/data/board-brief.json"
  "Examples/data/research-abstract.json"
  "Examples/data/lab-report.json"
  "Examples/outputs/product-launch.html"
  "Examples/outputs/invoice.html"
  "Examples/outputs/release-notes.html"
  "Examples/outputs/component-gallery.html"
  "Examples/outputs/config-audit.html"
  "Examples/outputs/board-brief.md"
  "Examples/outputs/research-abstract.md"
  "Examples/outputs/lab-report.tex"
)

for path in "${required_files[@]}"; do
  assert_file "$path"
done

while IFS= read -r template; do
  assert_contains "$template" "swift run liquid render $template"
  assert_contains "$template" "--output Examples/outputs/"
done < <(find Examples/templates -type f -name '*.liquid' | sort)

assert_contains "Examples/README.md" "Examples/outputs/"
assert_contains "Examples/README.md" "bash Examples/render-product-launch.sh"
assert_contains "Examples/README.md" "Source, Data, Command, Output"
assert_contains "Examples/README.md" "gallery-manifest.json"
assert_contains "Examples/COMMANDS.md" "bash Examples/render-all.sh"
assert_contains "Examples/COMMANDS.md" "LIQUID_EXAMPLE_OUTPUT_DIR=/tmp/rhoeliquid-gallery"

manifest_paths=(
  "Examples/templates/product-launch.html.liquid"
  "Examples/templates/invoice.html.liquid"
  "Examples/templates/release-notes.html.liquid"
  "Examples/templates/component-gallery.html.liquid"
  "Examples/templates/config-audit.html.liquid"
  "Examples/templates/board-brief.md.liquid"
  "Examples/templates/research-abstract.md.liquid"
  "Examples/templates/lab-report.tex.liquid"
  "Examples/data/product-launch.json"
  "Examples/data/invoice.json"
  "Examples/data/release-notes.json"
  "Examples/data/component-gallery.json"
  "Examples/data/config-audit.json"
  "Examples/data/board-brief.json"
  "Examples/data/research-abstract.json"
  "Examples/data/lab-report.json"
  "Examples/render-product-launch.sh"
  "Examples/render-invoice.sh"
  "Examples/render-release-notes.sh"
  "Examples/render-component-gallery.sh"
  "Examples/render-config-audit.sh"
  "Examples/render-board-brief.sh"
  "Examples/render-research-abstract.sh"
  "Examples/render-lab-report.sh"
  "Examples/outputs/product-launch.html"
  "Examples/outputs/invoice.html"
  "Examples/outputs/release-notes.html"
  "Examples/outputs/component-gallery.html"
  "Examples/outputs/config-audit.html"
  "Examples/outputs/board-brief.md"
  "Examples/outputs/research-abstract.md"
  "Examples/outputs/lab-report.tex"
)

for path in "${manifest_paths[@]}"; do
  assert_contains "Examples/gallery-manifest.json" "\"$path\""
done

while IFS= read -r script; do
  assert_contains "Examples/COMMANDS.md" "bash $script"
done < <(find Examples -maxdepth 1 -type f -name 'render-*.sh' | sort)

output_dir="$(mktemp -d "${TMPDIR:-/tmp}/rhoeliquid-examples.XXXXXX")"
trap 'rm -rf "$output_dir"' EXIT

echo "==> rendering public examples"
LIQUID_EXAMPLE_OUTPUT_DIR="$output_dir" bash Examples/render-all.sh

assert_matches "$output_dir/product-launch.html" "Examples/outputs/product-launch.html"
assert_matches "$output_dir/invoice.html" "Examples/outputs/invoice.html"
assert_matches "$output_dir/release-notes.html" "Examples/outputs/release-notes.html"
assert_matches "$output_dir/component-gallery.html" "Examples/outputs/component-gallery.html"
assert_matches "$output_dir/config-audit.html" "Examples/outputs/config-audit.html"
assert_matches "$output_dir/board-brief.md" "Examples/outputs/board-brief.md"
assert_matches "$output_dir/research-abstract.md" "Examples/outputs/research-abstract.md"
assert_matches "$output_dir/lab-report.tex" "Examples/outputs/lab-report.tex"

assert_contains "$output_dir/product-launch.html" "Liquid templates that feel engineered"
assert_contains "$output_dir/invoice.html" "Invoice"
assert_contains "$output_dir/release-notes.html" "RhoeLiquid Public Foundation"
assert_contains "$output_dir/component-gallery.html" "Reusable Component Gallery"
assert_contains "$output_dir/config-audit.html" "Local Compute Kernel Audit"
assert_contains "$output_dir/board-brief.md" "Public Foundation Release Brief"
assert_contains "$output_dir/research-abstract.md" "Structured Templates as Release Evidence"
assert_contains "$output_dir/lab-report.tex" "\\documentclass"

echo "Example validation passed."
