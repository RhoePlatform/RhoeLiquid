#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

OUTPUT_DIR="${LIQUID_EXAMPLE_OUTPUT_DIR:-Examples/outputs}"
mkdir -p "$OUTPUT_DIR"

echo "==> config-audit.html"
swift run liquid render \
  "Examples/templates/config-audit.html.liquid" \
  --context "Examples/data/config-audit.json" \
  --output "$OUTPUT_DIR/config-audit.html"

echo "Rendered $OUTPUT_DIR/config-audit.html"
