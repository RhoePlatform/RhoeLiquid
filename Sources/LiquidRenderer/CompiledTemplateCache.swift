//
//  CompiledTemplateCache.swift
//  LiquidRenderer
//
//  Lightweight compatibility shim for the archived compiled-template cache.
//

import Foundation

/// Namespace for cache configuration and metrics preserved for source compatibility.
///
/// The active engine now manages warm compiled-template reuse through
/// `OptimizedRenderer` and `TemplateCache`. This namespace remains only to keep
/// older cache-configuration symbols source-compatible while the archived cache
/// implementation stays out of the live runtime path.
public enum CompiledTemplateCache {
    /// Cache budget and promotion hints for the active `OptimizedRenderer`.
    ///
    /// Active today:
    /// - `maxCacheSize`
    /// - `maxMemoryUsage`
    /// - `compilationThreshold`
    ///
    /// Compatibility-only today:
    /// - `enableCompression`
    /// - `enableDependencyTracking`
    ///
    /// The latter two fields are now on a formal deprecation path: they remain
    /// source-compatible for 1.x, but they do not enable the archived cache
    /// implementation and will be removed in the next major release.
    public struct CacheConfiguration: Sendable {
        private static func makeConfiguration(
            maxCacheSize: Int,
            maxMemoryUsage: Int,
            enableCompression: Bool,
            enableDependencyTracking: Bool,
            compilationThreshold: Int
        ) -> Self {
            Self(
                maxCacheSize: maxCacheSize,
                maxMemoryUsage: maxMemoryUsage,
                enableCompression: enableCompression,
                enableDependencyTracking: enableDependencyTracking,
                compilationThreshold: compilationThreshold,
                _deprecatedShim: ()
            )
        }

        /// Maximum number of cached template entries retained by the active runtime.
        public let maxCacheSize: Int

        /// Approximate memory budget enforced by the active runtime cache.
        public let maxMemoryUsage: Int

        private let enableCompressionStorage: Bool
        private let enableDependencyTrackingStorage: Bool

        /// Archived compatibility flag. Compression is not part of the live cache path.
        @available(*, deprecated, message: "Archived compatibility field. Use CacheConfiguration.active(...) instead. This field will be removed in the next major release.")
        public var enableCompression: Bool { enableCompressionStorage }

        /// Archived compatibility flag. Dependency tracking is not part of the live cache path.
        @available(*, deprecated, message: "Archived compatibility field. Use CacheConfiguration.active(...) instead. This field will be removed in the next major release.")
        public var enableDependencyTracking: Bool { enableDependencyTrackingStorage }

        /// Number of hits before a parsed AST is promoted to a compiled template.
        public let compilationThreshold: Int

        /// Preferred factory for the live cache configuration.
        public static func active(
            maxCacheSize: Int = 1_000,
            maxMemoryUsage: Int = 50 * 1024 * 1024,
            compilationThreshold: Int = 1
        ) -> Self {
            makeConfiguration(
                maxCacheSize: maxCacheSize,
                maxMemoryUsage: maxMemoryUsage,
                enableCompression: false,
                enableDependencyTracking: false,
                compilationThreshold: compilationThreshold
            )
        }

        @available(*, deprecated, message: "Use CacheConfiguration.active(...) instead. enableCompression and enableDependencyTracking are archived compatibility fields and will be removed in the next major release.")
        public init(
            maxCacheSize: Int = 1_000,
            maxMemoryUsage: Int = 50 * 1024 * 1024,
            enableCompression: Bool = false,
            enableDependencyTracking: Bool = false,
            compilationThreshold: Int = 1
        ) {
            self = Self.makeConfiguration(
                maxCacheSize: maxCacheSize,
                maxMemoryUsage: maxMemoryUsage,
                enableCompression: enableCompression,
                enableDependencyTracking: enableDependencyTracking,
                compilationThreshold: compilationThreshold
            )
        }

        private init(
            maxCacheSize: Int,
            maxMemoryUsage: Int,
            enableCompression: Bool,
            enableDependencyTracking: Bool,
            compilationThreshold: Int,
            _deprecatedShim: Void
        ) {
            self.maxCacheSize = maxCacheSize
            self.maxMemoryUsage = maxMemoryUsage
            self.enableCompressionStorage = enableCompression
            self.enableDependencyTrackingStorage = enableDependencyTracking
            self.compilationThreshold = compilationThreshold
        }

        public static let production = active()
        public static let development = active(
            maxCacheSize: 200,
            maxMemoryUsage: 10 * 1024 * 1024,
            compilationThreshold: 1
        )
    }

    /// Active cache metrics produced by `OptimizedRenderer`.
    ///
    /// These statistics describe the live cache implementation, not the archived
    /// legacy cache pipeline.
    public struct CacheStatistics: Sendable {
        public let cacheHits: Int
        public let cacheMisses: Int
        public let hitRate: Double
        public let compilations: Int
        public let evictions: Int
        public let cachedTemplates: Int
        public let memoryUsage: Int
        public let averageCompilationTime: TimeInterval

        public init(
            cacheHits: Int = 0,
            cacheMisses: Int = 0,
            hitRate: Double = 0,
            compilations: Int = 0,
            evictions: Int = 0,
            cachedTemplates: Int = 0,
            memoryUsage: Int = 0,
            averageCompilationTime: TimeInterval = 0
        ) {
            self.cacheHits = cacheHits
            self.cacheMisses = cacheMisses
            self.hitRate = hitRate
            self.compilations = compilations
            self.evictions = evictions
            self.cachedTemplates = cachedTemplates
            self.memoryUsage = memoryUsage
            self.averageCompilationTime = averageCompilationTime
        }
    }
}

public typealias CacheStatistics = CompiledTemplateCache.CacheStatistics
