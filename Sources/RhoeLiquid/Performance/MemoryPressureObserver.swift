#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
import Dispatch
import Foundation
import LiquidCore

final class MemoryPressureObserver {
    private let source: any DispatchSourceMemoryPressure

    init(handler: @escaping @Sendable (CachePressureLevel) -> Void) {
        let source = DispatchSource.makeMemoryPressureSource(
            eventMask: [.warning, .critical],
            queue: DispatchQueue(label: "com.rhoeliquid.memory-pressure", qos: .utility)
        )
        self.source = source

        source.setEventHandler { [source] in
            let data = source.data
            if data.contains(.critical) {
                handler(.critical)
            } else if data.contains(.warning) {
                handler(.warning)
            }
        }

        source.resume()
    }

    deinit {
        source.cancel()
    }
}
#endif // Apple platforms
