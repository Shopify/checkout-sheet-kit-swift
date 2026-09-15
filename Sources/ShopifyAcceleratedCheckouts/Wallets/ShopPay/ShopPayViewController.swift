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

import ShopifyCheckoutSheetKit
import SwiftUI

@available(iOS 16.0, *)
public class ShopPayViewController: WalletController {
    var eventHandlers: EventHandlers

    public init(
        identifier: CheckoutIdentifier,
        configuration: ShopifyAcceleratedCheckouts.Configuration,
        eventHandlers: EventHandlers = EventHandlers()
    ) {
        self.eventHandlers = eventHandlers
        super.init(
            identifier: identifier,
            storefront: StorefrontAPI(
                storefrontDomain: configuration.storefrontDomain,
                storefrontAccessToken: configuration.storefrontAccessToken
            ),
            configuration: configuration
        )
        self.identifier = identifier.parse()
    }

    @MainActor
    public func onPress() async {
        do {
            let cart = try await fetchCartByCheckoutIdentifier()
            guard let url = cart.checkoutUrl.url.appendQueryParam(name: "payment", value: "shop_pay") else {
                throw ShopifyAcceleratedCheckouts.Error.invariant(expected: "url")
            }
            try await present(url: url, delegate: self)
        } catch {
            let error = CheckoutError.sdkError(underlying: error)
            ShopifyAcceleratedCheckouts.logger.error("[present] Failed to create cart: \(error)")
            eventHandlers.checkoutDidFail?(error)
        }
    }
}

@available(iOS 16.0, *)
extension ShopPayViewController: CheckoutDelegate {
    public func checkoutDidComplete(event: CheckoutCompletedEvent) {
        eventHandlers.checkoutDidComplete?(event)
    }

    public func checkoutDidFail(error: CheckoutError) {
        checkoutViewController?.dismiss(animated: true)
        eventHandlers.checkoutDidFail?(error)
    }

    public func checkoutDidCancel() {
        // x right button on CSK doesn't dismiss automatically
        checkoutViewController?.dismiss(animated: true)
        eventHandlers.checkoutDidCancel?()
    }

    public func shouldRecoverFromError(error: CheckoutError) -> Bool {
        return eventHandlers.shouldRecoverFromError?(error) ?? error.isRecoverable
    }

    public func checkoutDidClickLink(url: URL) {
        eventHandlers.checkoutDidClickLink?(url)
    }

    public func checkoutDidEmitWebPixelEvent(event: PixelEvent) {
        eventHandlers.checkoutDidEmitWebPixelEvent?(event)
    }
}
