#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

OUTPUT_DIR="${LIQUID_EXAMPLE_OUTPUT_DIR:-Examples/outputs}"
mkdir -p "$OUTPUT_DIR"

echo "==> product-launch.html"
swift run liquid render \
  "Examples/templates/product-launch.html.liquid" \
  --context "Examples/data/product-launch.json" \
  --output "$OUTPUT_DIR/product-launch.html"

echo "Rendered $OUTPUT_DIR/product-launch.html"
