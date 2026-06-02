//
//  SourceLocation.swift
//  LiquidCore
//
//  Created as part of RhoeLiquid
//  A high-performance Swift 6.3 implementation of the Liquid template language
//

import Foundation

/// Represents a location in the source template
public struct LiquidSourceLocation: Sendable, Equatable, Codable {
    /// The line number (1-based)
    public let line: Int
    
    /// The column number (1-based)
    public let column: Int
    
    /// The character position in the template (0-based)
    public let position: Int
    
    /// Optional template name or identifier
    public let templateName: String?
    
    /// Creates a new source location
    /// - Parameters:
    ///   - line: The line number (1-based)
    ///   - column: The column number (1-based)
    ///   - position: The character position (0-based)
    ///   - templateName: Optional template identifier
    public init(line: Int, column: Int, position: Int, templateName: String? = nil) {
        self.line = line
        self.column = column
        self.position = position
        self.templateName = templateName
    }
    
    /// Creates a source location from a token position
    /// - Parameter token: The token to extract location from
    public init(from token: Token) {
        self.line = token.line
        self.column = token.column
        self.position = token.position
        self.templateName = nil
    }
    
    /// A default unknown location
    public static let unknown = LiquidSourceLocation(line: 0, column: 0, position: 0)
}

// MARK: - CustomStringConvertible

extension LiquidSourceLocation: CustomStringConvertible {
    public var description: String {
        if let templateName = templateName {
            return "\(templateName):\(line):\(column)"
        } else {
            return "\(line):\(column)"
        }
    }
}

// MARK: - Comparable

extension LiquidSourceLocation: Comparable {
    public static func < (lhs: LiquidSourceLocation, rhs: LiquidSourceLocation) -> Bool {
        if lhs.line != rhs.line {
            return lhs.line < rhs.line
        }
        return lhs.column < rhs.column
    }
}