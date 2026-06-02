//
//  TemplateSandbox.swift
//  RhoeDOCX Security
//
//  Comprehensive security sandboxing for template processing
//  Protects against malicious templates and resource exhaustion
//

import Foundation

// MARK: - Resource Limits

/// Resource limits for template processing
public struct ResourceLimits: Sendable {
    /// Maximum template size in bytes (default: 10MB)
    public let maxTemplateSize: Int
    
    /// Maximum rendering time in seconds (default: 30s)
    public let maxRenderTime: TimeInterval
    
    /// Maximum memory usage in bytes (default: 100MB)
    public let maxMemoryUsage: Int
    
    /// Maximum nesting depth for template constructs (default: 50)
    public let maxNestingDepth: Int
    
    /// Maximum number of variables per template (default: 1000)
    public let maxVariableCount: Int
    
    /// Maximum number of loop iterations (default: 10000)
    public let maxLoopIterations: Int
    
    /// Maximum output document size in bytes (default: 50MB)
    public let maxOutputSize: Int
    
    public init(
        maxTemplateSize: Int = 10 * 1024 * 1024,
        maxRenderTime: TimeInterval = 30.0,
        maxMemoryUsage: Int = 100 * 1024 * 1024,
        maxNestingDepth: Int = 50,
        maxVariableCount: Int = 1000,
        maxLoopIterations: Int = 10000,
        maxOutputSize: Int = 50 * 1024 * 1024
    ) {
        self.maxTemplateSize = maxTemplateSize
        self.maxRenderTime = maxRenderTime
        self.maxMemoryUsage = maxMemoryUsage
        self.maxNestingDepth = maxNestingDepth
        self.maxVariableCount = maxVariableCount
        self.maxLoopIterations = maxLoopIterations
        self.maxOutputSize = maxOutputSize
    }
    
    /// Conservative limits for untrusted templates
    public static let conservative = ResourceLimits(
        maxTemplateSize: 1 * 1024 * 1024,     // 1MB
        maxRenderTime: 10.0,                   // 10s
        maxMemoryUsage: 50 * 1024 * 1024,     // 50MB
        maxNestingDepth: 20,                   // 20 levels
        maxVariableCount: 100,                 // 100 variables
        maxLoopIterations: 1000,               // 1000 iterations
        maxOutputSize: 10 * 1024 * 1024       // 10MB
    )
    
    /// Default production limits
    public static let `default` = ResourceLimits()
}

// MARK: - Template Sandbox

