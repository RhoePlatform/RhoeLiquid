//
//  CacheTag.swift
//  LiquidTags
//
//  Created as part of RhoeLiquid
//  A high-performance Swift implementation of the Liquid template language
//

import Foundation
import LiquidCore

/// Custom tag for caching expensive template content with TTL and LRU eviction.
///
/// ## Usage
///
/// ```liquid
/// {% cache 'user_profile', expires: '1h' %}
///   <!-- Expensive content generation -->
///   {% for item in user.complex_data %}
///     {{ item | complex_filter }}
///   {% endfor %}
/// {% endcache %}
/// ```
///
/// ```liquid
/// {% cache product.id, expires: '30m', vary_on: 'user.role' %}
///   {{ product | render_complex_view }}
/// {% endcache %}
/// ```
///
/// ## Parameters
/// - `key`: Cache key (required) -- can be a string literal or variable name
/// - `expires`: Cache expiration time in seconds or human-readable format ("1h", "30m", "1d")
/// - `vary_on`: Additional variable to include in cache key for variation
/// - `condition`: Only cache if condition is truthy
public struct CacheTag: CustomTag {
    public let name = "cache"
    public let type = TagType.block
    public let allowsNesting = true
    public let maxNestingDepth: Int? = 10

    /// Global cache store shared across all CacheTag instances.
    private static let cache = CacheStore()

    public init() {}

    public func parse(_ parameters: String, context: TagParsingContext) async throws -> TagParameters {
        let trimmed = parameters.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw TagParsingError.missingRequiredParameter("key")
        }

        let tokens = tokenize(trimmed)
        var params: [String: Any] = [:]

        guard let firstToken = tokens.first else {
            throw TagParsingError.missingRequiredParameter("key")
        }
        params["key"] = firstToken

        // Parse named parameters (keyword: value pairs separated by commas)
        var i = 1
        while i < tokens.count {
            let token = tokens[i]

            // Skip comma separators
            if token == "," {
                i += 1
                continue
            }

            if token.hasSuffix(":"), i + 1 < tokens.count {
                let paramName = String(token.dropLast())
                let paramValue = tokens[i + 1]

                switch paramName {
                case "expires":
                    params["expires"] = try parseExpiration(paramValue)
                case "vary_on":
                    params["vary_on"] = paramValue
                case "condition":
                    params["condition"] = paramValue
                default:
                    throw TagParsingError.invalidParameterValue(paramName, expected: "known parameter (expires, vary_on, condition)")
                }
                i += 2
            } else {
                i += 1
            }
        }

        // Default expiration: 1 hour
        if params["expires"] == nil {
            params["expires"] = 3600.0
        }

