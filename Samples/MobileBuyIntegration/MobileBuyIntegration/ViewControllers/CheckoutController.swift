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
import OSLog
import ShopifyCheckoutSheetKit
import UIKit

class CheckoutController: UIViewController {
    var window: UIWindow?
    var root: UIViewController?

    init(window: UIWindow?) {
        self.window = window
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public static var shared: CheckoutController?

    public func present(checkout url: URL) {
        if let rootViewController = window?.topMostViewController() {
            _Concurrency.Task {
                var options: CheckoutOptions?

                if AuthenticationService.shared.hasConfiguration() {
                    do {
                        let token = try await AuthenticationService.shared.fetchAccessToken()
                        options = CheckoutOptions(authentication: .token(token))
                        OSLogger.shared.debug("[CheckoutController] Authentication token fetched successfully")
                    } catch {
                        OSLogger.shared.error("[CheckoutController] Failed to fetch authentication token: \(error.localizedDescription)")
                    }
                } else {
                    OSLogger.shared.debug("[CheckoutController] Authentication not configured, proceeding without token")
                }

                await MainActor.run {
                    ShopifyCheckoutSheetKit.preload(checkout: url, options: options)
                    ShopifyCheckoutSheetKit.present(checkout: url, from: rootViewController, delegate: self, options: options)
                    self.root = rootViewController
                }
            }
        }
    }

    public func preload() {
//        CartManager.shared.preloadCheckout()
    }
}

extension CheckoutController: CheckoutDelegate {
    func checkoutDidComplete(event: CheckoutCompletedEvent) {
        OSLogger.shared.debug(
            "[CheckoutDelegate] Checkout completed. Order ID: \(event.orderConfirmation.order.id)")
        CartManager.shared.resetCart()
    }

    func checkoutDidCancel() {
        OSLogger.shared.debug("[CheckoutDelegate] Checkout cancelled.")
        root?.dismiss(animated: true, completion: nil)
    }

    func checkoutDidFail(error: ShopifyCheckoutSheetKit.CheckoutError) {
        OSLogger.shared.debug("[CheckoutDelegate] Checkout failed: \(error.localizedDescription)")
    }

    func checkoutDidEmitWebPixelEvent(event: ShopifyCheckoutSheetKit.PixelEvent) {
        var eventName: String?

        switch event {
        case let .standardEvent(event):
            eventName = event.name
        case let .customEvent(event):
            eventName = event.name
        }

        OSLogger.shared.debug("[CheckoutDelegate] Pixel event: \(eventName ?? "")")
    }

    func checkoutDidRequestAddressChange(event: AddressChangeRequested) {
        OSLogger.shared.debug("[CheckoutDelegate] Address change intent received for addressType: \(event.params.addressType)")

        // Respond with a hardcoded address after 2 seconds to simulate native address picker
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let hardcodedAddress = CartAddress(
                firstName: "John",
                lastName: "Doe",
                address1: "123 Test Street",
                address2: "Apt 4B",
                city: "Toronto",
                countryCode: "CA",
                phone: "+1-416-555-0123",
                provinceCode: "ON",
                zip: "M5V 1A1"
            )

            let addressInput = CartSelectableAddress(address: hardcodedAddress)
            let delivery = CartDelivery(addresses: [addressInput])
            let response = DeliveryAddressChangePayload(delivery: delivery)

            OSLogger.shared.debug("[CheckoutDelegate] Responding with hardcoded Toronto address")
            do {
                try event.respondWith(payload: response)
            } catch {
                OSLogger.shared.error("[CheckoutDelegate] Failed to respond to address change intent: \(error)")
            }
        }
    }
}
