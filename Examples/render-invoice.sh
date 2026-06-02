#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

OUTPUT_DIR="${LIQUID_EXAMPLE_OUTPUT_DIR:-Examples/outputs}"
mkdir -p "$OUTPUT_DIR"

echo "==> invoice.html"
swift run liquid render \
  "Examples/templates/invoice.html.liquid" \
  --context "Examples/data/invoice.json" \
  --output "$OUTPUT_DIR/invoice.html"

echo "Rendered $OUTPUT_DIR/invoice.html"
