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

/// Base protocol for all checkout events (notifications and requests)
public protocol CheckoutNotification {
    /// The method name that identifies this event type
    /// e.g., "checkout.start", "checkout.addressChangeStart"
    var method: String { get }
}

/// Protocol for checkout events that expect a response (bidirectional)
public protocol CheckoutRequest: CheckoutNotification {
    /// Unique identifier for this request, used to correlate responses
    /// For bidirectional events, this should always be present (non-null)
    var id: String? { get }

    /// Respond with a JSON string payload
    func respondWith(json jsonString: String) throws

    /// Respond with an error message
    func respondWith(error: String) throws
}
