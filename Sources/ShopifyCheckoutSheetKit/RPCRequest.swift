/*
 MIT License

 Copyright 2023 - Present, Shopify Inc.

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import Foundation
import WebKit

/// (Web) The Client is defined as the origin of Request objects and the handler of Response objects.
/// (Native) The Server is defined as the origin of Response objects and the handler of Request objects.
public protocol RPCRequest: AnyObject {
    associatedtype RPCResponse: Codable

    /// nil if request is a notification type
    var id: String? { get }
    var jsonrpc: String { get }

    // 4.1 Notification - https://www.jsonrpc.org/specification
    var isNotification: Bool { get }

    /// Event Name
    static var type: String { get }

    var hasResponded: Bool { get set }
    var webview: WKWebView? { get set }

    /// jsonString should decode into RPCResponse
    func respondWith(json jsonString: String) throws
    func respondWith(result: RPCResponse) throws

    /// (Optional) Called in respondWith before dispatching message over bridge
    /// Apply validations outside of RPCResponse decoding
    /// e.g. RPCResponse.someArrayProperty.count > 0
    /// default: no-op
    func validate(payload: RPCResponse) throws
}

extension RPCRequest {
    public var jsonrpc: String { "2.0" }
    // TODO; May not be needed
    /// id is nil if notification type
    public var isNotification: Bool { id == nil }

    public func respondWith(json jsonString: String) throws {
        let payload = try decode(from: jsonString)
        try respondWith(result: payload)
    }

    public func respondWith(result: RPCResponse) throws {
        guard let webview else { return }
        guard !isNotification else { return }
        guard !hasResponded else { return }
        hasResponded = true

        try validate(payload: result)

        guard let payload = SdkToWebEvent(detail: result).toJson() else { return }

        CheckoutBridge.sendMessage(webview, messageName: Self.type, messageBody: payload)
    }

    /// `from` should be a .utf8 encoded json string
    /// Decodes into RespondableEvent.RPCResponse Codable
    func decode(from responseData: String) throws -> RPCResponse {
        guard let data = responseData.data(using: .utf8) else {
            throw EventResponseError.invalidEncoding
        }

        do {
            return try JSONDecoder().decode(RPCResponse.self, from: data)
        } catch let error as DecodingError {
            throw EventResponseError.decodingFailed(formatDecodingError(error))
        } catch {
            throw EventResponseError.decodingFailed(error.localizedDescription)
        }
    }

    public func validate(payload _: RPCResponse) throws {}
}

public enum EventResponseError: Error {
    case invalidEncoding
    case decodingFailed(String)
    case validationFailed(String)
}

func formatDecodingError(_ error: DecodingError) -> String {
    switch error {
    case let .keyNotFound(key, _):
        return "Missing required field: \(key.stringValue)"
    case let .typeMismatch(type, context):
        let path = context.codingPath.map(\.stringValue).joined(separator: ".")
        return "Type mismatch at \(path): expected \(type)"
    case let .valueNotFound(type, context):
        let path = context.codingPath.map(\.stringValue).joined(separator: ".")
        return "Missing value at \(path): expected \(type)"
    case let .dataCorrupted(context):
        return "Data corrupted: \(context.debugDescription)"
    @unknown default:
        return "Unknown decoding error"
    }
}
