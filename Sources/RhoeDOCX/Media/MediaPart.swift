//
//  MediaPart.swift
//  RhoeDOCX
//
//  Media and image handling for DOCX documents
//  Supports images, audio, video, and other media embedded in documents
//

import Foundation

/// Media Part for handling embedded media in DOCX documents
public struct MediaPart: Sendable, DocumentPart {
    
    /// Media content data
    public let data: Data
    
    /// Content type (image/jpeg, image/png, etc.)
    public let contentType: String
    
    /// Original filename if available
    public let filename: String?
    
    /// Media format specific properties
    public let properties: MediaProperties
    
    /// Unique identifier for this media part
    public let id: String
    
    public init(data: Data, 
                contentType: String, 
                filename: String? = nil, 
                properties: MediaProperties = MediaProperties(),
                id: String = UUID().uuidString) {
        self.data = data
        self.contentType = contentType
        self.filename = filename
        self.properties = properties
        self.id = id
    }
}

/// Media Properties for format-specific metadata
public struct MediaProperties: Sendable {
    
    /// Image dimensions (for image media)
    public let dimensions: MediaDimensions?
    
    /// Color space information
    public let colorSpace: String?
    
    /// Compression information
    public let compression: String?
    
    /// DPI/Resolution information
    public let resolution: MediaResolution?
    
    /// Additional metadata
    public let metadata: [String: String]
    
    public init(dimensions: MediaDimensions? = nil,
                colorSpace: String? = nil,
                compression: String? = nil,
                resolution: MediaResolution? = nil,
                metadata: [String: String] = [:]) {
        self.dimensions = dimensions
        self.colorSpace = colorSpace
        self.compression = compression
        self.resolution = resolution
        self.metadata = metadata
    }
}

/// Media dimensions in pixels
public struct MediaDimensions: Sendable {
    public let width: Int
    public let height: Int
    public let aspectRatio: Double
    
    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
        self.aspectRatio = Double(width) / Double(height)
    }
}

/// Media resolution information
public struct MediaResolution: Sendable {
    public let horizontal: Double  // DPI
    public let vertical: Double    // DPI
    public let unit: ResolutionUnit
    
    public init(horizontal: Double, vertical: Double, unit: ResolutionUnit = .dpi) {
        self.horizontal = horizontal
        self.vertical = vertical
        self.unit = unit
    }
}

/// Resolution unit
public enum ResolutionUnit: String, Sendable, CaseIterable {
    case dpi = "dpi"
    case ppi = "ppi"
    case dpcm = "dpcm"
}

/// Supported media types in DOCX documents
public enum MediaType: String, Sendable, CaseIterable {
    
    // Images
    case jpeg = "image/jpeg"
    case png = "image/png"
    case gif = "image/gif"
    case bmp = "image/bmp"
    case tiff = "image/tiff"
    case svg = "image/svg+xml"
    case emf = "image/x-emf"
    case wmf = "image/x-wmf"
    
    // Audio
    case mp3 = "audio/mpeg"
    case wav = "audio/wav"
    case aiff = "audio/aiff"
    
    // Video
    case mp4 = "video/mp4"
    case avi = "video/avi"
    case wmv = "video/x-ms-wmv"
    
    // Documents
    case pdf = "application/pdf"
    
    /// File extension for this media type
    public var fileExtension: String {
        switch self {
        case .jpeg: return "jpg"
        case .png: return "png"
        case .gif: return "gif"
        case .bmp: return "bmp"
        case .tiff: return "tiff"
        case .svg: return "svg"
        case .emf: return "emf"
        case .wmf: return "wmf"
        case .mp3: return "mp3"
        case .wav: return "wav"
        case .aiff: return "aiff"
        case .mp4: return "mp4"
        case .avi: return "avi"
        case .wmv: return "wmv"
        case .pdf: return "pdf"
        }
    }
    
    /// Whether this media type represents an image
    public var isImage: Bool {
        return rawValue.hasPrefix("image/")
    }
    
    /// Whether this media type represents audio
    public var isAudio: Bool {
        return rawValue.hasPrefix("audio/")
    }
    
    /// Whether this media type represents video
    public var isVideo: Bool {
        return rawValue.hasPrefix("video/")
    }
}

// MARK: - Drawing Support (WordprocessingML Drawing)

/// Drawing element for embedding media in WordprocessingML
public struct WMLDrawing: Sendable {
    
    /// Drawing content (inline or anchor)
    public let content: DrawingContent
    
    /// Distance from text
    public let distanceFromText: DrawingMargins?
    
    /// Layout properties
    public let layout: DrawingLayout?
    
    /// Unique drawing ID
    public let drawingId: String
    
    public init(content: DrawingContent,
                distanceFromText: DrawingMargins? = nil,
                layout: DrawingLayout? = nil,
                drawingId: String = UUID().uuidString) {
        self.content = content
        self.distanceFromText = distanceFromText
        self.layout = layout
        self.drawingId = drawingId
    }
}

/// Drawing content types
public enum DrawingContent: Sendable {
    case inline(InlineDrawing)
    case anchor(AnchorDrawing)
}

/// Inline drawing (flows with text)
public struct InlineDrawing: Sendable {
    public let graphic: DrawingGraphic
    public let extents: DrawingExtents
    
    public init(graphic: DrawingGraphic, extents: DrawingExtents) {
        self.graphic = graphic
        self.extents = extents
    }
}

/// Anchor drawing (positioned absolutely)
public struct AnchorDrawing: Sendable {
    public let graphic: DrawingGraphic
    public let extents: DrawingExtents
    public let position: DrawingPosition
    public let wrapping: TextWrapping
    
