# RhoeLiquid

![License: Apache 2.0](https://img.shields.io/badge/license-Apache%202.0-blue.svg)
![Swift 6.3](https://img.shields.io/badge/Swift-6.3-orange.svg)
![Platforms](https://img.shields.io/badge/platforms-macOS%20%7C%20Linux%20%7C%20WASM-lightgrey.svg)
![Release](https://img.shields.io/badge/release-v0.1.0--rc-green.svg)

Swift-native Liquid rendering for the RhoePlatform foundation line: a high-performance template engine, DOCX templating layer, localhost HTTP service, command-line tool, WebAssembly target, and full contributor-facing documentation under Apache 2.0.

RhoeLiquid is designed for real document and publishing workflows, not just toy templates. It supports standard Liquid syntax, Rhoe authoring extensions, data loading, reusable template components, strict Swift concurrency, release-grade examples, and generated CLI/API documentation.

## 🏷 Repository Metadata

- **Description**: Swift-native Liquid template engine, CLI, DOCX renderer, local service, and WASM target for document automation.
- **License**: Apache 2.0.
- **Primary language**: Swift 6.3 with Swift Package Manager.
- **CLI identity**: Homebrew formula `rhoe-liquid`, installed executable `liquid`.
- **Public docs**: DocC Pages at `https://rhoeplatform.github.io/RhoeLiquid/` after launch.
- **Keywords**: Liquid, template engine, Swift, Swift Package Manager, CLI, document generation, DOCX, WASM, WebAssembly, Markdown, HTML, LaTeX, JSON, YAML, publishing, Apache 2.0.

## ✨ Why RhoeLiquid

- **Production-shaped engine**: async Swift 6.3 implementation with actor-backed registries, compiled template caching, and performance metrics.
- **Document-native surface**: render HTML, Markdown, LaTeX, and DOCX-centered workflows from the same Liquid foundation.
- **Batteries-included CLI**: `liquid` ships with render, analyze, batch, validate, benchmark, init, help, version, shell completions, and a generated man page.
- **Structured data loading**: JSON, XML/HTML, CSV, YAML, TOML, SQLite-shaped rows, GraphQL responses, and Markdown frontmatter.
- **Open foundation strategy**: contributor-facing Apache 2.0 engine repo with premium downstream apps intentionally kept out of this seed.

## ⚡ Quick Start

### Swift Package Manager

For development against the staged `main` branch:

```swift
dependencies: [
    .package(url: "https://github.com/RhoePlatform/RhoeLiquid.git", branch: "main")
]
```

After the first public `v0.1.0` tag is cut, prefer the tagged dependency form:

```swift
dependencies: [
    .package(url: "https://github.com/RhoePlatform/RhoeLiquid.git", from: "0.1.0")
]
```

### Render From Swift

```swift
import RhoeLiquid

let engine = LiquidEngine()
let output = try await engine.render(
    template: "Hello, {{ name | upcase }}!",
    context: ["name": "World"]
)

print(output) // Hello, WORLD!
```

### Render From The CLI

```bash
swift run liquid render Examples/templates/product-launch.html.liquid \
  --context Examples/data/product-launch.json \
  --output /tmp/product-launch.html
```

Useful CLI discovery commands:

```bash
swift run liquid --help
swift run liquid --version
swift run liquid help render
```

### Install From Homebrew

After the first public `v0.1.0` release and tap publication, the bottle-first install path will be:

```bash
brew tap RhoePlatform/rhoe
brew install rhoe-liquid
liquid --version
```

The Homebrew formula is named `rhoe-liquid`; the installed executable remains `liquid`.

### Run The Example Gallery

```bash
bash Examples/render-all.sh
```

The `Examples/` gallery contains complete HTML, Markdown, and LaTeX templates with paired JSON data, one-command render scripts, and checked-in canonical outputs.

## 📦 What's Inside

| Component | Language / Target | Description |
| --- | --- | --- |
| **RhoeLiquid** | Swift 6.3 / Swift 6 language mode | Async Liquid engine with standard syntax plus Rhoe authoring extensions |
| **RhoeDOCX** | Swift 6.3 / Swift 6 language mode | DOCX reading, writing, templating, package handling, and analysis support |
| **liquid CLI** | Swift 6.3 | Public command-line tool with generated manual and shell completions |
| **HTTP Service** | Swift 6.3 / Hummingbird | Localhost rendering, analysis, service contracts, metrics, and DOCX endpoints |
| **RhoeLiquidWasm** | Swift 6.3 / WASI | WebAssembly-facing engine target for downstream client integrations |
| **Release tooling** | Bash / SwiftPM | Public hygiene checks, DocC Pages generation, examples validation, Homebrew formula template validation |

## 🧭 Language Surface

RhoeLiquid supports:

- Liquid variables, expressions, filters, control flow, iteration, includes, and rendering.
- Rhoe extensions for inheritance, macros, slots, fills, input contracts, data loading, diagnostics, and template analysis.
- A self-contained language reference in DocC with status labels for `Liquid standard`, `Shopify-compatible`, `RhoeLiquid extension`, `Deprecated`, `Archived`, `Unsupported`, and `Deferred`.

Start here:

- `Sources/RhoeLiquid/Documentation.docc/LanguageReference/LanguageReference.md`
- `Documentation/LanguageReference/rhoe-liquid-language-surface.json`
- `Sources/RhoeLiquid/Documentation.docc/GettingStarted.md`

## 🧪 Examples

The example gallery is intentionally end-to-end. Each example includes source, data, command, and canonical output.

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

See:

- `Examples/README.md`
- `Examples/COMMANDS.md`
- `Examples/gallery-manifest.json`
- `Examples/outputs/`

## 🏗 Architecture

### Engine Pipeline

```text
Template source
    |
    v
Lexer -> Parser -> Renderer -> Rendered output
```

### Module Dependency Graph

```text
RhoeLiquid
├── LiquidRenderer
│   ├── LiquidParser
│   │   ├── LiquidLexer
│   │   └── LiquidCore -> Yams
│   ├── LiquidExtensions
│   ├── LiquidTags
│   └── LiquidUtilities
└── LiquidFilters

RhoeDOCX -> RhoeLiquid

ServiceCore -> RhoeLiquid + RhoeDOCX
HTTPService -> ServiceCore + Hummingbird
ServiceLauncher -> HTTPService + ArgumentParser
```

### Service Shape

```text
Downstream clients
    |
    | HTTP on localhost:13480
    v
HTTPService
    |
ServiceCore
    |
RhoeLiquid + RhoeDOCX
```

## 🖥 Platforms

| Platform | Minimum / Toolchain | Engine | CLI | Service |
| --- | --- | --- | --- | --- |
| macOS | macOS 14+, Swift 6.3 | Yes | Yes | Yes |
| Linux x86_64 | Swift 6.3.2 + Static Linux SDK | Yes | Yes | Deferred for static target |
| iOS | iOS 17+ | Yes | No | No |
| watchOS | watchOS 10+ | Yes | No | No |
| tvOS | tvOS 17+ | Yes | No | No |
| visionOS | visionOS 1+ | Yes | No | No |
| WebAssembly | Swift 6.3 WASI SDK | Targeted engine surface | No | No |

Linux CLI validation uses:

```bash
bash Scripts/CI/build-linux-cli.sh
```

The Static Linux SDK target currently uses `x86_64-swift-linux-musl`; see `Documentation/Release/LinuxCLIReadiness.md`.

## 🛠 Development

```bash
make build                # Build all Swift targets
make test                 # Run Swift tests
make cli                  # Build the liquid executable
make examples-check       # Validate the public example gallery
make docs-check           # Validate README, DocC, CLI docs, and language reference
make cli-artifacts-check  # Check generated man page and shell completions for drift
make linux-cli            # Build the Linux x86_64 CLI target with the Static Linux SDK
make release-check        # Full release-readiness verification
```

Direct SwiftPM commands:

```bash
swift package dump-package
swift build --product liquid
swift test
```

## 📚 Documentation

- `Documentation/README.md`: supplemental documentation index.
- `Documentation/CLI/README.md`: CLI manual and completion artifact workflow.
- `Documentation/Release/LinuxCLIReadiness.md`: static Linux release target notes.
- `Documentation/Release/YAMLDependencyAssessment.md`: Yams upgrade and vendoring decision record.
- `Sources/RhoeLiquid/Documentation.docc/`: primary DocC catalog.
- `Sources/RhoeDOCX/Documentation.docc/`: DOCX documentation catalog.
- `api/openapi.yaml` and `api/schema.json`: checked-in HTTP service contract assets.

## ✅ Release Readiness

The release checklist is source-first: generated build products should not be checked in, and the initial public seed should be created only after the full preflight passes.

Recommended pre-initialization gate:

```bash
swift package dump-package
swift build --product liquid
swift test
bash Scripts/CI/validate-docs.sh
bash Scripts/CI/validate-language-reference.sh
bash Scripts/CI/validate-cli-artifacts.sh
bash Scripts/CI/validate-examples.sh
bash Scripts/CI/validate-public-release.sh
bash Scripts/CI/validate-homebrew-template.sh
bash Scripts/CI/verify-release-readiness.sh
```

Before creating the initial commit, confirm no generated staging artifacts are present:

```bash
find . -maxdepth 3 \
  -name .git -print -o \
  -name .build -print -o \
  -name .swiftpm -print -o \
  -name Package.resolved -print -o \
  -name .DS_Store -print
```

## 🌱 Current platform surface

- Contributor-facing foundation repo: engine, DOCX, service, CLI, WebAssembly, contract assets, examples, release tooling, and Swift-side documentation.
- Downstream app shell: `RhoePublishStudio` owns the Word add-in line and is intentionally not part of this foundation seed.
- Canonical package identity: `RhoeLiquid`; pre-public package aliases have been retired from the contributor-facing surface.

## 🤝 Contributing

This repo is prepared for public contributor workflows:

- `CONTRIBUTING.md`: contributor setup and expectations.
- `CODE_OF_CONDUCT.md`: community behavior baseline.
- `GOVERNANCE.md`: maintainer and decision process.
- `SECURITY.md`: vulnerability reporting.
- `.github/`: issue templates, PR template, CODEOWNERS, and CI workflows.

## 🧾 Language Authority

`RhoeLiquid` consumes [`RhoeLanguageSpec`](https://github.com/RhoePlatform/RhoeLanguageSpec) as the authoritative home for the stable `v0.51` language baseline.

- Authority note: `docs/21-language-authority.md`
- Maintainer gate: `Scripts/verify-cutover.sh`
- Canonical authority release: `machine/registries/rhoe-language-spec-release.json` in `RhoeLanguageSpec`

For local verification before both public repos are checked out side by side, set `RHOE_LANGUAGE_SPEC_ROOT` to the local `RhoeLanguageSpec` checkout before running the maintainer gate.

The engine, DOCX, service, CLI, and WASM implementation surfaces remain in `RhoeLiquid`, while the language authority source stays explicit through the companion language-spec repository.

## 📄 License

Apache 2.0. See `LICENSE` and `NOTICE`.