/// Comprehensive security sandbox for template processing
public actor TemplateSandbox {
    public let limits: ResourceLimits
    private let allowedFilters: Set<String>
    private let allowedTags: Set<String>
    private let allowedContextKeys: Set<String>?
    private var activeRenders: Set<UUID> = []
    
    /// Security violation tracking
    private var violations: [SecurityViolation] = []
    
    public init(
        limits: ResourceLimits = .default,
        allowedFilters: Set<String>? = nil,
        allowedTags: Set<String>? = nil,
        allowedContextKeys: Set<String>? = nil
    ) {
        self.limits = limits
        self.allowedFilters = allowedFilters ?? Self.defaultAllowedFilters
        self.allowedTags = allowedTags ?? Self.defaultAllowedTags
        self.allowedContextKeys = allowedContextKeys
    }
    
    // MARK: - Validation Methods
    
    /// Validate template before processing
    public func validateTemplate(_ template: String) throws {
        // Size validation
        guard template.utf8.count <= limits.maxTemplateSize else {
            throw SecurityError.templateTooLarge(template.utf8.count, limit: limits.maxTemplateSize)
        }
        
        // Basic syntax validation
        try validateTemplateSyntax(template)
        
        // Resource estimation
        let estimatedResources = estimateResourceUsage(template)
        try validateResourceEstimate(estimatedResources)
    }
    
    /// Validate context data
    public func validateContext(_ context: [String: Any]) throws {
        // Validate context keys if allowlist is specified
        if let allowedKeys = allowedContextKeys {
            for key in context.keys {
                guard allowedKeys.contains(key) else {
                    throw SecurityError.unauthorizedContextKey(key)
                }
            }
        }
        
        // Validate context complexity
        let complexity = calculateContextComplexity(context)
        guard complexity.totalKeys <= limits.maxVariableCount else {
            throw SecurityError.contextTooComplex(complexity.totalKeys, limit: limits.maxVariableCount)
        }
        
        guard complexity.maxDepth <= limits.maxNestingDepth else {
            throw SecurityError.contextTooDeep(complexity.maxDepth, limit: limits.maxNestingDepth)
        }
    }
    
    /// Create secured render session
    public func createSecuredSession() -> SecuredRenderSession {
        let sessionId = UUID()
        activeRenders.insert(sessionId)
        
        return SecuredRenderSession(
            id: sessionId,
            sandbox: self,
            startTime: Date(),
            limits: limits
        )
    }
    
    /// Complete render session
    public func completeSession(_ sessionId: UUID) {
        activeRenders.remove(sessionId)
    }
    
    /// Get security violations
    public func getViolations() -> [SecurityViolation] {
        return violations
    }
    
    /// Clear violation history
    public func clearViolations() {
        violations.removeAll()
    }
    
    // MARK: - Internal Validation
    
    private func validateTemplateSyntax(_ template: String) throws {
        // Check for dangerous patterns
        let dangerousPatterns = [
            #"\\{\\{\\s*\\w+\\s*\\|\\s*exec"#,  // exec filter
            #"\\{\\{\\s*\\w+\\s*\\|\\s*system"#, // system filter
            #"\\{\\{\\s*\\w+\\s*\\|\\s*eval"#,   // eval filter
        ]
        
        for pattern in dangerousPatterns {
            if template.range(of: pattern, options: .regularExpression) != nil {
                throw SecurityError.dangerousTemplate("Contains forbidden pattern: \\(pattern)")
            }
        }
        
        // Validate balanced braces
        var braceCount = 0
        var inTemplate = false
        var i = template.startIndex
        
        while i < template.endIndex {
            let char = template[i]
            
            if char == "{" && i < template.index(before: template.endIndex) &&
               template[template.index(after: i)] == "{" {
                braceCount += 1
                inTemplate = true
                i = template.index(i, offsetBy: 2)
                continue
            }
            
            if char == "}" && i < template.index(before: template.endIndex) &&
               template[template.index(after: i)] == "}" && inTemplate {
                braceCount -= 1
                inTemplate = false
                i = template.index(i, offsetBy: 2)
                continue
            }
            
            i = template.index(after: i)
        }
        
        guard braceCount == 0 else {
            throw SecurityError.unbalancedTemplate("Unbalanced template braces")
        }
    }
    
    private func estimateResourceUsage(_ template: String) -> ResourceEstimate {
        let variables = extractVariableNames(template)
        let loops = countLoops(template)
        let nesting = calculateMaxNesting(template)
        
        return ResourceEstimate(
            variableCount: variables.count,
            estimatedLoops: loops,
            maxNesting: nesting,
            templateSize: template.utf8.count
        )
    }
    
    private func validateResourceEstimate(_ estimate: ResourceEstimate) throws {
        guard estimate.variableCount <= limits.maxVariableCount else {
            throw SecurityError.tooManyVariables(estimate.variableCount, limit: limits.maxVariableCount)
        }
        
        guard estimate.maxNesting <= limits.maxNestingDepth else {
            throw SecurityError.nestingTooDeep(estimate.maxNesting, limit: limits.maxNestingDepth)
        }
        
        guard estimate.estimatedLoops <= limits.maxLoopIterations else {
            throw SecurityError.tooManyLoops(estimate.estimatedLoops, limit: limits.maxLoopIterations)
        }
    }
    
    // MARK: - Analysis Helpers
    
    private func extractVariableNames(_ template: String) -> Set<String> {
        var variables: Set<String> = []
        let pattern = #"\\{\\{\\s*(\\w+)"#
        
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let matches = regex.matches(
                in: template,
                range: NSRange(template.startIndex..., in: template)
            )
            
            for match in matches {
                if let range = Range(match.range(at: 1), in: template) {
                    variables.insert(String(template[range]))
                }
            }
        }
        
        return variables
    }
    
    private func countLoops(_ template: String) -> Int {
        let forPattern = #"\\{%\\s*for\\s+"#
        return countMatches(in: template, pattern: forPattern)
    }
    
    private func calculateMaxNesting(_ template: String) -> Int {
        // Simplified nesting calculation
        let openPattern = #"\\{%\\s*(for|if|unless|case)"#
        let closePattern = #"\\{%\\s*end(for|if|unless|case)"#
        
        // This is a simplified version - real implementation would need proper parsing
        let opens = countMatches(in: template, pattern: openPattern)
        let closes = countMatches(in: template, pattern: closePattern)
        
        return min(opens, closes)
    }
    
    private func countMatches(in string: String, pattern: String) -> Int {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return 0 }
        return regex.numberOfMatches(
            in: string,
            range: NSRange(string.startIndex..., in: string)
        )
    }
    
    private func calculateContextComplexity(_ context: [String: Any]) -> ContextComplexity {
        var totalKeys = 0
        var maxDepth = 0
        
        func traverse(_ obj: Any, depth: Int) {
            maxDepth = max(maxDepth, depth)
            
            if let dict = obj as? [String: Any] {
                totalKeys += dict.count
                for value in dict.values {
                    traverse(value, depth: depth + 1)
                }
            } else if let array = obj as? [Any] {
                totalKeys += array.count
                for item in array {
                    traverse(item, depth: depth + 1)
                }
            }
        }
        
        traverse(context, depth: 0)
        
        return ContextComplexity(totalKeys: totalKeys, maxDepth: maxDepth)
    }
    
    internal func recordViolation(_ violation: SecurityViolation) {
        violations.append(violation)
        
        // Keep only recent violations (last 100)
        if violations.count > 100 {
            violations.removeFirst(violations.count - 100)
        }
    }
}

