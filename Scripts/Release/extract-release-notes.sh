#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

VERSION="${1:-}"
OUTPUT_PATH="${2:-release_notes.md}"

if [[ -z "$VERSION" ]]; then
  echo "usage: $0 <version> [output-path]" >&2
  exit 1
fi

if grep -q "^## \\[$VERSION\\]" CHANGELOG.md; then
  SECTION_HEADER="$(grep -m1 "^## \\[$VERSION\\]" CHANGELOG.md)"
else
  SECTION_HEADER="$(grep -m1 "^## \\[Unreleased\\]" CHANGELOG.md)"
fi

awk -v section_header="$SECTION_HEADER" '
  BEGIN { capture = 0 }
  $0 == section_header { capture = 1; next }
  capture && /^## \[/ { exit }
  capture { print }
' CHANGELOG.md > "$OUTPUT_PATH"

if ! grep -q '[^[:space:]]' "$OUTPUT_PATH"; then
  echo "error: no release notes content found in CHANGELOG.md for $VERSION" >&2
  exit 1
fi

echo "Wrote release notes to $OUTPUT_PATH"
