//
//  RhoeDOCX.swift
//  RhoeDOCX
//
//  Public entry points for the active DOCX support layer.
//

import Foundation

/// Public namespace for the active `RhoeDOCX` module.
///
/// The normalized release surface focuses on:
/// - ZIP-based DOCX package inspection
/// - foundational WordprocessingML models
/// - lightweight Liquid rendering inside text nodes
/// - actor-based APIs that compose cleanly with Swift concurrency
///
public enum RhoeDOCX {
    
    /// Current module version string.
    public static let version = "0.1.0"
    
    /// Performs a quick structural validation on a DOCX file at a URL.
    public static func isValidDOCX(at url: URL) async -> Bool {
        do {
            let archive = ZIPArchive(url: url)
            let package = try await archive.open()
            
            // Check for required DOCX structure
            return package.exists(path: "[Content_Types].xml") &&
                   package.exists(path: "_rels/.rels") &&
                   package.exists(path: "word/document.xml")
        } catch {
            return false
        }
    }
    
    /// Performs a quick structural validation on in-memory DOCX data.
    public static func isValidDOCX(data: Data) async -> Bool {
        do {
            let archive = ZIPArchive(data: data)
            let package = try await archive.open()
            
            // Check for required DOCX structure
            return package.exists(path: "[Content_Types].xml") &&
                   package.exists(path: "_rels/.rels") &&
                   package.exists(path: "word/document.xml")
        } catch {
            return false
        }
    }
}

// MARK: - Public namespace
