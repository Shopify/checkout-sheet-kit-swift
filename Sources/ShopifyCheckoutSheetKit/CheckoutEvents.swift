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

/// Base protocol for all checkout events.
///
/// Checkout events are messages sent from the checkout web experience to your app.
/// Events can be either notifications (one-way messages) or requests (expecting a response).
///
/// Examples of notification events: `CheckoutStartEvent`, `CheckoutCompleteEvent`
public protocol CheckoutNotification {
    /// The method name that identifies this event type
    /// e.g., "checkout.start", "checkout.addressChangeStart"
    var method: String { get }
}

/// Protocol for checkout events that require a response from your app.
///
/// Request events represent bidirectional communication where the checkout is waiting
/// for your app to provide data or complete an operation before continuing.
///
/// Examples: `CheckoutAddressChangeStart`, `CheckoutSubmitStart`, `CheckoutPaymentMethodChangeStart`
///
/// Each concrete event class provides a strongly-typed `respondWith(payload:)` method for
/// responding with the appropriate payload type. You must respond to allow the checkout to continue.
public protocol CheckoutRequest: CheckoutNotification {
    /// Unique identifier for this request, used to correlate responses
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
