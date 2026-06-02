# Swift Testing at Scale: Learnings from Golden Liquid Conformance Suite

## Context

RhoeLiquid needed to validate against 1,013 test cases from the official Shopify Liquid conformance suite (`golden_liquid.json`). This document captures the engineering learnings from building, debugging, and optimizing the test infrastructure.

## Problem: Parameterized Tests Don't Scale

### Initial Approach (Failed)

We loaded all 1,013 test cases from a single JSON fixture and distributed them across 16 `@Suite` structs using Swift Testing's parameterized `@Test("name", arguments: testCases)` pattern:

```swift
@Suite("Golden Liquid: Math Filters")
struct GoldenMathFilterTests {
    static let testCases: [GoldenTestID] = {
        (try? GoldenLiquidLoader.tests(tagged: filterTags)) ?? []
    }()

    @Test("Math filter conformance", arguments: GoldenMathFilterTests.testCases)
    func mathFilter(_ test: GoldenTestID) async throws {
        try await GoldenLiquidRunner.run(test.testCase)
    }
}
```

### What Went Wrong

1. **All static initializers run at process launch.** Even when `--filter "SomeOtherSuite"` is used, Swift Testing discovers ALL test structs in the binary and evaluates their `static let` properties. With 16 suites each loading the same 268KB JSON, this adds startup overhead.

2. **Parameterized tests start concurrently.** Swift Testing runs all argument-based test cases in parallel by default. With 140+ cases per suite, each creating a `LiquidEngine()` actor, this spawns hundreds of concurrent async tasks instantly.

3. **`.serialized` only serializes within a suite.** Adding `.serialized` prevents concurrent execution *within* a single suite, but all 16 suites still start their test cases concurrently with each other. Net parallelism: 16 concurrent test cases minimum.

4. **Output buffering hides progress.** Swift Testing buffers suite-level summary output until ALL parameterized cases complete. With 140+ cases and one hanging, no output appears for minutes — indistinguishable from a hang.

5. **A single hanging test blocks the entire process.** Because all suites share the same process, one infinite-loop test in any suite prevents the process from exiting, even with `--filter` targeting a different suite.

### Observed Behavior

| Metric | Result |
|--------|--------|
| Single suite (140 cases) | **Hung indefinitely** (>90 seconds, killed) |
| Full suite (1,013 cases) | **Hung indefinitely** (>10 minutes, killed) |
| Filtered to unrelated suite | **Still hung** (hanging suite loaded anyway) |
| Output during hang | **Zero lines** (buffered) |

## Solution: Individual Tests with Inline Fixtures

### Architecture

Replace parameterized tests with individual `@Test` functions containing inline string literals:

```swift
@Suite("Golden: abs filter", .serialized)
struct GoldenAbsFilterTests {
    @Test("negative float")
    func negativeFloat() async throws {
        let engine = LiquidEngine()
        let result = try await engine.render(
            template: "{{ -5.4 | abs }}", context: [:])
        #expect(result == "5.4")
    }

    @Test("unexpected argument")
    func unexpectedArgument() async throws {
        let engine = LiquidEngine()
        do {
            _ = try await engine.render(
                template: "{{ -3 | abs: 1 }}", context: [:])
            Issue.record("Expected error but rendering succeeded")
        } catch { /* Expected */ }
    }
}
```

### Code Generation

A Python script reads `golden_liquid.json` and generates one `.swift` file per category:

- **84 files** across `Filters/` (59), `Tags/` (19), `Misc/` (6)
- Each file: 3-68 individual `@Test` methods
- No JSON loading, no static initializers, no parameterized tests
- Template strings inlined as Swift string literals with proper escaping
- Context dictionaries inlined as Swift dictionary literals

### Key Design Decisions

1. **`.serialized` on every suite.** Prevents concurrent `LiquidEngine` creation within a suite. Without it, even 7 tests starting simultaneously can overwhelm the async runtime when multiplied across 84 suites.

