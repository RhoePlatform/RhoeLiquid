//
//  StringUtils.swift
//  LiquidUtilities
//
//  Created as part of RhoeLiquid
//  A high-performance Swift 6.3 implementation of the Liquid template language
//

import Foundation

/// String utilities shared by higher-level integration code.
public enum StringUtils {
    /// Returns the string with leading and trailing whitespace removed.
    public static func trimmingWhitespaceAndNewlines(_ string: String) -> String {
        string.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Returns `true` when the string contains only whitespace.
    public static func isBlank(_ string: String) -> Bool {
        string.allSatisfy(\.isWhitespace)
    }

    /// Returns the number of leading characters shared by both strings.
    public static func commonPrefixLength(_ lhs: String, _ rhs: String) -> Int {
        zip(lhs, rhs).prefix { $0 == $1 }.count
    }
}
