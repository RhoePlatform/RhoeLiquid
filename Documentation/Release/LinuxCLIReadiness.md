# Linux CLI Readiness

`RhoeLiquid` treats the `liquid` command-line executable as the first official Linux x86_64 release target. The target is intentionally narrower than the full package surface: it covers the Liquid engine, CLI commands, data loaders that are available on the active Swift SDK, and package dependencies required by the CLI product graph.

## Target

| Field | Value |
| --- | --- |
| Product | `liquid` |
| SDK identifier | `x86_64-swift-linux-musl` |
| Default build | `swift build -c release --product liquid --swift-sdk x86_64-swift-linux-musl` |
| Gate script | `bash Scripts/CI/build-linux-cli.sh` |

The target follows Swift's Static Linux SDK model: install a matching swift.org toolchain and Static Linux SDK, then build the CLI as a statically linked Linux executable.

## Current Scope

- Supported: parser, renderer, built-in tags and filters, CLI render/batch/analyze/benchmark/help flows, and JSON/CSV/XML/YAML/TOML/GraphQL data loading when the corresponding Foundation modules are available.
- Conditional: SQLite loading is compiled and registered only when the `SQLite3` module is available in the active SDK.
- Excluded from this target: `RhoeLiquidService`, DOCX rendering, and macOS-specific memory-pressure integration.

## Portability Hardening

The CLI graph is kept Linux-safe through three explicit guards:

- Foundation networking is imported with `canImport(FoundationNetworking)` in URL-backed data loaders.
- Apple-only low-power and thermal-state APIs are used only on Apple platforms; Linux falls back to a nominal runtime profile.
- Dispatch memory-pressure notifications are Apple-platform only; Linux uses normal cache limits without proactive OS pressure callbacks.
- Yams 6.2.2+ is required for Static Linux SDK compatibility; older Yams 5.x releases fail Swift 6.3 static Linux compilation.

## Local Verification

Run the gate from the repository root:

```bash
bash Scripts/CI/build-linux-cli.sh
```

Override the SDK or product if needed:

```bash
RHOE_LINUX_SDK_ID=x86_64-swift-linux-musl bash Scripts/CI/build-linux-cli.sh
```

Override the SDK identifier separately when validating another Static Linux architecture:

```bash
RHOE_LINUX_SDK_ID=aarch64-swift-linux-musl bash Scripts/CI/build-linux-cli.sh
```

If the SDK is not installed, the script exits before building and prints the official Swift SDK installation command shape. Once the SDK is installed, this gate is the acceptance check for publishing the Linux x86_64 CLI artifact.
