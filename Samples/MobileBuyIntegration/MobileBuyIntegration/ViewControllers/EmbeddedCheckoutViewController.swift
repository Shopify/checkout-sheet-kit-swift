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

class EmbeddedCheckoutViewController: UIViewController {
    private let checkoutURL: URL
    private var checkoutWebViewController: CheckoutWebViewController?
    // ^ CheckoutWebViewController currently is an internal component
    // If we expose it, consumers can construct it in a UIViewController
    // This allows presenting it *without* the sheet wrapper

    init(checkoutURL: URL) {
        self.checkoutURL = checkoutURL
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Checkout"
        //view.backgroundColor = .systemBackground
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.black
        ]

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelCheckout)
        )

        setupCheckoutWebViewController()
    }
    // ^ viewDidLoad calls setupCheckoutWebViewController, causing `addChild` to attach it to the view
    
    private func setupCheckoutWebViewController() {
        let webViewController = CheckoutWebViewController(
            checkoutURL: checkoutURL,
            delegate: self
        )

        addChild(webViewController)

        if let webView = webViewController.view {
            webView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(webView)

            NSLayoutConstraint.activate([
                webView.topAnchor.constraint(equalTo: view.topAnchor),
                webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }

        webViewController.didMove(toParent: self)
        checkoutWebViewController = webViewController

        webViewController.notifyPresented()
    }

    @objc private func cancelCheckout() {
        dismiss(animated: true)
    }

    deinit {
        checkoutWebViewController?.willMove(toParent: nil)
        checkoutWebViewController?.view.removeFromSuperview()
        checkoutWebViewController?.removeFromParent()
    }
}

extension EmbeddedCheckoutViewController: CheckoutDelegate {
    func checkoutDidRequestAddressChange(event: AddressChangeRequest) {
        OSLogger.shared.debug("[EmbeddedCheckout] Address change intent received for addressType: \(event.addressType)")

        let addressViewController = AddressSelectionViewController(event: event)
        navigationController?.pushViewController(addressViewController, animated: true)
        // ^ UIViewController conforms to CheckoutDelegate
        // consumers can push onto the navigation stack
    }
    func checkoutDidComplete(event: CheckoutCompletedEvent) {
        OSLogger.shared.debug("[EmbeddedCheckout] Checkout completed. Order ID: \(event.orderDetails.id)")
        dismiss(animated: true)
    }

    func checkoutDidCancel() {
        OSLogger.shared.debug("[EmbeddedCheckout] Checkout cancelled.")
        dismiss(animated: true)
    }

    func checkoutDidFail(error: CheckoutError) {
        OSLogger.shared.debug("[EmbeddedCheckout] Checkout failed: \(error.localizedDescription)")
        dismiss(animated: true)
    }

    func checkoutDidEmitWebPixelEvent(event: PixelEvent) {
        var eventName: String?

        switch event {
        case let .standardEvent(event):
            eventName = event.name
        case let .customEvent(event):
            eventName = event.name
        }

        OSLogger.shared.debug("[EmbeddedCheckout] Pixel event: \(eventName ?? "")")
    }

}
