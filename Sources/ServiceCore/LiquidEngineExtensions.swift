/**
 * LiquidEngineExtensions.swift
 * 
 * Extensions to LiquidEngine and related types for native service integration
 */

import Foundation
import LiquidCore
import RhoeLiquid

// MARK: - LiquidConfiguration Extensions

extension LiquidConfiguration {
    
    /// Resource limit levels for different performance modes
    public enum ResourceLimits: String, Sendable, Codable, CaseIterable {
        case conservative = "conservative"
        case moderate = "moderate" 
        case generous = "generous"
        case unlimited = "unlimited"
        
        public var maxNestingDepth: Int {
            switch self {
            case .conservative: return 50
            case .moderate: return 100
            case .generous: return 200
            case .unlimited: return 500
            }
        }
        
        public var maxLoopIterations: Int {
            switch self {
            case .conservative: return 1000
            case .moderate: return 5000
            case .generous: return 20000
            case .unlimited: return 100000
            }
        }
        
        public var maxCacheSize: Int {
            switch self {
            case .conservative: return 10 * 1024 * 1024   // 10MB
            case .moderate: return 25 * 1024 * 1024       // 25MB
            case .generous: return 50 * 1024 * 1024       // 50MB
            case .unlimited: return 100 * 1024 * 1024     // 100MB
            }
        }
        
        public var maxCacheEntries: Int {
            switch self {
            case .conservative: return 100
            case .moderate: return 500
            case .generous: return 1000
            case .unlimited: return 5000
            }
        }
    }
    
    /// Caching strategy levels
    public enum CachingStrategy: String, Sendable, Codable, CaseIterable {
        case minimal = "minimal"
        case basic = "basic"
        case moderate = "moderate"
        case aggressive = "aggressive"
        
        public var enabled: Bool {
            return self != .minimal
        }
        
        public var templateCaching: Bool {
            return self != .minimal
        }
        
        public var astCaching: Bool {
            return self == .moderate || self == .aggressive
        }
        
        public var compiledCaching: Bool {
            return self == .aggressive
        }
    }
    
    /// Concurrency levels for different scenarios
    public enum ConcurrencyLevel: String, Sendable, Codable, CaseIterable {
        case singleThreaded = "single_threaded"
        case balanced = "balanced"
        case systemOptimal = "system_optimal"
        
        public var maxConcurrentOperations: Int {
            switch self {
            case .singleThreaded: return 1
            case .balanced: return min(4, ProcessInfo.processInfo.processorCount)
            case .systemOptimal: return ProcessInfo.processInfo.processorCount
            }
        }
    }
    
    /// Create configuration optimized for native service
    public static func nativeService(
        resourceLimits: ResourceLimits = .generous,
        caching: CachingStrategy = .moderate,
        concurrency: ConcurrencyLevel = .balanced
    ) -> LiquidConfiguration {
        _ = concurrency

        return LiquidConfiguration(
            strictMode: false,
            maxNestingDepth: resourceLimits.maxNestingDepth,
            maxLoopIterations: resourceLimits.maxLoopIterations,
            autoEscape: true,
            maxCacheSize: resourceLimits.maxCacheSize,
            maxCacheEntries: resourceLimits.maxCacheEntries,
            cacheEnabled: caching.enabled
        )
    }
}

// MARK: - LiquidEngine Extensions

extension LiquidEngine {
    /// Configure engine for specific performance profile.
    ///
    /// The active service creates a fresh engine for each service profile, so this
    /// remains a no-op compatibility hook.
    public func configure(for profile: ServiceCore.PerformanceMode) async {
        _ = profile
    }
}
