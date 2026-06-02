//
//  GraphQLDataSource.swift
//  LiquidCore
//
//  GraphQL data source loader for RhoeLiquid
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Data source for executing GraphQL queries
///
/// `GraphQLDataSource` enables powerful API integration by executing GraphQL
/// queries against remote endpoints. Perfect for headless CMS integration,
/// modern APIs, and dynamic data fetching.
///
/// ## Features
///
/// - **Query Execution**: Run GraphQL queries with variables
/// - **Mutation Support**: Execute mutations (with care)
/// - **Introspection**: Discover API schema
/// - **Error Handling**: Detailed GraphQL error reporting
/// - **Caching**: Smart caching based on queries
/// - **Headers**: Authentication and custom headers
///
/// ## Usage Examples
///
/// ### Basic Query
/// ```liquid
/// {% data posts = load("https://api.example.com/graphql",
///     query: "query { posts { id title content author { name } } }") %}
/// 
/// {% for post in posts.data.posts %}
///   <h2>{{ post.title }}</h2>
///   <p>By {{ post.author.name }}</p>
///   {{ post.content }}
/// {% endfor %}
/// ```
///
/// ### Query with Variables
/// ```liquid
/// {% data user = load("https://api.example.com/graphql",
///     query: "query GetUser($id: ID!) { user(id: $id) { name email posts { title } } }",
///     variables: {"id": "123"}) %}
/// 
/// <h1>{{ user.data.user.name }}</h1>
/// <p>{{ user.data.user.email }}</p>
/// 
/// <h2>Posts</h2>
/// {% for post in user.data.user.posts %}
///   - {{ post.title }}
/// {% endfor %}
/// ```
///
/// ### With Authentication
/// ```liquid
/// {% data profile = load("https://api.example.com/graphql",
///     headers: {"Authorization": "Bearer " ~ access_token},
///     query: "query { me { id name email } }") %}
/// ```
///
/// ### Complex Queries
/// ```liquid
/// {% capture query %}
/// query GetProducts($category: String, $limit: Int = 10) {
///   products(category: $category, first: $limit) {
///     edges {
///       node {
///         id
///         name
///         price
///         images {
///           url
///           alt
///         }
///         variants {
///           id
///           name
///           price
///         }
///       }
///     }
///     pageInfo {
///       hasNextPage
///       endCursor
///     }
///   }
/// }
/// {% endcapture %}
/// 
/// {% data products = load("https://shop.example.com/graphql",
///     query: query,
///     variables: {"category": "electronics", "limit": 20}) %}
/// ```
///
/// ## Error Handling
///
/// GraphQL responses include both data and errors:
/// ```liquid
/// {% data result = load("https://api.example.com/graphql",
///     query: "query { user(id: $id) { name } }",
///     variables: {"id": user_id}) %}
/// 
/// {% if result.errors %}
///   {% for error in result.errors %}
///     <p class="error">{{ error.message }}</p>
///   {% endfor %}
/// {% endif %}
/// 
/// {% if result.data %}
///   {{ result.data.user.name }}
/// {% endif %}
/// ```
///
/// ## Introspection
///
/// Discover API schema:
/// ```liquid
/// {% data schema = load("https://api.example.com/graphql",
///     query: "{ __schema { types { name } } }") %}
/// ```
///
/// ## See Also
/// - ``DataSource``: Protocol this implements
/// - ``LoadOptions``: Configuration options
/// - ``DataValue``: The data representation format
public struct GraphQLDataSource: DataSource {
    public init() {}
    
    public var supportedExtensions: [String] {
        ["graphql", "gql"]
    }
    
    public var supportedSchemes: [String] {
        ["http", "https", "graphql"]
    }
    
    public func load(from url: URL, options: LoadOptions) async throws -> DataValue {
        // Extract GraphQL query and variables from URL or options
        let (query, variables, operationName) = try extractGraphQLParameters(from: url, options: options)
        
        // Build request body
        var requestBody: [String: Any] = ["query": query]
        if let variables = variables {
            requestBody["variables"] = variables
        }
        if let operationName = operationName {
            requestBody["operationName"] = operationName
        }
        
        // Serialize to JSON
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Create request
        #if os(WASI)
        throw DataSourceError.unsupportedFormat("Network loading not available in WebAssembly")
        #else
        var request = URLRequest(url: url.scheme == "graphql" ? URL(string: url.absoluteString.replacingOccurrences(of: "graphql://", with: "https://"))! : url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.timeoutInterval = options.timeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add custom headers
        for (key, value) in options.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Execute request
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            // Check response
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode >= 400 {
                throw DataSourceError.networkError(
                    NSError(
                        domain: "GraphQL",
                        code: httpResponse.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"]
                    )
                )
            }

            // Parse response
            let json = try JSONSerialization.jsonObject(with: data)
            return DataValue(from: json)

        } catch {
            throw DataSourceError.networkError(error)
        }
        #endif
    }
    
