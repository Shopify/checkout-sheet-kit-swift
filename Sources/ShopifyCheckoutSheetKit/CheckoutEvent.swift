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

/// Base protocol for all checkout events (notifications and requests).
/// All checkout events have a method name that identifies their type.
public protocol CheckoutNotification: Decodable {
    /// The method name that identifies this event type.
    /// e.g., "checkout.start", "checkout.addressChangeStart"
    static var method: String { get }

    /// Instance accessor for the method name.
    /// While technically redundant for structs, this improves developer experience
    /// by making the method property visible in autocomplete when working with event instances.
    var method: String { get }
}

/// Default implementation that returns the static method value.
extension CheckoutNotification {
    public var method: String { Self.method }
}

// Internal protocol for type-erased event decoding.
// Allows the registry to decode events without knowing their concrete types.
// internal protocol CheckoutEventDecodable: CheckoutNotification {
//    /// Decode an event from data with optional webview
//    /// Returns nil if the event requires a webview but none is provided
////    static func decodeEvent(from data: Data, webview: WKWebView?) throws -> Any?
// }

/// Default decode implementation for notification events.
/// Eliminates boilerplate for simple one-way events.
extension CheckoutNotification {
    internal static func decode(from data: Data) throws -> Self {
        let envelope = try JSONDecoder().decode(CheckoutNotificationEnvelope<Self>.self, from: data)

        guard envelope.jsonrpc == "2.0" else {
            throw BridgeError.invalidBridgeEvent()
        }

        guard envelope.method == Self.method else {
            throw BridgeError.invalidBridgeEvent()
        }

        return envelope.params
    }

//    internal static func decode(from data: Data, webview: WKWebView?) throws -> Self {
//        return try decode(from: data)
//    }
}

/// Protocol for request events that have decode(from:webview:) methods
internal protocol CheckoutRequestDecodable: CheckoutNotification {
    associatedtype Params: Decodable
    associatedtype ResponsePayload: Codable
    associatedtype Request: BaseRPCRequest<Params, ResponsePayload>

    static func decode(from data: Data, webview: WKWebView) throws -> Self
    init(rpcRequest: Request)
    var rpcRequest: Request { get }
}

extension CheckoutRequestDecodable {
    internal static func decode(from data: Data, webview: WKWebView) throws -> Self {
        let rpcRequest = try JSONDecoder().decode(Request.self, from: data)
        rpcRequest.webview = webview

        return Self(rpcRequest: rpcRequest)
    }
}

/// Protocol for checkout events that expect a response (bidirectional).
///
/// Request events allow the checkout to communicate with your app and receive
/// responses back. Examples include address selection, payment method changes,
/// and submit interception.
public protocol CheckoutRequest: CheckoutNotification {
    associatedtype Params: Decodable
    associatedtype ResponsePayload: Codable
//    associatedtype Request: BaseRPCRequest<Params, ResponsePayload>

    /// The type of response payload this request expects

    /// Unique identifier for this request, used to correlate responses.
    var id: String { get }

    /// Respond with a strongly-typed payload.
    ///
    /// - Parameter payload: The response payload
    func respondWith(payload: ResponsePayload) throws

    /// Respond with a JSON string payload.
    /// Useful for language bindings (e.g., React Native).
    ///
    /// - Parameter jsonString: A JSON string representing the response payload
    func respondWith(json jsonString: String) throws
}
