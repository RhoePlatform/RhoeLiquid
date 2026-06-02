//
//  DataSource.swift
//  LiquidCore
//
//  Protocol and types for data source loading in RhoeLiquid
//

import Foundation

/// Configuration options for loading data from external sources
///
/// `LoadOptions` provides fine-grained control over how data is loaded,
/// cached, and validated. It supports both local file system and network sources.
///
/// Note: programmatic registry usage is the stable data-loading surface today.
/// Template-tag driven loading is still being polished.
///
/// ## Overview
///
/// LoadOptions allows you to configure:
/// - **Caching**: Control how long data is cached to improve performance
/// - **File watching**: Monitor files for changes in development
/// - **Network settings**: Headers, timeouts for HTTP requests
/// - **Validation**: Schema validation for loaded data
/// - **Safety limits**: Maximum file size to prevent memory issues
///
/// ## Usage Examples
///
/// ### Basic Usage
/// ```swift
/// let registry = DataLoaderRegistry()
/// await registry.register(JSONDataSource())
/// let users = try await registry.load(from: "./users.json")
/// ```
///
/// ### With Caching
/// ```swift
/// let options = LoadOptions(cacheDuration: 3600)
/// let posts = try await registry.load(from: "./blog/posts.json", options: options)
/// ```
///
/// ### Network Request with Headers
/// ```liquid
/// {% data api = load("https://api.example.com/data", 
///                    headers: {"Authorization": "Bearer token"},
///                    timeout: 10) %}
/// ```
///
/// ### Development Mode with File Watching
/// ```liquid
/// {% data config = load("./config.yaml", watch: true) %}
/// ```
///
/// ## See Also
/// - ``DataSource``: Protocol for data source implementations
/// - ``DataLoaderRegistry``: Registry for managing data loaders
public struct LoadOptions: Sendable {
    /// Cache duration in seconds
    ///
    /// Controls how long loaded data is cached before being refreshed.
    /// - `nil`: No caching (default)
    /// - `0`: Cache indefinitely
    /// - `> 0`: Cache for specified seconds
    public let cacheDuration: TimeInterval?
    
    /// Whether to watch the file for changes
    ///
    /// When enabled, the data source will monitor the file for changes
    /// and automatically reload when modifications are detected.
    /// Only applicable to local file sources.
    public let watch: Bool
    
    /// Custom headers for HTTP requests
    ///
    /// Additional headers to include when loading data from HTTP(S) URLs.
    /// Common uses include authentication tokens, API keys, and content negotiation.
    ///
    /// Example:
    /// ```swift
    /// ["Authorization": "Bearer token",
    ///  "Accept": "application/json"]
    /// ```
    public let headers: [String: String]
    
    /// Timeout for network requests in seconds
    ///
    /// Maximum time to wait for a network response before failing.
    /// Default is 30 seconds.
    public let timeout: TimeInterval
    
    /// Schema for validation
    ///
    /// Optional schema to validate loaded data against.
    /// The format is specific to the data source type:
    /// - JSON: JSON Schema format
    /// - XML: XSD or RelaxNG
    /// - CSV: Column definitions
    public let schema: DataValue?
    
    /// Character encoding for text files
    ///
    /// The encoding to use when reading text-based formats.
    /// Default is UTF-8.
    public let encoding: String.Encoding
    
    /// Maximum file size in bytes
    ///
    /// Safety limit to prevent loading extremely large files
    /// that could cause memory issues. Default is 10MB.
    public let maxSize: Int
    
    public init(
        cacheDuration: TimeInterval? = nil,
        watch: Bool = false,
        headers: [String: String] = [:],
        timeout: TimeInterval = 30,
        schema: DataValue? = nil,
        encoding: String.Encoding = .utf8,
        maxSize: Int = 10 * 1024 * 1024 // 10MB default
    ) {
        self.cacheDuration = cacheDuration
        self.watch = watch
        self.headers = headers
        self.timeout = timeout
        self.schema = schema
        self.encoding = encoding
        self.maxSize = maxSize
    }
}

