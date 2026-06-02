# RhoeLiquid Example Gallery

This folder is the self-contained public gallery for RhoeLiquid. It keeps the Liquid source, JSON context, Bash command, render-all command, and canonical output together so a new user can inspect an example, run it, and compare the result without hunting through the rest of the repository.

These examples are intentionally not unit tests: each one is a realistic document or web artifact with paired JSON data, a one-example shell script, and a checked-in canonical output.

## Quick Run

Render every example and refresh the canonical outputs in `Examples/outputs/`:

```bash
bash Examples/render-all.sh
```

Render one example through its dedicated script:

```bash
bash Examples/render-product-launch.sh
```

Render the same example manually:

```bash
swift run liquid render Examples/templates/product-launch.html.liquid \
  --context Examples/data/product-launch.json \
  --output Examples/outputs/product-launch.html
```

Open the generated HTML files in a browser or inspect the Markdown and LaTeX outputs directly. The files under `Examples/outputs/` are the canonical expected outputs for the current release surface.

For a copy-paste command catalog, see `COMMANDS.md`. For tooling and future website generation, see `gallery-manifest.json`.

## Source, Data, Command, Output

| Example | Liquid source | JSON data | Bash command | Canonical output | Demonstrates |
| --- | --- | --- | --- | --- | --- |
| Product launch | `templates/product-launch.html.liquid` | `data/product-launch.json` | `bash Examples/render-product-launch.sh` | `outputs/product-launch.html` | loops, conditionals, filters, nested data |
| Invoice | `templates/invoice.html.liquid` | `data/invoice.json` | `bash Examples/render-invoice.sh` | `outputs/invoice.html` | numeric filters, computed line totals, totals table |
| Release notes | `templates/release-notes.html.liquid` | `data/release-notes.json` | `bash Examples/render-release-notes.sh` | `outputs/release-notes.html` | grouped sections, badges, dates, links |
| Component gallery | `templates/component-gallery.html.liquid` | `data/component-gallery.json` | `bash Examples/render-component-gallery.sh` | `outputs/component-gallery.html` | RhoeLiquid macros and reusable cards |
| Config audit | `templates/config-audit.html.liquid` | `data/config-audit.json` | `bash Examples/render-config-audit.sh` | `outputs/config-audit.html` | risk states, nested loops, service audit data |
| Board brief | `templates/board-brief.md.liquid` | `data/board-brief.json` | `bash Examples/render-board-brief.sh` | `outputs/board-brief.md` | Markdown generation, list rendering, KPIs |
| Research abstract | `templates/research-abstract.md.liquid` | `data/research-abstract.json` | `bash Examples/render-research-abstract.sh` | `outputs/research-abstract.md` | citations, structured findings, keyword lists |
| Lab report | `templates/lab-report.tex.liquid` | `data/lab-report.json` | `bash Examples/render-lab-report.sh` | `outputs/lab-report.tex` | non-HTML document generation and tabular output |

## Folder Contract

- `README.md` explains the gallery and points to every source/data/command/output pair.
- `COMMANDS.md` lists the render-all command, every one-example Bash command, and the equivalent raw CLI invocation.
- `gallery-manifest.json` provides a machine-readable source/data/script/output index.
- `templates/` contains the Liquid source templates.
- `data/` contains the JSON contexts used by the CLI.
- `render-*.sh` compiles one example into `outputs/`.
- `render-all.sh` compiles the full gallery into `outputs/`.
- `outputs/` contains the checked-in canonical output files.

## Maintainer Check

The examples are part of the public release surface. Run this before release:

```bash
bash Scripts/CI/validate-examples.sh
```
