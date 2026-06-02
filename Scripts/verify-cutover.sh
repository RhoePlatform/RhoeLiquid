#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SPEC_ROOT_DEFAULT="${REPO_ROOT}/../RhoeLanguageSpec"

resolve_spec_root() {
  if [[ -n "${RHOE_LANGUAGE_SPEC_ROOT:-}" && -d "${RHOE_LANGUAGE_SPEC_ROOT}" ]]; then
    printf '%s\n' "${RHOE_LANGUAGE_SPEC_ROOT}"
    return 0
  fi
  if [[ -d "${SPEC_ROOT_DEFAULT}" ]]; then
    printf '%s\n' "${SPEC_ROOT_DEFAULT}"
    return 0
  fi
  printf '%s\n' "${HOME}/RhoePlatform/01_Foundations/RhoeLanguageSpec"
}

SPEC_ROOT="$(resolve_spec_root)"

verify_language_authority() {
  local spec_root="${1}"
  python3 - "$spec_root" <<'PY'
from pathlib import Path
import json
import sys

spec_root = Path(sys.argv[1]).resolve()
manifest_path = spec_root / "machine/registries/rhoe-language-spec-release.json"

if not manifest_path.exists():
    raise SystemExit(f"Missing language authority manifest: {manifest_path}")

manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
if manifest.get("authorityRepo") != "RhoeLanguageSpec":
    raise SystemExit("Language authority manifest must declare authorityRepo RhoeLanguageSpec")
if manifest.get("baselineVersion") != "0.51":
    raise SystemExit("Language authority manifest must declare baselineVersion 0.51")
if manifest.get("status") != "stable_authority_baseline":
    raise SystemExit("Language authority manifest must declare status stable_authority_baseline")

entrypoints = manifest.get("authoritativeEntrypoints", {})
required = [
    spec_root / "00-index.md",
    spec_root / entrypoints["public_reference"],
    spec_root / entrypoints["release_pack_summary"],
    spec_root / entrypoints["cutover_verifier"],
]
missing = [str(path) for path in required if not path.exists()]
if missing:
    raise SystemExit(f"Language authority surface missing files: {', '.join(missing)}")

print("LANGUAGE_AUTHORITY PASS")
print(f"LANGUAGE_BASELINE {manifest['baselineVersion']}")
PY
}

cd "${REPO_ROOT}"

echo "==> verify RhoeLanguageSpec authority release"
verify_language_authority "${SPEC_ROOT}"

echo
echo "==> swift package dump-package"
swift package dump-package > /dev/null

echo
echo "==> Scripts/CI/verify-release-readiness.sh"
bash Scripts/CI/verify-release-readiness.sh

echo
echo "==> swift build --product liquid"
swift build --product liquid

echo
echo "==> swift build --product RhoeLiquidService"
swift build --product RhoeLiquidService

echo
echo "RhoeLiquid cutover verification passed."
