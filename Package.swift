// swift-tools-version: 6.3
// RhoeLiquid — High-performance Liquid template engine for Swift

import PackageDescription

let strictConcurrency: [SwiftSetting] = [
    .define("SWIFT_PACKAGE"),
    .enableUpcomingFeature("StrictConcurrency"),
]

let package = Package(
    name: "RhoeLiquid",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .watchOS(.v10),
        .tvOS(.v17),
        .visionOS(.v1),
    ],
    products: [
        // ── Engine ──────────────────────────────────────────────
        .library(name: "RhoeLiquid", targets: ["RhoeLiquid"]),
        .library(name: "LiquidCore", targets: ["LiquidCore"]),
        .library(name: "LiquidUtilities", targets: ["LiquidUtilities"]),

        // ── DOCX ────────────────────────────────────────────────
        .library(name: "RhoeDOCX", targets: ["RhoeDOCX"]),

        // ── Service (macOS) ─────────────────────────────────────
        .library(name: "ServiceCore", targets: ["ServiceCore"]),
        .library(name: "HTTPService", targets: ["HTTPService"]),
        .executable(name: "RhoeLiquidService", targets: ["ServiceLauncher"]),
        .executable(name: "ServiceContractGenerator", targets: ["ServiceContractGenerator"]),

        // ── CLI ────────────────────────────────────────────────
        .executable(name: "liquid", targets: ["LiquidCLI"]),

        // ── WebAssembly ───────────────────────────────────────
        .library(name: "RhoeLiquidWasm", targets: ["RhoeLiquidWasm"]),
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "6.2.2"),
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.1.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.1.0"),
    ],
    targets: [
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: - Engine
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        .target(
            name: "LiquidCore",
            dependencies: [
                .product(name: "Yams", package: "Yams", condition: .when(platforms: [.macOS, .iOS, .tvOS, .watchOS, .visionOS, .linux, .android, .windows])),
            ],
            swiftSettings: strictConcurrency
        ),
        .target(
            name: "LiquidLexer",
            dependencies: ["LiquidCore"],
            swiftSettings: strictConcurrency
        ),
        .target(
            name: "LiquidParser",
            dependencies: ["LiquidCore", "LiquidLexer"],
            swiftSettings: strictConcurrency
        ),
        .target(
            name: "LiquidRenderer",
            dependencies: [
                "LiquidCore", "LiquidLexer", "LiquidParser", "LiquidExtensions", "LiquidUtilities", "LiquidTags",
                .product(name: "OrderedCollections", package: "swift-collections"),
            ],
            swiftSettings: strictConcurrency
        ),
        .target(
            name: "LiquidFilters",
            dependencies: ["LiquidCore"],
            swiftSettings: strictConcurrency
        ),
        .target(
            name: "LiquidTags",
            dependencies: ["LiquidCore", "LiquidParser"],
            swiftSettings: strictConcurrency
        ),
        .target(
            name: "LiquidExtensions",
            dependencies: ["LiquidCore", "LiquidLexer", "LiquidParser"],
            swiftSettings: strictConcurrency
        ),
        .target(
            name: "LiquidUtilities",
            dependencies: ["LiquidCore"],
            swiftSettings: strictConcurrency
        ),
        .target(
            name: "RhoeLiquid",
            dependencies: [
                "LiquidCore", "LiquidLexer", "LiquidParser", "LiquidRenderer",
                "LiquidFilters", "LiquidTags", "LiquidExtensions", "LiquidUtilities",
            ],
            swiftSettings: strictConcurrency
        ),
        .target(
            name: "BenchmarkSupport",
            swiftSettings: strictConcurrency
        ),

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: - WebAssembly
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        .target(
            name: "RhoeLiquidWasm",
            dependencies: ["RhoeLiquid"],
            swiftSettings: strictConcurrency
        ),

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: - DOCX
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        .target(
            name: "RhoeDOCX",
            dependencies: ["RhoeLiquid"],
            swiftSettings: strictConcurrency
        ),

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: - Service
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        .target(
            name: "ServiceCore",
            dependencies: [
                "RhoeLiquid",
                "LiquidCore",
                "RhoeDOCX",
                .product(name: "Logging", package: "swift-log"),
            ],
            swiftSettings: strictConcurrency
        ),
        .target(
            name: "HTTPService",
            dependencies: [
                "ServiceCore",
                "RhoeDOCX",
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "Logging", package: "swift-log"),
            ],
            swiftSettings: strictConcurrency
        ),
        .executableTarget(
            name: "ServiceLauncher",
            dependencies: [
                "ServiceCore",
                "HTTPService",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Logging", package: "swift-log"),
            ],
            swiftSettings: strictConcurrency
        ),
        .executableTarget(
            name: "ServiceContractGenerator",
            dependencies: ["ServiceCore"],
            swiftSettings: strictConcurrency
        ),

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: - CLI
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        .target(
            name: "LiquidCLICore",
            dependencies: [
                "LiquidCore",
                "RhoeLiquid",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            swiftSettings: strictConcurrency
        ),
        .executableTarget(
            name: "LiquidCLI",
            dependencies: [
                "LiquidCLICore",
                "RhoeLiquid",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            swiftSettings: strictConcurrency
        ),

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: - Tests
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        // Engine tests
        .testTarget(name: "LiquidCoreTests", dependencies: ["LiquidCore", "BenchmarkSupport"], swiftSettings: strictConcurrency),
        .testTarget(name: "LiquidLexerTests", dependencies: ["LiquidLexer", "LiquidCore", "BenchmarkSupport"], swiftSettings: strictConcurrency),
        .testTarget(name: "LiquidParserTests", dependencies: ["LiquidParser", "LiquidLexer", "LiquidCore", "BenchmarkSupport"], swiftSettings: strictConcurrency),
        .testTarget(name: "LiquidRendererTests", dependencies: ["LiquidRenderer", "LiquidCore"], swiftSettings: strictConcurrency),
        .testTarget(name: "LiquidFiltersTests", dependencies: ["LiquidFilters", "LiquidCore", "RhoeLiquid"], swiftSettings: strictConcurrency),
        .testTarget(name: "LiquidUtilitiesTests", dependencies: ["LiquidUtilities"], swiftSettings: strictConcurrency),
        .testTarget(name: "LiquidTagsTests", dependencies: ["LiquidTags", "LiquidCore"], swiftSettings: strictConcurrency),
        .testTarget(name: "RhoeLiquidTests", dependencies: ["RhoeLiquid"], swiftSettings: strictConcurrency),
        .testTarget(
            name: "PerformanceTests",
            dependencies: ["RhoeLiquid", "LiquidCore", "LiquidLexer", "LiquidParser", "LiquidUtilities", "BenchmarkSupport"],
            swiftSettings: strictConcurrency
        ),
        .testTarget(name: "FuzzTests", dependencies: ["RhoeLiquid"], swiftSettings: strictConcurrency),
        .testTarget(
            name: "ExampleTests",
            dependencies: ["RhoeLiquid"],
            resources: [.copy("Templates"), .copy("Fixtures")],
            swiftSettings: strictConcurrency
        ),
        .testTarget(name: "IntegrationTests", dependencies: ["RhoeLiquid"], swiftSettings: strictConcurrency),
        .testTarget(
            name: "GoldenLiquidTests",
            dependencies: [
                "RhoeLiquid",
                .product(name: "OrderedCollections", package: "swift-collections"),
            ],
            resources: [.copy("Fixtures")],
            swiftSettings: strictConcurrency
        ),

        // DOCX tests
        .testTarget(name: "RhoeDOCXTests", dependencies: ["RhoeDOCX"], swiftSettings: strictConcurrency),

        // Service tests
        .testTarget(name: "ServiceCoreTests", dependencies: ["ServiceCore", "RhoeLiquid", "RhoeDOCX"], swiftSettings: strictConcurrency),
        .testTarget(name: "HTTPServiceTests", dependencies: ["HTTPService", "ServiceCore", "RhoeDOCX"], swiftSettings: strictConcurrency),
        .testTarget(
            name: "LiquidCLICoreTests",
            dependencies: [
                "LiquidCLICore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            swiftSettings: strictConcurrency
        ),
    ],
    swiftLanguageModes: [.v6]
)
