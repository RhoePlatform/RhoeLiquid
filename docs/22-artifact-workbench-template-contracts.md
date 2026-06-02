# Artifact Workbench Template Contracts

## Status
- Phase 23 contract-authority consumer surface.
- This repo owns semantic template vocabulary for Liquid-style template
  resolution only.
- It does not implement product UI, import/export, PowerPoint merge-back, data
  pipelines, or runtime execution.

## Upstream Authority
Template work must consume:

- `RhoeLanguageSpec/part-0-foundation/10-artifact-workbench-contract-authority.md`
- `RhoeLanguageSpec/fixtures/rhoejson/valid/artifact-workbench-board-readiness.json`
- `RhoeLanguageBlockKit/fixtures/rhoemarkdown-v1/artifact-workbench-edit-contract.json`

## Template Vocabulary
Artifact Workbench templates are semantic artifact types. A v1 template must
declare:

- `templateId`
- `artifactGenre`
- `narrativeFunction`
- `requiredSlots`
- `optionalSlots`
- `slotCardinality`
- `lockedProperties`
- `editableProperties`
- `styleProfileRef`
- `reviewGatePolicy`

The template renderer may materialize these values in HTML, DOCX, presentation,
or other target surfaces, but it must not treat visual placement as semantic
authority.

## Required V1 Families
The first contract vocabulary covers:

- `artifact-workbench.board-readiness-update`
- `artifact-workbench.decision-summary`
- `artifact-workbench.evidence-risk-pair`
- `artifact-workbench.recommendation-with-review-gate`
- `artifact-workbench.appendix-support`

## Fixture
The machine-readable template vocabulary fixture is:

- [`../Tests/Fixtures/ArtifactWorkbench/template-constraint-vocabulary.json`](../Tests/Fixtures/ArtifactWorkbench/template-constraint-vocabulary.json)

Downstream lanes should use the fixture to align Liquid template resolution with
Rhoe Language semantic slots and RhoeStyle style guardrails.

## Deferred Work
This lane does not add new Liquid tags, filters, service endpoints, or DOCX
rendering behavior. Those require follow-on implementation packets.
