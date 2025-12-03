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

/// Registry of all supported checkout event types
enum RPCRequestRegistry {
    /// Array of all supported event types that conform to CheckoutEventDecodable
    static let eventTypes: [any CheckoutEventDecodable.Type] = [
        // Notification events
        CheckoutStartEvent.self,
        CheckoutCompleteEvent.self,

        // Request events
        CheckoutAddressChangeStart.self,
        CheckoutSubmitStart.self,
        CheckoutPaymentMethodChangeStart.self
    ]

    /// Decode the appropriate event type for a given method
    /// Returns either a CheckoutNotification or a CheckoutRequest
    /// Returns nil if the method is unsupported or if a request event lacks required webview
    static func decode(for method: String, from data: Data, webview: WKWebView?) throws -> Any? {
        // Try to find matching event type using type-erased registry
        if let eventType = eventTypes.first(where: { $0.method == method }) {
            return try eventType.decodeEvent(from: data, webview: webview)
        }

        // Legacy RPC events (kept for internal compatibility)
        switch method {
        case CheckoutErrorRequest.method:
            guard let webview = webview else { return nil }
            let request = try CheckoutErrorRequest.decodeErased(from: data)
            request.webview = webview
            return request

        case CheckoutModalToggledRequest.method:
            guard let webview = webview else { return nil }
            let request = try CheckoutModalToggledRequest.decodeErased(from: data)
            request.webview = webview
            return request

        default:
            return nil
        }
    }
}
