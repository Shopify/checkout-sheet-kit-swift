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
class ShopPayViewController: WalletController {
    var configuration: ShopifyAcceleratedCheckouts.Configuration
    var eventHandlers: EventHandlers

    init(
        identifier: CheckoutIdentifier,
        configuration: ShopifyAcceleratedCheckouts.Configuration,
        eventHandlers: EventHandlers = EventHandlers()
    ) {
        self.configuration = configuration
        self.eventHandlers = eventHandlers
        super.init(
            identifier: identifier,
            storefront: StorefrontAPI(
                storefrontDomain: configuration.storefrontDomain,
                storefrontAccessToken: configuration.storefrontAccessToken
            )
        )
        self.identifier = identifier.parse()
    }

    func present() async throws {
        do {
            let cart = try await fetch()
            guard let url = try? await buildRedirectUrl() else {
                throw ShopifyAcceleratedCheckouts.Error.invariant(expected: "url")
            }
            try await present(url: url, delegate: self)
        } catch {
            ShopifyAcceleratedCheckouts.logger.error("[present] Failed to setup cart: \(error)")
        }
    }

    private func buildRedirectUrl() async throws -> URL? {
        guard let checkoutUrl = try await getCheckoutUrl() else {
            return nil
        }

        return checkoutUrl.appendQueryParam(name: "payment", value: "shop_pay")
    }

    private func getCheckoutUrl() async throws -> URL? {
        switch identifier {
        case let .cart(id):
            let cart = try await storefront.cart(by: .init(id))
            return cart?.checkoutUrl.url
        case let .variant(_, quantity):
            return URL(
                string:
                    "https://\(configuration.storefrontDomain)/cart/\(identifier.getTokenComponent()):\(quantity)"
            )
        case .invariant:
            return nil
        }
    }
}

@available(iOS 16.0, *)
extension ShopPayViewController: CheckoutDelegate {
    func checkoutDidComplete(event: CheckoutCompletedEvent) {
        eventHandlers.checkoutDidComplete?(event)
    }

    func checkoutDidFail(error: CheckoutError) {
        checkoutViewController?.dismiss(animated: true)
        eventHandlers.checkoutDidFail?(error)
    }

    func checkoutDidCancel() {
        /// x right button on CSK doesn't dismiss automatically
        checkoutViewController?.dismiss(animated: true)
        eventHandlers.checkoutDidCancel?()
    }

    func shouldRecoverFromError(error: CheckoutError) -> Bool {
        return eventHandlers.shouldRecoverFromError?(error) ?? false
    }

    func checkoutDidClickLink(url: URL) {
        eventHandlers.checkoutDidClickLink?(url)
    }

    func checkoutDidEmitWebPixelEvent(event: PixelEvent) {
        eventHandlers.checkoutDidEmitWebPixelEvent?(event)
    }
}
