# RhoeLiquid CLI Artifacts

This directory contains checked-in release artifacts for the public `liquid` command.

## Contents

- `man/liquid.1`: single-page manual generated from Swift ArgumentParser metadata.
- `completions/liquid.bash`: bash completion script.
- `completions/_liquid`: zsh completion script.
- `completions/liquid.fish`: fish completion script.

## Maintainer Workflow

Regenerate artifacts after changing command metadata, options, subcommands, validation, or help text:

```bash
bash Scripts/CI/generate-cli-artifacts.sh
```

Validate checked-in artifacts against freshly generated output:

```bash
bash Scripts/CI/validate-cli-artifacts.sh
```

The release-readiness gate runs the validator so stale manual pages or completion scripts cannot ship unnoticed.
