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

/// Protocol to enable type-erased decoding of RPC messages
protocol TypeErasedRPCDecodable {
    static func decodeErased(from data: Data) throws -> any RPCMessage
}

/// Response to be decoded to a string for transport over CheckoutBridge
public class RPCResponse<Payload: Codable>: Codable {
    /// A String specifying the version of the JSON-RPC protocol. MUST be exactly "2.0".
    public var jsonrpc: String = "2.0"

    /// This member is REQUIRED.
    /// It MUST be the same as the value of the id member in the Request Object.
    /// If there was an error in detecting the id in the Request object (e.g. Parse error/Invalid Request), it MUST be Null.
    /// Either the result member or error member MUST be included, but both members MUST NOT be included.
    var id: String?

    /// This member is REQUIRED on success.
    /// This member MUST NOT exist if there was an error invoking the method.
    /// The value of this member is determined by the method invoked on the Server.
    var result: Payload?

    /// This member is REQUIRED on error.
    /// This member MUST NOT exist if there was no error triggered during invocation.
    /// The value for this member MUST be an Object as defined in section 5.1.
    var error: String?

    init(id: String? = nil, result: Payload? = nil) {
        self.id = id
        self.result = result
    }

    init(id: String? = nil, error: String? = nil) {
        self.id = id
        self.error = error
    }
}

/// Base protocol for all RPC messages (both requests and notifications).
///
/// This protocol represents the common behavior shared by all JSON-RPC 2.0 messages
/// from the checkout web experience, whether they are requests (bidirectional, with id)
/// or notifications (unidirectional, without id).
///
/// Internal protocol - SDK consumers should use CheckoutNotification or CheckoutRequest protocols.
protocol RPCMessage: AnyObject, Decodable {
    /// Parameters associated with this message from Checkout
    associatedtype Params: Decodable

    /// A String specifying the version of the JSON-RPC protocol. MUST be exactly "2.0".
    var jsonrpc: String { get }

    /// The params from the JSON-RPC message
    /// Internal - subclasses should expose specific properties from params
    var params: Params { get }

    /// 4 Request object - https://www.jsonrpc.org/specification
    /// A String containing the name of the method to be invoked. Method names that begin with the word rpc followed by a period character (U+002E or ASCII 46) are reserved for rpc-internal methods and extensions and MUST NOT be used for anything else.
    static var method: String { get }

    /// 4.1 Notification - https://www.jsonrpc.org/specification
    var isNotification: Bool { get }

    var webview: WKWebView? { get set }

    /// Required initializer for creating messages from decoded params
    init(id: String?, params: Params)
}

/// Protocol for RPC request messages (bidirectional, with id, expects response).
///
/// Request events represent bidirectional communication where the checkout is waiting
/// for the app to provide data or complete an operation before continuing.
///
/// Examples: checkout.addressChangeStart, checkout.submitStart, checkout.paymentMethodChangeStart
///
/// Internal protocol - SDK consumers should use CheckoutRequest protocol instead.
protocol RPCRequest: RPCMessage {
    /// Expected data structure to send in response
    associatedtype ResponsePayload: Codable
    typealias Response = RPCResponse<ResponsePayload>

    /// An identifier established by the Client.
    /// Request events always have an id to correlate responses.
    var id: String { get }

    /// Respond with a JSON string payload.
    ///
    /// Primarily used for language bindings (e.g., React Native). Most Swift applications
    /// should use the strongly-typed `respondWith(payload:)` method defined on concrete event classes.
    ///
    /// - Parameter jsonString: A JSON string matching the expected response format for this event type
    /// - Throws: `CheckoutEventResponseError` if the JSON cannot be decoded or validated
    func respondWith(json jsonString: String) throws

    /// Respond with an error message if the operation cannot be completed.
    ///
    /// - Parameter error: A description of the error that occurred
    func respondWith(error: String) throws
}

struct RPCEnvelope<Params: Decodable>: Decodable {
    let id: String?
    let jsonrpc: String
    let method: String
    let params: Params
}

extension RPCMessage {
    public var jsonrpc: String { "2.0" }

    /// Default Decodable implementation for all RPCMessage types
    public init(from decoder: Decoder) throws {
        let envelope = try RPCEnvelope<Params>(from: decoder)

        // Validate JSON-RPC version
        guard envelope.jsonrpc == "2.0" else {
            throw BridgeError.invalidBridgeEvent()
        }

        // Validate method matches this type
        guard envelope.method == Self.method else {
            throw BridgeError.invalidBridgeEvent()
        }

        // Use the required initializer
        self.init(id: envelope.id, params: envelope.params)
    }

    static func decodeEnvelope(from decoder: Decoder) throws -> RPCEnvelope<Params> {
        let envelope = try RPCEnvelope<Params>(from: decoder)

        guard envelope.jsonrpc == "2.0" else {
            throw BridgeError.invalidBridgeEvent()
        }

        guard envelope.method == Self.method else {
            throw BridgeError.invalidBridgeEvent()
        }

        return envelope
    }
}

extension RPCRequest {
    /// `from` should be a .utf8 encoded json string
    /// Decodes into RespondableEvent.RPCResponse Codable
    func decode(from responseData: String) throws -> ResponsePayload {
        guard let data = responseData.data(using: .utf8) else {
            throw CheckoutEventResponseError.invalidEncoding
        }

        do {
            return try JSONDecoder().decode(ResponsePayload.self, from: data)
        } catch let error as DecodingError {
            throw CheckoutEventResponseError.decodingFailed(formatDecodingError(error))
        } catch {
            throw CheckoutEventResponseError.decodingFailed(error.localizedDescription)
        }
    }

    /// (Optional) Called in respondWith before dispatching message over bridge
    /// Apply validations outside of RPCResponse decoding
    /// e.g. RPCResponse.someArrayProperty.count > 0
    /// default: no-op
    public func validate(payload _: ResponsePayload) throws {}
}

public enum CheckoutEventResponseError: Error {
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
