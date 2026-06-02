#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

fail() {
  echo "error: $*" >&2
  exit 1
}

assert_file() {
  local path="$1"
  [[ -f "$path" ]] || fail "Missing required documentation file: $path"
}

assert_contains() {
  local path="$1"
  local expected="$2"
  grep -Fq "$expected" "$path" || fail "Expected '$expected' in $path"
}

assert_not_contains() {
  local path="$1"
  local forbidden="$2"
  if grep -Fq "$forbidden" "$path"; then
    fail "Found stale text '$forbidden' in $path"
  fi
}

DOCS_DIR="Sources/RhoeLiquid/Documentation.docc"

required_files=(
  "README.md"
  "CHANGELOG.md"
  "CONTRIBUTING.md"
  "GOVERNANCE.md"
  "SECURITY.md"
  "RELEASING.md"
  "Examples/README.md"
  "Examples/render-all.sh"
  "Examples/render-product-launch.sh"
  "Examples/outputs/product-launch.html"
  "Documentation/README.md"
  "Documentation/API-Reference.md"
  "Documentation/Architecture.md"
  "Documentation/Architecture/Feature-Comparison.md"
  "Documentation/CLI/README.md"
  "Documentation/CLI/man/liquid.1"
  "Documentation/CLI/completions/liquid.bash"
  "Documentation/CLI/completions/_liquid"
  "Documentation/CLI/completions/liquid.fish"
  "Documentation/Release/LinuxCLIReadiness.md"
  "$DOCS_DIR/RhoeLiquid.md"
  "$DOCS_DIR/GettingStarted.md"
  "$DOCS_DIR/Architecture.md"
  "$DOCS_DIR/PerformanceGuide.md"
  "$DOCS_DIR/CustomFilters.md"
  "$DOCS_DIR/DataSourceArchitecture.md"
  "$DOCS_DIR/TemplateBasics.md"
  "$DOCS_DIR/LanguageReference/LanguageReference.md"
  "$DOCS_DIR/LanguageReference/Syntax.md"
  "$DOCS_DIR/LanguageReference/ValuesAndVariables.md"
  "$DOCS_DIR/LanguageReference/Expressions.md"
  "$DOCS_DIR/LanguageReference/RuntimeSemantics.md"
  "$DOCS_DIR/LanguageReference/Tags-MacrosAndContracts.md"
  "$DOCS_DIR/LanguageReference/Tags-DataAndDebug.md"
  "$DOCS_DIR/LanguageReference/Filters-DateFormatting.md"
  "$DOCS_DIR/LanguageReference/Filters-EncodingEscaping.md"
  "$DOCS_DIR/LanguageReference/Filters-Data.md"
  "$DOCS_DIR/LanguageReference/UnsupportedAndDeferred.md"
  "$DOCS_DIR/LanguageReference/LanguageSurfaceManifest.md"
  "Documentation/LanguageReference/rhoe-liquid-language-surface.json"
  "Sources/RhoeDOCX/Documentation.docc/RhoeDOCX.md"
  "api/openapi.yaml"
  "api/schema.json"
)

for path in "${required_files[@]}"; do
  assert_file "$path"
done

while IFS= read -r ref; do
  [[ -z "$ref" ]] && continue

  if ! find "$DOCS_DIR" -type f -name "$ref.md" -print -quit | grep -q .; then
    fail "Unresolved DocC article reference: <doc:$ref>"
  fi
done < <(
  grep -Rho '<doc:[^>]*>' "$DOCS_DIR" --include='*.md' \
    | sed -E 's#<doc:([^>]+)>#\1#' \
    | sort -u
)

assert_contains "README.md" 'Current platform surface'
assert_contains "README.md" 'RhoePublishStudio'
assert_contains "README.md" 'intentionally not part of this foundation seed'
assert_contains "README.md" 'https://github.com/RhoePlatform/RhoeLiquid.git'
assert_contains "README.md" 'Examples'
assert_not_contains "README.md" 'cd WordAddin'
assert_not_contains "README.md" 'make addin-ci'
assert_not_contains "README.md" '/Users/thorfuchs'
assert_not_contains "README.md" '~/Rhoe'
assert_not_contains "README.md" 'RhoeAI'

legacy_alias="RhoeLiquid""Kit"

assert_not_contains "Documentation/API-Reference.md" "$legacy_alias"
assert_contains "Documentation/API-Reference.md" 'Product Surface Policy'
assert_not_contains "Documentation/Architecture.md" 'RELEASE_AUDIT.md'
assert_not_contains "Documentation/Architecture.md" 'NEXT_WAVE_ROADMAP.md'
assert_not_contains "Documentation/README.md" 'RELEASE_AUDIT.md'
assert_not_contains "Documentation/README.md" 'NEXT_WAVE_ROADMAP.md'
assert_not_contains "Documentation/README.md" 'Archive/'
assert_not_contains "Documentation/README.md" 'SESSION_HANDOVER.md'
assert_contains "Documentation/README.md" 'Release/LinuxCLIReadiness.md'
assert_contains "Documentation/README.md" 'CLI/README.md'
assert_contains "Documentation/README.md" '../Examples/'
assert_contains "Examples/README.md" 'bash Examples/render-all.sh'
assert_contains "Examples/README.md" 'bash Examples/render-product-launch.sh'
assert_contains "Examples/README.md" 'Examples/outputs/'
assert_contains "Examples/README.md" 'lab-report.tex.liquid'
assert_contains "Documentation/CLI/README.md" 'bash Scripts/CI/generate-cli-artifacts.sh'
assert_contains "Documentation/CLI/man/liquid.1" '.Dt LIQUID 1'
assert_contains "Documentation/CLI/completions/liquid.bash" '__liquid'
assert_contains "Documentation/CLI/completions/_liquid" '#compdef liquid'
assert_contains "Documentation/CLI/completions/liquid.fish" "complete -c 'liquid'"
assert_contains "Documentation/Release/LinuxCLIReadiness.md" 'x86_64-swift-linux-musl'
assert_contains "Documentation/Release/LinuxCLIReadiness.md" 'bash Scripts/CI/build-linux-cli.sh'

assert_not_contains "$DOCS_DIR/RhoeLiquid.md" "$legacy_alias"
assert_contains "$DOCS_DIR/RhoeLiquid.md" '<doc:LanguageReference>'
assert_not_contains "$DOCS_DIR/GettingStarted.md" "$legacy_alias"
assert_contains "$DOCS_DIR/GettingStarted.md" 'https://github.com/RhoePlatform/RhoeLiquid.git'
assert_contains "Sources/RhoeDOCX/Documentation.docc/RhoeDOCX.md" 'RhoeLiquid foundation repo'
assert_not_contains "Sources/RhoeDOCX/Documentation.docc/RhoeDOCX.md" 'RhoeBookKit'

assert_not_contains "api/index.html" "$legacy_alias"
assert_contains "api/index.html" 'Apache 2.0 License'
assert_contains "api/openapi.yaml" 'version: 0.1.0'
assert_contains "Sources/LiquidCore/LiquidCore.swift" 'public let liquidCoreVersion = "0.1.0"'
assert_not_contains "Sources/LiquidCore/LiquidCore.swift" 'public let liquidCoreVersion = "1.0.0"'

swift package dump-package > /dev/null
bash Scripts/CI/validate-language-reference.sh

echo "Documentation validation passed."
