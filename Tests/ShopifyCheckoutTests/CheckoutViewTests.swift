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

import XCTest
import WebKit
@testable import ShopifyCheckout

class CheckoutViewTests: XCTestCase {
	private var view: CheckoutView!

	override func setUp() {
		view = CheckoutView()
	}

	func testEmailContactLinkDelegation() {
		let link = URL(string: "mailto:contact@shopify.com")!

		let delegate = MockCheckoutViewDelegate()
		let didClickContactLinkExpectation = expectation(
			description: "checkoutViewDidClickContactLink was called"
		)
		delegate.didClickContactLinkExpectation = didClickContactLinkExpectation
		view.delegate = delegate

		view.webView(view, decidePolicyFor: MockNavigationAction(url: link)) { policy in
			XCTAssertEqual(policy, .cancel)
		}

		wait(for: [didClickContactLinkExpectation], timeout: 1)
	}

	func testPhoneContactLinkDelegation() {
		let link = URL(string: "tel:1234567890")!

		let delegate = MockCheckoutViewDelegate()
		let didClickContactLinkExpectation = expectation(
			description: "checkoutViewDidClickContactLink was called"
		)
		delegate.didClickContactLinkExpectation = didClickContactLinkExpectation
		view.delegate = delegate

		view.webView(view, decidePolicyFor: MockNavigationAction(url: link)) { policy in
			XCTAssertEqual(policy, .cancel)
		}

		wait(for: [didClickContactLinkExpectation], timeout: 1)
	}

	func testURLLinkDelegation() {
		let link = URL(string: "https://www.shopify.com/legal/privacy/app-users")!

		let delegate = MockCheckoutViewDelegate()
		let didClickLinkExpectation = expectation(
			description: "checkoutViewDidClickLink was called"
		)
		delegate.didClickLinkExpectation = didClickLinkExpectation
		view.delegate = delegate

		view.webView(view, decidePolicyFor: MockExternalNavigationAction(url: link)) { policy in
			XCTAssertEqual(policy, .cancel)
		}

		wait(for: [didClickLinkExpectation], timeout: 1)
	}
}
