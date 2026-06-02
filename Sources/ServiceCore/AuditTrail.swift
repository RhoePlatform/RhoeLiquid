//
//  AuditTrail.swift
//  ServiceCore
//
//  Created as part of RhoeLiquid
//  A high-performance Swift implementation of the Liquid template language
//

import CryptoKit
import Foundation

// MARK: - Audit Types

/// A record of a rendering operation for compliance and debugging.
public struct AuditEntry: Sendable, Codable {
    public let timestamp: Date
    public let operation: AuditOperation
    public let templateHash: String
    public let contextHash: String
    public let outputHash: String?
    public let durationMs: Double
    public let stageId: String?
    public let pipelineId: String?
    public let success: Bool

    public init(
        timestamp: Date = Date(),
        operation: AuditOperation,
        templateHash: String,
        contextHash: String,
        outputHash: String? = nil,
        durationMs: Double,
        stageId: String? = nil,
        pipelineId: String? = nil,
        success: Bool
    ) {
        self.timestamp = timestamp
        self.operation = operation
        self.templateHash = templateHash
        self.contextHash = contextHash
        self.outputHash = outputHash
        self.durationMs = durationMs
        self.stageId = stageId
        self.pipelineId = pipelineId
        self.success = success
    }
}

/// The type of operation that was audited.
public enum AuditOperation: String, Sendable, Codable {
    case render
    case renderDocx = "render_docx"
    case batch
    case pipeline
    case pipelineStage = "pipeline_stage"
}

// MARK: - Audit Store

/// Thread-safe, append-only audit log for rendering operations.
///
/// Persists entries to a JSONL file (one JSON object per line) for efficient
/// append and streaming reads. Keeps a bounded in-memory buffer for fast queries.
public actor AuditStore {
    private let storageURL: URL?
    private var recentEntries: [AuditEntry] = []
    private let maxInMemory: Int

    public init(storageDirectory: URL? = nil, maxInMemory: Int = 500) {
        self.storageURL = storageDirectory?.appendingPathComponent("audit.jsonl")
        self.maxInMemory = maxInMemory
    }

    /// Record a new audit entry.
    public func record(_ entry: AuditEntry) {
        recentEntries.append(entry)
        if recentEntries.count > maxInMemory {
            recentEntries.removeFirst(recentEntries.count - maxInMemory)
        }

        // Persist to disk (append-only JSONL)
        if let url = storageURL {
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(entry)
                let line = String(data: data, encoding: .utf8)! + "\n"
                if FileManager.default.fileExists(atPath: url.path) {
                    let handle = try FileHandle(forWritingTo: url)
                    defer { try? handle.close() }
                    handle.seekToEndOfFile()
                    handle.write(line.data(using: .utf8)!)
                } else {
                    try line.write(to: url, atomically: true, encoding: .utf8)
                }
            } catch {
                // Audit persistence is best-effort; log but don't fail the operation.
            }
        }
    }

    /// Retrieve recent audit entries, optionally filtered by operation type.
    public func recentEntries(operation: AuditOperation? = nil, limit: Int = 100) -> [AuditEntry] {
        var entries = recentEntries
        if let op = operation {
            entries = entries.filter { $0.operation == op }
        }
        return Array(entries.suffix(limit))
    }

    /// Create a SHA-256 hash of a string for audit fingerprinting.
    public static func hash(_ string: String) -> String {
        let digest = SHA256.hash(data: Data(string.utf8))
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
}
