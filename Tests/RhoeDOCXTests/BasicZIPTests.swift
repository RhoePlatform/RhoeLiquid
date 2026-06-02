//
//  BasicZIPTests.swift
//  RhoeDOCXTests
//
//  Basic tests for ZIP implementation
//

import XCTest
@testable import RhoeDOCX

class BasicZIPTests: XCTestCase {
    
    func testCRC32Calculation() {
        let testData = "Hello, World!".data(using: .utf8)!
        let crc = testData.crc32
        
        // Known CRC32 for "Hello, World!"
        XCTAssertEqual(crc, 0xEC4AC3D0)
    }
    
    func testXMLEscaping() {
        let input = "Test & < > \" ' Special"
        let escaped = input.xmlEscaped
        
        XCTAssertEqual(escaped, "Test &amp; &lt; &gt; &quot; &apos; Special")
        
        let unescaped = escaped.xmlUnescaped
        XCTAssertEqual(unescaped, input)
    }
    
    func testPathNormalization() {
        XCTAssertEqual("test.txt".normalizedZIPPath, "test.txt")
        XCTAssertEqual("/test.txt".normalizedZIPPath, "test.txt")
        XCTAssertEqual("folder\\file.txt".normalizedZIPPath, "folder/file.txt")
        XCTAssertEqual("folder/".normalizedZIPPath, "folder/")
        
        XCTAssertTrue("folder/".isZIPDirectory)
        XCTAssertFalse("file.txt".isZIPDirectory)
    }
    
    func testCompressionDeflate() {
        let originalData = String(repeating: "Hello World! ", count: 100).data(using: .utf8)!
        
        guard let compressed = originalData.deflate() else {
            XCTFail("Compression failed")
            return
        }
        
        // Compressed should be smaller
        XCTAssertLessThan(compressed.count, originalData.count)
        
        guard let decompressed = compressed.inflate() else {
            XCTFail("Decompression failed")
            return
        }
        
        // Should match original
        XCTAssertEqual(decompressed, originalData)
    }
}