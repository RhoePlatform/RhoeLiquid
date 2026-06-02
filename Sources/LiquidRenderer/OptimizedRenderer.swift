//
//  OptimizedRenderer.swift
//  LiquidRenderer
//
//  Stable renderer shim that preserves the public API while the legacy
//  optimization stack lives in Archive/LiquidRendererLegacy.
//

import Foundation
import LiquidCore
import LiquidExtensions
import LiquidLexer
import LiquidParser
import LiquidTags

/// Lightweight expression metrics preserved for source compatibility.
public struct FastEvaluatorMetrics: Sendable {
    public var evaluationCount: Int
    public var cacheHits: Int
    public var averageEvaluationTime: TimeInterval

    public init(
        evaluationCount: Int = 0,
        cacheHits: Int = 0,
        averageEvaluationTime: TimeInterval = 0
    ) {
        self.evaluationCount = evaluationCount
        self.cacheHits = cacheHits
        self.averageEvaluationTime = averageEvaluationTime
    }
}

/// Comprehensive rendering performance statistics.
public struct RenderingStatistics: Sendable {
    public var totalRenders: Int = 0
    public var totalRenderTime: TimeInterval = 0
    public var averageRenderTime: TimeInterval = 0
    public var fastPathHits: Int = 0
    public var fallbackToStandard: Int = 0
    public var uptime: TimeInterval = 0

    public var expressionEvaluatorStats: FastEvaluatorMetrics?
    public var cacheStats: CacheStatistics?
    public var optimizerStats: OptimizationStatistics?

    public init() {}

