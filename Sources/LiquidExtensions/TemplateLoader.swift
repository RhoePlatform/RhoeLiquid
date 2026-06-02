//
//  TemplateLoader.swift
//  LiquidExtensions
//
//  Template loading with security protections
//

import Foundation
import LiquidCore
import LiquidLexer
import LiquidParser

/// Secure template loader with path traversal protection
public actor TemplateLoader {
    
    // MARK: - Configuration
    
    /// Base directory for template loading
    private let baseDirectory: URL?
    
    /// Allowed template extensions
    private let allowedExtensions: Set<String>
    
    /// Whether to allow absolute paths
    private let allowAbsolutePaths: Bool
    
    // MARK: - Initialization
    
    public init(
        baseDirectory: URL? = nil,
        allowedExtensions: Set<String> = ["liquid", "html", "txt", "md"],
        allowAbsolutePaths: Bool = false
    ) {
        self.baseDirectory = baseDirectory
        self.allowedExtensions = allowedExtensions
        self.allowAbsolutePaths = allowAbsolutePaths
    }
    
    // MARK: - Template Loading
    
    /// Loads a template from a file path with security checks.
    ///
    /// - Parameter path: The template path to load
    /// - Returns: The template content
    /// - Throws: TemplateLoaderError if the path is invalid or insecure
    public func loadTemplate(_ path: String, relativeTo parentTemplatePath: String? = nil) async throws -> String {
        // Validate the path
        try validatePath(path)
        
        // Resolve the full path
        let resolvedURL = try resolvePath(path, relativeTo: parentTemplatePath)
        
        // Ensure the resolved path is within allowed directories
        try validateResolvedPath(resolvedURL)
        
        // Try exact path first, then with .liquid extension (Shopify convention)
        let resolvedPath: URL
        if FileManager.default.fileExists(atPath: resolvedURL.path) {
            resolvedPath = resolvedURL
        } else {
            let withExtension = resolvedURL.appendingPathExtension("liquid")
            guard FileManager.default.fileExists(atPath: withExtension.path) else {
                throw TemplateLoaderError.templateNotFound(resolvedURL.path)
            }
            resolvedPath = withExtension
        }

        do {
            return try String(contentsOf: resolvedPath, encoding: .utf8)
        } catch {
            throw TemplateLoaderError.ioError(error.localizedDescription)
        }
    }
    
    /// Checks if a template exists at the given path
    ///
    /// - Parameter path: The template path to check
    /// - Returns: true if the template exists and is accessible
    public func templateExists(_ path: String, relativeTo parentTemplatePath: String? = nil) async -> Bool {
        do {
            let resolvedURL = try resolvePath(path, relativeTo: parentTemplatePath)
            try validateResolvedPath(resolvedURL)
            return FileManager.default.fileExists(atPath: resolvedURL.path)
        } catch {
            return false
        }
    }
    
    /// Loads a template and parses it into an AST
    ///
    /// - Parameter path: The template path to load
    /// - Returns: The parsed AST
    /// - Throws: TemplateLoaderError or parsing errors
    public func loadTemplateAST(
        _ path: String,
        relativeTo parentTemplatePath: String? = nil,
        customTagDescriptors: [CustomTagDescriptor] = []
    ) async throws -> ASTNode {
        // Load the template content
        let content = try await loadTemplate(path, relativeTo: parentTemplatePath)
        
        // Lex and parse the template
        let lexer = Lexer(content)
        let tokens = try lexer.tokenize()
        
        let parser = Parser(
            consuming: tokens,
            source: content,
            customTags: customTagDescriptors
        )
        return try parser.parse()
    }

    /// Resolves a template path to a validated canonical file-system path.
    public func resolvedTemplatePath(for path: String, relativeTo parentTemplatePath: String? = nil) throws -> String {
        try validatePath(path)
        let resolvedURL = try resolvePath(path, relativeTo: parentTemplatePath)
        try validateResolvedPath(resolvedURL)
        return resolvedURL.path
    }
    
    // MARK: - Path Validation
    
    /// Validates a template path for security issues
    private func validatePath(_ path: String) throws {
        // Check for empty path
        guard !path.isEmpty else {
            throw TemplateLoaderError.invalidPath("Empty path")
        }
        
        // Check for path traversal attempts
        let pathComponents = path.components(separatedBy: "/")
        for component in pathComponents {
            if component == ".." {
                throw TemplateLoaderError.pathTraversal("Path traversal detected: \(path)")
            }
            if component == "." && pathComponents.count > 1 {
                // Single dot is okay only as the full path
                throw TemplateLoaderError.pathTraversal("Relative path component detected: \(path)")
            }
        }
        
        // Check for absolute paths if not allowed
        if !allowAbsolutePaths {
            if path.hasPrefix("/") || path.hasPrefix("~") {
                throw TemplateLoaderError.absolutePathNotAllowed("Absolute paths not allowed: \(path)")
            }
            
            // Check for Windows absolute paths
            if path.count >= 3 && path.dropFirst().first == ":" {
                throw TemplateLoaderError.absolutePathNotAllowed("Absolute paths not allowed: \(path)")
            }
        }
        
        // Check for null bytes (path injection)
        if path.contains("\0") {
            throw TemplateLoaderError.invalidPath("Null byte in path: \(path)")
        }
        
        // Check for URL schemes
        let schemes = ["file://", "http://", "https://", "ftp://", "data:"]
        for scheme in schemes {
            if path.lowercased().hasPrefix(scheme) {
                throw TemplateLoaderError.invalidPath("URL schemes not allowed: \(path)")
            }
        }
    }
    
    /// Resolves a template path to a full URL
    private func resolvePath(_ path: String, relativeTo parentTemplatePath: String? = nil) throws -> URL {
        let cleanPath = path.trimmingCharacters(in: .whitespacesAndNewlines)

        if Self.isAbsolutePath(cleanPath) {
            return URL(fileURLWithPath: cleanPath).standardizedFileURL
        }

        if let parentTemplatePath {
            let parentDirectory = URL(fileURLWithPath: parentTemplatePath)
                .standardizedFileURL
                .deletingLastPathComponent()
            return parentDirectory.appendingPathComponent(cleanPath).standardizedFileURL
        }

        if let baseDirectory = baseDirectory {
            return baseDirectory.appendingPathComponent(cleanPath).standardizedFileURL
        }

        let currentDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        return currentDirectory.appendingPathComponent(cleanPath).standardizedFileURL
    }
    
    /// Validates that a resolved path is within allowed directories
    private func validateResolvedPath(_ url: URL) throws {
        // Get the canonical path
        let canonicalPath = url.standardizedFileURL.path
        
        // If we have a base directory, ensure the path is within it
        if let baseDirectory = baseDirectory {
            let basePath = baseDirectory.standardizedFileURL.path
            
            // Check if the resolved path is within the base directory
            if !canonicalPath.hasPrefix(basePath) {
                throw TemplateLoaderError.pathTraversal(
                    "Path escapes base directory: \(canonicalPath)"
                )
            }
        }
        
        // Check file extension
        let fileExtension = url.pathExtension.lowercased()
        if !fileExtension.isEmpty && !allowedExtensions.contains(fileExtension) {
            throw TemplateLoaderError.invalidExtension(
                "File extension '\(fileExtension)' not allowed"
            )
        }
        
        // Additional security checks
        let filename = url.lastPathComponent
        
        // Don't allow hidden files
        if filename.hasPrefix(".") {
            throw TemplateLoaderError.invalidPath("Hidden files not allowed: \(filename)")
        }
        
        // Don't allow system files
        let systemFiles = ["passwd", "shadow", "hosts", "sudoers", ".bash_history", ".ssh"]
        for systemFile in systemFiles {
            if filename.contains(systemFile) {
                throw TemplateLoaderError.invalidPath("System file access not allowed: \(filename)")
            }
        }
    }
}