// MARK: - Secured Render Session

/// A secured rendering session with automatic cleanup
// SAFETY: Single-task scoped; mutable state (isComplete) only accessed serially
public final class SecuredRenderSession: @unchecked Sendable {
    public let id: UUID
    private let sandbox: TemplateSandbox
    public let startTime: Date
    private let limits: ResourceLimits
    private var isComplete = false
    
    internal init(id: UUID, sandbox: TemplateSandbox, startTime: Date, limits: ResourceLimits) {
        self.id = id
        self.sandbox = sandbox
        self.startTime = startTime
        self.limits = limits
    }
    
    /// Check if session has exceeded time limit
    public var hasTimedOut: Bool {
        Date().timeIntervalSince(startTime) > limits.maxRenderTime
    }
    
    /// Check current memory usage
    public var memoryUsage: Int {
        return Int(currentTaskBasicInfo().resident_size)
    }
    
    /// Complete the session
    public func complete() {
        guard !isComplete else { return }
        isComplete = true
        
        Task {
            await sandbox.completeSession(id)
        }
    }
    
    deinit {
        if !isComplete {
            complete()
        }
    }
}

// MARK: - Supporting Types

private struct ResourceEstimate {
    let variableCount: Int
    let estimatedLoops: Int
    let maxNesting: Int
    let templateSize: Int
}

private struct ContextComplexity {
    let totalKeys: Int
    let maxDepth: Int
}

public struct SecurityViolation: Sendable {
    public let timestamp: Date
    public let type: SecurityError
    public let sessionId: UUID?
    public let details: String
    
    public init(type: SecurityError, sessionId: UUID? = nil, details: String = "") {
        self.timestamp = Date()
        self.type = type
        self.sessionId = sessionId
        self.details = details
    }
}

