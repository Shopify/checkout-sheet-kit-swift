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
@testable import ShopifyCheckoutSheetKit

class CheckoutViewDelegateTests: XCTestCase {

	private let checkoutURL = URL(string: "https://checkout-sdk.myshopify.com")!
	private var viewController: CheckoutWebViewController!
	private var navigationController: UINavigationController!

	override func setUp() {
		ShopifyCheckoutSheetKit.configure {
			$0.preloading.enabled = true
		}
		viewController = CheckoutWebViewController(
			checkoutURL: checkoutURL, delegate: ExampleDelegate())

		navigationController = UINavigationController(rootViewController: viewController)
	}

	func testTitleIsSetToCheckout() {
		XCTAssertEqual(viewController.title, "Checkout")
	}

	func testCheckoutViewDidCompleteCheckoutInvalidatesViewCache() {
		let one = CheckoutWebView.for(checkout: checkoutURL)
		let two = CheckoutWebView.for(checkout: checkoutURL)
		XCTAssertEqual(one, two)

		viewController.checkoutViewDidCompleteCheckout()

		let three = CheckoutWebView.for(checkout: checkoutURL)
		XCTAssertNotEqual(two, three)
	}

	func testCheckoutViewDidFailWithErrorInvalidatesViewCache() {
		let one = CheckoutWebView.for(checkout: checkoutURL)
		let two = CheckoutWebView.for(checkout: checkoutURL)
		XCTAssertEqual(one, two)

		viewController.checkoutViewDidFailWithError(error: .checkoutUnavailable(message: "error"))

		let three = CheckoutWebView.for(checkout: checkoutURL)
		XCTAssertNotEqual(two, three)
	}

	func testFailWithErrorDisablesPreloadingActivtedByClient() {
		CheckoutWebView.preloadingActivatedByClient = true

		let one = CheckoutWebView.for(checkout: checkoutURL)

		viewController.checkoutViewDidFailWithError(error: .checkoutUnavailable(message: "error"))

		XCTAssertEqual(false, CheckoutWebView.preloadingActivatedByClient)
	}

	func testCloseInvalidatesViewCache() {
		let one = CheckoutWebView.for(checkout: checkoutURL)
		let two = CheckoutWebView.for(checkout: checkoutURL)
		XCTAssertEqual(one, two)

		viewController.close()

		let three = CheckoutWebView.for(checkout: checkoutURL)
		XCTAssertNotEqual(two, three)
	}

	func testCloseDoesNotInvalidateViewCacheWhenPreloadingISCalledByClient() {
		ShopifyCheckoutSheetKit.preload(checkout: checkoutURL)

		let one = CheckoutWebView.for(checkout: checkoutURL)
		let two = CheckoutWebView.for(checkout: checkoutURL)
		XCTAssertEqual(one, two)

		viewController.close()

		let three = CheckoutWebView.for(checkout: checkoutURL)
		XCTAssertEqual(one, three)
	}

	func testPresentationControllerDidDismissInvalidatesViewCache() {
		let one = CheckoutWebView.for(checkout: checkoutURL)
		let two = CheckoutWebView.for(checkout: checkoutURL)
		XCTAssertEqual(one, two)

		let presentationController = UIViewController().presentationController!
		viewController.presentationControllerDidDismiss(presentationController)

		let three = CheckoutWebView.for(checkout: checkoutURL)
		XCTAssertNotEqual(two, three)
	}

	func testPresentationControllerDidDismissSavesCacheWhenActivatedByClient() {
		CheckoutWebView.preloadingActivatedByClient = true
		let one = CheckoutWebView.for(checkout: checkoutURL)
		let two = CheckoutWebView.for(checkout: checkoutURL)
		XCTAssertEqual(one, two)

		let presentationController = UIViewController().presentationController!
		viewController.presentationControllerDidDismiss(presentationController)

		let three = CheckoutWebView.for(checkout: checkoutURL)
		XCTAssertEqual(one, three)
	}

	func testCheckoutViewDidClickLinkDoesNotInvalidateViewCache() {
		let one = CheckoutWebView.for(checkout: checkoutURL)
		let two = CheckoutWebView.for(checkout: checkoutURL)
		XCTAssertEqual(one, two)

		viewController.checkoutViewDidClickLink(url: URL(string: "https://shopify.com/anything")!)

		let three = CheckoutWebView.for(checkout: checkoutURL)
		XCTAssertEqual(two, three)
	}

	func testCheckoutViewDidToggleModalAddsAndRemovesNavigationBar() {
		XCTAssertFalse(viewController.navigationController!.isNavigationBarHidden)

		viewController.checkoutViewDidToggleModal(modalVisible: true)
		XCTAssertTrue(viewController.navigationController!.isNavigationBarHidden)

		viewController.checkoutViewDidToggleModal(modalVisible: false)
		XCTAssertFalse(viewController.navigationController!.isNavigationBarHidden)
	}
}
