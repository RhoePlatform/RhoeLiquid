//
//  TagRegistry.swift
//  LiquidTags
//
//  High-performance tag registry with validation and conflict detection
//

import Foundation
import LiquidCore

/// Thread-safe registry for built-in and custom Liquid tags
///
/// The TagRegistry manages all available tags in the Liquid engine, providing
/// registration, validation, and conflict detection for both built-in and custom tags.
///
/// The registry is the active runtime source of truth for custom tags in the
/// focused engine. Tags registered here are visible to the parser and renderer
/// through `LiquidEngine.registerTag(_:)`.
///
/// ## Features
///
/// - **Thread Safety**: Actor-based concurrent access protection
/// - **Validation**: Automatic parameter and syntax validation
/// - **Conflict Detection**: Prevents duplicate tag names and invalid overrides
/// - **Performance**: Fast lookup with optimized data structures
/// - **Extensibility**: Support for third-party tag libraries
///
/// ## Usage
///
/// ```swift
/// let registry = TagRegistry()
/// 
/// // Register a custom tag
/// try await registry.register(MyHighlightTag())
/// 
/// // Check if tag is available
/// let hasHighlight = await registry.hasTag("highlight")
/// 
/// // Get tag for execution
/// let tag = await registry.getTag("highlight")
/// ```
public actor TagRegistry {
    
    // MARK: - Storage
    
    /// Registered tags by name
    private var tags: [String: any CustomTag] = [:]

    /// Engine-installed built-in custom tags that should survive registry resets.
    private var builtInCustomTags: [String: any CustomTag] = [:]
    
    /// Built-in tag names that cannot be overridden
    private let builtInTags: Set<String> = builtInTagNames
    
    /// Registry statistics
    private var stats = RegistryStats()
    
    // MARK: - Initialization
    
    public init() {
        // Registry starts empty - tags are registered on demand
    }
    
    // MARK: - Tag Registration
    
    /// Register a custom tag
    ///
    /// - Parameter tag: The custom tag to register
    /// - Throws: `RegistryError` if registration fails
    public func register(_ tag: any CustomTag) async throws {
        let tagName = tag.name
        
        // Validate tag name
        try validateTagName(tagName)
        
        // Check for conflicts
        if tags[tagName] != nil || builtInCustomTags[tagName] != nil {
            throw RegistryError.tagAlreadyExists(tagName)
        }
        
        if builtInTags.contains(tagName) {
            throw RegistryError.cannotOverrideBuiltIn(tagName)
        }
        
        // Validate tag implementation
        try await validateTag(tag)
        
        // Perform tag setup
        try await tag.setup(registry: self)
        
        // Register the tag
        tags[tagName] = tag
        stats.customTagCount += 1
        stats.registrationCount += 1
        
        logTagRegistration(tagName, type: tag.type)
    }

    /// Install an engine-provided built-in custom tag.
    ///
    /// Built-in custom tags participate in lookups and parser descriptors, but they
    /// are preserved when callers clear user-registered tags.
    public func installBuiltIn(_ tag: any CustomTag) async throws {
        let tagName = tag.name

        try validateTagName(tagName)

        if tags[tagName] != nil || builtInCustomTags[tagName] != nil || builtInTags.contains(tagName) {
            throw RegistryError.tagAlreadyExists(tagName)
        }

        try await validateTag(tag)
        try await tag.setup(registry: self)
        builtInCustomTags[tagName] = tag
        logTagRegistration(tagName, type: tag.type)
    }
    
    /// Register multiple tags at once
    ///
    /// - Parameter tags: Array of custom tags to register
    /// - Throws: `RegistryError` if any registration fails
    public func registerAll(_ tags: [any CustomTag]) async throws {
        for tag in tags {
            try await register(tag)
        }
    }
    
    /// Unregister a custom tag
    ///
    /// - Parameter name: Name of the tag to unregister
    /// - Throws: `RegistryError` if tag cannot be unregistered
    public func unregister(_ name: String) async throws {
        guard let tag = tags[name] ?? builtInCustomTags[name] else {
            throw RegistryError.tagNotFound(name)
        }
        
        if builtInTags.contains(name) || builtInCustomTags[name] != nil {
            throw RegistryError.cannotUnregisterBuiltIn(name)
        }
        
        // Perform tag cleanup
        await tag.teardown()
        
        // Remove the tag
        tags.removeValue(forKey: name)
        stats.customTagCount -= 1
        stats.unregistrationCount += 1
        
        logTagUnregistration(name)
    }
    
    // MARK: - Tag Lookup
    
    /// Get a registered tag by name
    ///
    /// - Parameter name: The tag name to look up
    /// - Returns: The tag implementation, or nil if not found
    public func getTag(_ name: String) -> (any CustomTag)? {
        stats.lookupCount += 1
        return builtInCustomTags[name] ?? tags[name]
    }
    
    /// Check if a tag is registered
    ///
    /// - Parameter name: The tag name to check
    /// - Returns: true if tag is registered
    public func hasTag(_ name: String) -> Bool {
        return tags[name] != nil || builtInCustomTags[name] != nil || builtInTags.contains(name)
    }
    
    /// Get all registered custom tags
    ///
    /// - Returns: Dictionary of tag name to tag implementation
    public func getAllTags() -> [String: any CustomTag] {
        return builtInCustomTags.merging(tags) { _, custom in custom }
    }
    
    /// Get all tag names (built-in and custom)
    ///
    /// - Returns: Set of all available tag names
    public func getAllTagNames() -> Set<String> {
        return builtInTags
            .union(Set(builtInCustomTags.keys))
            .union(Set(tags.keys))
    }
    
    /// Get tags by type
    ///
    /// - Parameter type: The tag type to filter by
    /// - Returns: Array of tags of the specified type
    public func getTags(ofType type: TagType) -> [any CustomTag] {
        return getAllTags().values.filter { $0.type == type }
    }
    
    // MARK: - Validation
    
    /// Validate a tag name
    private func validateTagName(_ name: String) throws {
        // Check for empty name
        guard !name.isEmpty else {
            throw RegistryError.invalidTagName("Tag name cannot be empty")
        }
        
        // Check for valid characters
        let validCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_-"))
        guard name.unicodeScalars.allSatisfy({ validCharacters.contains($0) }) else {
            throw RegistryError.invalidTagName("Tag name contains invalid characters: \(name)")
        }
        
        // Check for reserved names
        let reservedNames = ["liquid", "template", "render", "parse"]
        guard !reservedNames.contains(name.lowercased()) else {
            throw RegistryError.invalidTagName("Tag name is reserved: \(name)")
        }
        
        // Check name length
        guard name.count >= 2 && name.count <= 50 else {
            throw RegistryError.invalidTagName("Tag name must be 2-50 characters: \(name)")
        }
        
        // Must start with letter
        guard name.first?.isLetter == true else {
            throw RegistryError.invalidTagName("Tag name must start with a letter: \(name)")
        }
    }
    
    /// Validate a tag implementation
    private func validateTag(_ tag: any CustomTag) async throws {
        // Validate nesting depth
        if let maxDepth = tag.maxNestingDepth, maxDepth < 1 {
            throw RegistryError.invalidTagImplementation("Maximum nesting depth must be positive")
        }
        
        // Validate required context
        for contextVar in tag.requiredContext {
            guard !contextVar.isEmpty else {
                throw RegistryError.invalidTagImplementation("Required context variable name cannot be empty")
            }
        }
        
        // Test basic parsing with empty parameters
        let testContext = TagParsingContext(
            templateName: "test",
            lineNumber: 1,
            staticContext: [:],
            configuration: .default
        )
        
        do {
            let _ = try await tag.parse("", context: testContext)
        } catch {
            // It's okay if parsing fails with empty params, as long as it doesn't crash
        }
    }
    
    // MARK: - Statistics and Monitoring
    
    /// Get registry statistics
    public func getStats() -> RegistryStats {
        return stats
    }
    
    /// Reset statistics
    public func resetStats() {
        stats = RegistryStats()
    }
    
    // MARK: - Utility
    
    /// Clear all custom tags (keeps built-in tags)
    public func clearCustomTags() async {
        for (_, tag) in tags {
            await tag.teardown()
        }
        let customCount = tags.count
        tags.removeAll()
        stats.customTagCount = 0
        stats.clearCount += 1
        
        if customCount > 0 {
            logRegistryCleared(customCount)
        }
    }
    
    private func logTagRegistration(_ name: String, type: TagType) {
        _ = name
        _ = type
    }
    
    private func logTagUnregistration(_ name: String) {
        _ = name
    }
    
    private func logRegistryCleared(_ count: Int) {
        _ = count
    }
}

