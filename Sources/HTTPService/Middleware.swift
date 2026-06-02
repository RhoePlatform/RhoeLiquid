import Foundation
import Hummingbird
import HTTPTypes
import Logging
import ServiceCore

private actor RateLimitStore {
    private var requestCounts: [String: [Date]] = [:]

    func shouldLimit(clientIP: String, now: Date, requestsPerMinute: Int) -> Bool {
        let windowStart = now.addingTimeInterval(-60)
        self.requestCounts[clientIP] = self.requestCounts[clientIP]?.filter { $0 > windowStart } ?? []

        let currentCount = self.requestCounts[clientIP]?.count ?? 0
        if currentCount >= requestsPerMinute {
            return true
        }

        self.requestCounts[clientIP, default: []].append(now)
        return false
    }
}

struct ConnectionTrackingMiddleware: RouterMiddleware {
    typealias Context = BasicRequestContext

    let httpService: HTTPService
    let logger = Logger(label: "connection-middleware")

    func handle(
        _ request: Request,
        context: BasicRequestContext,
        next: (Request, BasicRequestContext) async throws -> Response
    ) async throws -> Response {
        try await self.process(request) { request in
            try await next(request, context)
        }
    }

    func apply(
        to request: Request,
        next: (Request) async throws -> Response
    ) async throws -> Response {
        try await self.process(request, next: next)
    }

    private func process(
        _ request: Request,
        next: (Request) async throws -> Response
    ) async throws -> Response {
        await self.httpService.connectionOpened()

        defer {
            Task {
                await self.httpService.connectionClosed()
            }
        }

        do {
            return try await next(request)
        } catch {
            self.logger.warning("Request failed in connection tracking: \(error)")
            throw error
        }
    }
}

struct SecurityMiddleware: RouterMiddleware {
    typealias Context = BasicRequestContext

    let configuration: ServiceConfiguration
    let logger = Logger(label: "security-middleware")

    func handle(
        _ request: Request,
        context: BasicRequestContext,
        next: (Request, BasicRequestContext) async throws -> Response
    ) async throws -> Response {
        try await self.process(request) { request in
            try await next(request, context)
        }
    }

    func apply(
        to request: Request,
        next: (Request) async throws -> Response
    ) async throws -> Response {
        try await self.process(request, next: next)
    }

    private func process(
        _ request: Request,
        next: (Request) async throws -> Response
    ) async throws -> Response {
        if let host = request.headers["Host"] {
            let allowedHosts = ["localhost", "127.0.0.1", "::1"]
            let hostWithoutPort = host.split(separator: ":").first.map(String.init) ?? host
            if !allowedHosts.contains(hostWithoutPort) {
                self.logger.warning("Blocked request from non-local host: \(host)")
                throw HTTPError(.forbidden, message: "Access denied: service only accepts local connections")
            }
        }

        if let contentLength = request.headers[.contentLength],
           let length = Int(contentLength),
           length > self.configuration.rateLimits.maxTemplateSizeBytes {
            self.logger.warning("Request too large: \(length) bytes")
            throw HTTPError(.contentTooLarge, message: "Request body too large")
        }

        var response = try await next(request)
        response.headers[.xContentTypeOptions] = "nosniff"
        response.headers[.xFrameOptions] = "DENY"
        response.headers[.xXSSProtection] = "1; mode=block"
        response.headers[.referrerPolicy] = "strict-origin-when-cross-origin"
        response.headers[.server] = "RhoeLiquid-Native-Service/1.0"
        return response
    }
}

struct RateLimitMiddleware: RouterMiddleware {
    typealias Context = BasicRequestContext

    let configuration: RateLimitConfiguration
    let logger = Logger(label: "rate-limit-middleware")

    private static let store = RateLimitStore()

    func handle(
        _ request: Request,
        context: BasicRequestContext,
        next: (Request, BasicRequestContext) async throws -> Response
    ) async throws -> Response {
        try await self.process(request) { request in
            try await next(request, context)
        }
    }

    func apply(
        to request: Request,
        next: (Request) async throws -> Response
    ) async throws -> Response {
        try await self.process(request, next: next)
    }

