//
//  ZIPArchive.swift
//  RhoeDOCX
//
//  Actor-backed ZIP reading for the active DOCX support layer.
//

import Foundation

/// Reads ZIP archives used by DOCX packages.
///
/// `ZIPArchive` provides the active ZIP surface that `RhoeDOCX` builds on:
/// opening an archive, streaming entries, and extracting file data.
public actor ZIPArchive: Sendable {
    
    /// Central directory structure for fast lookups
    private var centralDirectory: CentralDirectory?
    
    /// The underlying data source
    private let dataSource: ZIPDataSource
    
    /// Compression actor for parallel compression/decompression
    private let compressionActor = CompressionActor()
    
    // MARK: - Initialization
    
    /// Creates an archive reader backed by in-memory ZIP data.
    public init(data: Data) {
        self.dataSource = .memory(data)
    }
    
    /// Creates an archive reader backed by a file URL.
    public init(url: URL) {
        self.dataSource = .file(url)
    }
    
    // MARK: - Public API
    
    /// Parses the ZIP archive and returns a navigable package view.
    public func open() async throws -> ZIPPackage {
        // Parse End of Central Directory Record
        let eocd = try await findAndParseEOCD()
        
        // Parse Central Directory
        self.centralDirectory = try await parseCentralDirectory(eocd: eocd)
        
        // Build package structure
        return try await buildPackage()
    }
    
    /// Streams file entries without extracting their contents.
    public func stream() -> AsyncThrowingStream<ZIPEntry, Error> {
        AsyncThrowingStream { continuation in
            Task { [weak self] in
                guard let self = self else {
                    continuation.finish(throwing: ZIPError.invalidArchive("Archive deallocated"))
                    return
                }
                
                do {
                    let directory = try await self.getCentralDirectory()
                    for entry in directory.entries {
                        continuation.yield(entry)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    /// Extracts a single file entry by archive path.
    public func extract(path: String) async throws -> Data {
        let directory = try await getCentralDirectory()
        
        guard let entry = directory.entries.first(where: { $0.path == path }) else {
            throw ZIPError.entryNotFound(path)
        }
        
        return try await extractEntry(entry)
    }
    
    // MARK: - Private Implementation
    
    private func findAndParseEOCD() async throws -> EndOfCentralDirectory {
        let data = try await dataSource.readTail(size: 65536) // Read last 64KB
        
        // Search for EOCD signature (0x06054b50) from the end
        guard let eocdOffset = findEOCDSignature(in: data) else {
            throw ZIPError.invalidArchive("EOCD signature not found")
        }
        
        // Parse EOCD
        let eocdData = Data(data[eocdOffset...])
        return try EndOfCentralDirectory(data: eocdData)
    }
    
    private func parseCentralDirectory(eocd: EndOfCentralDirectory) async throws -> CentralDirectory {
        let cdData = try await dataSource.read(
            offset: Int(eocd.centralDirectoryOffset),
            size: Int(eocd.centralDirectorySize)
        )
        
        var entries: [ZIPEntry] = []
        var offset = 0
        
        while offset < cdData.count {
            let entryData = Data(cdData[offset...])
            let entry = try CentralDirectoryEntry(data: entryData)
            
            entries.append(ZIPEntry(
                path: entry.fileName,
                compressedSize: Int(entry.compressedSize),
                uncompressedSize: Int(entry.uncompressedSize),
                compressionMethod: entry.compressionMethod,
                crc32: entry.crc32,
                localHeaderOffset: Int(entry.localHeaderOffset),
                isDirectory: entry.fileName.hasSuffix("/"),
                lastModified: entry.lastModified,
                attributes: entry.externalAttributes
            ))
            
            offset += entry.totalSize
        }
        
        return CentralDirectory(entries: entries)
    }
    
    private func extractEntry(_ entry: ZIPEntry) async throws -> Data {
        // Read local file header
        let headerData = try await dataSource.read(
            offset: entry.localHeaderOffset,
            size: 30 // Minimum local header size
        )
        
        let localHeader = try LocalFileHeader(data: headerData)
        
        // Calculate data offset
        let dataOffset = entry.localHeaderOffset + localHeader.totalHeaderSize
        
        // Read compressed data
        let compressedData = try await dataSource.read(
            offset: dataOffset,
            size: entry.compressedSize
        )
        
        // Decompress if needed
        switch entry.compressionMethod {
        case .stored:
            return compressedData
        case .deflated:
            return try await compressionActor.decompress(compressedData)
        default:
            throw ZIPError.unsupportedCompression(entry.compressionMethod)
        }
    }
    
    private func findEOCDSignature(in data: Data) -> Int? {
        let signature: UInt32 = 0x06054b50
        let signatureBytes = withUnsafeBytes(of: signature.littleEndian) { Data($0) }
        
        // Search from end backwards
        guard data.count >= 22 else { return nil }
        
        for i in (0...(data.count - 22)).reversed() {
            // Check bounds before accessing
            guard i + 4 <= data.count else { continue }
            
            // Compare bytes directly
            var match = true
            for j in 0..<4 {
                if data[i + j] != signatureBytes[j] {
                    match = false
                    break
                }
            }
            
            if match {
                return i
            }
        }
        return nil
    }
    
    private func parseCentralDirectoryIfNeeded() async throws -> CentralDirectory {
        if let directory = centralDirectory {
            return directory
        }
        let eocd = try await findAndParseEOCD()
        let directory = try await parseCentralDirectory(eocd: eocd)
        self.centralDirectory = directory
        return directory
    }
    
    private func getCentralDirectory() async throws -> CentralDirectory {
        if let directory = centralDirectory {
            return directory
        }
        return try await parseCentralDirectoryIfNeeded()
    }
    
    private func buildPackage() async throws -> ZIPPackage {
        guard let directory = centralDirectory else {
            throw ZIPError.invalidArchive("No central directory")
        }
        
        var files: [String: ZIPEntry] = [:]
        var directories: Set<String> = []
        
        for entry in directory.entries {
            if entry.isDirectory {
                directories.insert(entry.path)
            } else {
                files[entry.path] = entry
                
                // Add parent directories
                let components = entry.path.split(separator: "/")
                for i in 1..<components.count {
                    let dir = components[0..<i].joined(separator: "/") + "/"
                    directories.insert(dir)
                }
            }
        }
        
        return ZIPPackage(
            files: files,
            directories: directories,
            archive: self
        )
    }
}

// MARK: - ZIP Data Structures

/// End of Central Directory Record
private struct EndOfCentralDirectory {
    let signature: UInt32 = 0x06054b50
    let diskNumber: UInt16
    let centralDirectoryDisk: UInt16
    let centralDirectoryCount: UInt16
    let totalCentralDirectoryCount: UInt16
    let centralDirectorySize: UInt32
    let centralDirectoryOffset: UInt32
    let commentLength: UInt16
    let comment: String
    
    init(data: Data) throws {
        guard data.count >= 22 else {
            throw ZIPError.invalidArchive("EOCD too small")
        }
        
        var offset = 0
        
        // Verify signature
        guard let sig = data.readUInt32LE(at: offset) else {
            throw ZIPError.invalidArchive("EOCD too small")
        }
        guard sig == signature else {
            throw ZIPError.invalidArchive("Invalid EOCD signature")
        }
        offset += 4
        
        guard let diskNum = data.readUInt16LE(at: offset) else {
            throw ZIPError.invalidArchive("EOCD too small")
        }
        diskNumber = diskNum
        offset += 2
        
        guard let cdDisk = data.readUInt16LE(at: offset) else {
            throw ZIPError.invalidArchive("EOCD too small")
        }
        centralDirectoryDisk = cdDisk
        offset += 2
        
        guard let cdCount = data.readUInt16LE(at: offset) else {
            throw ZIPError.invalidArchive("EOCD too small")
        }
        centralDirectoryCount = cdCount
        offset += 2
        
        guard let totalCDCount = data.readUInt16LE(at: offset) else {
            throw ZIPError.invalidArchive("EOCD too small")
        }
        totalCentralDirectoryCount = totalCDCount
        offset += 2
        
        guard let cdSize = data.readUInt32LE(at: offset) else {
            throw ZIPError.invalidArchive("EOCD too small")
        }
        centralDirectorySize = cdSize
        offset += 4
        
        guard let cdOffset = data.readUInt32LE(at: offset) else {
            throw ZIPError.invalidArchive("EOCD too small")
        }
        centralDirectoryOffset = cdOffset
        offset += 4
        
        guard let commLen = data.readUInt16LE(at: offset) else {
            throw ZIPError.invalidArchive("EOCD too small")
        }
        commentLength = commLen
        offset += 2
        
        if commentLength > 0 {
            let commentData = Data(data[offset..<(offset + Int(commentLength))])
            comment = String(data: commentData, encoding: .utf8) ?? ""
        } else {
            comment = ""
        }
    }
}

/// Central Directory Entry
private struct CentralDirectoryEntry {
    let signature: UInt32 = 0x02014b50
    let versionMadeBy: UInt16
    let versionNeeded: UInt16
    let flags: UInt16
    let compressionMethod: CompressionMethod
    let lastModifiedTime: UInt16
    let lastModifiedDate: UInt16
    let crc32: UInt32
    let compressedSize: UInt32
    let uncompressedSize: UInt32
    let fileNameLength: UInt16
    let extraFieldLength: UInt16
    let fileCommentLength: UInt16
    let diskNumberStart: UInt16
    let internalAttributes: UInt16
    let externalAttributes: UInt32
    let localHeaderOffset: UInt32
    let fileName: String
    let extraField: Data
    let fileComment: String
    
    var totalSize: Int {
        46 + Int(fileNameLength) + Int(extraFieldLength) + Int(fileCommentLength)
    }
    
    var lastModified: Date {
        ZIPDateConverter.dateFromDOSDateTime(date: lastModifiedDate, time: lastModifiedTime)
    }
    
    init(data: Data) throws {
        guard data.count >= 46 else {
            throw ZIPError.invalidArchive("Central directory entry too small")
        }
        
        var offset = 0
        
        // Verify signature
        guard let sig = data.readUInt32LE(at: offset) else {
            throw ZIPError.invalidArchive("Central directory entry too small")
        }
        guard sig == signature else {
            throw ZIPError.invalidArchive("Invalid central directory entry signature")
        }
        offset += 4
        
        guard let vmb = data.readUInt16LE(at: offset) else {
            throw ZIPError.invalidArchive("Central directory entry too small")
        }
        versionMadeBy = vmb
        offset += 2
        
        guard let vn = data.readUInt16LE(at: offset) else {
            throw ZIPError.invalidArchive("Central directory entry too small")
        }
        versionNeeded = vn
        offset += 2
        
        guard let f = data.readUInt16LE(at: offset) else {
            throw ZIPError.invalidArchive("Central directory entry too small")
        }
        flags = f
        offset += 2
        
        guard let method = data.readUInt16LE(at: offset) else {
            throw ZIPError.invalidArchive("Central directory entry too small")
        }
        compressionMethod = CompressionMethod(rawValue: method) ?? .unknown
        offset += 2
        
        guard let lmt = data.readUInt16LE(at: offset) else {
            throw ZIPError.invalidArchive("Central directory entry too small")
        }
        lastModifiedTime = lmt
        offset += 2
        
        guard let lmd = data.readUInt16LE(at: offset) else {
            throw ZIPError.invalidArchive("Central directory entry too small")
        }
        lastModifiedDate = lmd
        offset += 2
        
        guard let c = data.readUInt32LE(at: offset) else {
            throw ZIPError.invalidArchive("Central directory entry too small")
        }
        crc32 = c
        offset += 4
        
        guard let cs = data.readUInt32LE(at: offset) else {
            throw ZIPError.invalidArchive("Central directory entry too small")
        }
        compressedSize = cs
        offset += 4
        
        guard let us = data.readUInt32LE(at: offset) else {
            throw ZIPError.invalidArchive("Central directory entry too small")
        }
        uncompressedSize = us
        offset += 4
        
        guard let fnl = data.readUInt16LE(at: offset) else {
            throw ZIPError.invalidArchive("Central directory entry too small")
        }
        fileNameLength = fnl
        offset += 2
        
        guard let efl = data.readUInt16LE(at: offset) else {
            throw ZIPError.invalidArchive("Central directory entry too small")
        }
        extraFieldLength = efl
        offset += 2
        
        guard let fcl = data.readUInt16LE(at: offset) else {
            throw ZIPError.invalidArchive("Central directory entry too small")
        }
        fileCommentLength = fcl
        offset += 2
        
        guard let dns = data.readUInt16LE(at: offset) else {
            throw ZIPError.invalidArchive("Central directory entry too small")
        }
        diskNumberStart = dns
        offset += 2
        
        guard let ia = data.readUInt16LE(at: offset) else {
            throw ZIPError.invalidArchive("Central directory entry too small")
        }
        internalAttributes = ia
        offset += 2
        
        guard let ea = data.readUInt32LE(at: offset) else {
            throw ZIPError.invalidArchive("Central directory entry too small")
        }
        externalAttributes = ea
        offset += 4
        
        guard let lho = data.readUInt32LE(at: offset) else {
            throw ZIPError.invalidArchive("Central directory entry too small")
        }
        localHeaderOffset = lho
        offset += 4
        
        // Read variable length fields
        let fileNameData = Data(data[offset..<(offset + Int(fileNameLength))])
        fileName = String(data: fileNameData, encoding: .utf8) ?? ""
        offset += Int(fileNameLength)
        
        extraField = Data(data[offset..<(offset + Int(extraFieldLength))])
        offset += Int(extraFieldLength)
        
        if fileCommentLength > 0 {
            let commentData = Data(data[offset..<(offset + Int(fileCommentLength))])
            fileComment = String(data: commentData, encoding: .utf8) ?? ""
        } else {
            fileComment = ""
        }
    }
}

/// Local File Header
private struct LocalFileHeader {
    let signature: UInt32 = 0x04034b50
    let versionNeeded: UInt16
    let flags: UInt16
    let compressionMethod: UInt16
    let lastModifiedTime: UInt16
    let lastModifiedDate: UInt16
    let crc32: UInt32
    let compressedSize: UInt32
    let uncompressedSize: UInt32
    let fileNameLength: UInt16
    let extraFieldLength: UInt16
    
    var totalHeaderSize: Int {
        30 + Int(fileNameLength) + Int(extraFieldLength)
    }
    
    init(data: Data) throws {
        guard data.count >= 30 else {
            throw ZIPError.invalidArchive("Local file header too small")
        }
        
        var offset = 0
        
        // Verify signature
        guard let sig = data.readUInt32LE(at: offset) else {
            throw ZIPError.invalidArchive("Local file header too small")
        }
        guard sig == signature else {
            throw ZIPError.invalidArchive("Invalid local file header signature")
        }
        offset += 4
        
        guard let vn = data.readUInt16LE(at: offset) else {
            throw ZIPError.invalidArchive("Local file header too small")
        }
        versionNeeded = vn
        offset += 2
        
        guard let f = data.readUInt16LE(at: offset) else {
            throw ZIPError.invalidArchive("Local file header too small")
        }
        flags = f
        offset += 2
        
        guard let cm = data.readUInt16LE(at: offset) else {
            throw ZIPError.invalidArchive("Local file header too small")
        }
        compressionMethod = cm
        offset += 2
        
        guard let lmt = data.readUInt16LE(at: offset) else {
            throw ZIPError.invalidArchive("Local file header too small")
        }
        lastModifiedTime = lmt
        offset += 2
        
        guard let lmd = data.readUInt16LE(at: offset) else {
            throw ZIPError.invalidArchive("Local file header too small")
        }
        lastModifiedDate = lmd
        offset += 2
        
        guard let c = data.readUInt32LE(at: offset) else {
            throw ZIPError.invalidArchive("Local file header too small")
        }
        crc32 = c
        offset += 4
        
        guard let cs = data.readUInt32LE(at: offset) else {
            throw ZIPError.invalidArchive("Local file header too small")
        }
        compressedSize = cs
        offset += 4
        
        guard let us = data.readUInt32LE(at: offset) else {
            throw ZIPError.invalidArchive("Local file header too small")
        }
        uncompressedSize = us
        offset += 4
        
        guard let fnl = data.readUInt16LE(at: offset) else {
            throw ZIPError.invalidArchive("Local file header too small")
        }
        fileNameLength = fnl
        offset += 2
        
        guard let efl = data.readUInt16LE(at: offset) else {
            throw ZIPError.invalidArchive("Local file header too small")
        }
        extraFieldLength = efl
    }
}

// MARK: - Supporting Types

/// Central directory for fast lookups
private struct CentralDirectory {
    let entries: [ZIPEntry]
}

/// Compression methods understood by the active ZIP reader.
public enum CompressionMethod: UInt16, Sendable {
    case stored = 0
    case deflated = 8
    case unknown = 0xFFFF
}

/// ZIP data source abstraction
private enum ZIPDataSource {
    case memory(Data)
    case file(URL)
    
    func read(offset: Int, size: Int) async throws -> Data {
        switch self {
        case .memory(let data):
            guard offset + size <= data.count else {
                throw ZIPError.invalidArchive("Read beyond data bounds")
            }
            return Data(data[offset..<(offset + size)])
            
        case .file(let url):
            let handle = try FileHandle(forReadingFrom: url)
            defer { try? handle.close() }
            
            try handle.seek(toOffset: UInt64(offset))
            guard let data = try handle.read(upToCount: size) else {
                throw ZIPError.invalidArchive("Failed to read from file")
            }
            return data
        }
    }
    
    func readTail(size: Int) async throws -> Data {
        switch self {
        case .memory(let data):
            let start = Swift.max(0, data.count - size)
            return Data(data[start..<data.count])
            
        case .file(let url):
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            guard let fileSize = attributes[.size] as? Int else {
                throw ZIPError.invalidArchive("Cannot determine file size")
            }
            
            let offset = max(0, fileSize - size)
            return try await read(offset: offset, size: min(size, fileSize))
        }
    }
}