    public init(graphic: DrawingGraphic, 
                extents: DrawingExtents,
                position: DrawingPosition,
                wrapping: TextWrapping = .square) {
        self.graphic = graphic
        self.extents = extents
        self.position = position
        self.wrapping = wrapping
    }
}

/// Drawing graphic (reference to actual media)
public struct DrawingGraphic: Sendable {
    public let mediaReference: MediaReference
    public let transform: DrawingTransform?
    public let effects: [DrawingEffect]
    
    public init(mediaReference: MediaReference,
                transform: DrawingTransform? = nil,
                effects: [DrawingEffect] = []) {
        self.mediaReference = mediaReference
        self.transform = transform
        self.effects = effects
    }
}

/// Reference to media part
public struct MediaReference: Sendable {
    public let relationshipId: String
    public let mediaPartId: String
    public let title: String?
    public let description: String?
    
    public init(relationshipId: String,
                mediaPartId: String,
                title: String? = nil,
                description: String? = nil) {
        self.relationshipId = relationshipId
        self.mediaPartId = mediaPartId
        self.title = title
        self.description = description
    }
}

/// Drawing dimensions and positioning
public struct DrawingExtents: Sendable {
    public let width: EMU  // English Metric Units
    public let height: EMU
    
    public init(width: EMU, height: EMU) {
        self.width = width
        self.height = height
    }
    
    /// Create extents from pixel dimensions at 96 DPI
    public static func fromPixels(width: Int, height: Int, dpi: Double = 96.0) -> DrawingExtents {
        let emuPerInch: Double = 914400
        let widthEMU = EMU(Double(width) / dpi * emuPerInch)
        let heightEMU = EMU(Double(height) / dpi * emuPerInch)
        return DrawingExtents(width: widthEMU, height: heightEMU)
    }
}

/// Drawing position for anchored drawings
public struct DrawingPosition: Sendable {
    public let horizontal: HorizontalPosition
    public let vertical: VerticalPosition
    
    public init(horizontal: HorizontalPosition, vertical: VerticalPosition) {
        self.horizontal = horizontal
        self.vertical = vertical
    }
}

/// Horizontal positioning
public struct HorizontalPosition: Sendable {
    public let alignment: HorizontalAlignment?
    public let offset: EMU?
    public let relativeTo: HorizontalRelativeTo
    
    public init(alignment: HorizontalAlignment? = nil, 
                offset: EMU? = nil,
                relativeTo: HorizontalRelativeTo) {
        self.alignment = alignment
        self.offset = offset
        self.relativeTo = relativeTo
    }
}

/// Vertical positioning
public struct VerticalPosition: Sendable {
    public let alignment: VerticalAlignment?
    public let offset: EMU?
    public let relativeTo: VerticalRelativeTo
    
    public init(alignment: VerticalAlignment? = nil,
                offset: EMU? = nil,
                relativeTo: VerticalRelativeTo) {
        self.alignment = alignment
        self.offset = offset
        self.relativeTo = relativeTo
    }
}

/// Drawing margins (distance from text)
public struct DrawingMargins: Sendable {
    public let top: EMU
    public let right: EMU
    public let bottom: EMU
    public let left: EMU
    
    public init(top: EMU = 0, right: EMU = 0, bottom: EMU = 0, left: EMU = 0) {
        self.top = top
        self.right = right
        self.bottom = bottom
        self.left = left
    }
    
    public init(all: EMU) {
        self.init(top: all, right: all, bottom: all, left: all)
    }
}

/// Drawing layout properties
public struct DrawingLayout: Sendable {
    public let behindDocument: Bool
    public let locked: Bool
    public let allowOverlap: Bool
    
    public init(behindDocument: Bool = false, 
                locked: Bool = false,
                allowOverlap: Bool = true) {
        self.behindDocument = behindDocument
        self.locked = locked
        self.allowOverlap = allowOverlap
    }
}

// MARK: - Enumerations

/// Horizontal alignment options
public enum HorizontalAlignment: String, Sendable, CaseIterable {
    case left = "left"
    case center = "center"
    case right = "right"
    case inside = "inside"
    case outside = "outside"
}

/// Vertical alignment options
public enum VerticalAlignment: String, Sendable, CaseIterable {
    case top = "top"
    case center = "center"
    case bottom = "bottom"
    case inside = "inside"
    case outside = "outside"
}

/// Horizontal relative positioning
public enum HorizontalRelativeTo: String, Sendable, CaseIterable {
    case character = "character"
    case column = "column"
    case insideMargin = "insideMargin"
    case leftMargin = "leftMargin"
    case margin = "margin"
    case outsideMargin = "outsideMargin"
    case page = "page"
    case rightMargin = "rightMargin"
}

/// Vertical relative positioning  
public enum VerticalRelativeTo: String, Sendable, CaseIterable {
    case bottomMargin = "bottomMargin"
    case insideMargin = "insideMargin"
    case line = "line"
    case margin = "margin"
    case outsideMargin = "outsideMargin"
    case page = "page"
    case paragraph = "paragraph"
    case topMargin = "topMargin"
}

/// Text wrapping options
public enum TextWrapping: String, Sendable, CaseIterable {
    case inline = "inline"
    case square = "square"
    case tight = "tight"
    case through = "through"
    case topAndBottom = "topAndBottom"
    case behind = "behind"
    case inFrontOf = "inFrontOf"
}

// MARK: - Type Aliases

/// English Metric Units (1 inch = 914,400 EMU)
public typealias EMU = Int64

/// Drawing transform (rotation, scaling, etc.)
public typealias DrawingTransform = String  // Placeholder for now

/// Drawing effects (shadows, reflections, etc.)  
public typealias DrawingEffect = String     // Placeholder for now