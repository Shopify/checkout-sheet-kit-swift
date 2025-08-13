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

@testable import ShopifyAcceleratedCheckouts
import ShopifyCheckoutSheetKit
import UIKit
import XCTest

@available(iOS 17.0, *)
class ApplePayViewControllerTests: XCTestCase {
    var viewController: ApplePayViewController!
    var mockConfiguration: ApplePayConfigurationWrapper!

    override func setUp() {
        super.setUp()

        // Create mock shop settings
        let paymentSettings = PaymentSettings(countryCode: "US", acceptedCardBrands: [.visa, .mastercard])
        let primaryDomain = Domain(host: "test-shop.myshopify.com", url: "https://test-shop.myshopify.com")
        let shopSettings = ShopSettings(
            name: "Test Shop",
            primaryDomain: primaryDomain,
            paymentSettings: paymentSettings
        )

        // Create common configuration
        let commonConfig = ShopifyAcceleratedCheckouts.Configuration(
            storefrontDomain: "test-shop.myshopify.com",
            storefrontAccessToken: "test-token"
        )

        // Create Apple Pay configuration
        let applePayConfig = ShopifyAcceleratedCheckouts.ApplePayConfiguration(
            merchantIdentifier: "test.merchant",
            contactFields: []
        )

        // Create configuration wrapper
        mockConfiguration = ApplePayConfigurationWrapper(
            common: commonConfig,
            applePay: applePayConfig,
            shopSettings: shopSettings
        )

        // Create system under test
        let identifier = CheckoutIdentifier.cart(cartID: "gid://Shopify/Cart/test-cart-id")
        viewController = ApplePayViewController(
            identifier: identifier,
            configuration: mockConfiguration
        )
    }

    override func tearDown() {
        viewController = nil
        mockConfiguration = nil
        super.tearDown()
    }

    // MARK: - CheckoutDelegate Tests

    @MainActor
    func testCheckoutDidCancel_invokesDelegateMethod() async {
        class TestDelegate: CheckoutDelegate {
            var cancelCallbackInvoked = false
            let expectation: XCTestExpectation

            init(expectation: XCTestExpectation) {
                self.expectation = expectation
            }

            func checkoutDidComplete(event _: CheckoutCompletedEvent) {}
            func checkoutDidFail(error _: CheckoutError) {}
            func checkoutDidClickLink(url _: URL) {}
            func checkoutDidEmitWebPixelEvent(event _: PixelEvent) {}

            func checkoutDidCancel() {
                cancelCallbackInvoked = true
                expectation.fulfill()
            }
        }

        let expectation = XCTestExpectation(description: "Cancel delegate method should be invoked")
        let delegate = TestDelegate(expectation: expectation)

        // Create view controller with delegate
        let identifier = CheckoutIdentifier.cart(cartID: "gid://Shopify/Cart/test-cart-id")
        let viewControllerWithDelegate = ApplePayViewController(
            identifier: identifier,
            configuration: mockConfiguration,
            checkoutDelegate: delegate
        )

        viewControllerWithDelegate.checkoutDidCancel()

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(delegate.cancelCallbackInvoked, "Cancel delegate method should be invoked when checkoutDidCancel is called")
    }

    @MainActor
    func testCheckoutDidComplete_invokesDelegateMethod() async {
        class TestDelegate: CheckoutDelegate {
            var completeCallbackInvoked = false
            let expectation: XCTestExpectation

            init(expectation: XCTestExpectation) {
                self.expectation = expectation
            }

            func checkoutDidComplete(event _: CheckoutCompletedEvent) {
                completeCallbackInvoked = true
                expectation.fulfill()
            }

            func checkoutDidFail(error _: CheckoutError) {}
            func checkoutDidCancel() {}
            func checkoutDidClickLink(url _: URL) {}
            func checkoutDidEmitWebPixelEvent(event _: PixelEvent) {}
        }

        let expectation = XCTestExpectation(description: "Complete delegate method should be invoked")
        let delegate = TestDelegate(expectation: expectation)

        // Create view controller with delegate
        let identifier = CheckoutIdentifier.cart(cartID: "gid://Shopify/Cart/test-cart-id")
        let viewControllerWithDelegate = ApplePayViewController(
            identifier: identifier,
            configuration: mockConfiguration,
            checkoutDelegate: delegate
        )

        // Create a mock checkout completed event
        let completedEvent = createEmptyCheckoutCompletedEvent(id: "test-order")

        viewControllerWithDelegate.checkoutDidComplete(event: completedEvent)

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(delegate.completeCallbackInvoked, "Complete delegate method should be invoked when checkoutDidComplete is called")
    }

    @MainActor
    func testCheckoutDidFail_invokesDelegateMethod() async {
        class TestDelegate: CheckoutDelegate {
            var failCallbackInvoked = false
            let expectation: XCTestExpectation

            init(expectation: XCTestExpectation) {
                self.expectation = expectation
            }

            func checkoutDidComplete(event _: CheckoutCompletedEvent) {}

            func checkoutDidFail(error _: CheckoutError) {
                failCallbackInvoked = true
                expectation.fulfill()
            }

            func checkoutDidCancel() {}
            func checkoutDidClickLink(url _: URL) {}
            func checkoutDidEmitWebPixelEvent(event _: PixelEvent) {}
        }

        let expectation = XCTestExpectation(description: "Fail delegate method should be invoked")
        let delegate = TestDelegate(expectation: expectation)

        // Create view controller with delegate
        let identifier = CheckoutIdentifier.cart(cartID: "gid://Shopify/Cart/test-cart-id")
        let viewControllerWithDelegate = ApplePayViewController(
            identifier: identifier,
            configuration: mockConfiguration,
            checkoutDelegate: delegate
        )

        // Create a mock checkout error
        let checkoutError = CheckoutError.configurationError(
            message: "Test error",
            code: .unknown,
            recoverable: false
        )

        viewControllerWithDelegate.checkoutDidFail(error: checkoutError)

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(delegate.failCallbackInvoked, "Fail delegate method should be invoked when checkoutDidFail is called")
    }

    func testCheckoutDidCancel_worksWithoutDelegate() async {
        // Test that checkoutDidCancel works without a delegate (should not crash)
        await MainActor.run {
            viewController.checkoutDidCancel()
        }
        // If we get here without crashing, the test passes
        XCTAssertTrue(true, "checkoutDidCancel should work without a delegate")
    }
}
