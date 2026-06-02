//
//  InlineString.swift
//  LiquidCore
//
//  Created as part of RhoeLiquid
//  A high-performance Swift 6.3 implementation of the Liquid template language
//

import Foundation
#if swift(>=6.2) && canImport(InlineCollections)
import InlineCollections
#endif

/// A memory-optimized string storage that avoids heap allocation for small strings
///
/// `InlineString` stores strings up to 23 bytes directly in the struct without heap allocation.
/// Longer strings are stored on the heap. This optimization is particularly effective for
/// template tokens which are often short identifiers, keywords, or small text fragments.
///
/// The implementation uses Swift 6.3's `InlineArray` when available, with a fallback
/// to tuple-based storage for compatibility.
public struct InlineString: Sendable, Equatable, Hashable {
    // MARK: - Constants
    
    /// Maximum number of UTF-8 bytes that can be stored inline
    private static let inlineCapacity = 23
    
    // MARK: - Storage
    
    #if swift(>=6.2) && canImport(InlineCollections)
    /// Inline storage using Swift 6.3's InlineArray for optimal performance
    private var storage: InlineArray<UInt8, inlineCapacity>
    #else
    /// Fallback storage using a tuple for older Swift versions
    private var storage: (UInt64, UInt64, UInt64)
    #endif
    
    /// Length of the string when stored inline (0 indicates heap storage)
    private var length: UInt8
    
    /// Heap storage for strings longer than inline capacity
    private var heap: String?
    
    // MARK: - Initialization
    
    /// Creates an InlineString from a Swift String
    ///
    /// Automatically chooses between inline and heap storage based on the string's UTF-8 length.
    ///
    /// - Parameter string: The string to store
    public init(_ string: String) {
        let utf8Count = string.utf8.count

        if utf8Count <= Self.inlineCapacity {
            // Store inline
            #if swift(>=6.2) && canImport(InlineCollections)
            self.length = UInt8(utf8Count)
            self.storage = InlineArray()
            for (i, byte) in string.utf8.enumerated() {
                self.storage[i] = byte
            }
            #else
            self.length = UInt8(utf8Count)
            var tuple: (UInt64, UInt64, UInt64) = (0, 0, 0)
            withUnsafeMutableBytes(of: &tuple) { buffer in
                for (i, byte) in string.utf8.enumerated() {
                    buffer[i] = byte
                }
            }
            self.storage = tuple
            #endif
            self.heap = nil
        } else {
            // Store on heap
            self.length = 0
            #if swift(>=6.2) && canImport(InlineCollections)
            self.storage = InlineArray()
            #else
            self.storage = (0, 0, 0)
            #endif
            self.heap = string
        }
    }

    /// Creates an `InlineString` directly from a UTF-8 byte collection.
    ///
    /// This avoids an intermediate `String` allocation for short borrowed slices
    /// such as lexer tokens and text fragments.
    public init<Bytes: Collection>(utf8 bytes: Bytes) where Bytes.Element == UInt8 {
        let utf8Count = bytes.count

        if utf8Count <= Self.inlineCapacity {
            self.length = UInt8(utf8Count)
            #if swift(>=6.2) && canImport(InlineCollections)
            self.storage = InlineArray()
            var index = 0
            for byte in bytes {
                self.storage[index] = byte
                index += 1
            }
            #else
            var tuple: (UInt64, UInt64, UInt64) = (0, 0, 0)
            withUnsafeMutableBytes(of: &tuple) { buffer in
                var index = 0
                for byte in bytes {
                    buffer[index] = byte
                    index += 1
                }
            }
            self.storage = tuple
            #endif
            self.heap = nil
        } else {
            self.length = 0
            #if swift(>=6.2) && canImport(InlineCollections)
            self.storage = InlineArray()
            #else
            self.storage = (0, 0, 0)
            #endif
            self.heap = String(decoding: bytes, as: UTF8.self)
        }
    }
    
    /// Creates an empty InlineString
    public init() {
        self.init("")
    }
    
    // MARK: - Properties
    