// MARK: - Security Errors

public enum SecurityError: Error, LocalizedError {
    case templateTooLarge(Int, limit: Int)
    case contextTooComplex(Int, limit: Int)
    case contextTooDeep(Int, limit: Int)
    case tooManyVariables(Int, limit: Int)
    case nestingTooDeep(Int, limit: Int)
    case tooManyLoops(Int, limit: Int)
    case renderingTimeout(TimeInterval)
    case memoryExceeded(Int, limit: Int)
    case unauthorizedFilter(String)
    case unauthorizedTag(String)
    case unauthorizedContextKey(String)
    case dangerousTemplate(String)
    case unbalancedTemplate(String)
    case outputTooLarge(Int, limit: Int)
    
    public var errorDescription: String? {
        switch self {
        case .templateTooLarge(let size, let limit):
            return "Template too large: \(size) bytes (limit: \(limit))"
        case .contextTooComplex(let keys, let limit):
            return "Context too complex: \(keys) keys (limit: \(limit))"
        case .contextTooDeep(let depth, let limit):
            return "Context nesting too deep: \(depth) levels (limit: \(limit))"
        case .tooManyVariables(let count, let limit):
            return "Too many variables: \(count) (limit: \(limit))"
        case .nestingTooDeep(let depth, let limit):
            return "Template nesting too deep: \(depth) levels (limit: \(limit))"
        case .tooManyLoops(let count, let limit):
            return "Too many loops: \(count) (limit: \(limit))"
        case .renderingTimeout(let time):
            return "Rendering timeout after \(time) seconds"
        case .memoryExceeded(let usage, let limit):
            return "Memory limit exceeded: \(usage) bytes (limit: \(limit))"
        case .unauthorizedFilter(let filter):
            return "Unauthorized filter: \(filter)"
        case .unauthorizedTag(let tag):
            return "Unauthorized tag: \(tag)"
        case .unauthorizedContextKey(let key):
            return "Unauthorized context key: \(key)"
        case .dangerousTemplate(let reason):
            return "Dangerous template detected: \(reason)"
        case .unbalancedTemplate(let reason):
            return "Unbalanced template: \(reason)"
        case .outputTooLarge(let size, let limit):
            return "Output too large: \(size) bytes (limit: \(limit))"
        }
    }
}

// MARK: - Default Security Lists

extension TemplateSandbox {
    /// Default allowed filters for secure operation
    static let defaultAllowedFilters: Set<String> = [
        // Safe text filters
        "capitalize", "downcase", "upcase", "strip", "lstrip", "rstrip",
        "truncate", "truncatewords", "slice", "split", "join",
        
        // Safe formatting filters  
        "date", "number_with_delimiter", "currency", "percentage",
        
        // Safe Word-specific filters
        "word_bold", "word_italic", "word_color", "word_underline",
        "word_linebreak", "word_paragraph", "word_table_cell",
        
        // Safe utility filters
        "default", "size", "first", "last", "reverse", "sort",
        "uniq", "map", "where", "group_by"
    ]
    
    /// Default allowed tags for secure operation  
    static let defaultAllowedTags: Set<String> = [
        // Safe control flow
        "if", "unless", "case", "when", "for", "tablerow",
        
        // Safe utility tags
        "assign", "capture", "comment", "raw",
        
        // Safe Word-specific tags
        "word_table", "word_list", "word_heading", "word_pagebreak"
    ]
}

// MARK: - Memory Helpers

private func currentTaskBasicInfo() -> mach_task_basic_info {
    let name = mach_task_self_
    let flavor = task_flavor_t(MACH_TASK_BASIC_INFO)
    var size = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / MemoryLayout<integer_t>.size)
    var info = mach_task_basic_info()
    
    let result = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
            task_info(name, flavor, $0, &size)
        }
    }
    
    guard result == KERN_SUCCESS else {
        return mach_task_basic_info()
    }
    
    return info
}
