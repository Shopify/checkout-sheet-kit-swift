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
@testable import ShopifyCheckoutSheetKit
import XCTest

@available(iOS 17.0, *)
final class ApplePayCallbackTests: XCTestCase {
    // MARK: - Properties

    var viewController: ApplePayViewController!
    var mockConfiguration: ApplePayConfigurationWrapper!
    var mockIdentifier: CheckoutIdentifier!
    var testDelegate: TestCheckoutDelegate!

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        // Create mock configuration
        let commonConfig = ShopifyAcceleratedCheckouts.Configuration(
            storefrontDomain: "test-shop.myshopify.com",
            storefrontAccessToken: "test-token"
        )

        let applePayConfig = ShopifyAcceleratedCheckouts.ApplePayConfiguration(
            merchantIdentifier: "test.merchant.id",
            contactFields: []
        )

        let shopSettings = ShopSettings(
            name: "Test Shop",
            primaryDomain: Domain(
                host: "test-shop.myshopify.com",
                url: "https://test-shop.myshopify.com"
            ),
            paymentSettings: PaymentSettings(countryCode: "US", acceptedCardBrands: [.visa, .mastercard])
        )

        mockConfiguration = ApplePayConfigurationWrapper(
            common: commonConfig,
            applePay: applePayConfig,
            shopSettings: shopSettings
        )

        mockIdentifier = .cart(cartID: "gid://Shopify/Cart/test-cart-id")

