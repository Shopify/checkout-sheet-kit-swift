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
import UIKit

/// A delegate protocol for managing checkout lifecycle events.
public protocol CheckoutDelegate: AnyObject {
	/// Tells the delegate that the checkout successfully completed.
	func checkoutDidComplete()

	/// Tells the delegate that the checkout was cancelled by the buyer.
	func checkoutDidCancel()

	/// Tells the delegate that the checkout encoutered one or more errors.
	func checkoutDidFail(error: CheckoutError)

    /// Tells te delegate that the buyer clicked a link
	/// This includes email address or telephone number via `mailto:` or `tel:` or `http` links directed outside the application.
	func checkoutDidClickLink(url: URL)
}

extension CheckoutDelegate {
	public func checkoutDidClickLink(url: URL) {
		handleUrl(url)
	}

	public func checkoutDidFail(error: CheckoutError) throws {
		throw error
	}

	private func handleUrl(_ url: URL) {
		if UIApplication.shared.canOpenURL(url) {
			UIApplication.shared.open(url)
		}
	}
}
