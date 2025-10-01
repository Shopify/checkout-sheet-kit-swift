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

public protocol RespondableEvent: AnyObject {
    associatedtype ResponseType: Codable

    var id: String { get }
    var responseMessageName: String { get }
    var cancellationMessageName: String? { get }
    var hasResponded: Bool { get set }
    var webView: WKWebView? { get set }

    func respondWith(json jsonString: String) throws
    func decode(from responseData: String) throws -> ResponseType
    func respondWith(result: ResponseType)
    func validate(payload: ResponseType) throws
}

extension RespondableEvent {
    public func respondWith(json jsonString: String) throws {
        let payload = try decode(from: jsonString)
        respondWith(result: payload)
    }

    public func respondWith(result: ResponseType) {
        guard !hasResponded else { return }
        hasResponded = true
        guard let webView else { return }

        if let payload = SdkToWebEvent(detail: result).toJson() {
            CheckoutBridge.sendMessage(
                webView,
                messageName: responseMessageName,
                messageBody: payload
            )
        }
    }

    public func decode(from responseData: String) throws -> ResponseType {
        guard let data = responseData.data(using: .utf8) else {
            throw EventResponseError.invalidEncoding
        }

        do {
            let payload = try JSONDecoder().decode(ResponseType.self, from: data)
            try validate(payload: payload)
            return payload
        } catch let error as DecodingError {
            throw EventResponseError.decodingFailed(formatDecodingError(error))
        } catch let error as EventResponseError {
            throw error
        } catch {
            throw EventResponseError.decodingFailed(error.localizedDescription)
        }
    }

    public func validate(payload _: ResponseType) throws {}
}

public enum EventResponseError: Error {
    case invalidEncoding
    case decodingFailed(String)
    case validationFailed(String)
}

func formatDecodingError(_ error: DecodingError) -> String {
    switch error {
    case .keyNotFound(let key, _):
        return "Missing required field: \(key.stringValue)"
    case .typeMismatch(let type, let context):
        let path = context.codingPath.map(\.stringValue).joined(separator: ".")
        return "Type mismatch at \(path): expected \(type)"
    case .valueNotFound(let type, let context):
        let path = context.codingPath.map(\.stringValue).joined(separator: ".")
        return "Missing value at \(path): expected \(type)"
    case .dataCorrupted(let context):
        return "Data corrupted: \(context.debugDescription)"
    @unknown default:
        return "Unknown decoding error"
    }
}