    private func process(
        _ request: Request,
        next: (Request) async throws -> Response
    ) async throws -> Response {
        let clientIP = self.getClientIP(request)
        let shouldLimit = await Self.store.shouldLimit(
            clientIP: clientIP,
            now: Date(),
            requestsPerMinute: self.configuration.requestsPerMinute
        )

        if shouldLimit {
            self.logger.warning("Rate limit exceeded for client: \(clientIP)")
            throw HTTPError(.tooManyRequests, message: "Rate limit exceeded")
        }

        return try await next(request)
    }

    private func getClientIP(_ request: Request) -> String {
        request.headers[.xForwardedFor]
            ?? request.headers[.xRealIP]
            ?? "127.0.0.1"
    }
}

struct MetricsMiddleware: RouterMiddleware {
    typealias Context = BasicRequestContext

    let httpService: HTTPService
    let logger = Logger(label: "metrics-middleware")

    func handle(
        _ request: Request,
        context: BasicRequestContext,
        next: (Request, BasicRequestContext) async throws -> Response
    ) async throws -> Response {
        try await self.process(request) { request in
            try await next(request, context)
        }
    }

    func apply(
        to request: Request,
        next: (Request) async throws -> Response
    ) async throws -> Response {
        try await self.process(request, next: next)
    }

    private func process(
        _ request: Request,
        next: (Request) async throws -> Response
    ) async throws -> Response {
        let startTime = CFAbsoluteTimeGetCurrent()

        do {
            let response = try await next(request)
            let processingTime = CFAbsoluteTimeGetCurrent() - startTime
            self.logger.debug("Request processed in \((processingTime * 1000).rounded())ms")
            return response
        } catch {
            let processingTime = CFAbsoluteTimeGetCurrent() - startTime
            self.logger.error("Request failed after \((processingTime * 1000).rounded())ms: \(error)")
            throw error
        }
    }
}

struct ErrorMiddleware: RouterMiddleware {
    typealias Context = BasicRequestContext

    let logger = Logger(label: "error-middleware")

    func handle(
        _ request: Request,
        context: BasicRequestContext,
        next: (Request, BasicRequestContext) async throws -> Response
    ) async throws -> Response {
        try await self.process(request) { request in
            try await next(request, context)
        }
    }

    func apply(
        to request: Request,
        next: (Request) async throws -> Response
    ) async throws -> Response {
        try await self.process(request, next: next)
    }

    private func process(
        _ request: Request,
        next: (Request) async throws -> Response
    ) async throws -> Response {
        do {
            return try await next(request)
        } catch let httpError as HTTPError {
            throw httpError
        } catch let serviceError as ServiceError {
            let httpError = self.convertServiceError(serviceError)
            self.logger.error("Converted service error to HTTP error \(httpError.status.code)")
            throw httpError
        } catch {
            self.logger.error("Unhandled error in request processing: \(error)")
            throw HTTPError(.internalServerError, message: "Internal server error")
        }
    }

    private func convertServiceError(_ error: ServiceError) -> HTTPError {
        switch error {
        case .rateLimitExceeded:
            return HTTPError(.tooManyRequests, message: error.localizedDescription)
        case .templateTooLarge, .contextTooLarge:
            return HTTPError(.contentTooLarge, message: error.localizedDescription)
        case .serviceUnavailable:
            return HTTPError(.serviceUnavailable, message: error.localizedDescription)
        case .configurationError:
            return HTTPError(.internalServerError, message: error.localizedDescription)
        }
    }
}

struct CORSMiddleware: RouterMiddleware {
    typealias Context = BasicRequestContext

    enum AllowOrigin {
        case all
        case originBased
        case specific([String])
    }

    let allowOrigin: AllowOrigin
    let allowHeaders: [HTTPField.Name]
    let allowMethods: [HTTPRequest.Method]
    let allowCredentials: Bool

    init(
        allowOrigin: AllowOrigin = .originBased,
        allowHeaders: [HTTPField.Name] = [.contentType],
        allowMethods: [HTTPRequest.Method] = [.get, .post],
        allowCredentials: Bool = false
    ) {
        self.allowOrigin = allowOrigin
        self.allowHeaders = allowHeaders
        self.allowMethods = allowMethods
        self.allowCredentials = allowCredentials
    }

