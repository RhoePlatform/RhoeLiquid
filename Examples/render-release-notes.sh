#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

OUTPUT_DIR="${LIQUID_EXAMPLE_OUTPUT_DIR:-Examples/outputs}"
mkdir -p "$OUTPUT_DIR"

echo "==> release-notes.html"
swift run liquid render \
  "Examples/templates/release-notes.html.liquid" \
  --context "Examples/data/release-notes.json" \
  --output "$OUTPUT_DIR/release-notes.html"

echo "Rendered $OUTPUT_DIR/release-notes.html"
