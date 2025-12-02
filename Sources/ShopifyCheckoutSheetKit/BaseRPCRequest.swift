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
///
/// Request events represent bidirectional communication where the checkout is waiting
/// for the app to provide data or complete an operation before continuing.
///
/// This class extends `BaseRPCMessage` and adds request-specific behavior:
/// - Storage for the request `id` field
/// - Implementation of response methods
/// - Validation logic for responses
public class BaseRPCRequest<P: Decodable, R: Codable>: BaseRPCMessage<P>, RPCRequest {
    public typealias ResponsePayload = R

    /// The request ID - always non-null for request events
    private let _id: String

    /// Public accessor for the request ID
    public var id: String { _id }

    /// Whether this is a notification (always false for BaseRPCRequest - requests have IDs)
    override public var isNotification: Bool { false }

    /// Required initializer for RPCRequest protocol
    public required init(id: String?, params: Params) {
        // Request events must have an id - if nil, use empty string as fallback
        _id = id ?? ""
        super.init(params: params, webview: nil)
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

// TypeErasedRPCDecodable conformance is inherited from BaseRPCMessage
