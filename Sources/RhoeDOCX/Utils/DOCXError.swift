//
//  DOCXError.swift
//  RhoeDOCX
//
//  Error types for DOCX processing
//

import Foundation

/// Errors that can occur during DOCX processing
public enum DOCXError: Error, Sendable {
    case invalidPackage(String)
    case missingPart(String)
    case xmlParseError(String, Error?)
    case xmlGenerationError(String)
    case encodingError(String)
    case invalidStructure(String)
    case unsupportedFeature(String)
    case ioError(String, Error?)
}

// MARK: - Error Descriptions

extension DOCXError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidPackage(let message):
            return "Invalid DOCX package: \(message)"
            
        case .missingPart(let part):
            return "Missing required part: \(part)"
            
        case .xmlParseError(let message, let underlying):
            if let underlying = underlying {
                return "XML parse error: \(message) - \(underlying.localizedDescription)"
            }
            return "XML parse error: \(message)"
            
        case .xmlGenerationError(let message):
            return "XML generation error: \(message)"
            
        case .encodingError(let message):
            return "Encoding error: \(message)"
            
        case .invalidStructure(let message):
            return "Invalid document structure: \(message)"
            
        case .unsupportedFeature(let feature):
            return "Unsupported feature: \(feature)"
            
        case .ioError(let message, let underlying):
            if let underlying = underlying {
                return "I/O error: \(message) - \(underlying.localizedDescription)"
            }
            return "I/O error: \(message)"
        }
    }
}