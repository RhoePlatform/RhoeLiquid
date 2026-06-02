#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

OUTPUT_DIR="${1:-.build/docc-pages}"
BASE_PATH="${DOCC_HOSTING_BASE_PATH:-RhoeLiquid}"
TARGETS=(RhoeLiquid RhoeDOCX RhoeLiquidWasm)

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

for target in "${TARGETS[@]}"; do
  target_output="${OUTPUT_DIR}/${target}"
  echo "==> Building DocC site for ${target}"
  swift package \
    --allow-writing-to-directory "$target_output" \
    generate-documentation \
    --target "$target" \
    --disable-indexing \
    --transform-for-static-hosting \
    --hosting-base-path "${BASE_PATH}/${target}" \
    --output-path "$target_output"
done

cat > "${OUTPUT_DIR}/index.html" <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>RhoeLiquid Documentation</title>
  <style>
    :root {
      color-scheme: light dark;
      font-family: ui-serif, Georgia, Cambria, "Times New Roman", Times, serif;
    }
    body {
      margin: 0;
      min-height: 100vh;
      display: grid;
      place-items: center;
      background:
        radial-gradient(circle at 20% 20%, rgba(61, 112, 255, 0.16), transparent 28rem),
        linear-gradient(135deg, #f9f7f1 0%, #edf4f7 100%);
      color: #18212f;
    }
    main {
      width: min(760px, calc(100vw - 48px));
      padding: 48px;
      border: 1px solid rgba(24, 33, 47, 0.12);
      border-radius: 28px;
      background: rgba(255, 255, 255, 0.76);
      box-shadow: 0 24px 80px rgba(24, 33, 47, 0.12);
    }
    h1 {
      margin: 0 0 12px;
      font-size: clamp(2.4rem, 8vw, 5rem);
      line-height: 0.92;
      letter-spacing: -0.06em;
    }
    p {
      max-width: 56ch;
      font-size: 1.1rem;
      line-height: 1.6;
    }
    a {
      display: inline-block;
      margin: 16px 16px 0 0;
      color: #173b67;
      font-weight: 700;
    }
  </style>
</head>
<body>
  <main>
    <h1>RhoeLiquid</h1>
    <p>Contributor-facing API documentation for the RhoeLiquid engine, DOCX foundation, and WebAssembly target.</p>
    <a href="./RhoeLiquid/documentation/rhoeliquid/">RhoeLiquid API</a>
    <a href="./RhoeDOCX/documentation/rhoedocx/">RhoeDOCX API</a>
    <a href="./RhoeLiquidWasm/documentation/rhoeliquidwasm/">RhoeLiquidWasm API</a>
  </main>
</body>
</html>
HTML

echo "DocC Pages artifact written to ${OUTPUT_DIR}"
