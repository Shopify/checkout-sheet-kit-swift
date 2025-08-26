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
final class ShopPayCallbackTests: XCTestCase {
    // MARK: - Properties

    var viewController: ShopPayViewController!
    var mockConfiguration: ShopifyAcceleratedCheckouts.Configuration!
    var mockIdentifier: CheckoutIdentifier!
    var testDelegate: TestCheckoutDelegate!

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        mockConfiguration = ShopifyAcceleratedCheckouts.Configuration(
            storefrontDomain: "test-shop.myshopify.com",
            storefrontAccessToken: "test-token"
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

    // MARK: - EventHandlers Tests (Valid Properties Only)

    @MainActor
    func testEventHandlers_ValidationDidFailInvoked() async {
        let validationExpectation = expectation(description: "Validation callback should be invoked")

        let eventHandlers = EventHandlers(
            validationDidFail: { _ in
                validationExpectation.fulfill()
            }
        )

        viewController = ShopPayViewController(
            identifier: mockIdentifier,
            configuration: mockConfiguration,
            eventHandlers: eventHandlers
        )

        let userError = ValidationError.UserError(message: "Test error", field: nil, code: nil)
        let mockValidationError = AcceleratedCheckoutError.validation(ValidationError(userErrors: [userError]))
        viewController.eventHandlers.validationDidFail?(mockValidationError)

        await fulfillment(of: [validationExpectation], timeout: 1.0)
    }

    func testEventHandlers_ValidationDidFailNotInvokedWhenNil() {
        viewController = ShopPayViewController(
            identifier: mockIdentifier,
            configuration: mockConfiguration
        )

        XCTAssertNil(viewController.eventHandlers.validationDidFail)

        let userError = ValidationError.UserError(message: "Test error", field: nil, code: nil)
        let mockValidationError = AcceleratedCheckoutError.validation(ValidationError(userErrors: [userError]))
        viewController.eventHandlers.validationDidFail?(mockValidationError) // Should not crash

        XCTAssertTrue(true, "Should not crash when callback is nil")
    }

    @MainActor
    func testEventHandlers_RenderStateDidChangeInvoked() async {
        let renderStateExpectation = expectation(description: "Render state callback should be invoked")

        let eventHandlers = EventHandlers(
            renderStateDidChange: { _ in
                renderStateExpectation.fulfill()
            }
        )

        viewController = ShopPayViewController(
            identifier: mockIdentifier,
            configuration: mockConfiguration,
            eventHandlers: eventHandlers
        )

        viewController.eventHandlers.renderStateDidChange?(.rendered)

        await fulfillment(of: [renderStateExpectation], timeout: 1.0)
    }

    func testEventHandlers_RenderStateDidChangeNotInvokedWhenNil() {
        viewController = ShopPayViewController(
            identifier: mockIdentifier,
            configuration: mockConfiguration
        )

        XCTAssertNil(viewController.eventHandlers.renderStateDidChange)

        viewController.eventHandlers.renderStateDidChange?(.rendered) // Should not crash

        XCTAssertTrue(true, "Should not crash when callback is nil")
    }

    // MARK: - CheckoutDelegate Tests

    @MainActor
    func testCheckoutDelegate_CheckoutDidCompleteInvoked() async {
        testDelegate.reset()
        let expectation = XCTestExpectation(description: "Complete delegate method should be invoked")
        testDelegate.expectation = expectation

        viewController = ShopPayViewController(
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
    func testCheckoutDelegate_CheckoutDidFailInvoked() async {
        testDelegate.reset()
        let expectation = XCTestExpectation(description: "Fail delegate method should be invoked")
        testDelegate.expectation = expectation

        viewController = ShopPayViewController(
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
    func testCheckoutDelegate_CheckoutDidCancelInvoked() async {
        testDelegate.reset()
        let expectation = XCTestExpectation(description: "Cancel delegate method should be invoked")
        testDelegate.expectation = expectation

        viewController = ShopPayViewController(
            identifier: mockIdentifier,
            configuration: mockConfiguration,
            checkoutDelegate: testDelegate
        )

        viewController.checkoutDidCancel()

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(testDelegate.cancelCallbackInvoked, "Cancel delegate method should be invoked")
    }

    @MainActor
    func testCheckoutDelegate_CheckoutDidClickLinkInvoked() async {
        testDelegate.reset()
        let expectation = XCTestExpectation(description: "Link click delegate method should be invoked")
        testDelegate.expectation = expectation

        viewController = ShopPayViewController(
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
    func testCheckoutDelegate_CheckoutDidEmitWebPixelEventInvoked() async {
        testDelegate.reset()
        let expectation = XCTestExpectation(description: "Web pixel delegate method should be invoked")
        testDelegate.expectation = expectation

        viewController = ShopPayViewController(
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
    func testCheckoutDelegate_ShouldRecoverFromErrorInvoked() async {
        testDelegate.reset()
        let expectation = XCTestExpectation(description: "shouldRecoverFromError delegate method should be invoked")
        testDelegate.expectation = expectation
        testDelegate.recoveryDecision = true

        viewController = ShopPayViewController(
            identifier: mockIdentifier,
            configuration: mockConfiguration,
            checkoutDelegate: testDelegate
        )

        let testError = CheckoutError.checkoutUnavailable(
            message: "Test error",
            code: .clientError(code: .unknown),
            recoverable: true
        )
        let result = viewController.shouldRecoverFromError(error: testError)

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(testDelegate.errorRecoveryAsked, "shouldRecoverFromError delegate method should be invoked")
        XCTAssertTrue(result, "Should return true as specified by delegate")
    }

    // MARK: - No Delegate/EventHandler Tests

    @MainActor
    func testCheckoutDelegate_NoDelegate() async {
        // Create view controller without delegate
        viewController = ShopPayViewController(
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

        let shouldRecoverResult = viewController.shouldRecoverFromError(error: checkoutError)
        XCTAssertFalse(shouldRecoverResult, "Should return false when no delegate is present")

        // Wait a moment to ensure no crash occurs
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        XCTAssertTrue(true, "Should not crash when delegate is nil")
    }

    // MARK: - Combined EventHandlers and CheckoutDelegate Tests

    @MainActor
    func testBothEventHandlersAndCheckoutDelegateTogether() async {
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

        var eventHandlerInvoked = false
        let eventHandlers = EventHandlers(
            validationDidFail: { _ in
                eventHandlerInvoked = true
            }
        )

        let expectation = XCTestExpectation(description: "Delegate should be invoked")
        let delegate = TestDelegate(expectation: expectation)

        viewController = ShopPayViewController(
            identifier: mockIdentifier,
            configuration: mockConfiguration,
            eventHandlers: eventHandlers,
            checkoutDelegate: delegate
        )

        // Trigger via EventHandlers (using actual supported property)
        let userError = ValidationError.UserError(message: "Test error", field: nil, code: nil)
        let mockValidationError = AcceleratedCheckoutError.validation(ValidationError(userErrors: [userError]))
        viewController.eventHandlers.validationDidFail?(mockValidationError)
        XCTAssertTrue(eventHandlerInvoked, "EventHandler should be invoked")

        // Trigger via CheckoutDelegate
        let completedEvent = createEmptyCheckoutCompletedEvent(id: "test-order")
        viewController.checkoutDidComplete(event: completedEvent)
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(delegate.completeCallbackInvoked, "Delegate should be invoked")
    }

    // MARK: - Legacy EventHandlers Tests (using valid properties only)

    @MainActor
    func testLegacy_ValidationFailCallback() {
        var validationInvoked = false
        let eventHandlers = EventHandlers(
            validationDidFail: { _ in validationInvoked = true }
        )

        viewController = ShopPayViewController(
            identifier: mockIdentifier,
            configuration: mockConfiguration,
            eventHandlers: eventHandlers
        )

        let userError = ValidationError.UserError(message: "Test error", field: nil, code: nil)
        let mockValidationError = AcceleratedCheckoutError.validation(ValidationError(userErrors: [userError]))
        viewController.eventHandlers.validationDidFail?(mockValidationError)

        XCTAssertTrue(validationInvoked, "Validation fail callback should be invoked")
    }

    @MainActor
    func testLegacy_RenderStateChangeCallback() {
        var renderStateChanged = false
        let eventHandlers = EventHandlers(
            renderStateDidChange: { _ in renderStateChanged = true }
        )

        viewController = ShopPayViewController(
            identifier: mockIdentifier,
            configuration: mockConfiguration,
            eventHandlers: eventHandlers
        )

        viewController.eventHandlers.renderStateDidChange?(.rendered)

        XCTAssertTrue(renderStateChanged, "Render state change callback should be invoked")
    }

    @MainActor
    func testLegacy_EventHandlersIndependentFromDelegateBehavior() {
        var validationInvoked = false
        let eventHandlers = EventHandlers(
            validationDidFail: { _ in validationInvoked = true }
        )

        viewController = ShopPayViewController(
            identifier: mockIdentifier,
            configuration: mockConfiguration,
            eventHandlers: eventHandlers
        )

        // Trigger CheckoutDelegate method - should not affect EventHandlers
        viewController.checkoutDidCancel()

        // EventHandlers should remain unaffected
        XCTAssertFalse(validationInvoked, "EventHandlers should not be invoked by delegate methods")
    }
}
