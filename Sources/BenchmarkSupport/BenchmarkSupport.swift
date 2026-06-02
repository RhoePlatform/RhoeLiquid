import Foundation

public struct BenchmarkPlan: Sendable {
    public let iterations: Int
    public let warmupIterations: Int
    public let trials: Int

    public init(
        iterations: Int,
        warmupIterations: Int = 5,
        trials: Int = 5
    ) {
        self.iterations = max(1, iterations)
        self.warmupIterations = max(0, warmupIterations)
        self.trials = max(1, trials)
    }
}

public struct BenchmarkSummary: Sendable {
    public let samplesMicroseconds: [Double]

    public init(samplesMicroseconds: [Double]) {
        self.samplesMicroseconds = samplesMicroseconds
    }

    public var medianMicroseconds: Double {
        let sorted = samplesMicroseconds.sorted()
        let middle = sorted.count / 2
        if sorted.count.isMultiple(of: 2) {
            return (sorted[middle - 1] + sorted[middle]) / 2
        }
        return sorted[middle]
    }

    public var meanMicroseconds: Double {
        samplesMicroseconds.reduce(0, +) / Double(samplesMicroseconds.count)
    }

    public var standardDeviationMicroseconds: Double {
        guard samplesMicroseconds.count > 1 else { return 0 }

        let mean = meanMicroseconds
        let variance = samplesMicroseconds.reduce(0) { partial, sample in
            let delta = sample - mean
            return partial + (delta * delta)
        } / Double(samplesMicroseconds.count)

        return variance.squareRoot()
    }

    public var minimumMicroseconds: Double {
        samplesMicroseconds.min() ?? 0
    }

    public var maximumMicroseconds: Double {
        samplesMicroseconds.max() ?? 0
    }

    public var percentile95Microseconds: Double {
        let sorted = samplesMicroseconds.sorted()
        guard !sorted.isEmpty else { return 0 }
        let index = min(Int(Double(sorted.count) * 0.95), sorted.count - 1)
        return sorted[index]
    }

    public func formatted(label: String, iterations: Int) -> String {
        let median = String(format: "%.2f", medianMicroseconds)
        let mean = String(format: "%.2f", meanMicroseconds)
        let p95 = String(format: "%.2f", percentile95Microseconds)
        let stdev = String(format: "%.2f", standardDeviationMicroseconds)
        let minimum = String(format: "%.2f", minimumMicroseconds)
        let maximum = String(format: "%.2f", maximumMicroseconds)

        return "\(label): \(iterations) iterations/trial, median \(median)us, mean \(mean)us, p95 \(p95)us, stdev \(stdev)us, range \(minimum)-\(maximum)us"
    }
}

public enum BenchmarkRunner {
    public static func measure(
        plan: BenchmarkPlan,
        operation: () throws -> Void
    ) rethrows -> BenchmarkSummary {
        for _ in 0..<plan.warmupIterations {
            try operation()
        }

        let clock = ContinuousClock()
        var samples: [Double] = []
        samples.reserveCapacity(plan.trials)

        for _ in 0..<plan.trials {
            let start = clock.now
            for _ in 0..<plan.iterations {
                try operation()
            }
            let elapsed = start.duration(to: clock.now)
            samples.append(averageMicroseconds(from: elapsed, iterations: plan.iterations))
        }

        return BenchmarkSummary(samplesMicroseconds: samples)
    }

    public static func measure(
        plan: BenchmarkPlan,
        operation: () async throws -> Void
    ) async rethrows -> BenchmarkSummary {
        for _ in 0..<plan.warmupIterations {
            try await operation()
        }

        let clock = ContinuousClock()
        var samples: [Double] = []
        samples.reserveCapacity(plan.trials)

        for _ in 0..<plan.trials {
            let start = clock.now
            for _ in 0..<plan.iterations {
                try await operation()
            }
            let elapsed = start.duration(to: clock.now)
            samples.append(averageMicroseconds(from: elapsed, iterations: plan.iterations))
        }

        return BenchmarkSummary(samplesMicroseconds: samples)
    }

    private static func averageMicroseconds(from duration: Duration, iterations: Int) -> Double {
        let totalNanoseconds = Double(duration.components.seconds) * 1_000_000_000
            + Double(duration.components.attoseconds) / 1_000_000_000
        return totalNanoseconds / Double(iterations) / 1_000
    }
}
