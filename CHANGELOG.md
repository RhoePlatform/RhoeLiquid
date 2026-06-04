# Changelog

All notable changes to RhoeLiquid will be documented in this file.

## [0.1.1] - 2026-06-04

- Fix Linux Swift 6.3 builds by replacing the last raw C `stderr` write with Swift `FileHandle.standardError`.
- Keep the public `0.1.x` API surface unchanged while unblocking downstream RhoeMarkdown Linux CLI certification.

## [0.1.0] - 2026-05-31

- Initial contributor-facing Apache 2.0 foundation release candidate for the `RhoePlatform/RhoeLiquid` repo.
- Includes the Swift Liquid engine, DOCX support, localhost HTTP service, CLI, WASM target, documentation, tests, and release-readiness tooling.
- Keeps downstream app shells outside this repo while preserving the complete foundation package surface.
