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

/// Event handlers for checkout lifecycle events
public struct EventHandlers {
    public var checkoutDidComplete: ((CheckoutCompletedEvent) -> Void)?
    public var checkoutDidFail: ((CheckoutError) -> Void)?
    public var checkoutDidCancel: (() -> Void)?
    public var shouldRecoverFromError: ((CheckoutError) -> Bool)?
    public var checkoutDidClickLink: ((URL) -> Void)?
    public var checkoutDidEmitWebPixelEvent: ((PixelEvent) -> Void)?

    public init(
        checkoutDidComplete: ((CheckoutCompletedEvent) -> Void)? = nil,
        checkoutDidFail: ((CheckoutError) -> Void)? = nil,
        checkoutDidCancel: (() -> Void)? = nil,
        shouldRecoverFromError: ((CheckoutError) -> Bool)? = nil,
        checkoutDidClickLink: ((URL) -> Void)? = nil,
        checkoutDidEmitWebPixelEvent: ((PixelEvent) -> Void)? = nil
    ) {
        self.checkoutDidComplete = checkoutDidComplete
        self.checkoutDidFail = checkoutDidFail
        self.checkoutDidCancel = checkoutDidCancel
        self.shouldRecoverFromError = shouldRecoverFromError
        self.checkoutDidClickLink = checkoutDidClickLink
        self.checkoutDidEmitWebPixelEvent = checkoutDidEmitWebPixelEvent
    }
}

public class CheckoutViewController: UINavigationController {
    public init(checkout url: URL, delegate: CheckoutDelegate? = nil) {
        let rootViewController = CheckoutWebViewController(checkoutURL: url, delegate: delegate)
        rootViewController.notifyPresented()
        super.init(rootViewController: rootViewController)
        presentationController?.delegate = rootViewController
    }

    init(checkout url: URL, eventHandlers: EventHandlers) {
        let rootViewController = CheckoutWebViewController(checkoutURL: url, eventHandlers: eventHandlers)
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
    @available(*, deprecated, message: "Use \"CheckoutSheet\" instead.")
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

public struct CheckoutSheet: UIViewControllerRepresentable, CheckoutConfigurable {
    public typealias UIViewControllerType = CheckoutViewController

    var checkoutURL: URL
    var eventHandlers = EventHandlers()

    public init(checkout url: URL) {
        checkoutURL = url

        /// Programatic usage of the library will invalidate the cache each time the configuration changes.
        /// This should not happen in the case of SwiftUI, where the config can change each time a modifier function runs.
        ShopifyCheckoutSheetKit.invalidateOnConfigurationChange = false
    }

    public func makeUIViewController(context _: Self.Context) -> CheckoutViewController {
        return CheckoutViewController(checkout: checkoutURL, eventHandlers: eventHandlers)
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

        webViewController.updateEventHandlers(eventHandlers)
    }

    /// Lifecycle methods

    @discardableResult public func onCancel(_ action: @escaping () -> Void) -> Self {
        var newView = self
        newView.eventHandlers.checkoutDidCancel = action
        return newView
    }

    @discardableResult public func onComplete(_ action: @escaping (CheckoutCompletedEvent) -> Void) -> Self {
        var newView = self
        newView.eventHandlers.checkoutDidComplete = action
        return newView
    }

    @discardableResult public func onFail(_ action: @escaping (CheckoutError) -> Void) -> Self {
        var newView = self
        newView.eventHandlers.checkoutDidFail = action
        return newView
    }

    @discardableResult public func onPixelEvent(_ action: @escaping (PixelEvent) -> Void) -> Self {
        var newView = self
        newView.eventHandlers.checkoutDidEmitWebPixelEvent = action
        return newView
    }

    @discardableResult public func onLinkClick(_ action: @escaping (URL) -> Void) -> Self {
        var newView = self
        newView.eventHandlers.checkoutDidClickLink = action
        return newView
    }

    @discardableResult public func onShouldRecoverFromError(_ action: @escaping (CheckoutError) -> Bool) -> Self {
        var newView = self
        newView.eventHandlers.shouldRecoverFromError = action
        return newView
    }
}

public class CheckoutDelegateWrapper: CheckoutDelegate {
    var eventHandlers: EventHandlers

    init(eventHandlers: EventHandlers = EventHandlers()) {
        self.eventHandlers = eventHandlers
    }

    public func checkoutDidFail(error: CheckoutError) {
        eventHandlers.checkoutDidFail?(error)
    }

    public func checkoutDidEmitWebPixelEvent(event: PixelEvent) {
        eventHandlers.checkoutDidEmitWebPixelEvent?(event)
    }

    public func checkoutDidComplete(event: CheckoutCompletedEvent) {
        eventHandlers.checkoutDidComplete?(event)
    }

    public func checkoutDidCancel() {
        eventHandlers.checkoutDidCancel?()
    }

    public func checkoutDidClickLink(url: URL) {
        if let onLinkClick = eventHandlers.checkoutDidClickLink {
            onLinkClick(url)
            return
        }

        /// Use fallback behavior if callback is not provided
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    public func shouldRecoverFromError(error: CheckoutError) -> Bool {
        return eventHandlers.shouldRecoverFromError?(error) ?? error.isRecoverable
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
