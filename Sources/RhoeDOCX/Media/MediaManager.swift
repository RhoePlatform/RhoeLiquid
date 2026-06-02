//
//  MediaManager.swift
//  RhoeDOCX
//
//  Centralized management of media resources and their relationships in DOCX documents
//  Handles media embedding, relationship creation, and cross-references
//

import Foundation

/// Manages media resources within a DOCX document package
public actor MediaManager: Sendable {
    
    /// Registry of all media parts by ID
    private var mediaParts: [String: MediaPart] = [:]
    
    /// Media relationships mapping
    private var mediaRelationships: [String: MediaRelationship] = [:]
    
    /// Counter for generating unique media part names
    private var mediaCounter: Int = 1
    
    /// Counter for generating relationship IDs
    private var relationshipCounter: Int = 1
    
    public init() {}
    
    // MARK: - Media Registration
    
    /// Add a new media part to the document
    /// Returns the media part ID and relationship ID
    public func addMedia(_ data: Data, 
                        contentType: String,
                        filename: String? = nil) throws -> (mediaId: String, relationshipId: String) {
        
        // Validate media type
        guard MediaType(rawValue: contentType) != nil else {
            throw MediaError.unsupportedMediaType(contentType)
        }
        
        // Generate unique IDs
        let mediaId = generateMediaPartName(for: contentType)
        let relationshipId = generateRelationshipId()
        
        // Create media part
        let properties = try extractMediaProperties(from: data, contentType: contentType)
        let mediaPart = MediaPart(
            data: data,
            contentType: contentType,
            filename: filename,
            properties: properties,
            id: mediaId
        )
        
        // Create relationship
        let relationship = MediaRelationship(
            id: relationshipId,
            type: .media,
            target: "media/\(mediaId)",
            mediaType: contentType,
            mediaId: mediaId
        )
        
        // Register
        mediaParts[mediaId] = mediaPart
        mediaRelationships[relationshipId] = relationship
        
        return (mediaId: mediaId, relationshipId: relationshipId)
    }
    
    /// Get media part by ID
    public func getMediaPart(id: String) -> MediaPart? {
        return mediaParts[id]
    }
    
    /// Get relationship by ID
    public func getRelationship(id: String) -> MediaRelationship? {
        return mediaRelationships[id]
    }
    
    /// Get all media parts
    public func getAllMediaParts() -> [String: MediaPart] {
        return mediaParts
    }
    
    /// Get all relationships
    public func getAllRelationships() -> [String: MediaRelationship] {
        return mediaRelationships
    }
    
    // MARK: - Drawing Creation
    
    /// Create an inline drawing for the specified media
    public func createInlineDrawing(mediaId: String, 
                                   relationshipId: String,
                                   width: Int? = nil,
                                   height: Int? = nil,
                                   title: String? = nil,
                                   description: String? = nil) throws -> WMLDrawing {
        
        guard let mediaPart = mediaParts[mediaId] else {
            throw MediaError.mediaNotFound(mediaId)
        }
        
        // Determine dimensions
        let finalWidth = width ?? mediaPart.properties.dimensions?.width ?? 200
        let finalHeight = height ?? mediaPart.properties.dimensions?.height ?? 200
        
        // Create extents
        let extents = DrawingExtents.fromPixels(width: finalWidth, height: finalHeight)
        
        // Create media reference
        let mediaReference = MediaReference(
            relationshipId: relationshipId,
            mediaPartId: mediaId,
            title: title ?? mediaPart.filename,
            description: description
        )
        
        // Create graphic
        let graphic = DrawingGraphic(mediaReference: mediaReference)
        
        // Create inline drawing
        let inlineDrawing = InlineDrawing(graphic: graphic, extents: extents)
        
        return WMLDrawing(content: .inline(inlineDrawing))
    }
    
    /// Create an anchored drawing for the specified media
    public func createAnchoredDrawing(mediaId: String,
                                     relationshipId: String,
                                     position: DrawingPosition,
                                     wrapping: TextWrapping = .square,
                                     width: Int? = nil,
                                     height: Int? = nil,
                                     title: String? = nil,
                                     description: String? = nil) throws -> WMLDrawing {
        
        guard let mediaPart = mediaParts[mediaId] else {
            throw MediaError.mediaNotFound(mediaId)
        }
        
        // Determine dimensions
        let finalWidth = width ?? mediaPart.properties.dimensions?.width ?? 200
        let finalHeight = height ?? mediaPart.properties.dimensions?.height ?? 200
        
        // Create extents
        let extents = DrawingExtents.fromPixels(width: finalWidth, height: finalHeight)
        
        // Create media reference
        let mediaReference = MediaReference(
            relationshipId: relationshipId,
            mediaPartId: mediaId,
            title: title ?? mediaPart.filename,
            description: description
        )
        
        // Create graphic
        let graphic = DrawingGraphic(mediaReference: mediaReference)
        
        // Create anchor drawing
        let anchorDrawing = AnchorDrawing(
            graphic: graphic,
            extents: extents,
            position: position,
            wrapping: wrapping
        )
        
        return WMLDrawing(content: .anchor(anchorDrawing))
    }
    
    // MARK: - Utility Methods
    
    /// Generate a unique media part name
    private func generateMediaPartName(for contentType: String) -> String {
        let mediaType = MediaType(rawValue: contentType) ?? .jpeg
        let name = "image\(mediaCounter).\(mediaType.fileExtension)"
        mediaCounter += 1
        return name
    }
    
    /// Generate a unique relationship ID
    private func generateRelationshipId() -> String {
        let id = "rId\(relationshipCounter)"
        relationshipCounter += 1
        return id
    }
    
    /// Extract media properties from data
    private func extractMediaProperties(from data: Data, contentType: String) throws -> MediaProperties {
        
        guard let mediaType = MediaType(rawValue: contentType) else {
            throw MediaError.unsupportedMediaType(contentType)
        }
        
        // For images, try to extract dimensions
        if mediaType.isImage {
            let dimensions = try extractImageDimensions(from: data, mediaType: mediaType)
            return MediaProperties(
                dimensions: dimensions,
                colorSpace: nil,  // Could be extracted in future
                compression: nil,
                resolution: nil,
                metadata: [:]
            )
        }
        
        // For other media types, return basic properties
        return MediaProperties()
    }
    
    /// Extract image dimensions from data
    private func extractImageDimensions(from data: Data, mediaType: MediaType) throws -> MediaDimensions? {
        
        // Basic image dimension extraction for common formats
        switch mediaType {
        case .jpeg:
            return try extractJPEGDimensions(from: data)
        case .png:
            return try extractPNGDimensions(from: data)
        case .gif:
            return try extractGIFDimensions(from: data)
        case .bmp:
            return try extractBMPDimensions(from: data)
        default:
            // For unsupported formats, return nil (dimensions unknown)
            return nil
        }
    }
    
    /// Extract JPEG dimensions
    private func extractJPEGDimensions(from data: Data) throws -> MediaDimensions? {
        guard data.count > 10 else { return nil }
        
        // Simple JPEG dimension extraction
        // Look for SOF (Start of Frame) markers
        var index = 2 // Skip JPEG signature
        
        while index < data.count - 8 {
            if data[index] == 0xFF {
                let marker = data[index + 1]
                
                // SOF markers (0xC0-0xCF except 0xC4, 0xC8, 0xCC)
                if (marker >= 0xC0 && marker <= 0xC3) || 
                   (marker >= 0xC5 && marker <= 0xC7) ||
                   (marker >= 0xC9 && marker <= 0xCB) ||
                   (marker >= 0xCD && marker <= 0xCF) {
                    
                    // Height at offset 5-6, Width at offset 7-8 (big-endian)
                    let height = Int(data[index + 5]) << 8 | Int(data[index + 6])
                    let width = Int(data[index + 7]) << 8 | Int(data[index + 8])
                    
                    if width > 0 && height > 0 {
                        return MediaDimensions(width: width, height: height)
                    }
                }
                
                // Skip to next segment
                let segmentLength = Int(data[index + 2]) << 8 | Int(data[index + 3])
                index += 2 + segmentLength
            } else {
                index += 1
            }
        }
        
        return nil
    }
    
    /// Extract PNG dimensions
    private func extractPNGDimensions(from data: Data) throws -> MediaDimensions? {
        guard data.count > 24 else { return nil }
        
        // PNG signature: 89 50 4E 47 0D 0A 1A 0A
        // IHDR chunk starts at byte 8
        // Width: bytes 16-19 (big-endian)
        // Height: bytes 20-23 (big-endian)
        
        if data.subdata(in: 0..<8) == Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) {
            let width = data.withUnsafeBytes { bytes in
                let ptr = bytes.bindMemory(to: UInt32.self)
                return Int(UInt32(bigEndian: ptr[4]))
            }
            
            let height = data.withUnsafeBytes { bytes in
                let ptr = bytes.bindMemory(to: UInt32.self)
                return Int(UInt32(bigEndian: ptr[5]))
            }
            
            if width > 0 && height > 0 {
                return MediaDimensions(width: width, height: height)
            }
        }
        
        return nil
    }
    
    /// Extract GIF dimensions
    private func extractGIFDimensions(from data: Data) throws -> MediaDimensions? {
        guard data.count > 10 else { return nil }
        
        // GIF signature: "GIF87a" or "GIF89a"
        // Width: bytes 6-7 (little-endian)
        // Height: bytes 8-9 (little-endian)
        
        if data.subdata(in: 0..<6) == "GIF87a".data(using: .ascii) ||
           data.subdata(in: 0..<6) == "GIF89a".data(using: .ascii) {
            
            let width = Int(data[6]) | (Int(data[7]) << 8)
            let height = Int(data[8]) | (Int(data[9]) << 8)
            
            if width > 0 && height > 0 {
                return MediaDimensions(width: width, height: height)
            }
        }
        
        return nil
    }
    
    /// Extract BMP dimensions  
    private func extractBMPDimensions(from data: Data) throws -> MediaDimensions? {
        guard data.count > 26 else { return nil }
        
        // BMP signature: "BM"
        // Width: bytes 18-21 (little-endian)
        // Height: bytes 22-25 (little-endian)
        
        if data.subdata(in: 0..<2) == "BM".data(using: .ascii) {
            let width = data.withUnsafeBytes { bytes in
                let ptr = bytes.bindMemory(to: UInt32.self)
                return Int(UInt32(littleEndian: ptr[4]))  // Offset 18 / 4 = 4
            }
            
            let height = data.withUnsafeBytes { bytes in
                let ptr = bytes.bindMemory(to: UInt32.self)
                return Int(UInt32(littleEndian: ptr[5]))  // Offset 22 / 4 = 5  
            }
            
            if width > 0 && abs(height) > 0 {  // Height can be negative for top-down bitmaps
                return MediaDimensions(width: width, height: abs(height))
            }
        }
        
        return nil
    }
    
    // MARK: - Statistics
    
    /// Get media usage statistics
    public func getStatistics() -> MediaStatistics {
        let totalSize = mediaParts.values.reduce(0) { $0 + $1.data.count }
        let typeBreakdown = Dictionary(grouping: mediaParts.values) { $0.contentType }
            .mapValues { $0.count }
        
        return MediaStatistics(
            totalMediaParts: mediaParts.count,
            totalDataSize: totalSize,
            typeBreakdown: typeBreakdown,
            relationshipCount: mediaRelationships.count
        )
    }
}

