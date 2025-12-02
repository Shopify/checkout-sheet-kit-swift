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

/// Base class for all RPC message implementations.
///
/// Messages can be requests (bidirectional, with id) or notifications (unidirectional, without id).
/// Subclasses specialize for each type:
/// - `BaseRPCRequest` for request events (checkout.addressChangeStart, etc.)
/// - `BaseRPCNotification` for notification events (checkout.start, checkout.complete)
internal class BaseRPCMessage<P: Decodable>: RPCMessage {
    internal typealias Params = P

    /// The JSON-RPC version (always "2.0")
    var jsonrpc: String { "2.0" }

    /// Whether this is a notification - subclasses must override
    var isNotification: Bool {
        fatalError("Subclasses must override isNotification")
    }

    internal let params: Params
    internal weak var webview: WKWebView?

    internal class var method: String {
        fatalError("Subclasses must override method")
    }

    internal init(params: Params, webview: WKWebView? = nil) {
        self.params = params
        self.webview = webview
    }

    internal required init(id _: String?, params: Params) {
        self.params = params
        webview = nil
    }
}

// MARK: - TypeErasedRPCDecodable conformance

extension BaseRPCMessage: TypeErasedRPCDecodable {
    static func decodeErased(from data: Data) throws -> any RPCMessage {
        return try JSONDecoder().decode(Self.self, from: data)
    }
}
