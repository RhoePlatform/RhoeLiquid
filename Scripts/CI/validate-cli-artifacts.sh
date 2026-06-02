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
  [[ -f "$path" ]] || fail "Missing CLI artifact: $path"
}

checked_in=(
  "Documentation/CLI/man/liquid.1"
  "Documentation/CLI/completions/liquid.bash"
  "Documentation/CLI/completions/_liquid"
  "Documentation/CLI/completions/liquid.fish"
)

for path in "${checked_in[@]}"; do
  assert_file "$path"
done

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/rhoeliquid-cli-artifacts.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT

echo "==> regenerating CLI artifacts for drift check"
LIQUID_CLI_ARTIFACT_ROOT="$tmp_dir" bash Scripts/CI/generate-cli-artifacts.sh

for relative in \
  "man/liquid.1" \
  "completions/liquid.bash" \
  "completions/_liquid" \
  "completions/liquid.fish"
do
  diff -u "Documentation/CLI/$relative" "$tmp_dir/$relative" \
    || fail "CLI artifact drift detected for Documentation/CLI/$relative. Run bash Scripts/CI/generate-cli-artifacts.sh."
done

echo "CLI artifact validation passed."
