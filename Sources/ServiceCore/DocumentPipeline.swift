//
//  DocumentPipeline.swift
//  ServiceCore
//
//  Created as part of RhoeLiquid
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation

// MARK: - Pipeline Definition

/// A document pipeline orchestrates multi-stage, multi-output rendering.
/// Each stage transforms data into a document, with shared context flowing between stages.
public struct PipelineDefinition: Sendable, Codable {
    /// Unique identifier for this pipeline (e.g., "invoice-suite").
    public let id: String
    /// Ordered execution stages.
    public let stages: [PipelineStage]
    /// Context data available to all stages (merged with per-stage overrides).
    public let sharedContext: [String: String]?

    public init(id: String, stages: [PipelineStage], sharedContext: [String: String]? = nil) {
        self.id = id
        self.stages = stages
        self.sharedContext = sharedContext
    }
}

/// A single stage in a document pipeline.
public struct PipelineStage: Sendable, Codable {
    /// Unique stage identifier (e.g., "render-invoice").
    public let id: String
    /// Liquid template content.
    public let template: String
    /// Output format for this stage.
    public let outputFormat: PipelineOutputFormat
    /// Per-stage context additions (merged on top of shared context).
    public let contextOverrides: [String: String]?
    /// Optional Liquid condition expression — stage is skipped if this evaluates to falsy.
    public let condition: String?
    /// IDs of stages that must complete before this one starts.
    public let dependsOn: [String]?

    public init(
        id: String,
        template: String,
        outputFormat: PipelineOutputFormat = .text,
        contextOverrides: [String: String]? = nil,
        condition: String? = nil,
        dependsOn: [String]? = nil
    ) {
        self.id = id
        self.template = template
        self.outputFormat = outputFormat
        self.contextOverrides = contextOverrides
        self.condition = condition
        self.dependsOn = dependsOn
    }
}

/// Supported output formats for pipeline stages.
public enum PipelineOutputFormat: String, Sendable, Codable {
    case text
    case html
    case json
}

// MARK: - Pipeline Results

/// The result of executing a complete document pipeline.
public struct PipelineResult: Sendable, Codable {
    public let pipelineId: String
    public let stageResults: [StageResult]
    public let totalProcessingTime: TimeInterval
    public let auditTrail: [AuditEntry]

    public init(pipelineId: String, stageResults: [StageResult], totalProcessingTime: TimeInterval, auditTrail: [AuditEntry]) {
        self.pipelineId = pipelineId
        self.stageResults = stageResults
        self.totalProcessingTime = totalProcessingTime
        self.auditTrail = auditTrail
    }
}

/// The result of a single pipeline stage.
public struct StageResult: Sendable, Codable {
    public let stageId: String
    public let success: Bool
    public let output: String?
    public let error: String?
    public let processingTime: TimeInterval
    public let skipped: Bool

    public init(stageId: String, success: Bool, output: String? = nil, error: String? = nil,
                processingTime: TimeInterval = 0, skipped: Bool = false) {
        self.stageId = stageId
        self.success = success
        self.output = output
        self.error = error
        self.processingTime = processingTime
        self.skipped = skipped
    }
}