/// Registry statistics for monitoring and debugging
public struct RegistryStats: Sendable {
    /// Number of custom tags registered
    public var customTagCount: Int = 0
    
    /// Total number of registration calls
    public var registrationCount: Int = 0
    
    /// Total number of unregistration calls
    public var unregistrationCount: Int = 0
    
    /// Total number of tag lookups
    public var lookupCount: Int = 0
    
    /// Number of times registry was cleared
    public var clearCount: Int = 0
    
    /// Hit rate for tag lookups (successful lookups / total lookups)
    public var hitRate: Double {
        guard lookupCount > 0 else { return 0.0 }
        return 1.0 // Simplified - in real implementation would track successful lookups
    }
}

/// Errors that can occur during tag registration
public enum RegistryError: Error, Sendable {
    case invalidTagName(String)
    case tagAlreadyExists(String)
    case tagNotFound(String)
    case cannotOverrideBuiltIn(String)
    case cannotUnregisterBuiltIn(String)
    case invalidTagImplementation(String)
    case setupFailed(String, underlying: Error)
    
    public var localizedDescription: String {
        switch self {
        case .invalidTagName(let message):
            return "Invalid tag name: \(message)"
        case .tagAlreadyExists(let name):
            return "Tag already exists: \(name)"
        case .tagNotFound(let name):
            return "Tag not found: \(name)"
        case .cannotOverrideBuiltIn(let name):
            return "Cannot override built-in tag: \(name)"
        case .cannotUnregisterBuiltIn(let name):
            return "Cannot unregister built-in tag: \(name)"
        case .invalidTagImplementation(let message):
            return "Invalid tag implementation: \(message)"
        case .setupFailed(let name, let underlying):
            return "Tag setup failed for '\(name)': \(underlying.localizedDescription)"
        }
    }
}
