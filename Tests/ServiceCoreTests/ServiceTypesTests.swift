/**
 * ServiceTypesTests.swift
 * 
 * Comprehensive unit tests for ServiceCore types and models
 * Testing data structures, configurations, and type safety
 */

import XCTest
@testable import ServiceCore

/// Test suite for ServiceCore types and configurations
final class ServiceTypesTests: XCTestCase {
    
    // MARK: - ServiceConfiguration Tests
    
    func testDefaultServiceConfiguration() {
        // Given/When
        let config = ServiceConfiguration()
        
        // Then
        XCTAssertEqual(config.httpPort, 13480)
        XCTAssertEqual(config.maxConcurrentRequests, 100)
        XCTAssertEqual(config.requestTimeoutSeconds, 30.0)
        XCTAssertTrue(config.enableSecurity)
        XCTAssertEqual(config.performanceMode, .balanced)
        XCTAssertEqual(config.logLevel, .info)
    }
    
    func testProductionConfiguration() {
        // Given/When
        let config = ServiceConfiguration.production
        
        // Then
        XCTAssertEqual(config.httpPort, 13480)
        XCTAssertTrue(config.enableSecurity)
        XCTAssertEqual(config.performanceMode, .balanced)
    }
    
    func testHighPerformanceConfiguration() {
        // Given/When
        let config = ServiceConfiguration.highPerformance
        
        // Then
        XCTAssertEqual(config.maxConcurrentRequests, 500)
        XCTAssertEqual(config.requestTimeoutSeconds, 10.0)
        XCTAssertEqual(config.performanceMode, .performance)
        XCTAssertEqual(config.logLevel, .warning)
    }
    
    func testDevelopmentConfiguration() {
        // Given/When
        let config = ServiceConfiguration.development
        
        // Then
        XCTAssertEqual(config.httpPort, 13481)
        XCTAssertFalse(config.enableSecurity)
        XCTAssertEqual(config.performanceMode, .development)
        XCTAssertEqual(config.logLevel, .debug)
    }
    
    func testCustomConfiguration() {
        // Given/When
        let config = ServiceConfiguration(
            httpPort: 8080,
            maxConcurrentRequests: 200,
            requestTimeoutSeconds: 60.0,
            enableSecurity: false,
            rateLimits: RateLimitConfiguration(
                requestsPerMinute: 2000,
                burstLimit: 100
            ),
            performanceMode: .memory,
            logLevel: .trace
        )
        
        // Then
        XCTAssertEqual(config.httpPort, 8080)
        XCTAssertEqual(config.maxConcurrentRequests, 200)
        XCTAssertEqual(config.requestTimeoutSeconds, 60.0)
        XCTAssertFalse(config.enableSecurity)
        XCTAssertEqual(config.rateLimits.requestsPerMinute, 2000)
        XCTAssertEqual(config.performanceMode, .memory)
        XCTAssertEqual(config.logLevel, .trace)
    }
    
    // MARK: - RateLimitConfiguration Tests
    
    func testDefaultRateLimitConfiguration() {
        // Given/When
        let rateLimits = RateLimitConfiguration()
        
        // Then
        XCTAssertEqual(rateLimits.requestsPerMinute, 1000)
        XCTAssertEqual(rateLimits.burstLimit, 50)
        XCTAssertEqual(rateLimits.maxTemplateSizeBytes, 10 * 1024 * 1024)
        XCTAssertEqual(rateLimits.maxContextSizeBytes, 5 * 1024 * 1024)
    }
    
    func testCustomRateLimitConfiguration() {
        // Given/When
        let rateLimits = RateLimitConfiguration(
            requestsPerMinute: 500,
            burstLimit: 25,
            maxTemplateSizeBytes: 1024 * 1024,
            maxContextSizeBytes: 512 * 1024
        )
        
        // Then
        XCTAssertEqual(rateLimits.requestsPerMinute, 500)
        XCTAssertEqual(rateLimits.burstLimit, 25)
        XCTAssertEqual(rateLimits.maxTemplateSizeBytes, 1024 * 1024)
        XCTAssertEqual(rateLimits.maxContextSizeBytes, 512 * 1024)
    }
    
    // MARK: - PerformanceMode Tests
    
    func testPerformanceModeEngineConfiguration() {
        // Test each performance mode
        for mode in PerformanceMode.allCases {
            // Given/When
            let engineConfig = mode.engineConfiguration()
            
            // Then
            XCTAssertNotNil(engineConfig)
            
            switch mode {
            case .development:
                XCTAssertEqual(engineConfig.maxNestingDepth, 100)
                XCTAssertTrue(engineConfig.cacheEnabled)
                XCTAssertEqual(engineConfig.maxLoopIterations, 5_000)
            case .balanced:
                XCTAssertEqual(engineConfig.maxNestingDepth, 200)
                XCTAssertTrue(engineConfig.cacheEnabled)
            case .performance:
                XCTAssertEqual(engineConfig.maxNestingDepth, 500)
                XCTAssertTrue(engineConfig.cacheEnabled)
                XCTAssertEqual(engineConfig.maxLoopIterations, 100_000)
            case .memory:
                XCTAssertEqual(engineConfig.maxNestingDepth, 50)
                XCTAssertFalse(engineConfig.cacheEnabled)
            }
        }
    }
    