// MARK: - Errors

/// Errors that can occur during template loading
public enum TemplateLoaderError: LocalizedError, Sendable {
    case invalidPath(String)
    case pathTraversal(String)
    case absolutePathNotAllowed(String)
    case invalidExtension(String)
    case templateNotFound(String)
    case ioError(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidPath(let detail):
            return "Invalid template path: \(detail)"
        case .pathTraversal(let detail):
            return "Path traversal attempt blocked: \(detail)"
        case .absolutePathNotAllowed(let detail):
            return "Absolute path not allowed: \(detail)"
        case .invalidExtension(let detail):
            return "Invalid file extension: \(detail)"
        case .templateNotFound(let path):
            return "Template not found: \(path)"
        case .ioError(let detail):
            return "I/O error: \(detail)"
        }
    }
}

// MARK: - Safe Path Utilities

public extension TemplateLoader {
    static func isAbsolutePath(_ path: String) -> Bool {
        if path.hasPrefix("/") || path.hasPrefix("~") {
            return true
        }

        if path.count >= 2 {
            let scalars = Array(path.unicodeScalars)
            if scalars.count >= 2,
               CharacterSet.letters.contains(scalars[0]),
               scalars[1] == ":" {
                return true
            }
        }

        return false
    }

    /// Safely joins path components
    static func safePath(components: String...) -> String {
        return components
            .filter { !$0.isEmpty }
            .map { component in
                // Remove any path separators from individual components
                component.replacingOccurrences(of: "/", with: "")
                    .replacingOccurrences(of: "\\", with: "")
            }
            .joined(separator: "/")
    }
    
    /// Checks if a path is safe (no traversal)
    static func isPathSafe(_ path: String) -> Bool {
        do {
            // Create a non-actor version of path validation
            try validatePathStatic(path)
            return true
        } catch {
            return false
        }
    }
    
    /// Static version of path validation for non-async contexts
    private static func validatePathStatic(_ path: String) throws {
        // Check for empty path
        guard !path.isEmpty else {
            throw TemplateLoaderError.invalidPath("Empty path")
        }
        
        // Check for path traversal attempts
        let pathComponents = path.components(separatedBy: "/")
        for component in pathComponents {
            if component == ".." {
                throw TemplateLoaderError.pathTraversal("Path traversal detected: \(path)")
            }
            if component == "." && pathComponents.count > 1 {
                throw TemplateLoaderError.pathTraversal("Relative path component detected: \(path)")
            }
        }
        
        // Check for null bytes (path injection)
        if path.contains("\0") {
            throw TemplateLoaderError.invalidPath("Null byte in path: \(path)")
        }
        
        // Check for URL schemes
        let schemes = ["file://", "http://", "https://", "ftp://", "data:"]
        for scheme in schemes {
            if path.lowercased().hasPrefix(scheme) {
                throw TemplateLoaderError.invalidPath("URL schemes not allowed: \(path)")
            }
        }
    }
}
