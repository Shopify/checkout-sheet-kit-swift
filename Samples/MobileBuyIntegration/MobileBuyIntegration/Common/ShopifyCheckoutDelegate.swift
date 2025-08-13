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
import ShopifyAcceleratedCheckouts
import ShopifyCheckoutSheetKit
import UIKit

/**
 * Common CheckoutDelegate instance which can be reused across instances of Checkout Sheet Kit and Accelerated Checkouts.
 *
 * Use overrides to override the default behaviour.
 */
class CustomCheckoutDelegate: UIViewController, CheckoutDelegate {
    func checkoutDidComplete(event _: CheckoutCompletedEvent) {
        dismiss(animated: true)
    }

    func checkoutDidClickLink(url: URL) {
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    func checkoutDidFail(error: ShopifyCheckoutSheetKit.CheckoutError) {
        ShopifyCheckoutSheetKit.configuration.logger.log("Checkout failed: \(error.localizedDescription), Recoverable: \(error.isRecoverable)")
    }

    func checkoutDidEmitWebPixelEvent(event: ShopifyCheckoutSheetKit.PixelEvent) {
        Analytics.record(event)
    }

    func checkoutDidCancel() {
        dismiss(animated: true)
    }
}