        testDelegate = TestCheckoutDelegate()
    }

    override func tearDown() {
        viewController = nil
        mockConfiguration = nil
        mockIdentifier = nil
        testDelegate = nil
        super.tearDown()
    }

    // MARK: - CheckoutDelegate Tests

    @MainActor
    func testCheckoutDidComplete_invokesDelegateMethod() async {
        let expectation = XCTestExpectation(description: "Complete delegate method should be invoked")
        testDelegate.expectation = expectation

        // Create view controller with delegate
        viewController = ApplePayViewController(
            identifier: mockIdentifier,
            configuration: mockConfiguration,
            checkoutDelegate: testDelegate
        )

        let completedEvent = createEmptyCheckoutCompletedEvent(id: "test-order")
        viewController.checkoutDidComplete(event: completedEvent)

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(testDelegate.completeCallbackInvoked, "Complete delegate method should be invoked")
    }

    @MainActor
    func testCheckoutDidFail_invokesDelegateMethod() async {
        testDelegate.reset()
        let expectation = XCTestExpectation(description: "Fail delegate method should be invoked")
        testDelegate.expectation = expectation

        viewController = ApplePayViewController(
            identifier: mockIdentifier,
            configuration: mockConfiguration,
            checkoutDelegate: testDelegate
        )

        let checkoutError = CheckoutError.sdkError(
            underlying: NSError(domain: "TestError", code: 0, userInfo: nil),
            recoverable: false
        )
        viewController.checkoutDidFail(error: checkoutError)

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(testDelegate.failCallbackInvoked, "Fail delegate method should be invoked")
    }

    @MainActor
    func testCheckoutDidCancel_invokesDelegateMethod() async {
        testDelegate.reset()
        let expectation = XCTestExpectation(description: "Cancel delegate method should be invoked")
        testDelegate.expectation = expectation

        viewController = ApplePayViewController(
            identifier: mockIdentifier,
            configuration: mockConfiguration,
            checkoutDelegate: testDelegate
        )

        viewController.checkoutDidCancel()

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(testDelegate.cancelCallbackInvoked, "Cancel delegate method should be invoked")
    }

    @MainActor
    func testCheckoutDidClickLink_invokesDelegateMethod() async {
        testDelegate.reset()
        let expectation = XCTestExpectation(description: "Link click delegate method should be invoked")
        testDelegate.expectation = expectation

        viewController = ApplePayViewController(
            identifier: mockIdentifier,
            configuration: mockConfiguration,
            checkoutDelegate: testDelegate
        )

        let testURL = URL(string: "https://test-shop.myshopify.com/products/test")!
        viewController.checkoutDidClickLink(url: testURL)

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(testDelegate.linkCallbackInvoked, "Link click delegate method should be invoked")
        XCTAssertEqual(testDelegate.receivedURL, testURL, "URL should be passed to delegate")
    }

    @MainActor
    func testCheckoutDidEmitWebPixelEvent_invokesDelegateMethod() async {
        testDelegate.reset()
        let expectation = XCTestExpectation(description: "Web pixel delegate method should be invoked")
        testDelegate.expectation = expectation

        viewController = ApplePayViewController(
            identifier: mockIdentifier,
            configuration: mockConfiguration,
            checkoutDelegate: testDelegate
        )

        let customEvent = CustomEvent(context: nil, customData: nil, id: "test-id", name: "page_viewed", timestamp: nil)
        let testEvent = PixelEvent.customEvent(customEvent)
        viewController.checkoutDidEmitWebPixelEvent(event: testEvent)

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(testDelegate.webPixelCallbackInvoked, "Web pixel delegate method should be invoked")
        // Extract name from the PixelEvent enum
        let expectedName: String?
        switch testEvent {
        case let .customEvent(customEvent):
            expectedName = customEvent.name
        case let .standardEvent(standardEvent):
            expectedName = standardEvent.name
        }

        let receivedName: String?
        if let receivedEvent = testDelegate.receivedEvent {
            switch receivedEvent {
            case let .customEvent(customEvent):
                receivedName = customEvent.name
            case let .standardEvent(standardEvent):
                receivedName = standardEvent.name
            }
        } else {
            receivedName = nil
        }

        XCTAssertEqual(receivedName, expectedName, "Event should be passed to delegate")
    }

    @MainActor
    func testShouldRecoverFromError() async {
        testDelegate.reset()
        testDelegate.recoveryDecision = false
        let expectation = XCTestExpectation(description: "Should recovery delegate method should be invoked")
        testDelegate.expectation = expectation

        viewController = ApplePayViewController(
            identifier: mockIdentifier,
            configuration: mockConfiguration,
            checkoutDelegate: testDelegate
        )

        let checkoutError = CheckoutError.sdkError(
            underlying: NSError(domain: "TestError", code: 0, userInfo: nil),
            recoverable: true
        )
        let shouldRecover = viewController.shouldRecoverFromError(error: checkoutError)

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(testDelegate.errorRecoveryAsked, "Error recovery delegate method should be invoked")
        XCTAssertFalse(shouldRecover, "Should return delegate's decision")
    }

    // MARK: - No Delegate Tests

    @MainActor
    func testDelegateMethodsWorkWithoutDelegate() async {
        // Create view controller without delegate
        viewController = ApplePayViewController(
            identifier: mockIdentifier,
            configuration: mockConfiguration
        )

        // These should not crash when called without a delegate
        let completedEvent = createEmptyCheckoutCompletedEvent(id: "test-order")
        viewController.checkoutDidComplete(event: completedEvent)

        let checkoutError = CheckoutError.sdkError(
            underlying: NSError(domain: "TestError", code: 0, userInfo: nil),
            recoverable: false
        )
        viewController.checkoutDidFail(error: checkoutError)

        viewController.checkoutDidCancel()

        let testURL = URL(string: "https://test-shop.myshopify.com")!
        viewController.checkoutDidClickLink(url: testURL)

        let customEvent = CustomEvent(context: nil, customData: nil, id: "test-id", name: "test_event", timestamp: nil)
        let testEvent = PixelEvent.customEvent(customEvent)
        viewController.checkoutDidEmitWebPixelEvent(event: testEvent)

        // Wait a moment to ensure no crash occurs
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        XCTAssertTrue(true, "Should not crash when delegate is nil")
    }

    // MARK: - Multiple Event Tests

    @MainActor
    func testMultipleEventsWithSameDelegate() async {
        testDelegate.reset()

        let completeExpectations = [XCTestExpectation(description: "Complete 1"), XCTestExpectation(description: "Complete 2")]
        let failExpectations = [XCTestExpectation(description: "Fail 1"), XCTestExpectation(description: "Fail 2")]
        let cancelExpectations = [XCTestExpectation(description: "Cancel 1"), XCTestExpectation(description: "Cancel 2")]

        testDelegate.completeExpectations = completeExpectations
        testDelegate.failExpectations = failExpectations
        testDelegate.cancelExpectations = cancelExpectations

        viewController = ApplePayViewController(
            identifier: mockIdentifier,
            configuration: mockConfiguration,
            checkoutDelegate: testDelegate
        )

        // Trigger multiple events
        for _ in 0 ..< 2 {
            let completedEvent = createEmptyCheckoutCompletedEvent(id: "test-order")
            viewController.checkoutDidComplete(event: completedEvent)

            let checkoutError = CheckoutError.sdkError(
                underlying: NSError(domain: "TestError", code: 0, userInfo: nil),
                recoverable: false
            )
            viewController.checkoutDidFail(error: checkoutError)

            viewController.checkoutDidCancel()

            let testURL = URL(string: "https://test-shop.myshopify.com")!
            viewController.checkoutDidClickLink(url: testURL)

            let customEvent = CustomEvent(context: nil, customData: nil, id: "test-id", name: "test_event", timestamp: nil)
            let testEvent = PixelEvent.customEvent(customEvent)
            viewController.checkoutDidEmitWebPixelEvent(event: testEvent)
        }

        await fulfillment(of: completeExpectations + failExpectations + cancelExpectations, timeout: 2.0)

        XCTAssertEqual(testDelegate.completeCount, 2, "Should have received 2 complete events")
        XCTAssertEqual(testDelegate.failCount, 2, "Should have received 2 fail events")
        XCTAssertEqual(testDelegate.cancelCount, 2, "Should have received 2 cancel events")
        XCTAssertEqual(testDelegate.linkCount, 2, "Should have received 2 link events")
        XCTAssertEqual(testDelegate.webPixelCount, 2, "Should have received 2 web pixel events")
    }

    // MARK: - URL Variation Tests

    @MainActor
    func testCheckoutDidClickLinkWithVariousURLs() async {
        testDelegate.reset()

        let testURLs = [
            URL(string: "https://test-shop.myshopify.com/products/test")!,
            URL(string: "https://external-site.com/page")!,
            URL(string: "mailto:test@example.com")!,
            URL(string: "tel:+1234567890")!
        ]

        let expectations = testURLs.map { _ in
            expectation(description: "URL callback")
        }

        testDelegate.expectations = expectations

        viewController = ApplePayViewController(
            identifier: mockIdentifier,
            configuration: mockConfiguration,
            checkoutDelegate: testDelegate
        )

        for url in testURLs {
            viewController.checkoutDidClickLink(url: url)
        }

        await fulfillment(of: expectations, timeout: 1.0)
        XCTAssertEqual(testDelegate.receivedURLs, testURLs, "URLs should be captured in order")
    }
}
