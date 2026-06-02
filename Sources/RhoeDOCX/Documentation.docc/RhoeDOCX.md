# ``RhoeDOCX``

The active DOCX foundation inside the RhoeLiquid foundation repo.

@Metadata {
    @DisplayName("RhoeDOCX")
}

## Overview

`RhoeDOCX` currently provides the normalized, release-facing DOCX surface used by the `RhoeLiquid` foundation line and its downstream publishing and service consumers. It focuses on the pieces that are actively wired into the package today:

- ZIP archive reading and writing
- DOCX package inspection
- foundational WordprocessingML document models
- lightweight Liquid rendering inside text nodes

Older sprint-era experiments and broader DOCX subsystems live in `Archive/RhoeDOCXLegacy/` and are intentionally outside the active package graph.

## Topics

### Entry Points

- ``RhoeDOCX``
- ``DOCXPackage``
- ``DOCXTemplateEngine``

### ZIP Layer

- ``ZIPArchive``
- ``ZIPPackage``
- ``ZIPBuilder``
- ``ZIPEntry``

### WordprocessingML

- ``WordprocessingMLDOM``
- ``WMLDocument``
- ``WMLBody``
- ``WMLParagraph``
- ``WMLRun``
- ``WMLText``

## See Also

The downstream publishing and service layers consume these APIs through the public foundation package. `RhoeLiquid` provides the Liquid engine used during DOCX text rendering.
