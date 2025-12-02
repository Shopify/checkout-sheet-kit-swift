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

/// Base class for all RPC notification implementations
///
/// Notifications are one-way messages from the checkout to the app that do not expect a response.
/// Unlike requests, notifications do not have an `id` field in the JSON-RPC payload.
///
/// This class extends `BaseRPCMessage` and adds notification-specific behavior:
/// - No `id` field (returns empty string to satisfy protocol)
/// - Stub response methods (no-ops, notifications don't respond)
///
/// Examples: checkout.start, checkout.complete
public class BaseRPCNotification<P: Decodable>: BaseRPCMessage<P>, RPCNotification {
    public typealias ResponsePayload = EmptyResponse

    /// Whether this is a notification (always true for BaseRPCNotification)
    override public var isNotification: Bool { true }

    /// Required initializer for RPCNotification protocol
    /// Notifications receive nil for id in the JSON, which we ignore
    public required init(id _: String?, params: Params) {
        super.init(params: params, webview: nil)
    }
}

// TypeErasedRPCDecodable conformance is inherited from BaseRPCMessage
