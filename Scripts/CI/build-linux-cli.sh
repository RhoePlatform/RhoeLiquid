#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

sdk_available() {
  if swift sdk list | awk '{print $1}' | grep -Fxq "$SDK_ID"; then
    return 0
  fi

  local swift_sdks_dir="${SWIFT_SDKS_DIR:-$HOME/Library/org.swift.swiftpm/swift-sdks}"
  if [[ -d "$swift_sdks_dir" ]] && grep -R "\"$SDK_ID\"" "$swift_sdks_dir"/*.artifactbundle/*/*/swift-sdk.json >/dev/null 2>&1; then
    return 0
  fi

  return 1
}

SDK_ID="${RHOE_LINUX_SDK_ID:-x86_64-swift-linux-musl}"
PRODUCT="${RHOE_LINUX_CLI_PRODUCT:-liquid}"
CONFIGURATION="${RHOE_LINUX_BUILD_CONFIGURATION:-release}"

echo "Swift toolchain:"
swift --version
echo ""

echo "Checking Swift SDK target: ${SDK_ID}"
if ! sdk_available; then
  cat >&2 <<MESSAGE
error: Swift SDK '${SDK_ID}' is not installed.

Install the matching Swift Static Linux SDK for the active swift.org toolchain,
then rerun this gate. The canonical command shape is:

  swift sdk install <artifactbundle-url-or-file> --checksum <checksum>

See: https://www.swift.org/documentation/articles/static-linux-getting-started.html
MESSAGE
  exit 78
fi

echo "Building ${PRODUCT} for ${SDK_ID} (${CONFIGURATION})..."
swift build -c "$CONFIGURATION" --product "$PRODUCT" --swift-sdk "$SDK_ID"

echo "Linux CLI build passed for product '${PRODUCT}' with SDK '${SDK_ID}'."
