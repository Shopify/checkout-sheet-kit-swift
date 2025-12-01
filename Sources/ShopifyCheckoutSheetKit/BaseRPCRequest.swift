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

/// Base class for all RPC request implementations
public class BaseRPCRequest<P: Decodable, R: Codable>: RPCRequest {
    public typealias Params = P
    public typealias ResponsePayload = R

    /// The request ID (non-null for requests that can be responded to)
    private let _id: String

    /// Public accessor that exposes non-nullable id for CheckoutRequest protocol
    public var id: String { _id }

    /// The JSON-RPC version (always "2.0")
    var jsonrpc: String { "2.0" }

    /// Whether this is a notification (always false for BaseRPCRequest - requests have IDs)
    var isNotification: Bool { false }

    /// The parameters from the RPC request.
    /// Internal - subclasses should expose specific properties from params.
    internal let params: Params
    internal weak var webview: WKWebView?

    /// Subclasses must override this to provide their method name
    public class var method: String {
        fatalError("Subclasses must override method")
    }

    /// Required initializer for RPCRequest protocol (accepts optional id for wire format)
    public required init(id: String?, params: Params) {
        guard let id else {
            fatalError("BaseRPCRequest requires non-null id. Use notification event classes for events without id.")
        }
        _id = id
        self.params = params
        webview = nil
    }

    /// Default validation does nothing - subclasses can override
    internal func validate(payload _: ResponsePayload) throws {
        // Subclasses can override if they need validation
    }

    /// Respond with a typed payload
    public func respondWith(payload: ResponsePayload) throws {
        guard let webview else { return }
        guard !isNotification else { return }

        // Validate first
        try validate(payload: payload)

        // Encode and send
        let response = RPCResponse(id: id, result: payload)

        do {
            let encoder = JSONEncoder()
            let responseData = try encoder.encode(response)
            guard let responseJson = String(data: responseData, encoding: .utf8) else {
                OSLogger.shared.error(
                    "[BaseRPCRequest] sendResponse method: \(Self.method), id: \(id) failed to encode response string"
                )
                return
            }

            CheckoutBridge.sendResponse(webview, messageBody: responseJson)
        } catch {
            OSLogger.shared.error(
                "[BaseRPCRequest] sendResponse method: \(Self.method), id: \(id) encoding error: \(error)"
            )
        }
    }

    /// Respond with a JSON string
    public func respondWith(json jsonString: String) throws {
        guard let data = jsonString.data(using: .utf8) else {
            throw CheckoutEventResponseError.invalidEncoding
        }

        do {
            let payload = try JSONDecoder().decode(ResponsePayload.self, from: data)
            try respondWith(payload: payload)
        } catch let error as CheckoutEventResponseError {
            // Re-throw validation errors from respondWith(payload:)
            throw error
        } catch let error as DecodingError {
            throw CheckoutEventResponseError.decodingFailed(formatDecodingError(error))
        } catch {
            throw CheckoutEventResponseError.decodingFailed(error.localizedDescription)
        }
    }

    /// Respond with an error
    public func respondWith(error: String) throws {
        guard let webview else { return }
        guard !isNotification else { return }

        let response = RPCResponse<ResponsePayload>(id: id, error: error)

        do {
            let encoder = JSONEncoder()
            let responseData = try encoder.encode(response)
            guard let responseJson = String(data: responseData, encoding: .utf8) else {
                OSLogger.shared.error(
                    "[BaseRPCRequest] sendResponse error method: \(Self.method), id: \(id) failed to encode error response string"
                )
                return
            }

            CheckoutBridge.sendResponse(webview, messageBody: responseJson)
        } catch {
            OSLogger.shared.error(
                "[BaseRPCRequest] sendResponse error method: \(Self.method), id: \(id) encoding error: \(error)"
            )
        }
    }
}

// MARK: - TypeErasedRPCDecodable conformance

extension BaseRPCRequest: TypeErasedRPCDecodable {
    static func decodeErased(from data: Data) throws -> any RPCRequest {
        return try JSONDecoder().decode(Self.self, from: data)
    }
}
