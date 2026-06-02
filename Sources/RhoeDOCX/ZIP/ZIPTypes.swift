//
//  ZIPTypes.swift
//  RhoeDOCX
//
//  Public ZIP data structures used by `RhoeDOCX`.
//

import Foundation

/// Metadata for a single file entry in a ZIP archive.
public struct ZIPEntry: Sendable, Hashable {
    /// Full path within the archive
    public let path: String
    
    /// Compressed size in bytes
    public let compressedSize: Int
    
    /// Uncompressed size in bytes
    public let uncompressedSize: Int
    
    /// Compression method used
    public let compressionMethod: CompressionMethod
    
    /// CRC32 checksum
    public let crc32: UInt32
    
    /// Offset to local file header
    let localHeaderOffset: Int
    
    /// Whether this is a directory entry
    public let isDirectory: Bool
    
    /// Last modification date
    public let lastModified: Date
    
    /// External file attributes
    public let attributes: UInt32
    
    /// The file name portion of ``path``.
    public var fileName: String {
        if isDirectory {
            return String(path.dropLast()) // Remove trailing slash
                .split(separator: "/").last.map(String.init) ?? path
        } else {
            return path.split(separator: "/").last.map(String.init) ?? path
        }
    }
    
    /// The containing directory path, always ending in `/` when present.
    public var directoryPath: String {
        let components = path.split(separator: "/")
        if components.count > 1 {
            return components.dropLast().joined(separator: "/") + "/"
        }
        return ""
    }
}

/// A navigable view over an opened ZIP archive.
public struct ZIPPackage: Sendable {
    /// All file entries (excludes directories)
    public let files: [String: ZIPEntry]
    
    /// All directory paths
    public let directories: Set<String>
    
    /// Reference to the archive for extraction
    private let archive: ZIPArchive
    
    init(files: [String: ZIPEntry], directories: Set<String>, archive: ZIPArchive) {
        self.files = files
        self.directories = directories
        self.archive = archive
    }
    
    /// Lists entries at a specific directory level.
    public func entries(at path: String = "") -> [ZIPEntry] {
        let normalizedPath = path.isEmpty ? "" : (path.hasSuffix("/") ? path : path + "/")
        
        return files.values.filter { entry in
            if normalizedPath.isEmpty {
                // Root level - no slashes in name
                return !entry.path.dropLast().contains("/")
            } else {
                // Specific directory
                return entry.directoryPath == normalizedPath
            }
        }.sorted { $0.path < $1.path }
    }
    
    /// Extracts the contents of a file entry.
    public func extractData(for path: String) async throws -> Data {
        guard files[path] != nil else {
            throw ZIPError.entryNotFound(path)
        }
        
        return try await archive.extract(path: path)
    }
    
    /// Returns whether a file or directory path exists in the archive.
    public func exists(path: String) -> Bool {
        if files[path] != nil {
            return true
        }
        
        let dirPath = path.hasSuffix("/") ? path : path + "/"
        return directories.contains(dirPath)
    }
}

/// Errors that can occur while reading or building ZIP archives.
public enum ZIPError: Error, Sendable {
    case invalidArchive(String)
    case entryNotFound(String)
    case unsupportedCompression(CompressionMethod)
    case compressionFailed(String)
    case decompressionFailed(String)
    case crcMismatch(expected: UInt32, actual: UInt32)
    case invalidData(String)
}

/// Builds new ZIP archives in memory.
public actor ZIPBuilder {
    private var entries: [(path: String, data: Data, date: Date, compressionMethod: CompressionMethod)] = []
    private let compressionActor = CompressionActor()
    
    public init() {}
    
    /// Adds a file entry to the archive being built.
    public func addFile(
        path: String,
        data: Data,
        date: Date = Date(),
        compressionMethod: CompressionMethod = .deflated
    ) {
        entries.append((path, data, date, compressionMethod))
    }
    
    /// Adds an explicit directory entry.
    public func addDirectory(path: String, date: Date = Date()) {
        let dirPath = path.hasSuffix("/") ? path : path + "/"
        entries.append((dirPath, Data(), date, .stored))
    }
    
    /// Serializes all queued entries into ZIP data.
    public func build() async throws -> Data {
        var output = Data()
        var centralDirectory = Data()
        var cdEntries: [CentralDirectoryRecord] = []
        
        // Write local file headers and data
        for entry in entries {
            let localOffset = output.count
            
            // Compress data if needed
            let processedData: Data
            let crc32: UInt32
            
            switch entry.compressionMethod {
            case .stored:
                processedData = entry.data
                crc32 = entry.data.crc32
                
            case .deflated:
                if entry.data.isEmpty {
                    processedData = entry.data
                    crc32 = 0
                } else {
                    processedData = try await compressionActor.compress(entry.data)
                    crc32 = entry.data.crc32
                }
                
            default:
                throw ZIPError.unsupportedCompression(entry.compressionMethod)
            }
            
            // Write local file header
            let localHeader = LocalFileHeaderWriter(
                path: entry.path,
                date: entry.date,
                crc32: crc32,
                compressedSize: UInt32(processedData.count),
                uncompressedSize: UInt32(entry.data.count),
                compressionMethod: entry.compressionMethod
            )
            
            output.append(localHeader.data)
            output.append(processedData)
            
            // Record for central directory
            cdEntries.append(CentralDirectoryRecord(
                path: entry.path,
                date: entry.date,
                crc32: crc32,
                compressedSize: UInt32(processedData.count),
                uncompressedSize: UInt32(entry.data.count),
                compressionMethod: entry.compressionMethod,
                localHeaderOffset: UInt32(localOffset)
            ))
        }
        
        // Write central directory
        let cdOffset = output.count
        
        for record in cdEntries {
            centralDirectory.append(record.data)
        }
        
        output.append(centralDirectory)
        
        // Write end of central directory
        let eocd = EndOfCentralDirectoryWriter(
            entryCount: UInt16(cdEntries.count),
            centralDirectorySize: UInt32(centralDirectory.count),
            centralDirectoryOffset: UInt32(cdOffset)
        )
        
        output.append(eocd.data)
        
        return output
    }
}

