//
//  Token.swift
//  LiquidCore
//
//  Created as part of RhoeLiquid
//  A high-performance Swift 6.3 implementation of the Liquid template language
//

import Foundation

/// Represents a single token in a Liquid template with position information
///
/// Tokens are the fundamental units produced by the lexer and consumed by the parser.
/// Each token contains its type, position in the source text, and whitespace trimming information.
public struct Token: Sendable, Equatable {
    // MARK: - Properties
    
    /// The type and content of this token
    public let type: TokenType
    
    /// The byte position in the source string where this token starts
    public let position: Int
    
    /// The line number where this token appears (1-based)
    public let line: Int
    
    /// The column number where this token appears (1-based)
    public let column: Int
    
    /// Whether whitespace should be trimmed to the left of this token
    public let trimLeft: Bool
    
    /// Whether whitespace should be trimmed to the right of this token
    public let trimRight: Bool
    
    // MARK: - Initialization
    
    /// Creates a new token with the specified properties
    ///
    /// - Parameters:
    ///   - type: The type and content of the token
    ///   - position: The byte position in the source string
    ///   - line: The line number (1-based)
    ///   - column: The column number (1-based)
    ///   - trimLeft: Whether to trim whitespace to the left
    ///   - trimRight: Whether to trim whitespace to the right
    public init(
        type: TokenType,
        position: Int,
        line: Int,
        column: Int,
        trimLeft: Bool = false,
        trimRight: Bool = false
    ) {
        self.type = type
        self.position = position
        self.line = line
        self.column = column
        self.trimLeft = trimLeft
        self.trimRight = trimRight
    }
}

// MARK: - Token Extensions

extension Token {
    /// Returns true if this token represents a Liquid delimiter
    public var isDelimiter: Bool {
        switch type {
        case .variableStart, .variableEnd, .tagStart, .tagEnd:
            return true
        default:
            return false
        }
    }
    
    /// Returns true if this token represents an opening delimiter
    public var isOpeningDelimiter: Bool {
        switch type {
        case .variableStart, .tagStart:
            return true
        default:
            return false
        }
    }
    
    /// Returns true if this token represents a closing delimiter
    public var isClosingDelimiter: Bool {
        switch type {
        case .variableEnd, .tagEnd:
            return true
        default:
            return false
        }
    }
    
    /// Returns true if this token represents text content
    public var isText: Bool {
        if case .text = type {
            return true
        }
        return false
    }
    
    /// Returns true if this token represents an identifier
    public var isIdentifier: Bool {
        if case .identifier = type {
            return true
        }
        return false
    }
    
    /// Returns true if this token represents a literal value
    public var isLiteral: Bool {
        switch type {
        case .string, .number:
            return true
        case .identifier(let name):
            // Check for boolean literals
            return name.equals("true")
                || name.equals("false")
                || name.equals("nil")
                || name.equals("null")
        default:
            return false
        }
    }
    
    /// Returns the string content if this token contains string data
    public var stringValue: String? {
        switch type {
        case .text(let content), .identifier(let content), .string(let content):
            return content.description
        default:
            return nil
        }
    }
    
    /// Returns the numeric value if this token contains a number
    public var numberValue: Double? {
        if case .number(let value, _) = type {
            return value
        }
        return nil
    }
}

// MARK: - Token Position Information

extension Token {
    /// Creates a source location structure for error reporting
    public var sourceLocation: SourceLocation {
        SourceLocation(
            position: position,
            line: line,
            column: column
        )
    }
    
    /// Returns a human-readable description of the token's position
    public var positionDescription: String {
        "line \(line), column \(column)"
    }
}

/// Represents a location in source code for error reporting
public struct SourceLocation: Sendable, Equatable {
    /// The byte position in the source string
    public let position: Int
    
    /// The line number (1-based)
    public let line: Int
    
    /// The column number (1-based)
    public let column: Int
    
    public init(position: Int, line: Int, column: Int) {
        self.position = position
        self.line = line
        self.column = column
    }
}

// MARK: - CustomStringConvertible

extension Token: CustomStringConvertible {
    public var description: String {
        let trimInfo = (trimLeft || trimRight) ? 
            " (trim: \(trimLeft ? "left" : "")\(trimLeft && trimRight ? "+" : "")\(trimRight ? "right" : ""))" : ""
        return "\(type) at \(positionDescription)\(trimInfo)"
    }
}

extension SourceLocation: CustomStringConvertible {
    public var description: String {
        "line \(line), column \(column) (position \(position))"
    }
}

// MARK: - Token Collection Utilities

extension Collection where Element == Token {
    /// Finds the first token of the specified type
    public func first(where type: TokenType) -> Token? {
        return first { $0.type == type }
    }
    
    /// Returns all tokens of the specified type
    public func filter(by type: TokenType) -> [Token] {
        return filter { $0.type == type }
    }
    
    /// Returns true if any token matches the specified type
    public func contains(type: TokenType) -> Bool {
        return contains { $0.type == type }
    }
}
