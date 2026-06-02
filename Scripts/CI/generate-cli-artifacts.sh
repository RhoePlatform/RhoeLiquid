#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

fail() {
  echo "error: $*" >&2
  exit 1
}

ARTIFACT_ROOT="${LIQUID_CLI_ARTIFACT_ROOT:-Documentation/CLI}"
MAN_DIR="${ARTIFACT_ROOT}/man"
COMPLETION_DIR="${ARTIFACT_ROOT}/completions"
MANUAL_CONFIGURATION="${LIQUID_CLI_MANUAL_CONFIGURATION:-debug}"
MANUAL_DATE="${LIQUID_CLI_MANUAL_DATE:-2026-06-01}"
MANUAL_AUTHOR="${LIQUID_CLI_MANUAL_AUTHOR:-RhoePlatform Maintainers}"

mkdir -p "$MAN_DIR" "$COMPLETION_DIR"

echo "==> generating liquid(1) manual page"
swift package generate-manual \
  --configuration "$MANUAL_CONFIGURATION" \
  --date "$MANUAL_DATE" \
  --authors "$MANUAL_AUTHOR"

manual_path="$(
  find .build/plugins -path '*/GenerateManual/outputs/LiquidCLI/liquid.1' -print \
    | sort \
    | tail -n 1
)"

[[ -n "$manual_path" && -f "$manual_path" ]] || fail "Generated liquid.1 manual page was not found"
cp "$manual_path" "$MAN_DIR/liquid.1"

echo "==> generating shell completion scripts"
swift run liquid --generate-completion-script bash > "$COMPLETION_DIR/liquid.bash"
swift run liquid --generate-completion-script zsh > "$COMPLETION_DIR/_liquid"
swift run liquid --generate-completion-script fish > "$COMPLETION_DIR/liquid.fish"

echo "CLI artifacts generated in $ARTIFACT_ROOT"
