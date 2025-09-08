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
import UIKit

/// A delegate protocol for managing checkout lifecycle events.
public protocol CheckoutDelegate: AnyObject {
    /// Tells the delegate that the checkout successfully completed, returning a completed event with order details
    func checkoutDidComplete(event: CheckoutCompletedEvent)

    /// Tells the delegate that the checkout was cancelled by the buyer.
    func checkoutDidCancel()

    /// Tells the delegate that the checkout encoutered one or more errors.
    func checkoutDidFail(error: CheckoutError)

    /// Tells the delegate that checkout has encountered an error and the return value will determine if it is handled with a fallback
    func shouldRecoverFromError(error: CheckoutError) -> Bool

    /// Tells te delegate that the buyer clicked a link
    /// This includes email address or telephone number via `mailto:` or `tel:` or `http` links directed outside the application.
    func checkoutDidClickLink(url: URL)

    /// Tells te delegate that a Web Pixel event was emitted
    func checkoutDidEmitWebPixelEvent(event: PixelEvent)
    
    // MARK: - Embedded Checkout Events (Schema 2025-04)
    
    /// Tells the delegate that the embedded checkout state has changed
    func checkoutDidChangeState(state: CheckoutStatePayload)
    
    /// Tells the delegate that the embedded checkout successfully completed with order details
    func checkoutDidComplete(payload: CheckoutCompletePayload)
    
    /// Tells the delegate that the embedded checkout encountered one or more errors
    func checkoutDidFail(errors: [ErrorPayload])
    
    /// Tells the delegate that an embedded checkout web pixel event was emitted
    func checkoutDidEmitWebPixelEvent(payload: WebPixelsPayload)
}

extension CheckoutDelegate {
    public func checkoutDidComplete(event _: CheckoutCompletedEvent) {
        /// No-op by default
    }

    public func checkoutDidClickLink(url: URL) {
        handleUrl(url)
    }

    public func checkoutDidFail(error: CheckoutError) throws {
        throw error
    }

    public func shouldRecoverFromError(error: CheckoutError) -> Bool {
        return error.isRecoverable
    }

    private func handleUrl(_ url: URL) {
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Embedded Checkout Default Implementations
    
    public func checkoutDidChangeState(state: CheckoutStatePayload) {
        /// No-op by default
    }
    
    public func checkoutDidComplete(payload: CheckoutCompletePayload) {
        /// No-op by default
    }
    
    public func checkoutDidFail(errors: [ErrorPayload]) {
        /// No-op by default
    }
    
    public func checkoutDidEmitWebPixelEvent(payload: WebPixelsPayload) {
        /// No-op by default
    }
}
