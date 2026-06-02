# RhoeLiquid — Unified Makefile
# Swift engine + DOCX + HTTP service foundation

.PHONY: build test lint format ci clean cli cli-artifacts cli-artifacts-check examples examples-check install linux-cli \
        build-release benchmark golden docs docs-check \
        ci-all release-check release-check-all stats \
        public-hygiene homebrew-check docc-pages wasm wasm-release

# ── Swift ────────────────────────────────────────────────────

b build:
	swift build

t test:
	swift test

bt: build test

build-release:
	swift build -c release

cli:
	swift build --product liquid

cli-artifacts:
	bash Scripts/CI/generate-cli-artifacts.sh

cli-artifacts-check:
	bash Scripts/CI/validate-cli-artifacts.sh

examples:
	bash Examples/render-all.sh

examples-check:
	bash Scripts/CI/validate-examples.sh

linux-cli:
	bash Scripts/CI/build-linux-cli.sh

install: build-release
	install .build/release/liquid /usr/local/bin/liquid

benchmark:
	swift test --filter BenchmarkTests

golden: ## Run golden conformance tests (sequential, with per-test timeout)
	SWIFT_TESTING_MAX_PARALLELISM=1 swift test --filter GoldenLiquidTests

lint:
	swiftlint lint --strict

format:
	swiftformat .

docs:
	swift package generate-documentation

docs-check:
	bash Scripts/CI/validate-docs.sh

docc-pages:
	bash Scripts/CI/build-docc-pages.sh

public-hygiene:
	bash Scripts/CI/validate-public-release.sh

homebrew-check:
	bash Scripts/CI/validate-homebrew-template.sh

ci: build test docs-check cli-artifacts-check examples-check benchmark

release-check:
	bash Scripts/CI/verify-release-readiness.sh

clean:
	swift package clean
	rm -rf .build

stats:
	@echo "Swift source files:"; find Sources -name "*.swift" | wc -l
	@echo "Swift test files:"; find Tests -name "*.swift" | wc -l

# ── Unified ─────────────────────────────────────────────────

wasm: ## Build the WebAssembly target
	swift build --swift-sdk swift-6.3-RELEASE_wasm --target RhoeLiquidWasm

wasm-release: ## Build the WebAssembly target in release mode
	swift build -c release --swift-sdk swift-6.3-RELEASE_wasm --target RhoeLiquidWasm

ci-all: ci ## Full CI for the Swift-side foundation line

release-check-all: release-check ## Release readiness for the Swift-side foundation line
