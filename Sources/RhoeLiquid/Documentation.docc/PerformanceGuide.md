# Performance Guide

RhoeLiquid has already been through several hot-path optimization waves. This guide describes the current performance model and the most reliable ways to measure it.

## What The Engine Optimizes Today

The current implementation focuses on:

- UTF-8-first lexing and reduced tokenization allocation churn
- pre-sized parser buffers and cheaper tag dispatch
- fast expression evaluation and specialized variable access
- AST caching and compiled-template promotion for hot templates
- pooled renderer reuse
- runtime-tuned cache and pool defaults based on the current machine

## Use One Engine Instance

The single highest-leverage integration choice is to reuse a `LiquidEngine` instead of creating a new one for every render:

```swift
let engine = LiquidEngine()

let a = try await engine.render(template: template, context: contextA)
let b = try await engine.render(template: template, context: contextB)
```

That allows the engine to reuse its caches and renderer pool.

## Prefer Focused Benchmark Runs

For trustworthy measurements, use the active benchmark suites directly:

```bash
swift test --filter BenchmarkTests
swift test --filter ParserPerformanceTests
swift test --filter largeTemplateTokenizationBenchmark
```

`BenchmarkTests` now includes dedicated slices for string output, filtered output, conditional sections, loop-heavy sections, loop sections with static text only, loop sections with simple output only, loop sections with filtered output only, and a steady compiled warm-cache run. Those focused runs are much more reliable than reading micro-deltas out of a full mixed-suite run.

The benchmark suites are serialized internally so they do not compete with themselves, but the most trustworthy numbers still come from running a focused benchmark target on its own instead of reading benchmark output from a full `swift test` pass.

## Cached Versus Uncached Renders

There are two important performance modes:

- uncached: lexer + parser + renderer all run
- warm cached: the engine reuses parsed or compiled template state and mainly pays render cost

If your application reuses templates, warm-render performance is the number to watch most closely.

## Context Shape Matters

The renderer is optimized for normal dictionary-and-array style Liquid contexts. Performance is best when:

- dictionaries are reasonably shallow
- repeated dotted access paths are reused across renders
- values use normal Swift primitives such as `String`, `Int`, `Double`, `[Any]`, and `[String: Any]`

Extremely deep or reflection-heavy object graphs will still work, but they are not the fastest path.

## Built-In Metrics

`renderWithMetrics` is useful for timing and cache visibility:

```swift
let (output, metrics) = try await engine.renderWithMetrics(
    template: template,
    context: context
)

print(metrics.lexingTime)
print(metrics.parsingTime)
print(metrics.renderingTime)
print(metrics.cacheHit)
print(metrics.nodeCount)
print(metrics.memoryStats.totalBytes)
```

The memory section reports observed `InlineString`-backed storage across the template source, tokens generated for the current render, and the AST used for execution. That makes it a useful development-time signal for template shape and allocation pressure, even though it is not intended to replace whole-process memory profiling.

## Benchmark Output

The focused benchmark suites now report:

- median
- mean
- `p95`
- standard deviation
- min/max range

The two most useful render comparisons are now:

- `warm cache`: one priming render, then measure repeated renders
- `steady compiled warm cache`: two priming renders, then measure the already-promoted compiled-template path

If those two numbers stay close, compiled-template promotion is not the main bottleneck anymore and the next optimization wave should focus on the renderer hot path itself.

For loop-heavy templates, the most useful comparison is now:

- `loop section static text`: loop mechanics plus static per-item body text
- `loop section simple output`: loop mechanics plus plain per-item variable output
- `loop section filtered output`: loop mechanics plus filtered per-item output
- `loop section`: loop mechanics plus the current mixed body with both variable output and per-item filters

Those four slices make it much easier to tell whether a candidate change helps pure loop scaffolding, plain variable output inside loops, filtered per-item output inside loops, or the mixed real-world loop body.

Compiled renders now also stamp pure static `for` / `tablerow` bodies ahead of time, so the `loop section static text` slice is a direct read on how cheaply the engine can repeat a compiler-proved static iteration body.

Those summaries are the best way to compare optimization waves or check whether a change regressed warm versus uncached renders.

## Memory Pressure

If the engine is embedded in a long-lived app or service, keep caching enabled unless you have a strong reason not to. The runtime already trims caches under system pressure.

## When To Reach For More Optimization

Only optimize after a benchmark or production trace shows a real bottleneck. The most natural next lanes are:

- parser and expression-evaluation refinement
- compiled-template specialization
- extension-system completion so performance work is not fighting unstable semantics