/// Protocol for implementing custom data source loaders
///
/// `DataSource` defines the interface for loading structured data from various
/// sources and formats. RhoeLiquid includes built-in implementations for common
/// formats like JSON, Markdown, and CSV, and you can create custom loaders for
/// specialized formats.
///
/// ## Overview
///
/// A DataSource implementation is responsible for:
/// 1. Loading data from URLs (local files or network resources)
/// 2. Parsing the data into the unified `DataValue` format
/// 3. Optionally validating data against schemas
/// 4. Declaring which file extensions and URL schemes it supports
///
/// ## Built-in Data Sources
///
/// RhoeLiquid includes these data sources:
/// - **JSONDataSource**: JSON, JSONC, JSON5 files
/// - **MarkdownDataSource**: Markdown files with frontmatter
/// - **CSVDataSource**: CSV and TSV files with auto-detection
/// - **XMLDataSource**: XML and HTML files
///
/// ## Creating Custom Data Sources
///
/// To create a custom data source, implement this protocol:
///
/// ```swift
/// struct YAMLDataSource: DataSource {
///     var supportedExtensions: [String] { 
///         ["yaml", "yml"] 
///     }
///     
///     func load(from url: URL, options: LoadOptions) async throws -> DataValue {
///         // 1. Load raw data
///         let data = try Data(contentsOf: url)
///         
///         // 2. Check size limit
///         guard data.count <= options.maxSize else {
///             throw DataSourceError.fileTooLarge(data.count, options.maxSize)
///         }
///         
///         // 3. Parse YAML
///         let yaml = try YAMLParser.parse(data)
///         
///         // 4. Convert to DataValue
///         return DataValue(from: yaml)
///     }
/// }
/// ```
///
/// ## Registration
///
/// Register custom data sources with the `DataLoaderRegistry`:
///
/// ```swift
/// let registry = DataLoaderRegistry.shared
/// await registry.register(YAMLDataSource())
/// ```
///
/// ## Thread Safety
///
/// All DataSource implementations must be thread-safe and conform to `Sendable`.
/// Use immutable structures or proper synchronization for any shared state.
///
/// ## See Also
/// - ``DataValue``: The unified data representation
/// - ``LoadOptions``: Configuration for data loading
/// - ``DataLoaderRegistry``: Registry for managing data sources
/// - ``DataSourceError``: Common errors when loading data
public protocol DataSource: Sendable {
    /// Load data from the given URL with specified options
    ///
    /// This method is responsible for:
    /// 1. Loading raw data from the URL (file or network)
    /// 2. Parsing the data according to the format
    /// 3. Converting to the unified DataValue representation
    /// 4. Applying any schema validation if provided
    ///
    /// - Parameters:
    ///   - url: The URL to load data from (file:// or http(s)://)
    ///   - options: Configuration options for loading
    /// - Returns: The loaded and parsed data as a DataValue
    /// - Throws: DataSourceError for loading/parsing failures
    func load(from url: URL, options: LoadOptions) async throws -> DataValue
    
    /// File extensions this loader supports
    ///
    /// Return lowercase extensions without the dot prefix.
    /// Example: `["json", "jsonc", "json5"]`
    var supportedExtensions: [String] { get }
    
    /// URL schemes this loader supports
    ///
    /// Most loaders support `["file", "http", "https"]`.
    /// Custom loaders might support additional schemes like `ftp`, `s3`, etc.
    var supportedSchemes: [String] { get }
    
    /// Validate loaded data against a schema
    ///
    /// This method is optional and has a default implementation that
    /// always returns true. Implement this for formats that support
    /// schema validation (JSON Schema, XSD, etc.).
    ///
    /// - Parameters:
    ///   - data: The data to validate
    ///   - schema: The schema in format-specific representation
    /// - Returns: true if validation passes
    /// - Throws: DataSourceError.validationFailed with details
    func validate(_ data: DataValue, against schema: DataValue) async throws -> Bool
}

// Default implementation
extension DataSource {
    public var supportedSchemes: [String] {
        ["file", "http", "https"]
    }
    
    public func validate(_ data: DataValue, against schema: DataValue) async throws -> Bool {
        // Default: no validation
        return true
    }
}