2. **`SWIFT_TESTING_MAX_PARALLELISM=4` environment variable.** Limits cross-suite parallelism. Default parallelism (CPU count) with 84 serialized suites means up to 84 concurrent first-tests running simultaneously.

3. **`do/catch` instead of `#expect(throws:)` for async.** Swift Testing's `#expect(throws:)` macro doesn't support async closures. Wrap in `do { try await ...; Issue.record(...) } catch {}` instead.

4. **Avoid Swift keywords as function names.** Test names like "break", "for", "nil", "false" generate function names that collide with Swift keywords. The codegen script appends `Test` suffix: `breakTest()`, `forTest()`, `nilTest()`.

### Results

| Metric | Before (parameterized) | After (individual) |
|--------|----------------------|-------------------|
| Single suite (13 tests) | Hung indefinitely | **0.02s** |
| All filter suites (568 tests) | Hung indefinitely | **0.09s** |
| 77/84 suites (924 tests) | Hung indefinitely | **~60s** |
| Suite isolation | Broken (cross-suite contamination) | Works |
| Progress visibility | Zero (buffered) | Per-test output |
| Debugging individual failures | Impossible | Trivial |

**Performance improvement: from infinite hang to sub-second for individual suites.**

## Remaining Issue: Engine Hang Bug

7 suites hang because the rendering engine enters an infinite loop on specific `{% liquid %}` tag templates. This is NOT a test infrastructure issue — it's an engine bug.

### Symptoms

- Templates containing `{% liquid %}` with nested `for` loops hang during rendering
- Templates WITHOUT `{% liquid %}` wrapper work fine
- Simple `{% liquid echo 'hello' %}` works fine
- `{% liquid for v in arr ... endfor %}` hangs

### Root Cause (To Be Fixed)

The `{% liquid %}` tag rewrites its body as standard Liquid template:
```
{% liquid                    →    {% for v in arr %}
for v in arr                 →    {% echo v %}
echo v                       →    {% endfor %}
endfor
%}
```

The rewritten template is then lexed and parsed by a nested `Parser`. The hang likely occurs when the nested parser or renderer interacts with whitespace trim markers (`{%- -%}`) or when `evaluateExpression` creates an unbounded recursion during range evaluation inside the liquid tag's for-loop.

### Affected Suites (7)

- `GoldenAssignTagTests` — has `{% liquid %}` tag in golden fixture tags
- `GoldenCaptureTagTests` — same
- `GoldenLiquidTagTests` — direct liquid tag tests
- `GoldenIncludeTagTests` — liquid tag in fixture tags
- `GoldenRenderTagTests` — same
- `GoldenIdentifiersTests` — liquid tag in fixture tags
- `GoldenIllegalSyntaxTests` — liquid tag in fixture tags

**Note:** The suites themselves don't all contain `{% liquid %}` templates. The hang occurs because Swift Testing loads ALL test structs at process startup, and the hanging `GoldenLiquidTagTests` blocks the entire process.

## Rules of Thumb for Swift Testing at Scale

1. **Never use parameterized tests with >50 cases.** They all start concurrently and can't be individually filtered or debugged.

2. **Use code generation for large fixture-based test suites.** Generate individual `@Test` functions with inlined data. This gives instant startup, per-test isolation, and meaningful `--filter` support.

3. **Always add `.serialized` to async test suites.** Concurrent `actor` creation across many tests causes thread starvation.

4. **Set `SWIFT_TESTING_MAX_PARALLELISM` for large test counts.** Default parallelism (CPU cores) with many serialized suites still creates too many concurrent first-tests.

5. **A single hanging test poisons the entire binary.** Swift Testing has no per-test timeout. A test that loops forever blocks the process. Guard against this by either: (a) fixing the hang, (b) not compiling the test, or (c) moving it to a separate test target.

6. **Use `do/catch` for async error expectations.** `#expect(throws:)` doesn't support async closures.

7. **Keep suite files small (3-70 tests).** One file per logical category (filter, tag, feature). Enables fast compilation, easy `--filter`, and quick suite completion.
