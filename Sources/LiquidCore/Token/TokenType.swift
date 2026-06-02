//
//  TokenType.swift
//  LiquidCore
//
//  Created as part of RhoeLiquid
//  A high-performance Swift 6.3 implementation of the Liquid template language
//

import Foundation

/// Represents the different types of tokens that can be found in a Liquid template
///
/// This enum uses associated values to store token-specific data efficiently.
/// For tokens that contain data (like identifiers or strings), the data is stored
/// using `InlineString` for memory optimization.
public enum TokenType: Equatable, Sendable {
    // MARK: - Text Content
    /// Raw text content that should be output as-is
    case text(InlineString)
    
    // MARK: - Liquid Delimiters
    /// Opening variable delimiter: `{{`
    case variableStart
    /// Closing variable delimiter: `}}`
    case variableEnd
    /// Opening tag delimiter: `{%`
    case tagStart
    /// Closing tag delimiter: `%}`
    case tagEnd
    
    // MARK: - Identifiers and Literals
    /// Variable names, filter names, tag names, etc.
    case identifier(InlineString)
    /// String literals with quotes removed
    case string(InlineString)
    /// Numeric literals (integers and floats)
    /// - Parameters:
    ///   - Double: The numeric value
    ///   - Bool: `true` if the source literal had a decimal point
    case number(Double, isFloat: Bool = false)
    
    // MARK: - Operators and Punctuation
    /// Filter pipe operator: `|`
    case filter
    /// Colon for named parameters: `:`
    case colon
    /// Comma separator: `,`
    case comma
    /// Dot for property access: `.`
    case dot
    /// Assignment operator: `=`
    case equals
    /// Not equals operator: `!=`
    case notEquals
    /// Less than operator: `<`
    case lessThan
    /// Greater than operator: `>`
    case greaterThan
    /// Less than or equal operator: `<=`
    case lessThanOrEqual
    /// Greater than or equal operator: `>=`
    case greaterThanOrEqual
    /// Range operator: `..`
    case range
    /// Left parenthesis: `(`
    case leftParen
    /// Right parenthesis: `)`
    case rightParen
    /// Left bracket: `[`
    case leftBracket
    /// Right bracket: `]`
    case rightBracket
    
    // MARK: - Logical Operators
    /// Contains operator for substring/array membership
    case contains
    /// Logical AND operator
    case and
    /// Logical OR operator
    case or
    /// Test operator for type/state checking
    case `is`
    
    // MARK: - Control Flow Tags
    /// If conditional tag
    case `if`
    /// Else if conditional tag
    case elsif
    /// Else conditional tag
    case `else`
    /// End if tag
    case endif
    /// Unless conditional tag (inverse if)
    case unless
    /// End unless tag
    case endunless
    /// Case/switch statement tag
    case `case`
    /// When clause in case statement
    case when
    /// End case tag
    case endcase
    
    // MARK: - Loop Tags
    /// For loop tag
    case `for`
    /// End for loop tag
    case endfor
    /// In keyword for loops
    case `in`
    /// Empty clause for for loops (when collection is empty)
    case empty
    /// Break statement for early loop exit
    case `break`
    /// Continue statement for next iteration
    case `continue`
    /// Table row generation tag
    case tablerow
    /// End table row tag
    case endtablerow
    /// Cycle tag for alternating values
    case cycle
    
    // MARK: - Variable Tags
    /// Variable assignment tag
    case assign
    /// Capture tag for storing rendered content
    case capture
    /// End capture tag
    case endcapture
    /// Increment counter tag
    case increment
    /// Decrement counter tag
    case decrement
    
    // MARK: - Include and Template Tags
    /// Include template tag
    case include
    /// Render template tag
    case render
    /// Block definition tag
    case block
    /// End block tag
    case endblock
    /// Macro definition tag
    case macro
    /// End macro definition tag
    case endmacro
    /// Macro import tag
    case `import`
    /// From-import tag
    case from
    /// Template input declaration tag
    case input
    /// Tag-driven macro invocation
    case call
    /// Render block tag
    case render_block
    /// With keyword for parameter passing
    case with
    /// Recursive keyword for recursive includes
    case recursive
    /// Loop keyword for recursive loops
    case loop
    
