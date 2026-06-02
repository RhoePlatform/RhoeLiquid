#!/usr/bin/env bash

set -euo pipefail

LIQUID_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "==> RhoeLiquid v0.1.0 release-check"
(
  cd "${LIQUID_ROOT}"
  bash Scripts/CI/verify-release-readiness.sh
)

echo "RhoeLiquid foundation verification passed."
