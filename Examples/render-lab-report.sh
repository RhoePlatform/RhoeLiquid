#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

OUTPUT_DIR="${LIQUID_EXAMPLE_OUTPUT_DIR:-Examples/outputs}"
mkdir -p "$OUTPUT_DIR"

echo "==> lab-report.tex"
swift run liquid render \
  "Examples/templates/lab-report.tex.liquid" \
  --context "Examples/data/lab-report.json" \
  --output "$OUTPUT_DIR/lab-report.tex"

echo "Rendered $OUTPUT_DIR/lab-report.tex"
