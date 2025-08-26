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
    var testDelegate: TestCheckoutDelegate!

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

        testDelegate = TestCheckoutDelegate()
    }

    override func tearDown() {
        viewController = nil
        mockConfiguration = nil
        testDelegate = nil
        super.tearDown()
    }

    // MARK: - CheckoutDelegate Tests

    @MainActor
    func testCheckoutDidCancel_invokesDelegateMethod() async {
        testDelegate.reset()
        let expectation = XCTestExpectation(description: "Cancel delegate method should be invoked")
        testDelegate.expectation = expectation

        // Create view controller with delegate
        let identifier = CheckoutIdentifier.cart(cartID: "gid://Shopify/Cart/test-cart-id")
        let viewControllerWithDelegate = ApplePayViewController(
            identifier: identifier,
            configuration: mockConfiguration,
            checkoutDelegate: testDelegate
        )

        viewControllerWithDelegate.checkoutDidCancel()

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(testDelegate.cancelCallbackInvoked, "Cancel delegate method should be invoked when checkoutDidCancel is called")
    }

    @MainActor
    func testCheckoutDidComplete_invokesDelegateMethod() async {
        testDelegate.reset()
        let expectation = XCTestExpectation(description: "Complete delegate method should be invoked")
        testDelegate.expectation = expectation

        // Create view controller with delegate
        let identifier = CheckoutIdentifier.cart(cartID: "gid://Shopify/Cart/test-cart-id")
        let viewControllerWithDelegate = ApplePayViewController(
            identifier: identifier,
            configuration: mockConfiguration,
            checkoutDelegate: testDelegate
        )

        // Create a mock checkout completed event
        let completedEvent = createEmptyCheckoutCompletedEvent(id: "test-order")

        viewControllerWithDelegate.checkoutDidComplete(event: completedEvent)

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(testDelegate.completeCallbackInvoked, "Complete delegate method should be invoked when checkoutDidComplete is called")
    }

    @MainActor
    func testCheckoutDidFail_invokesDelegateMethod() async {
        testDelegate.reset()
        let expectation = XCTestExpectation(description: "Fail delegate method should be invoked")
        testDelegate.expectation = expectation

        // Create view controller with delegate
        let identifier = CheckoutIdentifier.cart(cartID: "gid://Shopify/Cart/test-cart-id")
        let viewControllerWithDelegate = ApplePayViewController(
            identifier: identifier,
            configuration: mockConfiguration,
            checkoutDelegate: testDelegate
        )

        // Create a mock checkout error
        let checkoutError = CheckoutError.configurationError(
            message: "Test error",
            code: .unknown,
            recoverable: false
        )

        viewControllerWithDelegate.checkoutDidFail(error: checkoutError)

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(testDelegate.failCallbackInvoked, "Fail delegate method should be invoked when checkoutDidFail is called")
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
