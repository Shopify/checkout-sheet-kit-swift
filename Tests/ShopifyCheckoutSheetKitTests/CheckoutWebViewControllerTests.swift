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
@testable import ShopifyCheckoutSheetKit
import WebKit
import XCTest

class CheckoutWebViewControllerTests: XCTestCase {
    private let url = URL(string: "http://shopify1.shopify.com/checkouts/cn/123")!

    func test_init_withNilEntryPoint_shouldSetCorrectUserAgent() {
        let viewController = CheckoutWebViewController(checkoutURL: url, delegate: nil, entryPoint: nil)

        let expectedUserAgent = CheckoutBridge.applicationName(entryPoint: nil)
        XCTAssertEqual(viewController.checkoutView.configuration.applicationNameForUserAgent, expectedUserAgent)
    }

    func test_init_withAcceleratedCheckoutsEntryPoint_shouldSetCorrectUserAgent() {
        let viewController = CheckoutWebViewController(checkoutURL: url, delegate: nil, entryPoint: .acceleratedCheckouts)

        let expectedUserAgent = CheckoutBridge.applicationName(entryPoint: .acceleratedCheckouts)
        XCTAssertEqual(viewController.checkoutView.configuration.applicationNameForUserAgent, expectedUserAgent)
    }
}
