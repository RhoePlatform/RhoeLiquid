# Releasing

This repository is staged for a clean `v0.1.0` public foundation release.

## Local Release Candidate

Run the full local gate before creating a tag:

```bash
bash Scripts/CI/verify-release-readiness.sh
RHOE_LANGUAGE_SPEC_ROOT=/path/to/RhoeLanguageSpec bash Scripts/verify-cutover.sh
```

The release gate builds debug and release products, runs tests, validates documentation, checks public hygiene, validates the Homebrew formula template, and builds the DocC Pages artifact.

## Git Sequence

The staging directory must remain uninitialized until release readiness passes. After certification:

```bash
git init
git add .
git commit -m "Initial RhoeLiquid 0.1.0 public foundation release"
```

Create `RhoePlatform/RhoeLiquid` as a private repository first, push the initial commit, enable repository settings, then perform the final visibility switch only after the public audit passes.

## Homebrew

`Packaging/Homebrew/rhoe-liquid.rb.template` intentionally keeps `__VERSION__` and `__SOURCE_SHA256__` placeholders until the `v0.1.0` source archive exists. The installable formula is published from the `RhoePlatform/homebrew-rhoe` tap after the tag archive checksum and bottle checksums are generated and reviewed.

## GitHub Pages

The DocC Pages workflow builds static API documentation for `RhoeLiquid`, `RhoeDOCX`, and `RhoeLiquidWasm`. Enable Pages only after the private remote is configured and the first maintainer gate passes on GitHub.
