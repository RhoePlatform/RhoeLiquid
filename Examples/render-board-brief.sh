#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

OUTPUT_DIR="${LIQUID_EXAMPLE_OUTPUT_DIR:-Examples/outputs}"
mkdir -p "$OUTPUT_DIR"

echo "==> board-brief.md"
swift run liquid render \
  "Examples/templates/board-brief.md.liquid" \
  --context "Examples/data/board-brief.json" \
  --output "$OUTPUT_DIR/board-brief.md"

echo "Rendered $OUTPUT_DIR/board-brief.md"
