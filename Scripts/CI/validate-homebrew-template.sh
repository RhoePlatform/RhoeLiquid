#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

TEMPLATE="Packaging/Homebrew/rhoe-liquid.rb.template"

fail() {
  echo "error: $*" >&2
  exit 1
}

[[ -f "$TEMPLATE" ]] || fail "Missing Homebrew formula template: $TEMPLATE"

grep -Fq 'class RhoeLiquid < Formula' "$TEMPLATE" || fail "Formula template must define class RhoeLiquid"
grep -Fq 'https://github.com/RhoePlatform/RhoeLiquid/archive/refs/tags/v__VERSION__.tar.gz' "$TEMPLATE" || fail "Formula template must use the RhoePlatform release archive URL"
grep -Fq 'sha256 "__SOURCE_SHA256__"' "$TEMPLATE" || fail "Formula template must leave a source checksum placeholder until the tag archive exists"
grep -Fq 'bin.install ".build/release/liquid"' "$TEMPLATE" || fail "Formula template must install the liquid CLI"

echo "Homebrew formula template validation passed."
