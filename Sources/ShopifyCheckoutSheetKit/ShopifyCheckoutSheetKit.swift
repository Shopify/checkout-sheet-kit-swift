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

import Common
import UIKit

/// The version of the `ShopifyCheckoutSheetKit` library.
public let version = "3.2.0"

var invalidateOnConfigurationChange = true

/// The configuration options for the `ShopifyCheckoutSheetKit` library.
public var configuration = Configuration() {
    didSet {
        if invalidateOnConfigurationChange {
            CheckoutWebView.invalidate()
        }
    }
}

/// A convienence function for configuring the `ShopifyCheckoutSheetKit` library.
public func configure(_ block: (inout Configuration) -> Void) {
    block(&configuration)
}

/// Preloads the checkout for faster presentation.
public func preload(checkout url: URL) {
    guard configuration.preloading.enabled else {
        return
    }

    CheckoutWebView.preloadingActivatedByClient = true
    CheckoutWebView.for(checkout: url).load(checkout: url, isPreload: true)
}

/// Invalidate the checkout cache from preload calls
public func invalidate() {
    CheckoutWebView.invalidate(disconnect: true)
}

/// Presents the checkout from a given `UIViewController`.
@discardableResult
public func present(checkout url: URL, from: UIViewController, delegate: CheckoutDelegate? = nil) -> CheckoutViewController {
    let viewController = CheckoutViewController(checkout: url, delegate: delegate)
    from.present(viewController, animated: true)
    return viewController
}

/// Internal function that presents the checkout from a given `UIViewController` with a specified entry point.
/// This is only used by other modules such as ShopifyAcceleratedCheckouts.
/// Consumers will use the public `present` function, and the UserAgent will *not* contain the entry field.
@discardableResult
package func present(checkout url: URL, from: UIViewController, entryPoint: MetaData.EntryPoint, delegate: CheckoutDelegate? = nil) -> CheckoutViewController {
    let viewController = CheckoutViewController(checkout: url, delegate: delegate, entryPoint: entryPoint)
    from.present(viewController, animated: true)
    return viewController
}
