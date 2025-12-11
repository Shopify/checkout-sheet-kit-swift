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

import OSLog
import ShopifyCheckoutSheetKit
import UIKit

class ShopifyCheckoutViewController: UIViewController {
    private var checkoutURL: URL
    private var checkoutWebViewController: CheckoutWebViewController
    private var options: CheckoutOptions?

    init(checkoutURL: URL, options: CheckoutOptions? = nil) {
        self.checkoutURL = checkoutURL
        self.options = options
        checkoutWebViewController = CheckoutWebViewController(checkoutURL: checkoutURL, options: options)
        super.init(nibName: nil, bundle: nil)
        // ShopifyCheckoutViewController conforms to CheckoutDelegate to respond to lifecycle events
        checkoutWebViewController.delegate = self
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupHeader()
        setupViewController()
    }

    private func setupHeader() {
        title = "Checkout"
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.black]
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelCheckout)
        )
    }

    private func setupViewController() {
        addChild(checkoutWebViewController)
        checkoutWebViewController.didMove(toParent: self)

        guard let webView = checkoutWebViewController.view else {
            OSLogger.shared.error(
                "[EmbeddedCheckoutViewController]: failed to attach web view to view hierarchy"
            )
            return
        }

        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubviewPinnedToEdges(of: webView)
        checkoutWebViewController.notifyPresented()
    }

    @objc private func cancelCheckout() {
        dismiss(animated: true)
    }

    deinit {
        checkoutWebViewController.willMove(toParent: nil)
        checkoutWebViewController.view.removeFromSuperview()
        checkoutWebViewController.removeFromParent()
    }
}

extension ShopifyCheckoutViewController: CheckoutDelegate {
    func checkoutDidStartAddressChange(event: CheckoutAddressChangeStartEvent) {
        OSLogger.shared.debug(
            "[EmbeddedCheckout] Address change start received for addressType: \(event.addressType)"
        )

        let addressViewController = AddressSelectionViewController(event: event)
        navigationController?.pushViewController(addressViewController, animated: true)
        // ^ UIViewController conforms to CheckoutDelegate
        // consumers can push onto the navigation stack
    }

    func checkoutDidStartPaymentMethodChange(event: CheckoutPaymentMethodChangeStartEvent) {
        OSLogger.shared.debug(
            "[EmbeddedCheckout] Payment method change start received"
        )

        let cardViewController = CardSelectionViewController(event: event)
        navigationController?.pushViewController(cardViewController, animated: true)
    }

    func checkoutDidStart(event: CheckoutStartEvent) {
        OSLogger.shared.debug(
            "[EmbeddedCheckout] Checkout started. Cart ID: \(event.cart.id)")
    }

    func checkoutDidComplete(event: CheckoutCompleteEvent) {
        OSLogger.shared.debug(
            "[EmbeddedCheckout] Checkout completed. Order ID: \(event.orderConfirmation.order.id)")
        dismiss(animated: true)
    }

    func checkoutDidCancel() {
        OSLogger.shared.debug("[EmbeddedCheckout] Checkout cancelled.")
        dismiss(animated: true)
    }

    func checkoutDidFail(error: CheckoutError) {
        OSLogger.shared.debug("[EmbeddedCheckout] Checkout failed: \(error)")
        dismiss(animated: true)
    }

    func checkoutDidStartSubmit(event: CheckoutSubmitStartEvent) {
        // Respond with updated cart containing payment credentials after 1 second
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let credential = CartCredential.remoteTokenPaymentCredential(
                CartCredential.RemoteTokenPaymentCredential(
                    token: "tok_test_123",
                    tokenType: "card",
                    tokenHandler: "delegated"
                )
            )

            let instrument = CartPaymentInstrument(
                externalReference: "payment-instrument-123",
                credentials: [credential]
            )

            let paymentMethod = CartPaymentMethod(instruments: [instrument])
            let payment = CartPayment(methods: [paymentMethod])

            // Create updated cart with payment credentials
            let updatedCart = Cart(
                id: event.cart.id,
                lines: event.cart.lines,
                cost: event.cart.cost,
                buyerIdentity: event.cart.buyerIdentity,
                deliveryGroups: event.cart.deliveryGroups,
                discountCodes: event.cart.discountCodes,
                appliedGiftCards: event.cart.appliedGiftCards,
                discountAllocations: event.cart.discountAllocations,
                delivery: event.cart.delivery,
                payment: payment
            )

            let response = CheckoutSubmitStartResponsePayload(cart: updatedCart)

            OSLogger.shared.debug("[EmbeddedCheckout] Attempting to respond with payment credentials")
            do {
                try event.respondWith(payload: response)
                OSLogger.shared.debug("[EmbeddedCheckout] Successfully sent response")
            } catch {
                OSLogger.shared.error("[EmbeddedCheckout] Failed to respond to submit start: \(error)")
            }
        }
    }
}
