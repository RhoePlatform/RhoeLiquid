#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

OUTPUT_DIR="${LIQUID_EXAMPLE_OUTPUT_DIR:-Examples/outputs}"
mkdir -p "$OUTPUT_DIR"

echo "==> component-gallery.html"
swift run liquid render \
  "Examples/templates/component-gallery.html.liquid" \
  --context "Examples/data/component-gallery.json" \
  --output "$OUTPUT_DIR/component-gallery.html"

echo "Rendered $OUTPUT_DIR/component-gallery.html"
