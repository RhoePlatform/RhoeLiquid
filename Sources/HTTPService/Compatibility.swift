import Foundation
import Hummingbird
import HTTPTypes
import NIOCore

typealias HTTPMethod = HTTPRequest.Method
typealias HTTPResponseStatus = HTTPResponse.Status

extension HTTPRequest.Method {
    static let GET = Self.get
    static let POST = Self.post
    static let PUT = Self.put
    static let DELETE = Self.delete
    static let OPTIONS = Self.options
}

extension HTTPResponse.Status {
    init(statusCode: Int) {
        self.init(code: statusCode)
    }
}

extension HTTPField.Name {
    static let referrerPolicy = Self("Referrer-Policy")!
    static let xContentTypeOptions = Self("X-Content-Type-Options")!
    static let xForwardedFor = Self("X-Forwarded-For")!
    static let xFrameOptions = Self("X-Frame-Options")!
    static let xRealIP = Self("X-Real-IP")!
    static let xXSSProtection = Self("X-XSS-Protection")!
}

struct HTTPHeaders: ExpressibleByDictionaryLiteral, Sequence, Sendable {
    private var storage: [String: String]

    init() {
        self.storage = [:]
    }

    init(_ values: [String: String]) {
        self.storage = values
    }

    init(dictionaryLiteral elements: (String, String)...) {
        self.storage = Dictionary(uniqueKeysWithValues: elements)
    }

    mutating func add(name: String, value: String) {
        self.storage[name] = value
    }

    subscript(_ name: String) -> String? {
        get { self.storage[name] }
        set { self.storage[name] = newValue }
    }

    func makeIterator() -> Dictionary<String, String>.Iterator {
        self.storage.makeIterator()
    }

    var httpFields: HTTPFields {
        var fields = HTTPFields()
        for (name, value) in self.storage {
            guard let fieldName = HTTPField.Name(name) else {
                continue
            }
            fields[fieldName] = value
        }
        return fields
    }
}

extension HTTPFields {
    subscript(_ name: String) -> String? {
        get {
            guard let fieldName = HTTPField.Name(name) else {
                return nil
            }
            return self[fieldName]
        }
        set {
            guard let fieldName = HTTPField.Name(name) else {
                return
            }
            self[fieldName] = newValue
        }
    }
}

extension Data {
    init(buffer: ByteBuffer) {
        self = Data(buffer.readableBytesView)
    }
}

extension Request {
    init(
        method: HTTPMethod,
        uri: String,
        headers: HTTPHeaders = HTTPHeaders(),
        body: String? = nil
    ) {
        let head = HTTPRequest(
            method: method,
            scheme: nil,
            authority: nil,
            path: uri,
            headerFields: headers.httpFields
        )

        if let body {
            var buffer = ByteBufferAllocator().buffer(capacity: body.utf8.count)
            buffer.writeString(body)
            self.init(head: head, body: .init(buffer: buffer))
        } else {
            self.init(head: head, body: .init(buffer: ByteBufferAllocator().buffer(capacity: 0)))
        }
    }
}

extension Response {
    init(
        status: HTTPResponseStatus,
        headers: HTTPHeaders = HTTPHeaders(),
        body: String? = nil
    ) {
        if let body {
            var buffer = ByteBufferAllocator().buffer(capacity: body.utf8.count)
            buffer.writeString(body)
            self.init(status: status, headers: headers.httpFields, body: .init(byteBuffer: buffer))
        } else {
            self.init(status: status, headers: headers.httpFields)
        }
    }
}
