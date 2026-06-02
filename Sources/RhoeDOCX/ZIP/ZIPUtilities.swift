//
//  ZIPUtilities.swift
//  RhoeDOCX
//
//  Utility functions for ZIP archive handling
//

import Foundation
import Compression

/// ZIP date/time conversion utilities
public enum ZIPDateConverter {
    
    /// Convert DOS date/time to Date
    public static func dateFromDOSDateTime(date: UInt16, time: UInt16) -> Date {
        let year = 1980 + Int((date >> 9) & 0x7F)
        let month = Int((date >> 5) & 0x0F)
        let day = Int(date & 0x1F)
        
        let hour = Int((time >> 11) & 0x1F)
        let minute = Int((time >> 5) & 0x3F)
        let second = Int((time & 0x1F) * 2)
        
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        
        return Calendar(identifier: .gregorian).date(from: components) ?? Date()
    }
    
    /// Convert Date to DOS date/time
    public static func dosDateTimeFromDate(_ date: Date) -> (date: UInt16, time: UInt16) {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        
        let year = max(0, min(127, (components.year ?? 1980) - 1980))
        let month = max(1, min(12, components.month ?? 1))
        let day = max(1, min(31, components.day ?? 1))
        
        let hour = max(0, min(23, components.hour ?? 0))
        let minute = max(0, min(59, components.minute ?? 0))
        let second = max(0, min(59, components.second ?? 0)) / 2
        
        let dosDate = UInt16((year << 9) | (month << 5) | day)
        let dosTime = UInt16((hour << 11) | (minute << 5) | second)
        
        return (dosDate, dosTime)
    }
}

// MARK: - Data Compression Extensions

public extension Data {
    
    /// Compress data using deflate algorithm
    func deflate() -> Data? {
        return self.compress(algorithm: COMPRESSION_ZLIB)
    }
    
    /// Decompress data using inflate algorithm
    func inflate() -> Data? {
        return self.decompress(algorithm: COMPRESSION_ZLIB)
    }
    
    /// Generic compression helper
    private func compress(algorithm: compression_algorithm) -> Data? {
        guard !self.isEmpty else { return self }
        
        return self.withUnsafeBytes { sourceBuffer in
            let sourcePtr = sourceBuffer.bindMemory(to: UInt8.self).baseAddress!
            let destinationCapacity = count + 1024
            let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: destinationCapacity)
            defer { destinationBuffer.deallocate() }
            
            let compressedSize = compression_encode_buffer(
                destinationBuffer, destinationCapacity,
                sourcePtr, count,
                nil, algorithm
            )
            
            guard compressedSize > 0 else { return nil }
            return Data(bytes: destinationBuffer, count: compressedSize)
        }
    }
    
    /// Generic decompression helper
    private func decompress(algorithm: compression_algorithm) -> Data? {
        guard !self.isEmpty else { return self }
        
        return self.withUnsafeBytes { sourceBuffer in
            let sourcePtr = sourceBuffer.bindMemory(to: UInt8.self).baseAddress!
            
            // Try with increasing buffer sizes
            var destinationCapacity = Swift.max(count * 4, 1024)
            for attempt in 0..<10 {
                let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: destinationCapacity)
                defer { destinationBuffer.deallocate() }
                
                let decompressedSize = compression_decode_buffer(
                    destinationBuffer, destinationCapacity,
                    sourcePtr, count,
                    nil, algorithm
                )
                
                if decompressedSize == 0 {
                    // Error occurred
                    return nil
                } else if decompressedSize < destinationCapacity {
                    // Success - buffer was large enough
                    return Data(bytes: destinationBuffer, count: decompressedSize)
                } else {
                    // Buffer might be too small, try larger
                    destinationCapacity *= 4
                    if attempt == 9 {
                        // Last attempt, use what we got
                        return Data(bytes: destinationBuffer, count: decompressedSize)
                    }
                }
            }
            
            return nil
        }
    }
    
    /// Calculate CRC32 checksum
    var crc32: UInt32 {
        var crc: UInt32 = 0xFFFFFFFF
        
        self.withUnsafeBytes { buffer in
            let bytes = buffer.bindMemory(to: UInt8.self)
            
            for byte in bytes {
                crc = (crc >> 8) ^ crcTable[Int((crc ^ UInt32(byte)) & 0xFF)]
            }
        }
        
        return ~crc
    }
}

// CRC32 lookup table
private let crcTable: [UInt32] = {
    var table = [UInt32](repeating: 0, count: 256)
    
    for i in 0..<256 {
        var crc = UInt32(i)
        for _ in 0..<8 {
            if crc & 1 != 0 {
                crc = (crc >> 1) ^ 0xEDB88320
            } else {
                crc >>= 1
            }
        }
        table[i] = crc
    }
    
    return table
}()

// MARK: - Path Utilities

public extension String {
    
    /// Normalize path separators for ZIP
    var normalizedZIPPath: String {
        // Replace backslashes with forward slashes
        var normalized = self.replacingOccurrences(of: "\\", with: "/")
        
        // Replace multiple slashes with single slash
        while normalized.contains("//") {
            normalized = normalized.replacingOccurrences(of: "//", with: "/")
        }
        
        // Remove leading slashes
        let trimmed = normalized.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        
        // Ensure directories end with slash
        if self.hasSuffix("/") || self.hasSuffix("\\") {
            return trimmed + "/"
        }
        
        return trimmed
    }
    
    /// Get parent directory path
    var parentZIPPath: String? {
        let components = self.split(separator: "/")
        guard components.count > 1 else { return nil }
        
        return components.dropLast().joined(separator: "/") + "/"
    }
    
    /// Check if path represents a directory
    var isZIPDirectory: Bool {
        return self.hasSuffix("/")
    }
}

// MARK: - Binary Reading Helpers

public extension Data {
    
    /// Read little-endian UInt16
    func readUInt16LE(at offset: Int) -> UInt16? {
        guard offset + 2 <= count else { return nil }
        let bytes = self[offset..<(offset + 2)]
        return bytes.withUnsafeBytes { buffer in
            let value = UInt16(buffer[0]) | (UInt16(buffer[1]) << 8)
            return value
        }
    }
    
    /// Read little-endian UInt32
    func readUInt32LE(at offset: Int) -> UInt32? {
        guard offset + 4 <= count else { return nil }
        let bytes = self[offset..<(offset + 4)]
        return bytes.withUnsafeBytes { buffer in
            let b0 = UInt32(buffer[0])
            let b1 = UInt32(buffer[1]) << 8
            let b2 = UInt32(buffer[2]) << 16
            let b3 = UInt32(buffer[3]) << 24
            return b0 | b1 | b2 | b3
        }
    }
    
    /// Read UTF-8 string
    func readUTF8String(at offset: Int, length: Int) -> String? {
        guard offset + length <= count else { return nil }
        let stringData = self[offset..<(offset + length)]
        return String(data: stringData, encoding: .utf8)
    }
}