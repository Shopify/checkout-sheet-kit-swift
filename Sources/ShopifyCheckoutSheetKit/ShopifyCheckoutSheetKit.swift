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

#if canImport(UIKit)
import UIKit
#endif

/// The version of the `ShopifyCheckoutSheetKit` library.
public var version: String {
    return "4.0.0"
}

var invalidateOnConfigurationChange = true

/// The configuration options for the `ShopifyCheckoutSheetKit` library.
public var configuration = Configuration() {
    didSet {
        if invalidateOnConfigurationChange {
            CheckoutWebView.invalidate()
        }
    }
}

/// A convenience function for configuring the `ShopifyCheckoutSheetKit` library.
public func configure(_ block: (inout Configuration) -> Void) {
    block(&configuration)
}

/// Configuration for partner authentication.
public struct CheckoutOptions {
    public enum AppAuthentication {
        case token(String)

        public var token: String {
            switch self {
            case let .token(tokenValue):
                return tokenValue
            }
        }
    }

    /// App authentication configuration for partner identification.
    public let appAuthentication: AppAuthentication?

    /// Initialize with app authentication configuration.
    public init(appAuthentication: AppAuthentication? = nil) {
        self.appAuthentication = appAuthentication
    }
}

/// Preloads the checkout for faster presentation.
public func preload(checkout url: URL, options: CheckoutOptions? = nil) {
    guard configuration.preloading.enabled else {
        return
    }

    CheckoutWebView.preloadingActivatedByClient = true
    let webView = CheckoutWebView.for(checkout: url)
    webView.checkoutOptions = options
    webView.load(checkout: url, isPreload: true)
}

/// Invalidate the checkout cache from preload calls
public func invalidate() {
    CheckoutWebView.invalidate(disconnect: true)
}

/// Presents the checkout from a given `UIViewController`.
@discardableResult
public func present(checkout url: URL, from: UIViewController, delegate: CheckoutDelegate? = nil, options: CheckoutOptions? = nil) -> CheckoutViewController {
    let viewController = CheckoutViewController(checkout: url, delegate: delegate, options: options)
    from.present(viewController, animated: true)
    return viewController
}

/// Shorter namespace alias for ShopifyCheckoutSheetKit functions.
public enum CheckoutKit {
    /// Presents the checkout from a given `UIViewController`.
    @discardableResult
    public static func present(checkout url: URL, from: UIViewController, delegate: CheckoutDelegate? = nil, options: CheckoutOptions? = nil) -> CheckoutViewController {
        return ShopifyCheckoutSheetKit.present(checkout: url, from: from, delegate: delegate, options: options)
    }

    /// Preloads the checkout for faster presentation.
    public static func preload(checkout url: URL, options: CheckoutOptions? = nil) {
        ShopifyCheckoutSheetKit.preload(checkout: url, options: options)
    }

    /// Invalidate the checkout cache from preload calls
    public static func invalidate() {
        ShopifyCheckoutSheetKit.invalidate()
    }
}
