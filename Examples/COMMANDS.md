# RhoeLiquid Gallery Commands

Run these commands from the repository root. Each command renders into `Examples/outputs/`, which contains the checked-in canonical output for the current release surface.

## Compile Everything

```bash
bash Examples/render-all.sh
```

## Per-Example Scripts

```bash
bash Examples/render-product-launch.sh
bash Examples/render-invoice.sh
bash Examples/render-release-notes.sh
bash Examples/render-component-gallery.sh
bash Examples/render-config-audit.sh
bash Examples/render-board-brief.sh
bash Examples/render-research-abstract.sh
bash Examples/render-lab-report.sh
```

## Raw CLI Commands

```bash
swift run liquid render Examples/templates/product-launch.html.liquid --context Examples/data/product-launch.json --output Examples/outputs/product-launch.html
swift run liquid render Examples/templates/invoice.html.liquid --context Examples/data/invoice.json --output Examples/outputs/invoice.html
swift run liquid render Examples/templates/release-notes.html.liquid --context Examples/data/release-notes.json --output Examples/outputs/release-notes.html
swift run liquid render Examples/templates/component-gallery.html.liquid --context Examples/data/component-gallery.json --output Examples/outputs/component-gallery.html
swift run liquid render Examples/templates/config-audit.html.liquid --context Examples/data/config-audit.json --output Examples/outputs/config-audit.html
swift run liquid render Examples/templates/board-brief.md.liquid --context Examples/data/board-brief.json --output Examples/outputs/board-brief.md
swift run liquid render Examples/templates/research-abstract.md.liquid --context Examples/data/research-abstract.json --output Examples/outputs/research-abstract.md
swift run liquid render Examples/templates/lab-report.tex.liquid --context Examples/data/lab-report.json --output Examples/outputs/lab-report.tex
```

To render into a temporary directory without changing the checked-in canonical outputs:

```bash
LIQUID_EXAMPLE_OUTPUT_DIR=/tmp/rhoeliquid-gallery bash Examples/render-all.sh
```
