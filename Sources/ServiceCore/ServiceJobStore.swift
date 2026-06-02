import Foundation

private struct StoredJobsSnapshot: Codable {
    let jobs: [UUID: JobHandle]
}

public actor ServiceJobStore {
    private var jobs: [UUID: JobHandle]
    private let storageURL: URL
    private let retentionInterval: TimeInterval
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(storageDirectory: URL, retentionInterval: TimeInterval) {
        let storageURL = storageDirectory.appendingPathComponent("jobs.json")
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        try? FileManager.default.createDirectory(
            at: storageDirectory,
            withIntermediateDirectories: true
        )

        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601

        self.storageURL = storageURL
        self.retentionInterval = retentionInterval
        self.encoder = encoder
        self.decoder = decoder
        let now = Date()
        let recoveredJobs = Self.recover(Self.loadJobs(from: storageURL, decoder: decoder), now: now)
        self.jobs = Self.cleanupExpiredJobs(recoveredJobs, now: now)
        Self.persist(self.jobs, to: storageURL, encoder: encoder)
    }

    public func create(kind: ServiceJobKind, diagnostics: JobDiagnostics = JobDiagnostics()) -> JobHandle {
        self.cleanupExpiredJobs(now: Date())

        let now = Date()
        let handle = JobHandle(
            kind: kind,
            status: .queued,
            createdAt: now,
            updatedAt: now,
            expiresAt: now.addingTimeInterval(self.retentionInterval),
            progress: JobProgress(fractionCompleted: 0, currentStep: "Queued", completedSteps: 0, totalSteps: 1),
            diagnostics: diagnostics
        )
        self.jobs[handle.id] = handle
        self.persist()
        return handle
    }

    public func markRunning(
        id: UUID,
        progress: JobProgress = JobProgress(
            fractionCompleted: 0.1,
            currentStep: "Running",
            completedSteps: 0,
            totalSteps: 1
        )
    ) -> JobHandle? {
        self.cleanupExpiredJobs(now: Date())
        guard let job = self.jobs[id], !job.status.isTerminal else {
            return self.jobs[id]
        }

        let updated = JobHandle(
            id: job.id,
            kind: job.kind,
            status: .running,
            createdAt: job.createdAt,
            updatedAt: Date(),
            expiresAt: job.expiresAt,
            progress: progress,
            payload: job.payload,
            diagnostics: job.diagnostics,
            error: job.error
        )
        self.jobs[id] = updated
        self.persist()
        return updated
    }

    public func updateProgress(id: UUID, progress: JobProgress) -> JobHandle? {
        self.cleanupExpiredJobs(now: Date())
        guard let job = self.jobs[id], !job.status.isTerminal else {
            return self.jobs[id]
        }

        let updated = JobHandle(
            id: job.id,
            kind: job.kind,
            status: job.status,
            createdAt: job.createdAt,
            updatedAt: Date(),
            expiresAt: job.expiresAt,
            progress: progress,
            payload: job.payload,
            diagnostics: job.diagnostics,
            error: job.error
        )
        self.jobs[id] = updated
        self.persist()
        return updated
    }

    public func complete(id: UUID, payload: JobPayload, diagnostics: JobDiagnostics) -> JobHandle? {
        self.cleanupExpiredJobs(now: Date())
        guard let job = self.jobs[id], !job.status.isTerminal else {
            return self.jobs[id]
        }

        let updated = JobHandle(
            id: job.id,
            kind: job.kind,
            status: .completed,
            createdAt: job.createdAt,
            updatedAt: Date(),
            expiresAt: job.expiresAt,
            progress: JobProgress(fractionCompleted: 1.0, currentStep: "Completed", completedSteps: 1, totalSteps: 1),
            payload: payload,
            diagnostics: diagnostics,
            error: nil
        )
        self.jobs[id] = updated
        self.persist()
        return updated
    }

    public func fail(id: UUID, error: String, diagnostics: JobDiagnostics) -> JobHandle? {
        self.cleanupExpiredJobs(now: Date())
        guard let job = self.jobs[id], !job.status.isTerminal else {
            return self.jobs[id]
        }

        let updated = JobHandle(
            id: job.id,
            kind: job.kind,
            status: .failed,
            createdAt: job.createdAt,
            updatedAt: Date(),
            expiresAt: job.expiresAt,
            progress: JobProgress(
                fractionCompleted: job.progress.fractionCompleted,
                currentStep: "Failed",
                completedSteps: job.progress.completedSteps,
                totalSteps: job.progress.totalSteps
            ),
            payload: job.payload,
            diagnostics: diagnostics,
            error: error
        )
        self.jobs[id] = updated
        self.persist()
        return updated
    }

    public func cancel(id: UUID) -> JobHandle? {
        self.cleanupExpiredJobs(now: Date())
        guard let job = self.jobs[id], !job.status.isTerminal else {
            return self.jobs[id]
        }

        let updated = JobHandle(
            id: job.id,
            kind: job.kind,
            status: .cancelled,
            createdAt: job.createdAt,
            updatedAt: Date(),
            expiresAt: job.expiresAt,
            progress: JobProgress(
                fractionCompleted: job.progress.fractionCompleted,
                currentStep: "Cancelled",
                completedSteps: job.progress.completedSteps,
                totalSteps: job.progress.totalSteps
            ),
            payload: job.payload,
            diagnostics: job.diagnostics,
            error: nil
        )
        self.jobs[id] = updated
        self.persist()
        return updated
    }

    public func job(id: UUID) -> JobHandle? {
        self.cleanupExpiredJobs(now: Date())
        return self.jobs[id]
    }

    private func cleanupExpiredJobs(now: Date) {
        self.jobs = Self.cleanupExpiredJobs(self.jobs, now: now)
    }

    private func persist() {
        Self.persist(self.jobs, to: self.storageURL, encoder: self.encoder)
    }

    private static func cleanupExpiredJobs(_ jobs: [UUID: JobHandle], now: Date) -> [UUID: JobHandle] {
        jobs.filter { _, handle in
            handle.expiresAt > now
        }
    }

    private static func persist(_ jobs: [UUID: JobHandle], to url: URL, encoder: JSONEncoder) {
        let snapshot = StoredJobsSnapshot(jobs: jobs)
        guard let data = try? encoder.encode(snapshot) else {
            return
        }
        try? data.write(to: url, options: [.atomic])
    }

    private static func loadJobs(from url: URL, decoder: JSONDecoder) -> [UUID: JobHandle] {
        guard let data = try? Data(contentsOf: url) else {
            return [:]
        }

        if let snapshot = try? decoder.decode(StoredJobsSnapshot.self, from: data) {
            return snapshot.jobs
        }

        return [:]
    }

    private static func recover(_ jobs: [UUID: JobHandle], now: Date) -> [UUID: JobHandle] {
        Dictionary(uniqueKeysWithValues: jobs.map { id, handle in
            guard !handle.status.isTerminal else {
                return (id, handle)
            }

            let recovered = JobHandle(
                id: handle.id,
                kind: handle.kind,
                status: .failed,
                createdAt: handle.createdAt,
                updatedAt: now,
                expiresAt: handle.expiresAt,
                progress: JobProgress(
                    fractionCompleted: handle.progress.fractionCompleted,
                    currentStep: "Interrupted by service restart",
                    completedSteps: handle.progress.completedSteps,
                    totalSteps: handle.progress.totalSteps
                ),
                payload: handle.payload,
                diagnostics: JobDiagnostics(
                    warnings: handle.diagnostics.warnings,
                    errors: handle.diagnostics.errors + ["Service restarted before the async job completed."],
                    templateAnalysis: handle.diagnostics.templateAnalysis,
                    docxAnalysis: handle.diagnostics.docxAnalysis
                ),
                error: "Service restarted before the async job completed."
            )
            return (id, recovered)
        })
    }
}
