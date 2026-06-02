import ArgumentParser
import Foundation
import HTTPService
import LiquidCore
import Logging
import ServiceCore

@main
public struct RhoeLiquidServiceApp: AsyncParsableCommand, Sendable {
    public static let configuration = CommandConfiguration(
        commandName: "RhoeLiquidService",
        abstract: "Run the local RhoeLiquid HTTP service.",
        discussion: """
        Starts the localhost RhoeLiquid service for template rendering, analysis, \
        DOCX processing, async jobs, and service contract inspection.
        """,
        version: liquidCoreVersion
    )

    @Option(name: .customLong("port"), help: "HTTP server port")
    var port: Int = 13480

    @Option(
        name: .customLong("mode"),
        help: "Performance mode: development, balanced, performance, or memory.",
        completion: ServicePerformanceModeArgument.completion
    )
    var performanceMode: ServicePerformanceModeArgument = .balanced

    @Flag(name: .customLong("service-mode"), help: "Run in background service mode (no UI)")
    var serviceMode: Bool = false

    @Option(
        name: .customLong("log-level"),
        help: "Logging level: trace, debug, info, notice, warning, error, or critical.",
        completion: ServiceLogLevelArgument.completion
    )
    var logLevel: ServiceLogLevelArgument = .info

    @Flag(name: .customLong("development"), help: "Enable development mode")
    var development: Bool = false

    public init() {}

    public func run() async throws {
        let loggerLevel = self.logLevel.loggerLevel

        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardOutput(label: label)
            handler.logLevel = loggerLevel
            return handler
        }

        let logger = Logger(label: "rhoe-liquid-service")
        let config = ServiceConfiguration(
            httpPort: self.port,
            performanceMode: self.development ? .development : self.performanceMode.serviceMode,
            logLevel: self.logLevel.serviceLogLevel
        )

        if !self.serviceMode {
            logger.info("Menu bar UI is archived for now; starting the local service runtime instead")
        }

        let launcher = await MainActor.run {
            ServiceLauncher(configuration: config)
        }

        do {
            try await launcher.start()
            logger.info("Service available at http://127.0.0.1:\(config.httpPort)")

            while !Task.isCancelled {
                try await Task.sleep(for: .seconds(1))
            }
        } catch is CancellationError {
            logger.info("Service cancelled")
        } catch {
            await launcher.stop()
            throw error
        }

        await launcher.stop()
    }
}

enum ServicePerformanceModeArgument: String, CaseIterable, ExpressibleByArgument, Sendable {
    case development
    case balanced
    case performance
    case memory

    init?(argument: String) {
        self.init(rawValue: argument)
    }

    static var completion: CompletionKind {
        .list(allCases.map(\.rawValue))
    }

    var serviceMode: PerformanceMode {
        switch self {
        case .development:
            return .development
        case .balanced:
            return .balanced
        case .performance:
            return .performance
        case .memory:
            return .memory
        }
    }
}

enum ServiceLogLevelArgument: String, CaseIterable, ExpressibleByArgument, Sendable {
    case trace
    case debug
    case info
    case notice
    case warning
    case error
    case critical

    init?(argument: String) {
        self.init(rawValue: argument)
    }

    static var completion: CompletionKind {
        .list(allCases.map(\.rawValue))
    }

    var loggerLevel: Logger.Level {
        switch self {
        case .trace:
            return .trace
        case .debug:
            return .debug
        case .info:
            return .info
        case .notice:
            return .notice
        case .warning:
            return .warning
        case .error:
            return .error
        case .critical:
            return .critical
        }
    }

    var serviceLogLevel: LogLevel {
        switch self {
        case .trace:
            return .trace
        case .debug:
            return .debug
        case .info:
            return .info
        case .notice:
            return .notice
        case .warning:
            return .warning
        case .error:
            return .error
        case .critical:
            return .critical
        }
    }
}

@MainActor
private final class ServiceLauncher {
    private let serviceManager: ServiceManager
    private let httpService: HTTPService

    init(configuration: ServiceConfiguration) {
        self.serviceManager = ServiceManager(configuration: configuration)
        self.httpService = HTTPService(serviceManager: self.serviceManager, configuration: configuration)
    }

    func start() async throws {
        try await self.serviceManager.startService()
        try await self.httpService.start()
    }

    func stop() async {
        await self.httpService.stop()
        await self.serviceManager.stopService()
    }
}
