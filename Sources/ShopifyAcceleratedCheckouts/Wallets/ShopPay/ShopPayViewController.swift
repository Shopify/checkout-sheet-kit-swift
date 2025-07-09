//
//  ShopPayViewController.swift
//  ShopifyAcceleratedCheckouts
//

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
        identifier: CheckoutIdentifier, configuration: ShopifyAcceleratedCheckouts.Configuration, eventHandlers: EventHandlers = EventHandlers()
    ) {
        self.configuration = configuration
        self.identifier = identifier.parse()
        self.eventHandlers = eventHandlers
        storefront = StorefrontAPI(
            shopDomain: configuration.shopDomain,
            storefrontAccessToken: configuration.storefrontAccessToken
        )
    }

    func action() async throws {
        guard let redirectUrl = try await buildRedirectUrl() else {
            print("Failed to build redirect url for Shop Pay")
            return
        }

        let topViewController = await MainActor.run { getTopViewController() }
        guard let topViewController else {
            print("Failed to get top view controller for Shop Pay")
            return
        }

        await MainActor.run {
            self.checkoutViewController = ShopifyCheckoutSheetKit.present(
                checkout: redirectUrl,
                from: topViewController,
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
                string: "https://\(configuration.shopDomain)/cart/\(identifier.getTokenComponent()):\(quantity)"
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

extension ShopPayViewController: CheckoutDelegate {
    func checkoutDidComplete(event _: ShopifyCheckoutSheetKit.CheckoutCompletedEvent) {
        checkoutViewController?.dismiss(animated: true)
        eventHandlers.checkoutSuccessHandler?()
    }

    func checkoutDidFail(error _: ShopifyCheckoutSheetKit.CheckoutError) {
        checkoutViewController?.dismiss(animated: true)
        eventHandlers.checkoutErrorHandler?()
    }

    func checkoutDidCancel() {
        /// x right button on CSK doesn't dismiss automatically
        checkoutViewController?.dismiss(animated: true)
        eventHandlers.checkoutCancelHandler?()
    }

    func checkoutShouldRecoverFromError(error: ShopifyCheckoutSheetKit.CheckoutError) -> Bool {
        return eventHandlers.shouldRecoverFromErrorHandler?(error) ?? false
    }

    func checkoutDidClickLink(url: URL) {
        eventHandlers.clickLinkHandler?(url)
    }

    func checkoutDidEmitWebPixelEvent(event: ShopifyCheckoutSheetKit.PixelEvent) {
        eventHandlers.webPixelEventHandler?(event)
    }
}
