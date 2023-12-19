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
@testable import ShopifyCheckoutKit

class CheckoutWebViewTests: XCTestCase {
	private var view: CheckoutWebView!
	private var mockDelegate: MockCheckoutWebViewDelegate!

	override func setUp() {
		view = CheckoutWebView.for(checkout: URL(string: "http://shopify1.shopify.com/checkouts/cn/123")!)
        mockDelegate = MockCheckoutWebViewDelegate()
        view.viewDelegate = mockDelegate
	}

	func testEmailContactLinkDelegation() {
		let link = URL(string: "mailto:contact@shopify.com")!

		let delegate = MockCheckoutWebViewDelegate()
		let didClickLinkExpectation = expectation(
			description: "checkoutViewDidClickLink was called"
		)
		delegate.didClickLinkExpectation = didClickLinkExpectation
		view.viewDelegate = delegate

		view.webView(view, decidePolicyFor: MockNavigationAction(url: link)) { policy in
			XCTAssertEqual(policy, .cancel)
		}

		wait(for: [didClickLinkExpectation], timeout: 1)
	}

	func testPhoneContactLinkDelegation() {
		let link = URL(string: "tel:1234567890")!

		let delegate = MockCheckoutWebViewDelegate()
		let didClickLinkExpectation = expectation(
			description: "checkoutViewDidClickLink was called"
		)
		delegate.didClickLinkExpectation = didClickLinkExpectation
		view.viewDelegate = delegate

		view.webView(view, decidePolicyFor: MockNavigationAction(url: link)) { policy in
			XCTAssertEqual(policy, .cancel)
		}

		wait(for: [didClickLinkExpectation], timeout: 1)
	}

	func testURLLinkDelegation() {
		let link = URL(string: "https://www.shopify.com/legal/privacy/app-users")!

		let delegate = MockCheckoutWebViewDelegate()
		let didClickLinkExpectation = expectation(
			description: "checkoutViewDidClickLink was called"
		)
		delegate.didClickLinkExpectation = didClickLinkExpectation
		view.viewDelegate = delegate

		view.webView(view, decidePolicyFor: MockExternalNavigationAction(url: link)) { policy in
			XCTAssertEqual(policy, .cancel)
		}

		wait(for: [didClickLinkExpectation], timeout: 1)
	}

	func testURLLinkDelegationWithExternalParam() {
		let link = URL(string: "https://www.shopify.com/legal/privacy/app-users?open_externally=true")!

		let delegate = MockCheckoutWebViewDelegate()
		let didClickLinkExpectation = expectation(
			description: "checkoutViewDidClickLink was called"
		)
		delegate.didClickLinkExpectation = didClickLinkExpectation
		view.viewDelegate = delegate

		view.webView(view, decidePolicyFor: MockExternalNavigationAction(url: link, navigationType: .other)) { policy in
			XCTAssertEqual(policy, .cancel)
		}

		wait(for: [didClickLinkExpectation], timeout: 1)
	}

    func test410responseOnCheckoutURLCodeDelegation() {
		view.load(checkout: URL(string: "http://shopify1.shopify.com/checkouts/cn/123")!)
		let link = view.url!
        let didFailWithErrorExpectation = expectation(description: "checkoutViewDidFailWithError was called")

        mockDelegate.didFailWithErrorExpectation = didFailWithErrorExpectation
        view.viewDelegate = mockDelegate

		let urlResponse = HTTPURLResponse(url: link, statusCode: 410, httpVersion: nil, headerFields: nil)!

        let policy = view.handleResponse(urlResponse)
        XCTAssertEqual(policy, .cancel)

        waitForExpectations(timeout: 5, handler: nil)
    }

	func testNormalresponseOnNonCheckoutURLCodeDelegation() {
		let link = URL(string: "http://shopify.com/resource_url")!
        let didFailWithErrorExpectation = expectation(description: "checkoutViewDidFailWithError was not called")
		didFailWithErrorExpectation.isInverted = true

        mockDelegate.didFailWithErrorExpectation = didFailWithErrorExpectation
        view.viewDelegate = mockDelegate

        let urlResponse = HTTPURLResponse(url: link, statusCode: 410, httpVersion: nil, headerFields: nil)!

        let policy = view.handleResponse(urlResponse)
		XCTAssertEqual(policy, .allow)

		waitForExpectations(timeout: 0.5, handler: nil)
    }

	func testEmitsPresentedMessageWhenPresentedAndFinishedLoading() {
		let testCheckoutView = TestCheckoutWebView()
		testCheckoutView.expectedScript = """
		if (window.MobileCheckoutSdk && window.MobileCheckoutSdk.dispatchMessage) {
			window.MobileCheckoutSdk.dispatchMessage('presented');
		} else {
			window.addEventListener('mobileCheckoutBridgeReady', function () {
				window.MobileCheckoutSdk.dispatchMessage('presented');
			}, {passive: true, once: true});
		}
		"""
		let evaluateJavaScriptExpectation = expectation(
			description: "evaluateJavaScript was called"
		)
		testCheckoutView.evaluateJavaScriptExpectation = evaluateJavaScriptExpectation

		testCheckoutView.checkoutDidPresent = true
		testCheckoutView.checkoutDidLoad = true

		wait(for: [evaluateJavaScriptExpectation], timeout: 1)
	}
}

class TestCheckoutWebView: CheckoutWebView {
	var expectedScript = ""

	var evaluateJavaScriptExpectation: XCTestExpectation?

	override func evaluateJavaScript(_ javaScriptString: String) async throws -> Any {
		if javaScriptString == expectedScript {
			evaluateJavaScriptExpectation?.fulfill()
		}
		return true
	}
}
