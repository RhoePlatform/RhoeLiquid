//
//  LexerError.swift
//  LiquidCore
//
//  Created as part of RhoeLiquid
//  A high-performance Swift 6.3 implementation of the Liquid template language
//

import Foundation

/// Errors that can occur during the lexical analysis (tokenization) phase
///
/// These errors represent problems with the template syntax at the character level,
/// such as malformed strings, invalid numbers, or unexpected characters.
public enum LexerError: Error, Sendable, Equatable {
    /// An unexpected character was encountered at the specified position
    case unexpectedCharacter(Character, position: Int)
    
    /// A string literal was not properly terminated with a closing quote
    case unterminatedString(position: Int)
    
    /// A numeric literal could not be parsed as a valid number
    case invalidNumber(String, position: Int)
    
    /// An escape sequence in a string is invalid or malformed
    case invalidEscapeSequence(Character, position: Int)
    
    /// The template contains invalid UTF-8 sequences
    case invalidUTF8(position: Int)
    
    /// A tag or variable delimiter is not properly closed
    case unclosedDelimiter(String, position: Int)
    
    /// The input ends unexpectedly while parsing a construct
    case unexpectedEndOfInput(position: Int)
}

// MARK: - Error Information

extension LexerError {
    /// Returns a human-readable description of the error
    public var message: String {
        switch self {
        case .unexpectedCharacter(let char, _):
            return "Unexpected character '\(char)'"
        case .unterminatedString:
            return "Unterminated string literal"
        case .invalidNumber(let string, _):
            return "Invalid number '\(string)'"
        case .invalidEscapeSequence(let char, _):
            return "Invalid escape sequence '\\\(char)'"
        case .invalidUTF8:
            return "Invalid UTF-8 sequence"
        case .unclosedDelimiter(let delimiter, _):
            return "Unclosed delimiter '\(delimiter)'"
        case .unexpectedEndOfInput:
            return "Unexpected end of input"
        }
    }
    
    /// Returns the position where the error occurred
    public var position: Int {
        switch self {
        case .unexpectedCharacter(_, let pos),
             .unterminatedString(let pos),
             .invalidNumber(_, let pos),
             .invalidEscapeSequence(_, let pos),
             .invalidUTF8(let pos),
             .unclosedDelimiter(_, let pos),
             .unexpectedEndOfInput(let pos):
            return pos
        }
    }
    
    /// Returns the error category for grouping similar errors
    public var category: ErrorCategory {
        switch self {
        case .unexpectedCharacter, .invalidUTF8:
            return .syntax
        case .unterminatedString, .unclosedDelimiter:
            return .unterminated
        case .invalidNumber, .invalidEscapeSequence:
            return .malformed
        case .unexpectedEndOfInput:
            return .incomplete
        }
    }
}

// MARK: - Error Recovery

extension LexerError {
    /// Suggests how to fix this error
    public var suggestion: String? {
        switch self {
        case .unexpectedCharacter(let char, _):
            if char.isWhitespace {
                return "Check for missing delimiters or incorrect tag structure"
            } else {
                return "Remove or escape the unexpected character"
            }
        case .unterminatedString:
            return "Add a closing quote to complete the string literal"
        case .invalidNumber(let string, _):
            if string.contains(".") {
                return "Check decimal point placement in the number"
            } else {
                return "Ensure the number contains only valid digits"
            }
        case .invalidEscapeSequence(let char, _):
            return "Use a valid escape sequence or escape the backslash: \\\(char) or \\\\"
        case .invalidUTF8:
            return "Ensure the template file is saved with UTF-8 encoding"
        case .unclosedDelimiter(let delimiter, _):
            switch delimiter {
            case "{{":
                return "Add '}}'  to close the variable"
            case "{%":
                return "Add '%}' to close the tag"
            default:
                return "Add the closing delimiter for '\(delimiter)'"
            }
        case .unexpectedEndOfInput:
            return "Complete the template with proper closing tags"
        }
    }
}

/// Categories of lexer errors for error handling strategies
public enum ErrorCategory: String, Sendable, CaseIterable {
    case syntax = "Syntax Error"
    case unterminated = "Unterminated Construct"
    case malformed = "Malformed Content"
    case incomplete = "Incomplete Template"
}

// MARK: - CustomStringConvertible

extension LexerError: CustomStringConvertible {
    public var description: String {
        let suggestion = self.suggestion.map { " (\($0))" } ?? ""
        return "\(category.rawValue): \(message) at position \(position)\(suggestion)"
    }
}

extension LexerError: LocalizedError {
    public var errorDescription: String? {
        return description
    }
    
    public var recoverySuggestion: String? {
        return suggestion
    }
}
