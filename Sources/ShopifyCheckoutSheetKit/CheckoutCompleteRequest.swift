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

/// Notification for checkout completion events.
///
/// This event is triggered when checkout completes successfully.
/// It's a one-way notification that does not require a response.
public final class CheckoutCompleteRequest: CheckoutNotification, RPCMessage {
    private let rpcNotification: BaseRPCNotification<CheckoutCompleteEvent>

    public static let method: String = "checkout.complete"
    public var method: String { Self.method }
    public var params: CheckoutCompleteEvent { rpcNotification.params }

    internal init(rpcNotification: BaseRPCNotification<CheckoutCompleteEvent>) {
        self.rpcNotification = rpcNotification
    }

    // MARK: - RPCMessage conformance

    internal var jsonrpc: String { rpcNotification.jsonrpc }
    internal var isNotification: Bool { rpcNotification.isNotification }
    internal var webview: WKWebView? {
        get { rpcNotification.webview }
        set { rpcNotification.webview = newValue }
    }

    internal required init(id: String?, params: CheckoutCompleteEvent) {
        self.rpcNotification = BaseRPCNotification(id: id, params: params)
    }
}

// MARK: - TypeErasedRPCDecodable conformance
extension CheckoutCompleteRequest: TypeErasedRPCDecodable {
    static func decodeErased(from data: Data) throws -> any RPCMessage {
        return try JSONDecoder().decode(CheckoutCompleteRequest.self, from: data)
    }
}
