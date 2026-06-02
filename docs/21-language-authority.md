# Language Authority

`RhoeLiquid` consumes `RhoeLanguageSpec` as the authoritative home for the stable `v0.51` language baseline.

## Authority surfaces

- [Normative index](../../RhoeLanguageSpec/00-index.md)
- [Release manifest](../../RhoeLanguageSpec/machine/registries/rhoe-language-spec-release.json)
- [Public reference](../../RhoeLanguageSpec/compiled/rhoe-spec-v0_51-public-reference.md)
- [Release pack summary](../../RhoeLanguageSpec/compiled/rhoe-spec-v0_51-release-pack.md)
- [Authority verifier](../../RhoeLanguageSpec/scripts/verify-cutover.sh)

## Consumer posture

- `RhoeLiquid` does not vendor the language-spec corpus locally.
- Repo-local maintainer verification checks the `RhoeLanguageSpec` release manifest before the Swift foundation release-readiness gate.
- Liquid parsing, rendering, DOCX templating, localhost service, CLI, and WASM
  implementation remain owned here as one contributor-facing engine contract.
- Artifact Workbench template work consumes the Phase 23 contract fixtures
  before adding renderer-specific template behavior.