    func testPerformanceModeDescriptions() {
        // Given/When/Then
        XCTAssertTrue(PerformanceMode.development.description.contains("Debug"))
        XCTAssertTrue(PerformanceMode.balanced.description.contains("Recommended"))
        XCTAssertTrue(PerformanceMode.performance.description.contains("Maximum"))
        XCTAssertTrue(PerformanceMode.memory.description.contains("Low resource"))
    }
    
    // MARK: - ServiceMetrics Tests
    
    func testDefaultServiceMetrics() {
        // Given/When
        let metrics = ServiceMetrics()
        
        // Then
        XCTAssertEqual(metrics.uptime, 0)
        XCTAssertEqual(metrics.totalRequests, 0)
        XCTAssertEqual(metrics.requestsToday, 0)
        XCTAssertEqual(metrics.averageRenderTime, 0)
        XCTAssertEqual(metrics.memoryUsage, 0)
        XCTAssertEqual(metrics.cpuUsage, 0)
        XCTAssertEqual(metrics.cacheHitRate, 0)
        XCTAssertEqual(metrics.activeConnections, 0)
        XCTAssertEqual(metrics.errorRate, 0)
        XCTAssertEqual(metrics.queueDepth, 0)
    }
    
    func testCustomServiceMetrics() {
        // Given/When
        let metrics = ServiceMetrics(
            uptime: 3600,
            totalRequests: 1000,
            requestsToday: 500,
            averageRenderTime: 0.005,
            memoryUsage: 25 * 1024 * 1024,
            cpuUsage: 15.5,
            cacheHitRate: 0.85,
            activeConnections: 5,
            errorRate: 0.02,
            queueDepth: 3
        )
        
        // Then
        XCTAssertEqual(metrics.uptime, 3600)
        XCTAssertEqual(metrics.totalRequests, 1000)
        XCTAssertEqual(metrics.requestsToday, 500)
        XCTAssertEqual(metrics.averageRenderTime, 0.005)
        XCTAssertEqual(metrics.memoryUsage, 25 * 1024 * 1024)
        XCTAssertEqual(metrics.cpuUsage, 15.5)
        XCTAssertEqual(metrics.cacheHitRate, 0.85)
        XCTAssertEqual(metrics.activeConnections, 5)
        XCTAssertEqual(metrics.errorRate, 0.02)
        XCTAssertEqual(metrics.queueDepth, 3)
    }
    
    // MARK: - ProcessingActivity Tests
    
    func testProcessingActivityCreation() {
        // Given/When
        let activity = ProcessingActivity(
            templateId: "template-123",
            renderTime: 0.005,
            status: .success,
            clientIP: "127.0.0.1",
            errorMessage: nil
        )
        
        // Then
        XCTAssertNotNil(activity.id)
        XCTAssertEqual(activity.templateId, "template-123")
        XCTAssertEqual(activity.renderTime, 0.005)
        XCTAssertEqual(activity.status, .success)
        XCTAssertEqual(activity.clientIP, "127.0.0.1")
        XCTAssertNil(activity.errorMessage)
        XCTAssertTrue(activity.timestamp.timeIntervalSinceNow < 1) // Recent timestamp
    }
    
    func testProcessingActivityWithError() {
        // Given/When
        let activity = ProcessingActivity(
            renderTime: 0.001,
            status: .error,
            errorMessage: "Template syntax error"
        )
        
        // Then
        XCTAssertNil(activity.templateId)
        XCTAssertEqual(activity.status, .error)
        XCTAssertEqual(activity.errorMessage, "Template syntax error")
    }
    
    // MARK: - ProcessingStatus Tests
    
    func testProcessingStatusEmojis() {
        // Given/When/Then
        XCTAssertEqual(ProcessingStatus.success.emoji, "✅")
        XCTAssertEqual(ProcessingStatus.warning.emoji, "⚠️")
        XCTAssertEqual(ProcessingStatus.error.emoji, "❌")
        XCTAssertEqual(ProcessingStatus.timeout.emoji, "⏱️")
        XCTAssertEqual(ProcessingStatus.rateLimited.emoji, "🚫")
    }
    
    func testProcessingStatusCases() {
        // Given
        let allStatuses = ProcessingStatus.allCases
        
        // Then
        XCTAssertEqual(allStatuses.count, 5)
        XCTAssertTrue(allStatuses.contains(.success))
        XCTAssertTrue(allStatuses.contains(.warning))
        XCTAssertTrue(allStatuses.contains(.error))
        XCTAssertTrue(allStatuses.contains(.timeout))
        XCTAssertTrue(allStatuses.contains(.rateLimited))
    }
    
