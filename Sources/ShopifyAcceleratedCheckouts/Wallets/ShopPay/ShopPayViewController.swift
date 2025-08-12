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

@available(iOS 17.0, *)
@Observable class ShopPayViewController {
    var configuration: ShopifyAcceleratedCheckouts.Configuration
    var storefront: StorefrontAPI
    var identifier: CheckoutIdentifier
    var checkoutViewController: CheckoutViewController?
    var eventHandlers: EventHandlers

    init(
        identifier: CheckoutIdentifier,
        configuration: ShopifyAcceleratedCheckouts.Configuration,
        eventHandlers: EventHandlers = EventHandlers()
    ) {
        self.configuration = configuration
        self.identifier = identifier.parse()
        self.eventHandlers = eventHandlers
        storefront = StorefrontAPI(
            storefrontDomain: configuration.storefrontDomain,
            storefrontAccessToken: configuration.storefrontAccessToken
        )
    }

    func present() async throws {
        guard let redirectUrl = try await buildRedirectUrl() else {
            ShopifyAcceleratedCheckouts.logger.error("Failed to build redirect url for Shop Pay")
            return
        }

        let topViewController = await MainActor.run { getTopViewController() }
        guard let topViewController else {
            ShopifyAcceleratedCheckouts.logger.error("Failed to get top view controller for Shop Pay")
            return
        }

        await MainActor.run {
            self.checkoutViewController = ShopifyCheckoutSheetKit.present(
                checkout: redirectUrl,
                from: topViewController,
                entryPoint: .acceleratedCheckouts,
                delegate: self
            )
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
                string: "https://\(configuration.storefrontDomain)/cart/\(identifier.getTokenComponent()):\(quantity)"
            )
        case .invariant:
            return nil
        }
    }

    private func getTopViewController() -> UIViewController? {
        guard
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = windowScene.windows.first
        else {
            return nil
        }

        var topController = window.rootViewController
        while let presentedController = topController?.presentedViewController {
            topController = presentedController
        }
        return topController
    }
}

@available(iOS 17.0, *)
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