    // MARK: - Utility Tags
    /// Comment tag (content ignored)
    case comment
    /// End comment tag
    case endcomment
    /// Raw tag (content not processed)
    case raw
    /// End raw tag
    case endraw
    /// Liquid tag for whitespace control
    case liquid
    /// End liquid tag
    case endliquid
    /// Echo tag for expression output
    case echo
    /// Debug tag for development
    case debug
    /// Pipeline tag for data transformation
    case pipeline
    /// End pipeline tag
    case endpipeline
}

// MARK: - TokenType Extensions

extension TokenType {
    /// Returns the keyword string for keyword token types used as variable names
    public var keywordString: String? {
        switch self {
        case .include: return "include"
        case .for: return "for"
        case .if: return "if"
        case .elsif: return "elsif"
        case .else: return "else"
        case .unless: return "unless"
        case .case: return "case"
        case .when: return "when"
        case .comment: return "comment"
        case .raw: return "raw"
        case .capture: return "capture"
        case .tablerow: return "tablerow"
        case .cycle: return "cycle"
        default: return nil
        }
    }

    /// Returns the approximate source lexeme for this token type.
    ///
    /// This is used when reconstructing normalized tag markup or template
    /// fragments from an already-tokenized stream.
    public var sourceLexeme: String {
        switch self {
        case .text(let content):
            return content.string
        case .variableStart:
            return "{{"
        case .variableEnd:
            return "}}"
        case .tagStart:
            return "{%"
        case .tagEnd:
            return "%}"
        case .identifier(let name):
            return name.string
        case .string(let value):
            let escaped = value.string
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
            return "\"\(escaped)\""
        case .number(let value, _):
            if value.rounded(.towardZero) == value {
                return String(Int(value))
            }
            return String(value)
        case .filter:
            return "|"
        case .colon:
            return ":"
        case .comma:
            return ","
        case .dot:
            return "."
        case .equals:
            return "="
        case .notEquals:
            return "!="
        case .lessThan:
            return "<"
        case .greaterThan:
            return ">"
        case .lessThanOrEqual:
            return "<="
        case .greaterThanOrEqual:
            return ">="
        case .range:
            return ".."
        case .leftParen:
            return "("
        case .rightParen:
            return ")"
        case .leftBracket:
            return "["
        case .rightBracket:
            return "]"
        case .contains:
            return "contains"
        case .and:
            return "and"
        case .or:
            return "or"
        case .is:
            return "is"
        case .if:
            return "if"
        case .elsif:
            return "elsif"
        case .else:
            return "else"
        case .endif:
            return "endif"
        case .unless:
            return "unless"
        case .endunless:
            return "endunless"
        case .case:
            return "case"
        case .when:
            return "when"
        case .endcase:
            return "endcase"
        case .for:
            return "for"
        case .endfor:
            return "endfor"
        case .in:
            return "in"
        case .empty:
            return "empty"
        case .break:
            return "break"
        case .continue:
            return "continue"
        case .tablerow:
            return "tablerow"
        case .endtablerow:
            return "endtablerow"
        case .cycle:
            return "cycle"
        case .assign:
            return "assign"
        case .capture:
            return "capture"
        case .endcapture:
            return "endcapture"
        case .increment:
            return "increment"
        case .decrement:
            return "decrement"
        case .include:
            return "include"
        case .render:
            return "render"
        case .block:
            return "block"
        case .endblock:
            return "endblock"
        case .macro:
            return "macro"
        case .endmacro:
            return "endmacro"
        case .import:
            return "import"
        case .from:
            return "from"
        case .input:
            return "input"
        case .call:
            return "call"
        case .render_block:
            return "render_block"
        case .with:
            return "with"
        case .recursive:
            return "recursive"
        case .loop:
            return "loop"
        case .comment:
            return "comment"
        case .endcomment:
            return "endcomment"
        case .raw:
            return "raw"
        case .endraw:
            return "endraw"
        case .liquid:
            return "liquid"
        case .endliquid:
            return "endliquid"
        case .echo:
            return "echo"
        case .debug:
            return "debug"
        case .pipeline:
            return "pipeline"
        case .endpipeline:
            return "endpipeline"
        }
    }

