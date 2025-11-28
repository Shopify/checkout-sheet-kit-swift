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

import SwiftUI
import UIKit

public class CheckoutViewController: UINavigationController {
    public init(checkout url: URL, delegate: CheckoutDelegate? = nil, options: CheckoutOptions? = nil) {
        let rootViewController = CheckoutWebViewController(checkoutURL: url, delegate: delegate, options: options)
        rootViewController.notifyPresented()
        super.init(rootViewController: rootViewController)
        presentationController?.delegate = rootViewController
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Deprecated
extension CheckoutViewController {
    @available(*, deprecated, message: "Use \"ShopifyCheckout\" instead.")
    public struct Representable: UIViewControllerRepresentable {
        @Binding var checkoutURL: URL?

        let delegate: CheckoutDelegate?

        public init(checkout url: Binding<URL?>, delegate: CheckoutDelegate? = nil) {
            _checkoutURL = url
            self.delegate = delegate
        }

        public func makeUIViewController(context _: Self.Context) -> CheckoutViewController {
            return CheckoutViewController(checkout: checkoutURL!, delegate: delegate)
        }

        public func updateUIViewController(_: CheckoutViewController, context _: Self.Context) {}
    }
}

public struct ShopifyCheckout: UIViewControllerRepresentable, CheckoutConfigurable {
    public typealias UIViewControllerType = CheckoutViewController

    var checkoutURL: URL
    var delegate = CheckoutDelegateWrapper()
    var options: CheckoutOptions = .init()

    public init(checkout url: URL) {
        checkoutURL = url

        /// Programmatic usage of the library will invalidate the cache each time the configuration changes.
        /// This should not happen in the case of SwiftUI, where the config can change each time a modifier function runs.
        ShopifyCheckoutSheetKit.invalidateOnConfigurationChange = false
    }

    public func makeUIViewController(context _: Self.Context) -> CheckoutViewController {
        return CheckoutViewController(checkout: checkoutURL, delegate: delegate, options: options)
    }

    public func updateUIViewController(_ uiViewController: CheckoutViewController, context _: Self.Context) {
        guard
            let webViewController = uiViewController
            .viewControllers
            .compactMap({ $0 as? CheckoutWebViewController })
            .first
        else {
            OSLogger.shared.debug(
                "[CheckoutViewController#updateUIViewController]: No ViewControllers matching CheckoutWebViewController \(uiViewController.viewControllers.map { String(describing: $0.self) }.joined(separator: ""))"
            )
            return
        }

        webViewController.delegate = delegate
    }

    /// Lifecycle methods

    @discardableResult public func onCancel(_ action: @escaping () -> Void) -> Self {
        delegate.onCancel = action
        return self
    }

    @discardableResult public func onStart(_ action: @escaping (CheckoutStartEvent) -> Void) -> Self {
        delegate.onStart = action
        return self
    }

    @discardableResult public func onComplete(_ action: @escaping (CheckoutCompleteEvent) -> Void) -> Self {
        delegate.onComplete = action
        return self
    }

    @discardableResult public func onFail(_ action: @escaping (CheckoutError) -> Void) -> Self {
        delegate.onFail = action
        return self
    }

    @discardableResult public func onLinkClick(_ action: @escaping (URL) -> Void) -> Self {
        delegate.onLinkClick = action
        return self
    }

    /// Called when the checkout has started an address change flow.
    ///
    /// This event is only emitted when native address selection is enabled for the authenticated app.
    /// When triggered, you can present a native address picker and respond with updated address data.
    @discardableResult public func onAddressChangeStart(_ action: @escaping (CheckoutAddressChangeStart) -> Void) -> Self {
        delegate.onAddressChangeStart = action
        return self
    }

    @discardableResult public func onPaymentMethodChangeStart(_ action: @escaping (CheckoutPaymentMethodChangeStart) -> Void) -> Self {
        delegate.onPaymentMethodChangeStart = action
        return self
    }

    /// Configuration methods

    @discardableResult public func auth(token: String?) -> Self {
        var view = self
        if let token {
            view.options.authentication = .token(token)
        } else {
            view.options.authentication = .none
        }
        return view
    }
}

public class CheckoutDelegateWrapper: CheckoutDelegate {
    var onStart: ((CheckoutStartEvent) -> Void)?
    var onComplete: ((CheckoutCompleteEvent) -> Void)?
    var onCancel: (() -> Void)?
    var onFail: ((CheckoutError) -> Void)?
    var onLinkClick: ((URL) -> Void)?
    var onAddressChangeStart: ((CheckoutAddressChangeStart) -> Void)?
    var onPaymentMethodChangeStart: ((CheckoutPaymentMethodChangeStart) -> Void)?

    public func checkoutDidStart(event: CheckoutStartEvent) {
        onStart?(event)
    }

    public func checkoutDidFail(error: CheckoutError) {
        onFail?(error)
    }

    public func checkoutDidComplete(event: CheckoutCompleteEvent) {
        onComplete?(event)
    }

    public func checkoutDidCancel() {
        onCancel?()
    }

    public func checkoutDidClickLink(url: URL) {
        if let onLinkClick {
            onLinkClick(url)
            return
        }

        /// Use fallback behavior if callback is not provided
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    public func checkoutDidStartAddressChange(event: CheckoutAddressChangeStart) {
        onAddressChangeStart?(event)
    }

    public func checkoutDidStartPaymentMethodChange(event: CheckoutPaymentMethodChangeStart) {
        onPaymentMethodChangeStart?(event)
    }
}

public protocol CheckoutConfigurable {
    func backgroundColor(_ color: UIColor) -> Self
    func colorScheme(_ colorScheme: ShopifyCheckoutSheetKit.Configuration.ColorScheme) -> Self
    func tintColor(_ color: UIColor) -> Self
    func title(_ title: String) -> Self
    func closeButtonTintColor(_ color: UIColor?) -> Self
}

extension CheckoutConfigurable {
    @discardableResult public func backgroundColor(_ color: UIColor) -> Self {
        ShopifyCheckoutSheetKit.configuration.backgroundColor = color
        return self
    }

    @discardableResult public func colorScheme(_ colorScheme: ShopifyCheckoutSheetKit.Configuration.ColorScheme) -> Self {
        ShopifyCheckoutSheetKit.configuration.colorScheme = colorScheme
        return self
    }

    @discardableResult public func tintColor(_ color: UIColor) -> Self {
        ShopifyCheckoutSheetKit.configuration.tintColor = color
        return self
    }

    @discardableResult public func title(_ title: String) -> Self {
        ShopifyCheckoutSheetKit.configuration.title = title
        return self
    }

    @discardableResult public func closeButtonTintColor(_ color: UIColor?) -> Self {
        ShopifyCheckoutSheetKit.configuration.closeButtonTintColor = color
        return self
    }
}
