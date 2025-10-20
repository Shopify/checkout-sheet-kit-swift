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
class WalletController: ObservableObject {
    @Published var identifier: CheckoutIdentifier
    @Published var storefront: StorefrontAPIProtocol
    @Published var checkoutViewController: CheckoutViewController?

    init(identifier: CheckoutIdentifier, storefront: StorefrontAPIProtocol) {
        self.identifier = identifier
        self.storefront = storefront
    }

    func fetchCartByCheckoutIdentifier() async throws -> StorefrontAPI.Types.Cart {
        switch identifier {
        case let .cart(id):
            guard let cart = try await storefront.cart(by: GraphQLScalars.ID(id)) else {
                throw ShopifyAcceleratedCheckouts.Error.cartAcquisition(identifier: identifier)
            }
            return cart

        case let .variant(id, quantity):
            let items = Array(repeating: GraphQLScalars.ID(id), count: quantity)
            return try await storefront.cartCreate(with: items, customer: nil)

        case .invariant:
            throw ShopifyAcceleratedCheckouts.Error.cartAcquisition(identifier: identifier)
        }
    }

    @MainActor
    func present(url: URL, delegate: CheckoutDelegate) async throws {
        guard let topViewController = getTopViewController() else {
            throw ShopifyAcceleratedCheckouts.Error.invariant(expected: "topViewController")
        }
        checkoutViewController = ShopifyCheckoutSheetKit.present(
            checkout: url,
            from: topViewController,
            delegate: delegate,
            options: CheckoutOptions(entryPoint: .acceleratedCheckouts)
        )
    }

    @MainActor
    func getTopViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
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
