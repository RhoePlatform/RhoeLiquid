# Contributing to RhoeLiquid

Thank you for your interest in contributing to RhoeLiquid!

## Prerequisites

- **Swift 6.2+** (Xcode 16+ or latest Swift toolchain)
- Optional: `swiftlint`, `swiftformat` (`brew install swiftlint swiftformat`)

## Development Workflow

```bash
# Build everything
make build

# Run all Swift tests
make test

# Build + test
make bt

# Lint and format
make lint
make format

# Full local CI (build, test, docs, benchmark)
make ci
```

The Word add-in shell now lives in `RhoePublishStudio` and is intentionally outside this foundation repo.

## Maintainer Gate

Run the contributor-facing maintainer gate before opening or updating a change:

```bash
bash ./Scripts/verify-cutover.sh
```

## Branch Naming

Use the pattern: `codex/your-change-description`

## Code Style

- **SwiftFormat** and **SwiftLint** configs are at the repo root
- 4-space indentation, 120 character line width
- All Swift files require the standard file header (see `.swiftformat`)
- No `force_cast`, `force_try`, or `force_unwrapping`

## Testing

This project uses **Swift Testing** (not XCTest) for engine and service tests:

```swift
@Suite("My Tests")
struct MyTests {
    @Test("Description")
    func myTest() async throws {
        let engine = LiquidEngine()
        let result = try await engine.render(template: "{{ x }}", context: ["x": "hi"])
        #expect(result == "hi")
    }
}
```

## What We're Looking For

- Bug fixes with targeted tests
- Documentation improvements
- Performance optimizations with benchmark evidence
- API polish and ergonomic improvements