    // MARK: - ServiceStatus Tests
    
    func testServiceStatusEmojis() {
        // Given/When/Then
        XCTAssertEqual(ServiceStatus.starting.emoji, "🔄")
        XCTAssertEqual(ServiceStatus.active.emoji, "🟢")
        XCTAssertEqual(ServiceStatus.stopping.emoji, "🟡")
        XCTAssertEqual(ServiceStatus.stopped.emoji, "🔴")
        XCTAssertEqual(ServiceStatus.error.emoji, "❌")
    }
    
    func testServiceStatusDescriptions() {
        // Given/When/Then
        XCTAssertEqual(ServiceStatus.starting.description, "Starting")
        XCTAssertEqual(ServiceStatus.active.description, "Active")
        XCTAssertEqual(ServiceStatus.stopping.description, "Stopping")
        XCTAssertEqual(ServiceStatus.stopped.description, "Stopped")
        XCTAssertEqual(ServiceStatus.error.description, "Error")
    }
    
    // MARK: - LogLevel Tests
    
    func testLogLevelCases() {
        // Given
        let allLevels = LogLevel.allCases
        
        // Then
        XCTAssertEqual(allLevels.count, 7)
        XCTAssertTrue(allLevels.contains(.trace))
        XCTAssertTrue(allLevels.contains(.debug))
        XCTAssertTrue(allLevels.contains(.info))
        XCTAssertTrue(allLevels.contains(.notice))
        XCTAssertTrue(allLevels.contains(.warning))
        XCTAssertTrue(allLevels.contains(.error))
        XCTAssertTrue(allLevels.contains(.critical))
    }
    
    // MARK: - ServiceInfo Tests
    
    func testServiceInfoCreation() {
        // Given
        let performance = PerformanceInfo(
            averageRenderTime: 0.005,
            cacheHitRate: 0.85,
            memoryUsage: 25 * 1024 * 1024,
            cpuUsage: 10.5
        )
        
        // When
        let info = ServiceInfo(
            status: .active,
            uptime: 3600,
            requestsProcessed: 1000,
            performance: performance
        )
        
        // Then
        XCTAssertEqual(info.service, "RhoeLiquid Native Service")
        XCTAssertEqual(info.version, "0.1.1")
        XCTAssertEqual(info.engine, "RhoeLiquid 0.1.1")
        XCTAssertEqual(info.status, .active)
        XCTAssertEqual(info.uptime, 3600)
        XCTAssertEqual(info.requestsProcessed, 1000)
        XCTAssertEqual(info.performance.averageRenderTime, 0.005)
    }
    
    // MARK: - Codable Tests
    
    func testServiceConfigurationCodable() throws {
        // Given
        let original = ServiceConfiguration(
            httpPort: 8080,
            performanceMode: .performance,
            logLevel: .debug
        )
        
        // When
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ServiceConfiguration.self, from: encoded)
        
        // Then
        XCTAssertEqual(decoded.httpPort, original.httpPort)
        XCTAssertEqual(decoded.performanceMode, original.performanceMode)
        XCTAssertEqual(decoded.logLevel, original.logLevel)
    }
    
    func testServiceMetricsCodable() throws {
        // Given
        let original = ServiceMetrics(
            uptime: 3600,
            totalRequests: 1000,
            averageRenderTime: 0.005,
            cacheHitRate: 0.85
        )
        
        // When
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ServiceMetrics.self, from: encoded)
        
        // Then
        XCTAssertEqual(decoded.uptime, original.uptime)
        XCTAssertEqual(decoded.totalRequests, original.totalRequests)
        XCTAssertEqual(decoded.averageRenderTime, original.averageRenderTime)
        XCTAssertEqual(decoded.cacheHitRate, original.cacheHitRate)
    }
    
    func testProcessingActivityCodable() throws {
        // Given
        let original = ProcessingActivity(
            templateId: "test-123",
            renderTime: 0.005,
            status: .success,
            clientIP: "127.0.0.1"
        )
        
        // When
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ProcessingActivity.self, from: encoded)
        
        // Then
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.templateId, original.templateId)
        XCTAssertEqual(decoded.renderTime, original.renderTime)
        XCTAssertEqual(decoded.status, original.status)
        XCTAssertEqual(decoded.clientIP, original.clientIP)
    }
    
    // MARK: - Sendable Conformance Tests
    
    func testTypesSendableConformance() async {
        // This test verifies that our types can be safely sent across actors
        let config = ServiceConfiguration()
        let metrics = ServiceMetrics()
        let activity = ProcessingActivity(renderTime: 0.001, status: .success)
        
        // Send across actor boundary
        await withCheckedContinuation { continuation in
            Task {
                _ = config
                _ = metrics  
                _ = activity
                continuation.resume()
            }
        }
        
        // If this compiles and runs, our types are properly Sendable
        XCTAssertTrue(true)
    }
}