    private func extractGraphQLParameters(from url: URL, options: LoadOptions) throws -> (query: String, variables: [String: Any]?, operationName: String?) {
        // Check URL query parameters first
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems {
            
            var params: [String: String] = [:]
            for item in queryItems {
                params[item.name] = item.value ?? ""
            }
            
            if let query = params["query"] {
                var variables: [String: Any]?
                if let varsString = params["variables"],
                   let varsData = varsString.data(using: .utf8) {
                    variables = try? JSONSerialization.jsonObject(with: varsData) as? [String: Any]
                }
                
                return (query, variables, params["operationName"])
            }
        }
        
        // Check if URL points to a .graphql file
        if url.pathExtension == "graphql" || url.pathExtension == "gql" {
            let queryData = try Data(contentsOf: url)
            guard let query = String(data: queryData, encoding: .utf8) else {
                throw DataSourceError.parseError("Unable to read GraphQL query file")
            }
            return (query, nil, nil)
        }
        
        // Default introspection query
        return (introspectionQuery, nil, nil)
    }
    
    private let introspectionQuery = """
    {
      __schema {
        queryType { name }
        mutationType { name }
        types {
          name
          kind
          description
        }
      }
    }
    """
}

// MARK: - GraphQL-specific Filters

/// Extract data from GraphQL response
///
/// Usage:
/// {{ response | graphql_data }}
public struct GraphQLDataFilter: CustomFilter {
    public let name = "graphql_data"
    
    public init() {}
    
    public func apply(
        to value: Any,
        arguments: [Any],
        namedArguments: [String: Any]
    ) async throws -> Any {
        guard let dataValue = value as? DataValue else {
            return value
        }
        
        // Extract data field from GraphQL response
        if case .object(let dict) = dataValue,
           let data = dict["data"] {
            return data.liquidValue
        }
        
        return value
    }
}

/// Extract errors from GraphQL response
///
/// Usage:
/// {{ response | graphql_errors }}
public struct GraphQLErrorsFilter: CustomFilter {
    public let name = "graphql_errors"
    
    public init() {}
    
    public func apply(
        to value: Any,
        arguments: [Any],
        namedArguments: [String: Any]
    ) async throws -> Any {
        guard let dataValue = value as? DataValue else {
            return []
        }
        
        // Extract errors field from GraphQL response
        if case .object(let dict) = dataValue,
           let errors = dict["errors"] {
            return errors.liquidValue
        }
        
        return []
    }
}

/// Check if GraphQL response has errors
///
/// Usage:
/// {% if response | graphql_has_errors %}
public struct GraphQLHasErrorsFilter: CustomFilter {
    public let name = "graphql_has_errors"
    
    public init() {}
    
    public func apply(
        to value: Any,
        arguments: [Any],
        namedArguments: [String: Any]
    ) async throws -> Any {
        guard let dataValue = value as? DataValue else {
            return false
        }
        
        // Check if errors field exists and is non-empty
        if case .object(let dict) = dataValue,
           let errors = dict["errors"],
           case .array(let errorArray) = errors {
            return !errorArray.isEmpty
        }
        
        return false
    }
}

// MARK: - GraphQL Query Builder

/// Helper for building GraphQL queries programmatically
public struct GraphQLQueryBuilder {
    private var operations: [String] = []
    private var fragments: [String] = []
    
    public init() {}
    
    public mutating func query(name: String? = nil, variables: [(String, String)] = [], fields: String) -> GraphQLQueryBuilder {
        var operation = "query"
        
        if let name = name {
            operation += " \(name)"
        }
        
        if !variables.isEmpty {
            let vars = variables.map { "$\($0.0): \($0.1)" }.joined(separator: ", ")
            operation += "(\(vars))"
        }
        
        operation += " {\n\(fields)\n}"
        operations.append(operation)
        
        return self
    }
    
    public mutating func mutation(name: String? = nil, variables: [(String, String)] = [], fields: String) -> GraphQLQueryBuilder {
        var operation = "mutation"
        
        if let name = name {
            operation += " \(name)"
        }
        
        if !variables.isEmpty {
            let vars = variables.map { "$\($0.0): \($0.1)" }.joined(separator: ", ")
            operation += "(\(vars))"
        }
        
        operation += " {\n\(fields)\n}"
        operations.append(operation)
        
        return self
    }
    
    public mutating func fragment(name: String, on type: String, fields: String) -> GraphQLQueryBuilder {
        fragments.append("fragment \(name) on \(type) {\n\(fields)\n}")
        return self
    }
    
    public func build() -> String {
        return (fragments + operations).joined(separator: "\n\n")
    }
}
