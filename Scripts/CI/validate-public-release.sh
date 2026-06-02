#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

fail() {
  echo "error: $*" >&2
  exit 1
}

scan_repo_fixed() {
  local pattern="$1"

  if command -v rg >/dev/null 2>&1; then
    rg -n --fixed-strings "$pattern" \
      --glob '!Scripts/CI/validate-public-release.sh' \
      --glob '!Scripts/CI/validate-docs.sh' \
      --glob '!Documentation/Guides/DataSources/TOMLDataSource-Guide.md' \
      --glob '!Tests/RhoeLiquidTests/RhoeLiquidCompatibilityTests.swift' \
      .
    return
  fi

  find . \
    \( -path './.build' -o -path './.git' \) -prune -o \
    -type f \
    ! -path './Scripts/CI/validate-public-release.sh' \
    ! -path './Scripts/CI/validate-docs.sh' \
    ! -path './Documentation/Guides/DataSources/TOMLDataSource-Guide.md' \
    ! -path './Tests/RhoeLiquidTests/RhoeLiquidCompatibilityTests.swift' \
    -exec grep -nF -- "$pattern" {} +
}

scan_files_fixed() {
  local pattern="$1"
  shift

  if command -v rg >/dev/null 2>&1; then
    rg -n --fixed-strings "$pattern" "$@"
    return
  fi

  grep -nF -- "$pattern" "$@"
}

for forbidden_path in .DS_Store SESSION_HANDOVER.md ARCHITECTURE_AUDIT.md; do
  if [[ -e "$forbidden_path" ]]; then
    fail "Forbidden public staging artifact present: $forbidden_path"
  fi
done

while IFS= read -r path; do
  fail "Forbidden macOS metadata file present: $path"
done < <(find . -path './.build' -prune -o -path './.git' -prune -o -name '.DS_Store' -print)

while IFS= read -r path; do
  fail "Legacy pre-public filename present: $path"
done < <(find . -path './.build' -prune -o -path './.git' -prune -o -name '*RhoeLiquidKit*' -print)

check_absent() {
  local pattern="$1"
  if scan_repo_fixed "$pattern"; then
    fail "Found forbidden public-release text: $pattern"
  fi
}

check_absent 'RhoeAI'
check_absent 'https://github.com/RhoeAI/RhoeLiquid'
check_absent 'MIT License'
check_absent '/Users/thorfuchs'
check_absent '~/Rhoe'
check_absent '0.0.0-internal'
check_absent 'internal-v2 RC'
check_absent 'SESSION_HANDOVER.md'
check_absent 'RhoeLiquidKit'
check_absent '../Archive/'

if ! scan_files_fixed 'Apache 2.0' README.md LICENSE NOTICE GOVERNANCE.md SECURITY.md RELEASING.md >/dev/null; then
  fail "Expected Apache 2.0 release identity in public docs"
fi

echo "Public release hygiene validation passed."