        return TagParameters(params)
    }

    public func execute(parameters: TagParameters, content: String?, context: TagExecutionContext) async throws -> String {
        let keyTemplate: String = try parameters.require("key")
        let expires: Double = parameters.get("expires", default: 3600.0)
        let varyOn: String? = parameters.get("vary_on")
        let conditionKey: String? = parameters.get("condition")

        // If a condition is specified, check whether caching should be skipped.
        if let conditionKey {
            let conditionValue = resolveVariable(conditionKey, context: context)
            if !isTruthy(conditionValue) {
                return content ?? ""
            }
        }

        // Build the full cache key.
        var cacheKey = "liquid_cache:\(resolveKeyValue(keyTemplate, context: context))"
        if let varyOn {
            let varyValue = resolveVariable(varyOn, context: context)
            cacheKey += ":vary:\(varyValue)"
        }

        // Check cache first.
        if let cached = await Self.cache.get(key: cacheKey) {
            return cached
        }

        // Cache miss -- return block content and store it.
        let rendered = content ?? ""
        let expiresAt = Date().addingTimeInterval(expires)
        await Self.cache.set(key: cacheKey, value: rendered, expiresAt: expiresAt)

        return rendered
    }

    public func teardown() async {
        await Self.cache.clear()
    }

    // MARK: - Private Helpers

    /// Tokenizes the parameter string, respecting quoted strings and commas.
    private func tokenize(_ input: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        var inQuotes = false
        var quoteChar: Character?

        for char in input {
            switch char {
            case "'", "\"":
                if inQuotes, char == quoteChar {
                    inQuotes = false
                    quoteChar = nil
                    if !current.isEmpty {
                        tokens.append(current)
                        current = ""
                    }
                } else if !inQuotes {
                    inQuotes = true
                    quoteChar = char
                } else {
                    current.append(char)
                }
            case ",":
                if inQuotes {
                    current.append(char)
                } else {
                    if !current.isEmpty {
                        tokens.append(current)
                        current = ""
                    }
                    tokens.append(",")
                }
            case " ", "\t":
                if inQuotes {
                    current.append(char)
                } else if !current.isEmpty {
                    tokens.append(current)
                    current = ""
                }
            default:
                current.append(char)
            }
        }

        if !current.isEmpty {
            tokens.append(current)
        }

        return tokens
    }

    /// Parses a human-readable expiration value into seconds.
    ///
    /// Supported formats: numeric seconds, or suffixed durations such as
    /// "30s", "5m", "1h", "2d", "30min", "1hour", "7days".
    private func parseExpiration(_ value: String) throws -> Double {
        if let seconds = Double(value) {
            return seconds
        }

        let lowered = value.lowercased()
        let numberString = lowered.prefix(while: { $0.isNumber || $0 == "." })
        guard let number = Double(numberString), number > 0 else {
            throw TagParsingError.invalidParameterValue("expires", expected: "time duration (e.g. 30s, 5m, 1h, 2d)")
        }

        let suffix = lowered.dropFirst(numberString.count)
        switch suffix {
        case "s", "sec", "seconds":
            return number
        case "m", "min", "minutes":
            return number * 60
        case "h", "hour", "hours":
            return number * 3600
        case "d", "day", "days":
            return number * 86400
        default:
            throw TagParsingError.invalidParameterValue("expires", expected: "time duration (e.g. 30s, 5m, 1h, 2d)")
        }
    }

    /// Resolves a key that may be a quoted literal or a variable path.
    private func resolveKeyValue(_ key: String, context: TagExecutionContext) -> String {
        // If it looks like a dotted variable path, resolve it.
        if key.contains(".") {
            return String(describing: resolveVariable(key, context: context))
        }
        return key
    }

    /// Walks a dotted variable path against the execution context's variables.
    private func resolveVariable(_ path: String, context: TagExecutionContext) -> Any {
        let components = path.split(separator: ".").map(String.init)
        var current: Any = context.variables

        for component in components {
            if let dict = current as? [String: Any], let next = dict[component] {
                current = next
            } else {
                return ""
            }
        }

        return current
    }

    /// Liquid-style truthiness evaluation.
    private func isTruthy(_ value: Any) -> Bool {
        switch value {
        case let b as Bool:
            return b
        case let s as String:
            return !s.isEmpty && s.lowercased() != "false"
        case is NSNull:
            return false
        default:
            return true
        }
    }
}

// MARK: - CacheStore

/// Thread-safe in-memory cache with TTL expiration and LRU eviction.
private actor CacheStore {
    private var storage: [String: CacheEntry] = [:]
    private let maxSize = 1000

    struct CacheEntry {
        let value: String
        let expiresAt: Date
    }

    func get(key: String) -> String? {
        guard let entry = storage[key] else {
            return nil
        }
        if entry.expiresAt < Date() {
            storage.removeValue(forKey: key)
            return nil
        }
        return entry.value
    }

    func set(key: String, value: String, expiresAt: Date) {
        if storage.count >= maxSize {
            evictExpiredAndOldest()
        }
        storage[key] = CacheEntry(value: value, expiresAt: expiresAt)
    }

    func clear() {
        storage.removeAll()
    }

    private func evictExpiredAndOldest() {
        let now = Date()
        // First pass: remove expired entries.
        storage = storage.filter { $0.value.expiresAt >= now }

        // If still over capacity, evict entries closest to expiration.
        if storage.count >= maxSize {
            let sortedKeys = storage.keys.sorted { key1, key2 in
                storage[key1]!.expiresAt < storage[key2]!.expiresAt
            }
            let removeCount = max(1, storage.count / 10)
            for key in sortedKeys.prefix(removeCount) {
                storage.removeValue(forKey: key)
            }
        }
    }
}
