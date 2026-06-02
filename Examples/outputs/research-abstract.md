
# Structured Templates as Release Evidence

Lea Hoffmann, Samir Voss, RhoePlatform Contributors

## Abstract

We study how executable examples reduce onboarding friction for template engines. A small gallery of real outputs improves first-run confidence and gives maintainers a living release-readiness check.

## Findings


- **Examples shorten time-to-first-render**: Users can run one command and inspect HTML, Markdown, and LaTeX artifacts immediately.

- **Checked commands improve trust**: Each template embeds the exact CLI command used by maintainers.

- **Diverse outputs clarify scope**: The same engine can produce web pages, reports, board briefs, and scientific summaries.


## Methods


1. Pair every template with a minimal JSON context file.

2. Render examples during release validation into a temporary output directory.

3. Compare freshly rendered outputs with the checked-in canonical gallery outputs.


## Keywords

Liquid, templates, release engineering, documentation, examples

## References


1. RhoePlatform Maintainers. "RhoeLiquid Language Reference." RhoeLiquid Documentation, 2026.

2. Swift Argument Parser Contributors. "Generated CLI Reference Artifacts." Swift Package Plugins, 2026.

