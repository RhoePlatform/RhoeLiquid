#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

OUTPUT_DIR="${LIQUID_EXAMPLE_OUTPUT_DIR:-Examples/outputs}"
mkdir -p "$OUTPUT_DIR"

scripts=(
  "render-product-launch.sh"
  "render-invoice.sh"
  "render-release-notes.sh"
  "render-component-gallery.sh"
  "render-config-audit.sh"
  "render-board-brief.sh"
  "render-research-abstract.sh"
  "render-lab-report.sh"
)

for script in "${scripts[@]}"; do
  bash "Examples/$script"
done

echo
echo "Rendered examples into $OUTPUT_DIR"