    /// Returns true if the string is stored inline (not on the heap)
    public var isInline: Bool {
        return length > 0 || (length == 0 && heap == nil)
    }
    
    /// Returns the length of the string in UTF-8 bytes
    public var utf8Count: Int {
        if let heap = heap {
            return heap.utf8.count
        } else {
            return Int(length)
        }
    }
    
    /// Returns true if the string is empty
    public var isEmpty: Bool {
        return utf8Count == 0
    }
    
    // MARK: - String Access
    
    /// Returns the string content as a Swift String
    public var string: String {
        if let heap = heap {
            return heap
        } else {
            #if swift(>=6.2) && canImport(InlineCollections)
            let count = Int(length)
            return String(unsafeUninitializedCapacity: count) { buffer in
                for index in 0..<count {
                    buffer[index] = storage[index]
                }
                return count
            }
            #else
            return withUnsafeBytes(of: storage) { buffer in
                String(decoding: buffer.prefix(Int(length)), as: UTF8.self)
            }
            #endif
        }
    }
}

// MARK: - Protocol Conformances

extension InlineString: CustomStringConvertible {
    public var description: String {
        return string
    }
}

extension InlineString: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

extension InlineString: Comparable {
    public static func < (lhs: InlineString, rhs: InlineString) -> Bool {
        return lhs.string < rhs.string
    }
}

// MARK: - Equatable and Hashable

extension InlineString {
    @inline(__always)
    private func inlineByte(at index: Int) -> UInt8 {
        #if swift(>=6.2) && canImport(InlineCollections)
        return storage[index]
        #else
        return withUnsafeBytes(of: storage) { buffer in
            buffer[index]
        }
        #endif
    }

    @inline(__always)
    package var firstUTF8Byte: UInt8? {
        if let heap {
            return heap.utf8.first
        }

        guard length > 0 else {
            return nil
        }

        return inlineByte(at: 0)
    }

    /// Returns true when the string exactly matches the given static string literal.
    @inline(__always)
    public func equals(_ literal: StaticString) -> Bool {
        let expectedCount = literal.utf8CodeUnitCount
        guard utf8Count == expectedCount else {
            return false
        }

        if let heap {
            return literal.withUTF8Buffer { literalBytes in
                heap.utf8.elementsEqual(literalBytes)
            }
        }

        return literal.withUTF8Buffer { literalBytes in
            for index in 0..<expectedCount where inlineByte(at: index) != literalBytes[index] {
                return false
            }
            return true
        }
    }

    public static func == (lhs: InlineString, rhs: InlineString) -> Bool {
        let lhsCount = lhs.utf8Count
        let rhsCount = rhs.utf8Count
        guard lhsCount == rhsCount else {
            return false
        }

        switch (lhs.heap, rhs.heap) {
        case (let lhsHeap?, let rhsHeap?):
            return lhsHeap.utf8.elementsEqual(rhsHeap.utf8)

        case (let lhsHeap?, nil):
            var index = 0
            for byte in lhsHeap.utf8 {
                if byte != rhs.inlineByte(at: index) {
                    return false
                }
                index += 1
            }
            return true

        case (nil, let rhsHeap?):
            var index = 0
            for byte in rhsHeap.utf8 {
                if lhs.inlineByte(at: index) != byte {
                    return false
                }
                index += 1
            }
            return true

        case (nil, nil):
            for index in 0..<lhsCount where lhs.inlineByte(at: index) != rhs.inlineByte(at: index) {
                return false
            }
            return true
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(utf8Count)

        if let heap {
            for byte in heap.utf8 {
                hasher.combine(byte)
            }
            return
        }

        for index in 0..<Int(length) {
            hasher.combine(inlineByte(at: index))
        }
    }
}

// MARK: - String Operations

extension InlineString {
    /// Creates a new InlineString by appending another string
    public func appending(_ other: String) -> InlineString {
        return InlineString(string + other)
    }
    
    /// Creates a new InlineString by appending another InlineString
    public func appending(_ other: InlineString) -> InlineString {
        return InlineString(string + other.string)
    }
    
