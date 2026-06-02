#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

swift --version
swift build
swift build -c release
swift test
bash Scripts/CI/validate-docs.sh
bash Scripts/CI/validate-language-reference.sh
bash Scripts/CI/validate-cli-artifacts.sh
bash Scripts/CI/validate-examples.sh
bash Scripts/CI/validate-public-release.sh
bash Scripts/CI/validate-homebrew-template.sh
bash Scripts/CI/build-docc-pages.sh

if [[ "${RHOE_RUN_LINUX_CLI_GATE:-0}" == "1" ]]; then
  bash Scripts/CI/build-linux-cli.sh
fi

echo "Release-readiness verification passed."