/// Compression/Decompression actor for thread-safe operations
actor CompressionActor {
    
    func compress(_ data: Data) async throws -> Data {
        return try await Task.detached {
            guard let compressed = data.deflate() else {
                throw ZIPError.compressionFailed("Deflate compression failed")
            }
            return compressed
        }.value
    }
    
    func decompress(_ data: Data) async throws -> Data {
        return try await Task.detached {
            guard let decompressed = data.inflate() else {
                throw ZIPError.decompressionFailed("Inflate decompression failed")
            }
            return decompressed
        }.value
    }
}

// MARK: - Internal Helpers

/// Local file header writer
private struct LocalFileHeaderWriter {
    let data: Data
    
    init(path: String, date: Date, crc32: UInt32, compressedSize: UInt32, 
         uncompressedSize: UInt32, compressionMethod: CompressionMethod) {
        
        var buffer = Data()
        
        // Signature
        buffer.append(UInt32(0x04034b50).littleEndianData)
        
        // Version needed
        buffer.append(UInt16(20).littleEndianData) // 2.0
        
        // Flags
        buffer.append(UInt16(0).littleEndianData)
        
        // Compression method
        buffer.append(compressionMethod.rawValue.littleEndianData)
        
        // DOS date/time
        let (dosDate, dosTime) = ZIPDateConverter.dosDateTimeFromDate(date)
        buffer.append(dosTime.littleEndianData)
        buffer.append(dosDate.littleEndianData)
        
        // CRC32
        buffer.append(crc32.littleEndianData)
        
        // Sizes
        buffer.append(compressedSize.littleEndianData)
        buffer.append(uncompressedSize.littleEndianData)
        
        // File name length
        let fileNameData = path.data(using: .utf8) ?? Data()
        buffer.append(UInt16(fileNameData.count).littleEndianData)
        
        // Extra field length
        buffer.append(UInt16(0).littleEndianData)
        
        // File name
        buffer.append(fileNameData)
        
        self.data = buffer
    }
}

/// Central directory record
private struct CentralDirectoryRecord {
    let data: Data
    
    init(path: String, date: Date, crc32: UInt32, compressedSize: UInt32,
         uncompressedSize: UInt32, compressionMethod: CompressionMethod,
         localHeaderOffset: UInt32) {
        
        var buffer = Data()
        
        // Signature
        buffer.append(UInt32(0x02014b50).littleEndianData)
        
        // Version made by (Unix, version 3.0)
        buffer.append(UInt16(0x031E).littleEndianData)
        
        // Version needed
        buffer.append(UInt16(20).littleEndianData)
        
        // Flags
        buffer.append(UInt16(0).littleEndianData)
        
        // Compression method
        buffer.append(compressionMethod.rawValue.littleEndianData)
        
        // DOS date/time
        let (dosDate, dosTime) = ZIPDateConverter.dosDateTimeFromDate(date)
        buffer.append(dosTime.littleEndianData)
        buffer.append(dosDate.littleEndianData)
        
        // CRC32
        buffer.append(crc32.littleEndianData)
        
        // Sizes
        buffer.append(compressedSize.littleEndianData)
        buffer.append(uncompressedSize.littleEndianData)
        
        // File name length
        let fileNameData = path.data(using: .utf8) ?? Data()
        buffer.append(UInt16(fileNameData.count).littleEndianData)
        
        // Extra field length
        buffer.append(UInt16(0).littleEndianData)
        
        // File comment length
        buffer.append(UInt16(0).littleEndianData)
        
        // Disk number start
        buffer.append(UInt16(0).littleEndianData)
        
        // Internal file attributes
        buffer.append(UInt16(0).littleEndianData)
        
        // External file attributes
        let isDirectory = path.hasSuffix("/")
        let attributes: UInt32 = isDirectory ? 0x41ED0010 : 0x81A40000
        buffer.append(attributes.littleEndianData)
        
        // Local header offset
        buffer.append(localHeaderOffset.littleEndianData)
        
        // File name
        buffer.append(fileNameData)
        
        self.data = buffer
    }
}

/// End of central directory writer
private struct EndOfCentralDirectoryWriter {
    let data: Data
    
    init(entryCount: UInt16, centralDirectorySize: UInt32, centralDirectoryOffset: UInt32) {
        var buffer = Data()
        
        // Signature
        buffer.append(UInt32(0x06054b50).littleEndianData)
        
        // Disk numbers
        buffer.append(UInt16(0).littleEndianData) // This disk
        buffer.append(UInt16(0).littleEndianData) // Central directory disk
        
        // Entry counts
        buffer.append(entryCount.littleEndianData) // Entries on this disk
        buffer.append(entryCount.littleEndianData) // Total entries
        
        // Central directory info
        buffer.append(centralDirectorySize.littleEndianData)
        buffer.append(centralDirectoryOffset.littleEndianData)
        
        // Comment length
        buffer.append(UInt16(0).littleEndianData)
        
        self.data = buffer
    }
}

// MARK: - Extensions

extension FixedWidthInteger {
    var littleEndianData: Data {
        withUnsafeBytes(of: self.littleEndian) { Data($0) }
    }
}
