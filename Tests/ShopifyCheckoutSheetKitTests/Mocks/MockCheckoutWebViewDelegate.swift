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

@testable import ShopifyCheckoutSheetKit
import XCTest

class MockCheckoutWebViewDelegate: CheckoutWebViewDelegate {
    var startEventReceived: CheckoutStartEvent?

    var completedEventReceived: CheckoutCompleteEvent?

    var errorReceived: CheckoutError?

    var didStartNavigationExpectation: XCTestExpectation?

    var didFinishNavigationExpectation: XCTestExpectation?

    var didStartExpectation: XCTestExpectation?

    var didCompleteCheckoutExpectation: XCTestExpectation?

    var didClickContactLinkExpectation: XCTestExpectation?

    var didClickLinkExpectation: XCTestExpectation?

    var didFailWithErrorExpectation: XCTestExpectation?

    var didToggleModalExpectation: XCTestExpectation?

    var didEmitCheckoutCompleteEventExpectation: XCTestExpectation?

    func checkoutViewDidStartNavigation() {
        didStartNavigationExpectation?.fulfill()
    }

    func checkoutViewDidStart(event: CheckoutStartEvent) {
        startEventReceived = event
        didStartExpectation?.fulfill()
    }

    func checkoutViewDidCompleteCheckout() {
        didCompleteCheckoutExpectation?.fulfill()
    }

    func checkoutViewDidFinishNavigation() {
        didFinishNavigationExpectation?.fulfill()
    }

    func checkoutViewDidClickContactLink(url _: URL) {
        didClickContactLinkExpectation?.fulfill()
    }

    func checkoutViewDidClickLink(url _: URL) {
        didClickLinkExpectation?.fulfill()
    }

    func checkoutViewDidFailWithError(error: CheckoutError) {
        errorReceived = error
        didFailWithErrorExpectation?.fulfill()
    }

    func checkoutViewDidToggleModal(modalVisible _: Bool) {
        didToggleModalExpectation?.fulfill()
    }

    func checkoutViewDidCompleteCheckout(event: ShopifyCheckoutSheetKit.CheckoutCompleteEvent) {
        completedEventReceived = event
        didEmitCheckoutCompleteEventExpectation?.fulfill()
    }

    func checkoutViewDidStartAddressChange(event _: CheckoutAddressChangeStart) {
        // Mock implementation - could add expectations here if needed for testing
    }

    func checkoutViewDidStartPaymentMethodChange(event _: CheckoutPaymentMethodChangeStart) {
        // No-op for tests unless explicitly asserted
    }

    func checkoutViewDidStartSubmit(event _: CheckoutSubmitStart) {
        // No-op for tests unless explicitly asserted
    }
}
