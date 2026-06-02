import Hummingbird
import XCTest
@testable import HTTPService
@testable import ServiceCore

final class MiddlewareTests: XCTestCase {
    func testSecurityMiddlewareBlocksExternalHosts() async throws {
        let middleware = SecurityMiddleware(configuration: .development)
        let request = Request(
            method: .GET,
            uri: "/health",
            headers: ["Host": "example.com:15480"]
        )

        do {
            _ = try await middleware.apply(to: request) { _ in
                Response(status: .ok, headers: .init(), body: .init())
            }
            XCTFail("Expected host validation to fail")
        } catch let error as HTTPError {
            XCTAssertEqual(error.status, .forbidden)
        }
    }

    func testCORSMiddlewareAddsOriginHeader() async throws {
        let middleware = CORSMiddleware(allowOrigin: .originBased)
        let request = Request(
            method: .GET,
            uri: "/health",
            headers: ["Origin": "http://localhost:3000"]
        )

        let response = try await middleware.apply(to: request) { _ in
            Response(status: .ok, headers: .init(), body: .init())
        }

        XCTAssertEqual(response.headers["Access-Control-Allow-Origin"], "http://localhost:3000")
    }

    func testRateLimitMiddlewareAllowsThenLimitsRequests() async throws {
        let middleware = RateLimitMiddleware(
            configuration: RateLimitConfiguration(requestsPerMinute: 1, burstLimit: 0)
        )
        let clientIP = "127.0.0.\(Int.random(in: 2...254))"
        let request = Request(
            method: .GET,
            uri: "/health",
            headers: ["X-Real-IP": clientIP]
        )

        _ = try await middleware.apply(to: request) { _ in
            Response(status: .ok, headers: .init(), body: .init())
        }

        do {
            _ = try await middleware.apply(to: request) { _ in
                Response(status: .ok, headers: .init(), body: .init())
            }
            XCTFail("Expected rate limiting on the second request")
        } catch let error as HTTPError {
            XCTAssertEqual(error.status, .tooManyRequests)
        }
    }
}
