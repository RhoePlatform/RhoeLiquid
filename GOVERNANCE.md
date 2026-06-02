# Governance

`RhoeLiquid` is a founder-led Apache 2.0 foundation repository for the RhoePlatform open-source engine line.

The initial maintainer group is `@RhoePlatform/maintainers`. Maintainers are responsible for reviewing public API changes, release readiness, language-authority alignment, security reports, and contributor experience.

## Decision Model

- Public API, package structure, release workflow, and licensing changes require maintainer review.
- Compatibility changes should include tests and documentation updates.
- Publishing, tags, Homebrew tap updates, and GitHub Pages activation are release actions and must not happen from unreviewed pull requests.
- The repository intentionally contains the Swift foundation surface only. Downstream app shells remain separate consumers.

## Release Stewardship

The `v0.1.0` line is staged as the first public foundation release candidate. Release authority stays with maintainers until the initial clean commit, private remote, final hygiene audit, and public visibility switch are complete.
