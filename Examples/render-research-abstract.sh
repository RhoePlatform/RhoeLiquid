#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

OUTPUT_DIR="${LIQUID_EXAMPLE_OUTPUT_DIR:-Examples/outputs}"
mkdir -p "$OUTPUT_DIR"

echo "==> research-abstract.md"
swift run liquid render \
  "Examples/templates/research-abstract.md.liquid" \
  --context "Examples/data/research-abstract.json" \
  --output "$OUTPUT_DIR/research-abstract.md"

echo "Rendered $OUTPUT_DIR/research-abstract.md"