    public var performanceMultiplier: Double {
        let baselineTime = 0.01
        return baselineTime / max(averageRenderTime, 0.001)
    }
}

    /// Compatibility renderer that uses the stable parser + renderer pipeline.
    // SAFETY: NSLock-protected mutable state (astCache, lock)
    public final class OptimizedRenderer: @unchecked Sendable {
        private struct ASTCacheKey: Hashable, Sendable {
            let templateName: String?
            let sourceHash: Int
            let sourceLength: Int
            let customTagSignature: Int
        }

    private struct CachedTemplateEntry {
        enum Storage {
            case parsed(ASTNode)
            case compiled(CompiledTemplate)

            var ast: ASTNode {
                switch self {
                case .parsed(let ast):
                    return ast
                case .compiled(let compiledTemplate):
                    return compiledTemplate.optimizedAST
                }
            }
        }

        var storage: Storage
        var renderCount: Int
    }

    private enum CacheLookupResult {
        case ready(CachedTemplateEntry.Storage)
        case needsCompilation(ASTNode)
    }

    private let configuration: RendererConfiguration
    private let cacheConfiguration: CompiledTemplateCache.CacheConfiguration
    private let optimizationOptions: ASTOptimizer.OptimizationOptions
    private let templateCompiler: TemplateCompiler
    private let stateLock = NSLock()
    private let maxRendererPoolSize: Int

    private var astCache: [ASTCacheKey: CachedTemplateEntry] = [:]
    private var rendererPool: [Renderer] = []
    private var cacheHits = 0
    private var cacheMisses = 0
    private var compilationCount = 0
    private var evictionCount = 0
    private var totalCompilationTime: TimeInterval = 0
    private var totalRenders = 0
    private var totalRenderTime: TimeInterval = 0
    private let startedAt = Date()

    public init(
        configuration: RendererConfiguration = .default,
        cacheConfiguration: CompiledTemplateCache.CacheConfiguration = .production,
        optimizationOptions: ASTOptimizer.OptimizationOptions = .aggressive
    ) {
        let runtimeProfile = RuntimePerformanceProfile.current
        self.configuration = configuration
        self.cacheConfiguration = cacheConfiguration
        self.optimizationOptions = optimizationOptions
        self.templateCompiler = TemplateCompiler(
            options: TemplateCompiler.Options(
                enableConstantFolding: optimizationOptions.enableConstantFolding,
                enableDeadCodeElimination: optimizationOptions.enableDeadCodeElimination,
                enableInlineOptimization: optimizationOptions.enableTemplateInlining,
                enableVariableHoisting: optimizationOptions.enableLoopOptimization
            )
        )
        self.maxRendererPoolSize = runtimeProfile.recommendedRendererPoolSize
        if cacheConfiguration.maxCacheSize > 0 {
            self.astCache.reserveCapacity(cacheConfiguration.maxCacheSize)
        }
        self.rendererPool.reserveCapacity(maxRendererPoolSize)
    }

    public func render(
        source: String,
        with variables: [String: Any] = [:],
        templateName: String? = nil,
        customFilters: [String: any CustomFilter] = [:],
        customTags: [String: any LiquidTags.CustomTag] = [:],
        templateLoader: TemplateLoader? = nil,
        dataLoaderRegistry: DataLoaderRegistry? = nil,
        rootTemplatePath: String? = nil
    ) async throws -> String {
        let renderStart = Date().timeIntervalSinceReferenceDate
        let storage = try cachedTemplateStorage(
            for: source,
            templateName: templateName,
            customTagDescriptors: customTagDescriptors(from: customTags)
        )
        let renderer = acquireRenderer()
        renderer.setCustomFilters(customFilters)
        renderer.setCustomTags(customTags)
        renderer.setTemplateLoader(templateLoader, rootTemplatePath: rootTemplatePath)
        renderer.setDataLoaderRegistry(dataLoaderRegistry)
        defer { releaseRenderer(renderer) }
        let output: String

        switch storage {
        case .parsed(let ast):
            output = try await renderer.render(ast, with: variables)
        case .compiled(let compiledTemplate):
            output = try await renderer.render(compiledTemplate, with: variables)
        }

        let duration = Date().timeIntervalSinceReferenceDate - renderStart
        stateLock.withLock {
            totalRenders += 1
            totalRenderTime += duration
        }

        return output
    }

    public var statistics: RenderingStatistics {
        stateLock.withLock {
            let hitRate = cacheHitRateLocked()
            let averageRenderTime = totalRenders > 0 ? totalRenderTime / Double(totalRenders) : 0

            var stats = RenderingStatistics()
            stats.totalRenders = totalRenders
            stats.totalRenderTime = totalRenderTime
            stats.averageRenderTime = averageRenderTime
            stats.fastPathHits = cacheHits
            stats.fallbackToStandard = cacheMisses
            stats.uptime = Date().timeIntervalSince(startedAt)
            stats.cacheStats = CacheStatistics(
                cacheHits: cacheHits,
                cacheMisses: cacheMisses,
                hitRate: hitRate,
                compilations: compilationCount,
                evictions: evictionCount,
                cachedTemplates: astCache.count,
                memoryUsage: estimatedCacheMemoryUsageLocked(),
                averageCompilationTime: compilationCount > 0 ? totalCompilationTime / Double(compilationCount) : 0
            )
            stats.optimizerStats = OptimizationStatistics(
                expressionsOptimized: 0,
                branchesEliminated: 0,
                loopsUnrolled: 0,
                filtersOptimized: 0,
                deadAssignmentsEliminated: 0,
                conditionalsMerged: 0,
                templatesInlined: optimizationOptions.enableTemplateInlining ? astCache.count : 0
            )
            stats.expressionEvaluatorStats = FastEvaluatorMetrics()
            return stats
        }
    }

    public func clearCaches() {
        stateLock.withLock {
            astCache.removeAll(keepingCapacity: true)
            cacheHits = 0
            cacheMisses = 0
            compilationCount = 0
            evictionCount = 0
            totalCompilationTime = 0
            totalRenders = 0
            totalRenderTime = 0
        }
    }

    public func handleMemoryPressure(_ level: CachePressureLevel) {
        stateLock.withLock {
            switch level {
            case .warning:
                trimCachesLocked()
            case .critical:
                evictionCount += astCache.count
                astCache.removeAll(keepingCapacity: true)
                if rendererPool.count > 1 {
                    rendererPool.removeSubrange(1...)
                }
            }
        }
    }

    public func warmupCaches(templates: [String: String]) async throws {
        for (name, source) in templates {
            _ = try cachedTemplateStorage(
                for: source,
                templateName: name,
                customTagDescriptors: [],
                forceCompilation: true
            )
        }
    }

    private func cachedTemplateStorage(
        for source: String,
        templateName: String?,
        customTagDescriptors: [CustomTagDescriptor],
        forceCompilation: Bool = false
    ) throws -> CachedTemplateEntry.Storage {
        let key = cacheKey(
            for: source,
            templateName: templateName,
            customTagDescriptors: customTagDescriptors
        )

        if let cached = stateLock.withLock({ cachedStorageLocked(for: key, forceCompilation: forceCompilation) }) {
            switch cached {
            case .ready(let storage):
                return storage

            case .needsCompilation(let ast):
                let compileStart = Date().timeIntervalSinceReferenceDate
                let compiledTemplate = templateCompiler.compile(ast)
                let compilationTime = Date().timeIntervalSinceReferenceDate - compileStart

                return stateLock.withLock {
                    if var entry = astCache[key] {
                        switch entry.storage {
                        case .compiled(let existing):
                            astCache[key] = entry
                            return .compiled(existing)
                        case .parsed:
                            entry.storage = .compiled(compiledTemplate)
                            astCache[key] = entry
                            compilationCount += 1
                            totalCompilationTime += compilationTime
                            return .compiled(compiledTemplate)
                        }
                    }

                    compilationCount += 1
                    totalCompilationTime += compilationTime
                    storeEntryLocked(
                        CachedTemplateEntry(
                            storage: .compiled(compiledTemplate),
                            renderCount: max(1, cacheConfiguration.compilationThreshold)
                        ),
                        for: key
                    )
                    return .compiled(compiledTemplate)
                }
            }
        }

        let compileStart = Date().timeIntervalSinceReferenceDate
        let ast = try parse(source, customTagDescriptors: customTagDescriptors)
        let compilationTime = Date().timeIntervalSinceReferenceDate - compileStart

        return stateLock.withLock {
            if var cached = astCache[key] {
                cacheHits += 1
                cached.renderCount += 1
                astCache[key] = cached
                return cached.storage
            }

            cacheMisses += 1
            totalCompilationTime += compilationTime
            compilationCount += 1
            storeEntryLocked(
                CachedTemplateEntry(storage: .parsed(ast), renderCount: 1),
                for: key
            )
            return .parsed(ast)
        }
    }

    private func parse(_ source: String, customTagDescriptors: [CustomTagDescriptor]) throws -> ASTNode {
        let lexer = Lexer(source)
        let tokens = try lexer.tokenize()
        let parser = Parser(
            consuming: tokens,
            source: source,
            customTags: customTagDescriptors
        )
        return try parser.parse()
    }

    private func cachedStorageLocked(
        for key: ASTCacheKey,
        forceCompilation: Bool
    ) -> CacheLookupResult? {
        guard var entry = astCache[key] else {
            return nil
        }

        cacheHits += 1
        entry.renderCount += 1
        astCache[key] = entry

        switch entry.storage {
        case .compiled(let compiledTemplate):
            return .ready(.compiled(compiledTemplate))
        case .parsed(let ast):
            if forceCompilation || shouldCompile(entry: entry) {
                return .needsCompilation(ast)
            }
            return .ready(.parsed(ast))
        }
    }

    private func shouldCompile(entry: CachedTemplateEntry) -> Bool {
        guard cacheConfiguration.compilationThreshold > 0 else {
            return false
        }

        switch entry.storage {
        case .compiled:
            return false
        case .parsed:
            return entry.renderCount >= cacheConfiguration.compilationThreshold
        }
    }

    private func storeEntryLocked(_ entry: CachedTemplateEntry, for key: ASTCacheKey) {
        if cacheConfiguration.maxCacheSize > 0 && astCache.count >= cacheConfiguration.maxCacheSize {
            if let evictedKey = astCache.keys.first {
                astCache.removeValue(forKey: evictedKey)
                evictionCount += 1
            }
        }
        astCache[key] = entry
        enforceCacheBudgetsLocked()
    }

    private func trimCachesLocked() {
        guard astCache.count > 1 else { return }

        let targetCount = max(1, astCache.count / 2)
        let removeCount = astCache.count - targetCount
        guard removeCount > 0 else { return }

        let victims = astCache
            .sorted { cacheRetentionScore($0.value) < cacheRetentionScore($1.value) }
            .prefix(removeCount)

        for (key, _) in victims {
            astCache.removeValue(forKey: key)
            evictionCount += 1
        }
    }

    @inline(__always)
    private func cacheRetentionScore(_ entry: CachedTemplateEntry) -> Int {
        var score = entry.renderCount * 4
        switch entry.storage {
        case .parsed:
            break
        case .compiled:
            score += 32
        }
        return score
    }

    private func enforceCacheBudgetsLocked() {
        guard cacheConfiguration.maxMemoryUsage > 0 else {
            return
        }

        while astCache.count > 1 && estimatedCacheMemoryUsageLocked() > cacheConfiguration.maxMemoryUsage {
            guard let victim = astCache.min(by: {
                cacheRetentionScore($0.value) < cacheRetentionScore($1.value)
            }) else {
                break
            }
            astCache.removeValue(forKey: victim.key)
            evictionCount += 1
        }
    }

    private func cacheKey(
        for source: String,
        templateName: String?,
        customTagDescriptors: [CustomTagDescriptor]
    ) -> ASTCacheKey {
        ASTCacheKey(
            templateName: templateName?.isEmpty == false ? templateName : nil,
            sourceHash: source.hashValue,
            sourceLength: source.utf8.count,
            customTagSignature: customTagSignature(for: customTagDescriptors)
        )
    }

    private func customTagDescriptors(from tags: [String: any LiquidTags.CustomTag]) -> [CustomTagDescriptor] {
        tags.values
            .map { tag in
                CustomTagDescriptor(name: tag.name, requiresEndTag: tag.type.requiresEndTag)
            }
            .sorted { $0.name < $1.name }
    }

    private func customTagSignature(for descriptors: [CustomTagDescriptor]) -> Int {
        descriptors.reduce(into: 5381) { partial, descriptor in
            for byte in descriptor.name.utf8 {
                partial = ((partial << 5) &+ partial) &+ Int(byte)
            }
            partial = ((partial << 5) &+ partial) &+ (descriptor.requiresEndTag ? 1 : 0)
        }
    }

    @inline(__always)
    private func acquireRenderer() -> Renderer {
        stateLock.withLock {
            rendererPool.popLast() ?? Renderer(configuration: configuration)
        }
    }

    @inline(__always)
    private func releaseRenderer(_ renderer: Renderer) {
        stateLock.withLock {
            guard rendererPool.count < maxRendererPoolSize else {
                return
            }
            rendererPool.append(renderer)
        }
    }

    private func cacheHitRateLocked() -> Double {
        let totalLookups = cacheHits + cacheMisses
        guard totalLookups > 0 else { return 0 }
        return Double(cacheHits) / Double(totalLookups)
    }

    private func estimatedCacheMemoryUsageLocked() -> Int {
        astCache.reduce(0) { total, element in
            let key = element.key
            let entry = element.value

            let keyBytes = MemoryLayout<ASTCacheKey>.stride + (key.templateName?.utf8.count ?? 0)
            let entryBytes = MemoryLayout<CachedTemplateEntry>.stride
            let storageBytes: Int

            switch entry.storage {
            case .parsed:
                storageBytes = MemoryLayout<ASTNode>.stride
            case .compiled(let compiledTemplate):
                storageBytes =
                    MemoryLayout<CompiledTemplate>.stride
                    + MemoryLayout<ASTNode>.stride
                    + compiledTemplate.staticSegments.reduce(0) { $0 + $1.utf8.count }
                    + compiledTemplate.variableAccess.keys.reduce(0) { $0 + $1.utf8.count }
                    + compiledTemplate.filterUsage.keys.reduce(0) { $0 + $1.utf8.count }
            }

            return total + keyBytes + entryBytes + storageBytes
        }
    }
}

