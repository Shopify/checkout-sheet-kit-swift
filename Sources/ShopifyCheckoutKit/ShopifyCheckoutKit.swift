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

import UIKit
import SwiftUI

/// The version of the `ShopifyCheckoutKit` library.
public let version = "0.7.0"

/// The configuration options for the `ShopifyCheckoutKit` library.
public var configuration = Configuration() {
	didSet {
		CheckoutView.invalidate()
	}
}

/// A convienence function for configuring the `ShopifyCheckoutKit` library.
public func configure(_ block: (inout Configuration) -> Void) {
	block(&configuration)
}

/// Preloads the checkout for faster presentation.
public func preload(checkout url: URL) {
	guard configuration.preloading.enabled else { return }
	CheckoutView.for(checkout: url).load(checkout: url)
}

/// Presents the checkout from a given `UIViewController`.
public func present(checkout url: URL, from: UIViewController, delegate: CheckoutDelegate? = nil) {
	let rootViewController = CheckoutViewController(checkoutURL: url, delegate: delegate)
	let view = UIHostingController(rootView: presentSwiftUI(checkout: url, delegate: delegate))
	from.present(view, animated: true)
}

public func presentSwiftUI(checkout url: URL, delegate: CheckoutDelegate? = nil) -> CheckoutViewControllerRepresentable {
	return CheckoutViewControllerRepresentable(url: url, delegate: delegate)
}