/// Errors that can occur during data loading
///
/// `DataSourceError` provides detailed error information for data loading failures,
/// helping developers diagnose and handle issues appropriately.
///
/// ## Error Cases
///
/// ### File System Errors
/// ```swift
/// do {
///     let data = try await loader.load(from: fileURL, options: options)
/// } catch DataSourceError.fileNotFound(let url) {
///     print("File not found at: \(url)")
/// } catch DataSourceError.accessDenied(let url) {
///     print("Permission denied for: \(url)")
/// }
/// ```
///
/// ### Network Errors
/// ```swift
/// do {
///     let data = try await loader.load(from: apiURL, options: options)
/// } catch DataSourceError.networkError(let error) {
///     print("Network failed: \(error)")
/// } catch DataSourceError.timeout {
///     print("Request timed out")
/// }
/// ```
///
/// ### Data Format Errors
/// ```swift
/// do {
///     let data = try await loader.load(from: url, options: options)
/// } catch DataSourceError.parseError(let details) {
///     print("Failed to parse: \(details)")
/// } catch DataSourceError.validationFailed(let reason) {
///     print("Validation failed: \(reason)")
/// }
/// ```
public enum DataSourceError: Error, Sendable {
    /// The file format is not supported by any registered data source
    case unsupportedFormat(String)
    
    /// The specified file could not be found
    case fileNotFound(URL)
    
    /// A network error occurred while loading remote data
    case networkError(Error)
    
    /// Failed to parse the data in the expected format
    case parseError(String)
    
    /// Data validation against schema failed
    case validationFailed(String)
    
    /// File exceeds maximum allowed size (actual, max)
    case fileTooLarge(Int, Int)
    
    /// Access to the file or URL was denied
    case accessDenied(URL)
    
    /// The provided URL string is malformed
    case invalidURL(String)
    
    /// The network request timed out
    case timeout
}

extension DataSourceError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unsupportedFormat(let format):
            return "Unsupported data format: \(format)"
        case .fileNotFound(let url):
            return "File not found: \(url.path)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .parseError(let message):
            return "Parse error: \(message)"
        case .validationFailed(let message):
            return "Validation failed: \(message)"
        case .fileTooLarge(let actual, let max):
            return "File too large: \(actual) bytes (max: \(max) bytes)"
        case .accessDenied(let url):
            return "Access denied: \(url.path)"
        case .invalidURL(let string):
            return "Invalid URL: \(string)"
        case .timeout:
            return "Request timed out"
        }
    }
}