    func handle(
        _ request: Request,
        context: BasicRequestContext,
        next: (Request, BasicRequestContext) async throws -> Response
    ) async throws -> Response {
        try await self.process(request) { request in
            try await next(request, context)
        }
    }

    func apply(
        to request: Request,
        next: (Request) async throws -> Response
    ) async throws -> Response {
        try await self.process(request, next: next)
    }

    private func process(
        _ request: Request,
        next: (Request) async throws -> Response
    ) async throws -> Response {
        if request.method == .options {
            return self.createPreflightResponse(for: request)
        }

        do {
            let response = try await next(request)
            return self.addCORSHeaders(to: response, for: request)
        } catch {
            var response = try self.httpErrorResponse(for: error)
            response = self.addCORSHeaders(to: response, for: request)
            return response
        }
    }

    private func createPreflightResponse(for request: Request) -> Response {
        self.addCORSHeaders(to: Response(status: .ok, headers: HTTPFields(), body: .init()), for: request)
    }

    private func addCORSHeaders(to response: Response, for request: Request) -> Response {
        var response = response

        if let origin = self.allowedOrigin(for: request) {
            response.headers[.accessControlAllowOrigin] = origin
        }
        response.headers[.accessControlAllowMethods] = self.allowMethods.map { $0.rawValue }.joined(separator: ", ")
        response.headers[.accessControlAllowHeaders] = self.allowHeaders.map { $0.canonicalName }.joined(separator: ", ")
        response.headers[.accessControlMaxAge] = "86400"

        if self.allowCredentials {
            response.headers[.accessControlAllowCredentials] = "true"
        }

        return response
    }

    private func allowedOrigin(for request: Request) -> String? {
        let requestOrigin = request.headers[.origin]

        switch self.allowOrigin {
        case .all:
            return "*"
        case .originBased:
            let allowedOrigins = [
                "http://localhost",
                "https://localhost",
                "http://127.0.0.1",
                "https://127.0.0.1",
                "file://",
            ]

            guard let requestOrigin else {
                return nil
            }

            return allowedOrigins.contains(where: requestOrigin.hasPrefix) ? requestOrigin : "null"
        case .specific(let origins):
            guard let requestOrigin else {
                return nil
            }
            return origins.contains(requestOrigin) ? requestOrigin : "null"
        }
    }

    private func httpErrorResponse(for error: Error) throws -> Response {
        if let httpError = error as? HTTPError {
            return Response(status: httpError.status, headers: HTTPHeaders(), body: httpError.body ?? "")
        }
        throw error
    }
}

struct LogRequestsMiddleware: RouterMiddleware {
    typealias Context = BasicRequestContext

    let logLevel: Logger.Level
    let logger = Logger(label: "request-logger")

    init(_ logLevel: Logger.Level = .info) {
        self.logLevel = logLevel
    }

    func handle(
        _ request: Request,
        context: BasicRequestContext,
        next: (Request, BasicRequestContext) async throws -> Response
    ) async throws -> Response {
        try await self.process(request) { request in
            try await next(request, context)
        }
    }

    func apply(
        to request: Request,
        next: (Request) async throws -> Response
    ) async throws -> Response {
        try await self.process(request, next: next)
    }

    private func process(
        _ request: Request,
        next: (Request) async throws -> Response
    ) async throws -> Response {
        let startTime = CFAbsoluteTimeGetCurrent()
        self.logger.log(level: self.logLevel, "Request \(request.method.rawValue) \(request.uri.path)")

        do {
            let response = try await next(request)
            let processingTime = CFAbsoluteTimeGetCurrent() - startTime
            self.logger.log(
                level: self.logLevel,
                "Response \(response.status.code) \(request.uri.path) in \((processingTime * 1000).rounded())ms"
            )
            return response
        } catch {
            let processingTime = CFAbsoluteTimeGetCurrent() - startTime
            self.logger.error("Response error \(request.uri.path) after \((processingTime * 1000).rounded())ms: \(error)")
            throw error
        }
    }
}