    /// Creates a new InlineString by prepending another string
    public func prepending(_ other: String) -> InlineString {
        return InlineString(other + string)
    }
    
    /// Returns true if this string contains the given substring
    public func contains(_ substring: String) -> Bool {
        return string.contains(substring)
    }
    
    /// Returns true if this string has the given prefix
    public func hasPrefix(_ prefix: String) -> Bool {
        return string.hasPrefix(prefix)
    }
    
    /// Returns true if this string has the given suffix
    public func hasSuffix(_ suffix: String) -> Bool {
        return string.hasSuffix(suffix)
    }
    
    /// Returns a lowercased version of this string
    public func lowercased() -> InlineString {
        return InlineString(string.lowercased())
    }
    
    /// Returns an uppercased version of this string
    public func uppercased() -> InlineString {
        return InlineString(string.uppercased())
    }
    
    /// Returns a copy with leading and trailing whitespace removed
    public func trimmingWhitespace() -> InlineString {
        return InlineString(string.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

// MARK: - Memory Statistics

extension InlineString {
    /// Returns memory usage statistics for debugging and optimization
    public static func memoryStats(for strings: [InlineString]) -> MemoryStats {
        var inlineCount = 0
        var heapCount = 0
        var totalInlineBytes = 0
        var totalHeapBytes = 0
        
        for string in strings {
            if string.isInline {
                inlineCount += 1
                totalInlineBytes += string.utf8Count
            } else {
                heapCount += 1
                totalHeapBytes += string.utf8Count
            }
        }
        
        let totalCount = inlineCount + heapCount
        return MemoryStats(
            inlineCount: inlineCount,
            heapCount: heapCount,
            totalInlineBytes: totalInlineBytes,
            totalHeapBytes: totalHeapBytes,
            averageInlineSize: inlineCount > 0 ? Double(totalInlineBytes) / Double(inlineCount) : 0,
            inlineEfficiency: totalCount > 0 ? Double(inlineCount) / Double(totalCount) : 0
        )
    }
}

/// Memory usage statistics for observed `InlineString` collections.
///
/// In `renderWithMetrics`, these values describe the template source, token, and
/// AST string storage seen during the current render, rather than whole-process RSS.
public struct MemoryStats: Sendable {
    /// Number of strings stored inline
    public let inlineCount: Int
    
    /// Number of strings stored on heap
    public let heapCount: Int
    
    /// Total bytes stored inline
    public let totalInlineBytes: Int
    
    /// Total bytes stored on heap
    public let totalHeapBytes: Int
    
    /// Average size of inline strings
    public let averageInlineSize: Double
    
    /// Percentage of strings stored inline (0.0 to 1.0)
    public let inlineEfficiency: Double
    
    public init(
        inlineCount: Int,
        heapCount: Int,
        totalInlineBytes: Int,
        totalHeapBytes: Int,
        averageInlineSize: Double,
        inlineEfficiency: Double
    ) {
        self.inlineCount = inlineCount
        self.heapCount = heapCount
        self.totalInlineBytes = totalInlineBytes
        self.totalHeapBytes = totalHeapBytes
        self.averageInlineSize = averageInlineSize
        self.inlineEfficiency = inlineEfficiency
    }
    
    /// Total number of strings
    public var totalCount: Int {
        return inlineCount + heapCount
    }
    
    /// Total bytes across all strings
    public var totalBytes: Int {
        return totalInlineBytes + totalHeapBytes
    }
}

extension MemoryStats: CustomStringConvertible {
    public var description: String {
        """
        InlineString Memory Stats:
        - Total strings: \(totalCount)
        - Inline: \(inlineCount) (\(String(format: "%.1f", inlineEfficiency * 100))%)
        - Heap: \(heapCount)
        - Total bytes: \(totalBytes)
        - Average inline size: \(String(format: "%.1f", averageInlineSize)) bytes
        - Inline efficiency: \(String(format: "%.1f", inlineEfficiency * 100))%
        """
    }
}