// MARK: - Supporting Types

/// Media relationship information
public struct MediaRelationship: Sendable {
    public let id: String
    public let type: RelationshipType
    public let target: String
    public let mediaType: String
    public let mediaId: String
    
    public init(id: String, type: RelationshipType, target: String, mediaType: String, mediaId: String) {
        self.id = id
        self.type = type
        self.target = target
        self.mediaType = mediaType
        self.mediaId = mediaId
    }
}

/// Relationship types for media
public enum RelationshipType: String, Sendable {
    case media = "http://schemas.openxmlformats.org/officeDocument/2006/relationships/image"
    case chart = "http://schemas.openxmlformats.org/officeDocument/2006/relationships/chart"
    case diagram = "http://schemas.openxmlformats.org/officeDocument/2006/relationships/diagram"
}

/// Media usage statistics
public struct MediaStatistics: Sendable {
    public let totalMediaParts: Int
    public let totalDataSize: Int
    public let typeBreakdown: [String: Int]
    public let relationshipCount: Int
    
    /// Human-readable total size
    public var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(totalDataSize))
    }
}

/// Media-related errors
public enum MediaError: Error, Sendable {
    case unsupportedMediaType(String)
    case mediaNotFound(String)
    case invalidImageData(String)
    case relationshipNotFound(String)
    case dimensionExtractionFailed(String)
}

extension MediaError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unsupportedMediaType(let type):
            return "Unsupported media type: \(type)"
        case .mediaNotFound(let id):
            return "Media not found: \(id)"
        case .invalidImageData(let reason):
            return "Invalid image data: \(reason)"
        case .relationshipNotFound(let id):
            return "Relationship not found: \(id)"
        case .dimensionExtractionFailed(let reason):
            return "Failed to extract dimensions: \(reason)"
        }
    }
}