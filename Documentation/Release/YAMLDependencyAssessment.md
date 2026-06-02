# YAML Dependency Assessment

`RhoeLiquid` uses Yams for YAML parsing and serialization in the Swift-native engine and CLI release surface.

## Decision

Keep Yams as the YAML implementation for `v0.1.0`, upgraded to `6.2.2` or newer.

The earlier `5.x` dependency line failed Swift 6.3 Static Linux SDK compilation in `Yams/Representer.swift` with an ambiguous `DBL_DECIMAL_DIG` reference. A dedicated probe against Yams `6.2.2` passed for the release target when built with the target SDK identifier:

```bash
swiftly run swift build \
  -c release \
  --product YamsProbe \
  --swift-sdk x86_64-swift-linux-musl \
  +6.3.2
```

That probe imported Yams, loaded a small YAML mapping, and linked successfully as a Static Linux SDK executable.

## Current Release Shape

- YAML loading remains part of the Linux CLI release target.
- `yaml_merge` and `to_yaml` remain part of the built-in filter surface outside WebAssembly.
- WebAssembly continues to exclude Yams-backed YAML because the WASI target does not include that dependency surface.
- The Linux CLI gate uses `--swift-sdk x86_64-swift-linux-musl`, not the artifact-bundle identifier plus `--triple`, because the latter can select the wrong SDK root on Apple Silicon hosts.

## Vendoring Criteria

A future `RhoeYAMLKit` vendoring or rewrite lane is still reasonable if one of these becomes true:

- Yams regresses on Static Linux SDK compatibility.
- The public repo needs a smaller dependency footprint than LibYAML-backed Yams.
- RhoeLiquid needs a formally specified YAML subset with deterministic dump output for reproducible release artifacts.
- We need first-party WASI YAML support.

If that lane opens, scope it as a `Rhoe YAML Profile` first: mappings, sequences, scalars, quoted strings, booleans, nulls, numbers, block scalars, multi-document streams, and deterministic serialization. Defer YAML tags, custom schemas, and advanced anchor/alias behavior unless product requirements demand them.