/// Registry for managing data source loaders and caching
///
/// `DataLoaderRegistry` is the central coordinator for all data loading operations
/// in RhoeLiquid. It manages data source registration, format detection, caching,
/// and provides a unified interface for loading data from various sources.
///
/// ## Overview
///
/// The registry:
/// - Maintains a collection of registered data sources
/// - Automatically selects the appropriate loader based on file extension or URL scheme
/// - Implements intelligent caching to improve performance
/// - Provides thread-safe access through Swift's actor model
///
/// ## Usage
///
/// ### Basic Loading
/// ```swift
/// let registry = DataLoaderRegistry.shared
/// let data = try await registry.load(from: "./data.json")
/// ```
///
/// ### Loading with Options
/// ```swift
/// let options = LoadOptions(
///     cacheDuration: 3600,  // Cache for 1 hour
///     headers: ["Authorization": "Bearer token"]
/// )
/// let data = try await registry.load(from: "https://api.example.com/data", options: options)
/// ```
///
/// ### Registering Custom Data Sources
/// ```swift
/// let customLoader = YAMLDataSource()
/// await registry.register(customLoader)
/// ```
///
/// ## Caching Strategy
///
/// The registry implements a simple but effective caching strategy:
/// - Data is cached based on the full path/URL as the key
/// - Cache entries expire based on the `cacheDuration` in LoadOptions
/// - Expired entries are automatically purged on access
/// - Cache is memory-only and doesn't persist between app launches
///
/// ## Format Detection
///
/// The registry determines which loader to use through:
/// 1. **File Extension**: Matches against registered extensions (e.g., .json, .csv)
/// 2. **URL Scheme**: For special protocols (e.g., s3://, ftp://)
/// 3. **Fallback**: Attempts content-type detection for extensionless files
///
/// ## Thread Safety
///
/// DataLoaderRegistry is an actor, ensuring all operations are thread-safe
/// and can be called from any context without synchronization concerns.
///
/// ## Built-in Loaders
///
/// RhoeLiquid includes these pre-registered loaders:
/// - JSON/JSONC/JSON5: ``JSONDataSource``
/// - Markdown/MDX: ``MarkdownDataSource``
/// - CSV/TSV: ``CSVDataSource``
///
/// ## See Also
/// - ``DataSource``: Protocol for implementing loaders
/// - ``LoadOptions``: Configuration for loading behavior
/// - ``DataValue``: The unified data representation
public actor DataLoaderRegistry {
    private var loaders: [String: any DataSource] = [:]
    private var schemeLoaders: [String: any DataSource] = [:]
    private var cache: [String: CacheEntry] = [:]
    
    /// Creates a new data loader registry
    public init() {}
    
    private struct CacheEntry {
        let data: DataValue
        let timestamp: Date
        let duration: TimeInterval
        
        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > duration
        }
    }
    
    /// Register a data source loader
    ///
    /// Registers a data source for its supported file extensions and URL schemes.
    /// Multiple loaders can be registered, but later registrations will override
    /// earlier ones for the same extensions/schemes.
    ///
    /// - Parameter loader: The data source implementation to register
    ///
    /// Example:
    /// ```swift
    /// let yamlLoader = YAMLDataSource()
    /// await registry.register(yamlLoader)
    /// // Now .yaml and .yml files can be loaded
    /// ```
    public func register(_ loader: any DataSource) {
        // Register by file extension
        for ext in loader.supportedExtensions {
            loaders[ext.lowercased()] = loader
        }
        
        // Register by URL scheme
        for scheme in loader.supportedSchemes {
            schemeLoaders[scheme.lowercased()] = loader
        }
    }
    
    /// Load data from a path or URL string
    ///
    /// This is the primary method for loading data. It handles:
    /// - Cache lookup and management
    /// - Format detection based on file extension
    /// - Loader selection and invocation
    /// - Optional schema validation
    /// - Error handling and reporting
    ///
    /// - Parameters:
    ///   - path: File path or URL string to load from
    ///   - options: Configuration options for loading behavior
    /// - Returns: Loaded and parsed data as a DataValue
    /// - Throws: DataSourceError for various failure conditions
    ///
    /// Example:
    /// ```swift
    /// // Load local file
    /// let users = try await registry.load(from: "./data/users.json")
    /// 
    /// // Load from URL with options
    /// let apiData = try await registry.load(
    ///     from: "https://api.example.com/data",
    ///     options: LoadOptions(cacheDuration: 3600)
    /// )
    /// ```
    public func load(from path: String, options: LoadOptions = LoadOptions()) async throws -> DataValue {
        // Check cache first
        if let cached = cache[path], !cached.isExpired {
            return cached.data
        }
        
        // Parse the path as URL
        let url: URL
        if path.contains("://") {
            guard let parsedURL = URL(string: path) else {
                throw DataSourceError.invalidURL(path)
            }
            url = parsedURL
        } else {
            // Treat as file path
            url = URL(fileURLWithPath: path)
        }
        
        // Find appropriate loader
        let loader = try findLoader(for: url)
        
        // Load the data
        let data = try await loader.load(from: url, options: options)
        
        // Validate if schema provided
        if let schema = options.schema {
            let isValid = try await loader.validate(data, against: schema)
            if !isValid {
                throw DataSourceError.validationFailed("Data does not match schema")
            }
        }
        
        // Cache if requested
        if let duration = options.cacheDuration {
            cache[path] = CacheEntry(
                data: data,
                timestamp: Date(),
                duration: duration
            )
        }
        
        return data
    }
    
    /// Clear cache
    public func clearCache() {
        cache.removeAll()
    }
    
    /// Clear expired cache entries
    public func cleanCache() {
        cache = cache.filter { !$0.value.isExpired }
    }
    
    private func findLoader(for url: URL) throws -> any DataSource {
        let ext = url.pathExtension.lowercased()

        // Local files should prefer extension-based dispatch so a generic "file"
        // scheme registration does not override more specific format handlers.
        if url.isFileURL {
            if !ext.isEmpty, let loader = loaders[ext] {
                return loader
            }
            if let loader = schemeLoaders["file"] {
                return loader
            }
        } else if let scheme = url.scheme?.lowercased(),
                  let loader = schemeLoaders[scheme] {
            return loader
        }

        // Fallback to extension-based lookup for non-file URLs.
        if !ext.isEmpty, let loader = loaders[ext] {
            return loader
        }
        
        // Check by content type for URLs
        if url.scheme?.hasPrefix("http") == true {
            // Default to JSON loader for HTTP requests
            if let loader = loaders["json"] {
                return loader
            }
        }
        
        throw DataSourceError.unsupportedFormat(ext.isEmpty ? "unknown" : ext)
    }
}

/// Global data loader registry
public let dataLoaderRegistry = DataLoaderRegistry()
