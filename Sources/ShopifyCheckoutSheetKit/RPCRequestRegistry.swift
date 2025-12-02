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

/// Registry of all supported RPC message types (both requests and notifications)
enum RPCRequestRegistry {
    /// Array of all supported message types
    static let messageTypes: [any RPCMessage.Type] = [
        CheckoutAddressChangeStart.self,
        CheckoutPaymentMethodChangeStart.self,
        CheckoutCompleteRequest.self,
        CheckoutErrorRequest.self,
        CheckoutModalToggledRequest.self,
        CheckoutStartRequest.self,
        CheckoutSubmitStart.self
    ]

    /// Find the message type for a given method name
    /// for:method corresponds to RPCMessage.method
    /// for:method is used to select correct Decoder
    static func messageType(for method: String) -> (any RPCMessage.Type)? {
        return messageTypes.first { $0.method == method }
    }

    /// Decode the appropriate message type for a given method
    /// for:method corresponds to RPCMessage.method
    /// for:method is used to select correct Decoder
    static func decode(for method: String, from data: Data, webview: WKWebView) throws -> (any RPCMessage)? {
        guard let messageType = messageTypes.first(where: { $0.method == method }) else {
            return nil
        }

        // Cast to our type-erased protocol and decode
        guard let decodableType = messageType as? any TypeErasedRPCDecodable.Type else {
            return nil
        }

        let message = try decodableType.decodeErased(from: data)
        message.webview = webview
        return message
    }
}
