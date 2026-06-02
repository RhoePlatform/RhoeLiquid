import Foundation

/// Lightweight runtime profile used to tune cache and concurrency defaults.
public struct RuntimePerformanceProfile: Sendable {
    public enum ThermalState: String, Sendable {
        case nominal
        case fair
        case serious
        case critical
    }

    public let activeProcessorCount: Int
    public let physicalMemory: UInt64
    public let isLowPowerModeEnabled: Bool
    public let thermalState: ThermalState

    public init(
        activeProcessorCount: Int,
        physicalMemory: UInt64,
        isLowPowerModeEnabled: Bool,
        thermalState: ThermalState
    ) {
        self.activeProcessorCount = max(1, activeProcessorCount)
        self.physicalMemory = physicalMemory
        self.isLowPowerModeEnabled = isLowPowerModeEnabled
        self.thermalState = thermalState
    }

    public static var current: RuntimePerformanceProfile {
        #if os(WASI)
        return RuntimePerformanceProfile(
            activeProcessorCount: 1,
            physicalMemory: 512 * 1024 * 1024,
            isLowPowerModeEnabled: false,
            thermalState: .nominal
        )
        #elseif os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
        let processInfo = ProcessInfo.processInfo
        return RuntimePerformanceProfile(
            activeProcessorCount: processInfo.activeProcessorCount,
            physicalMemory: processInfo.physicalMemory,
            isLowPowerModeEnabled: currentLowPowerModeState(processInfo),
            thermalState: ThermalState(processInfo.thermalState)
        )
        #else
        let processInfo = ProcessInfo.processInfo
        return RuntimePerformanceProfile(
            activeProcessorCount: processInfo.activeProcessorCount,
            physicalMemory: processInfo.physicalMemory,
            isLowPowerModeEnabled: false,
            thermalState: .nominal
        )
        #endif
    }

    public var recommendedRendererPoolSize: Int {
        let base = min(activeProcessorCount, 12)

        if isLowPowerModeEnabled {
            return max(1, base / 2)
        }

        switch thermalState {
        case .critical, .serious:
            return max(1, base / 2)
        case .fair:
            return max(1, (base * 3) / 4)
        case .nominal:
            return max(1, base)
        }
    }

    public var recommendedCacheSizeBytes: Int {
        let gigabytes = physicalMemory / 1_073_741_824
        let baseMegabytes: Int

        switch gigabytes {
        case ..<8:
            baseMegabytes = 32
        case ..<16:
            baseMegabytes = 64
        case ..<32:
            baseMegabytes = 128
        default:
            baseMegabytes = 192
        }

        let adjustedMegabytes = isLowPowerModeEnabled ? max(16, baseMegabytes / 2) : baseMegabytes
        return adjustedMegabytes * 1_048_576
    }

    public var recommendedCacheEntries: Int {
        let gigabytes = physicalMemory / 1_073_741_824
        let baseEntries: Int

        switch gigabytes {
        case ..<8:
            baseEntries = 750
        case ..<16:
            baseEntries = 1_500
        case ..<32:
            baseEntries = 3_000
        default:
            baseEntries = 5_000
        }

        return isLowPowerModeEnabled ? max(500, baseEntries / 2) : baseEntries
    }

    #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    private static func currentLowPowerModeState(_ processInfo: ProcessInfo) -> Bool {
        if #available(macOS 12.0, iOS 9.0, tvOS 9.0, watchOS 9.0, visionOS 1.0, *) {
            return processInfo.isLowPowerModeEnabled
        }
        return false
    }
    #endif
}

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
private extension RuntimePerformanceProfile.ThermalState {
    init(_ thermalState: ProcessInfo.ThermalState) {
        switch thermalState {
        case .nominal:
            self = .nominal
        case .fair:
            self = .fair
        case .serious:
            self = .serious
        case .critical:
            self = .critical
        @unknown default:
            self = .serious
        }
    }
}
#endif // Apple platforms
