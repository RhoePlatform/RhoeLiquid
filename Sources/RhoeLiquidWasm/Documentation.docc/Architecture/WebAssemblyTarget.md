# WebAssembly Target

Compile the RhoeLiquid template engine to WebAssembly for browser, edge, and platform-independent use.

## Overview

The `RhoeLiquidWasm` library provides a Wasm-compatible subset of the RhoeLiquid engine, enabling Liquid template rendering in any WebAssembly runtime. This includes browsers, Cloudflare Workers, Deno, Node.js (via WASI), and standalone runtimes like WasmKit and Wasmtime.

The Wasm target delivers the full Liquid template processing pipeline (1,013/1,013 Shopify golden test conformance) with 43+ built-in filters, all control flow tags, template composition, and template analysis.

## Building for WebAssembly

### Prerequisites

Install Swift 6.3+ and the Wasm SDK:

```bash
swiftly install 6.3
swiftly use 6.3
swift sdk install swift-6.3-RELEASE_wasm
```

### Compilation

```bash
swift build --swift-sdk swift-6.3-RELEASE_wasm --target RhoeLiquidWasm
```

The compiled module is located at `.build/wasm32-unknown-wasip1/debug/`.

### Release Build

```bash
swift build -c release --swift-sdk swift-6.3-RELEASE_wasm --target RhoeLiquidWasm
```

### Makefile

```bash
make wasm          # Debug build
make wasm-release  # Release build
```

## API Reference

The ``RhoeLiquidWasm`` facade provides a streamlined API:

### Render

```swift
let output = try await RhoeLiquidWasm.render(
    template: "Hello {{ name }}!",
    context: ["name": "World"]
)
// output == "Hello World!"
```

### Render with Metrics

```swift
let result = try await RhoeLiquidWasm.renderWithMetrics(
    template: template,
    context: context
)
print("Output: \(result.output)")
print("Render time: \(result.renderTimeMs)ms")
print("Variables: \(result.variableCount)")
```

### Validate

```swift
let errors = RhoeLiquidWasm.validate(template: "{% if unclosed")
// errors == ["Unexpected end of template..."]

let noErrors = RhoeLiquidWasm.validate(template: "{{ name }}")
// noErrors == []
```

### Extract Variables

```swift
let vars = RhoeLiquidWasm.extractVariables(
    template: "{{ user.name }} works at {{ company.name }}"
)
// vars == ["company.name", "user.name"]
```

### Feature Discovery

```swift
let caps = RhoeLiquidWasm.capabilities
print(caps.supportsRender)     // true
print(caps.supportsDocx)       // false
print(caps.builtInFilterCount) // 43
```

## Feature Matrix

| Capability | Wasm | Native |
|-----------|------|--------|
| Liquid template rendering | Yes | Yes |
| 43+ built-in filters | Yes | Yes |
| All control flow tags (if/for/case/unless) | Yes | Yes |
| Template composition (include/render/extends) | Yes | Yes |
| Template validation (syntax checking) | Yes | Yes |
| Variable extraction | Yes | Yes |
| Template caching | Yes | Yes |
| Compiled template optimization | Yes | Yes |
| InlineString memory optimization | Yes | Yes |
| DOCX rendering pipeline | No | Yes |
| HTTP service (localhost:13480) | No | Yes |
| CLI commands | No | Yes |
| Network data source loading | No | Yes |
| SQLite data source | No | Yes |
| YAML data source (Yams) | No | Yes |
| Memory pressure monitoring | No | Yes |
| System performance profiling | No | Yes |

## Architecture

### Module Dependencies

```
RhoeLiquidWasm
  |-- RhoeLiquid           (LiquidEngine actor, public API)
  |   |-- LiquidCore       (AST, tokens, errors, data sources, InlineString)
  |   |-- LiquidLexer      (single-pass O(n) tokenization)
  |   |-- LiquidParser     (recursive descent, typed throws)
  |   |-- LiquidRenderer   (async rendering, scope stack, compiled templates)
  |   |-- LiquidFilters    (43+ built-in filters)
  |   |-- LiquidTags       (custom tag protocol and registry)
  |   |-- LiquidExtensions (template inheritance, file loading)
  |   |-- LiquidUtilities  (HTML escaping, string helpers)
```

The Wasm target depends on the full engine via the `RhoeLiquid` umbrella module. Platform-specific features are disabled at compile time through conditional compilation guards.

### Platform Compilation Guards

Platform-specific code is guarded using standard Swift conditional compilation:

```swift
// Memory pressure monitoring (requires GCD)
#if !os(WASI)
import Dispatch
final class MemoryPressureObserver { ... }
#endif

// System resource profiling (requires ProcessInfo)
#if os(WASI)
return RuntimePerformanceProfile(activeProcessorCount: 1, physicalMemory: 512 * 1024 * 1024, ...)
#else
let processInfo = ProcessInfo.processInfo
return RuntimePerformanceProfile(activeProcessorCount: processInfo.activeProcessorCount, ...)
#endif

// Network data loading (requires URLSession)
} else {
    #if os(WASI)
    throw DataSourceError.unsupportedFormat("Network loading not available in WebAssembly")
    #else
    let (data, _) = try await URLSession.shared.data(for: request)
    #endif
}

// CoreFoundation type inspection
#if !os(WASI)
if CFGetTypeID(number) == CFBooleanGetTypeID() { ... }
#else
if number.objCType.pointee == UInt8(ascii: "c") { ... }
#endif
```

### Why Not Full Feature Parity?

Three categories of features cannot compile to Wasm:

1. **System frameworks** -- `DispatchSource` (memory pressure), `ProcessInfo.thermalState`, `Thread.callStackSymbols` require OS-level APIs unavailable in WASI.

2. **Network I/O** -- `URLSession` requires platform networking. Data sources that load from HTTP URLs are disabled; file-based loading works via WASI filesystem.

3. **Native libraries** -- SQLite3 (C library) and Yams/CYaml (C library) don't cross-compile to WASM. The YAML and SQLite data sources are guarded out.

## Adding New Features

When adding new features to the engine, follow these guidelines for Wasm compatibility:

1. **Default to Wasm-safe code.** Use Foundation types that work everywhere (`String`, `Data`, `Date`, `UUID`, `JSONSerialization`).

2. **Guard platform APIs.** If you must use `DispatchQueue`, `URLSession`, `ProcessInfo`, `Bundle.module`, or `Thread`, wrap in `#if !os(WASI)`.

3. **Provide fallbacks.** For guarded code, provide a Wasm-safe alternative in the `#else` branch (no-op, conservative default, or feature-disabled stub).

4. **Avoid `CFAbsoluteTimeGetCurrent()`.** Use `Date().timeIntervalSinceReferenceDate` instead (Foundation-based, works on all platforms).

5. **Test both targets.** After changes, verify with:
   ```bash
   swift build                                                          # Native
   swift build --swift-sdk swift-6.3-RELEASE_wasm --target RhoeLiquidWasm  # Wasm
   swift test                                                           # Native tests
   ```