private extension NSLock {
    @inline(__always)
    func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try body()
    }
}

/// Factory for creating optimized renderers with different profiles.
public enum OptimizedRendererFactory {
    public static func production() -> OptimizedRenderer {
        OptimizedRenderer(
            configuration: RendererConfiguration(
                autoEscape: true,
                strictMode: false,
                maxNestingDepth: 100,
                maxLoopIterations: 1_000_000
            ),
            cacheConfiguration: .production,
            optimizationOptions: .aggressive
        )
    }

    public static func development() -> OptimizedRenderer {
        OptimizedRenderer(
            configuration: RendererConfiguration(
                autoEscape: false,
                strictMode: false,
                maxNestingDepth: 50,
                maxLoopIterations: 100_000
            ),
            cacheConfiguration: .development,
            optimizationOptions: .balanced
        )
    }

    public static func memoryOptimized() -> OptimizedRenderer {
        OptimizedRenderer(
            configuration: RendererConfiguration(
                maxNestingDepth: 30,
                maxLoopIterations: 10_000
            ),
            cacheConfiguration: CompiledTemplateCache.CacheConfiguration.active(
                maxCacheSize: 100,
                maxMemoryUsage: 10 * 1024 * 1024
            ),
            optimizationOptions: .conservative
        )
    }
}