    /// Returns true if this token type represents a tag that requires an end tag
    public var requiresEndTag: Bool {
        switch self {
        case .if, .unless, .case, .for, .capture, .comment, .raw, .liquid,
             .block, .macro, .tablerow, .pipeline:
            return true
        default:
            return false
        }
    }
    
    /// Returns true if this token type is a control flow tag
    public var isControlFlow: Bool {
        switch self {
        case .if, .elsif, .else, .endif, .unless, .endunless, 
             .case, .when, .endcase:
            return true
        default:
            return false
        }
    }
    
    /// Returns true if this token type is a loop-related tag
    public var isLoop: Bool {
        switch self {
        case .for, .endfor, .in, .empty, .break, .continue, .tablerow, .endtablerow, .cycle:
            return true
        default:
            return false
        }
    }
    
    /// Returns true if this token type is an operator
    public var isOperator: Bool {
        switch self {
        case .filter, .equals, .notEquals, .lessThan, .greaterThan,
             .lessThanOrEqual, .greaterThanOrEqual, .contains, .and, .or, .is, .range:
            return true
        default:
            return false
        }
    }
    
    /// Returns the corresponding end tag type for tags that require one
    public var endTag: TokenType? {
        switch self {
        case .if: return .endif
        case .unless: return .endunless
        case .case: return .endcase
        case .for: return .endfor
        case .capture: return .endcapture
        case .comment: return .endcomment
        case .raw: return .endraw
        case .liquid: return .endliquid
        case .block: return .endblock
        case .macro: return .endmacro
        case .tablerow: return .endtablerow
        case .pipeline: return .endpipeline
        default: return nil
        }
    }
}

// MARK: - CustomStringConvertible

extension TokenType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .text(let content): return "text(\(content))"
        case .variableStart: return "{{"
        case .variableEnd: return "}}"
        case .tagStart: return "{%"
        case .tagEnd: return "%}"
        case .identifier(let name): return "identifier(\(name))"
        case .string(let value): return "string(\(value))"
        case .number(let value, _): return "number(\(value))"
        case .filter: return "|"
        case .colon: return ":"
        case .comma: return ","
        case .dot: return "."
        case .equals: return "=="
        case .notEquals: return "!="
        case .lessThan: return "<"
        case .greaterThan: return ">"
        case .lessThanOrEqual: return "<="
        case .greaterThanOrEqual: return ">="
        case .range: return ".."
        case .leftParen: return "("
        case .rightParen: return ")"
        case .leftBracket: return "["
        case .rightBracket: return "]"
        case .contains: return "contains"
        case .and: return "and"
        case .or: return "or"
        case .is: return "is"
        case .if: return "if"
        case .elsif: return "elsif"
        case .else: return "else"
        case .endif: return "endif"
        case .unless: return "unless"
        case .endunless: return "endunless"
        case .case: return "case"
        case .when: return "when"
        case .endcase: return "endcase"
        case .for: return "for"
        case .endfor: return "endfor"
        case .in: return "in"
        case .empty: return "empty"
        case .break: return "break"
        case .continue: return "continue"
        case .tablerow: return "tablerow"
        case .endtablerow: return "endtablerow"
        case .cycle: return "cycle"
        case .assign: return "assign"
        case .capture: return "capture"
        case .endcapture: return "endcapture"
        case .increment: return "increment"
        case .decrement: return "decrement"
        case .include: return "include"
        case .render: return "render"
        case .block: return "block"
        case .endblock: return "endblock"
        case .macro: return "macro"
        case .endmacro: return "endmacro"
        case .import: return "import"
        case .from: return "from"
        case .input: return "input"
        case .call: return "call"
        case .render_block: return "render_block"
        case .with: return "with"
        case .recursive: return "recursive"
        case .loop: return "loop"
        case .comment: return "comment"
        case .endcomment: return "endcomment"
        case .raw: return "raw"
        case .endraw: return "endraw"
        case .liquid: return "liquid"
        case .endliquid: return "endliquid"
        case .echo: return "echo"
        case .debug: return "debug"
        case .pipeline: return "pipeline"
        case .endpipeline: return "endpipeline"
        }
    }
}
