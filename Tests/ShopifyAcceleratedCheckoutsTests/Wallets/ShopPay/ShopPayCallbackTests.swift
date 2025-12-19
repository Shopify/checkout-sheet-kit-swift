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
    var successExpectation: XCTestExpectation!
    var errorExpectation: XCTestExpectation!
    var cancelExpectation: XCTestExpectation!

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        mockConfiguration = ShopifyAcceleratedCheckouts.Configuration(
            storefrontDomain: "test-shop.myshopify.com",
            storefrontAccessToken: "test-token"
        )

        mockIdentifier = .cart(cartID: "gid://Shopify/Cart/test-cart-id")

        viewController = ShopPayViewController(
            identifier: mockIdentifier,
            configuration: mockConfiguration
        )
    }

    override func tearDown() {
        viewController = nil
        mockConfiguration = nil
        mockIdentifier = nil
        successExpectation = nil
        errorExpectation = nil
        cancelExpectation = nil
        super.tearDown()
    }

    // MARK: - Success Callback Tests

    @MainActor
    func testSuccessCallbackInvoked() async {
        successExpectation = expectation(description: "Success callback should be invoked")
        let callbackInvokedExpectation = expectation(description: "Callback invoked")

        await MainActor.run {
            viewController.eventHandlers = EventHandlers(
                checkoutDidComplete: { [weak self] _ in
                    callbackInvokedExpectation.fulfill()
                    self?.successExpectation.fulfill()
                }
            )

            let mockEvent = createEmptyCheckoutCompleteEvent(id: "test-order-123")
            viewController.eventHandlers.checkoutDidComplete?(mockEvent)
        }

        await fulfillment(of: [successExpectation, callbackInvokedExpectation], timeout: 1.0)
    }

    func testSuccessCallbackNotInvokedWhenNil() {
        XCTAssertNil(viewController.eventHandlers.checkoutDidComplete)

        let mockEvent = createEmptyCheckoutCompleteEvent(id: "test-order-123")
        viewController.eventHandlers.checkoutDidComplete?(mockEvent) // Should not crash

        XCTAssertTrue(true, "Should not crash when callback is nil")
    }

    // MARK: - Error Callback Tests

    @MainActor
    func testErrorCallbackInvoked() async {
        errorExpectation = expectation(description: "Error callback should be invoked")
        let callbackInvokedExpectation = expectation(description: "Error callback invoked")

        viewController.eventHandlers = EventHandlers(
            checkoutDidFail: { [weak self] _ in
                callbackInvokedExpectation.fulfill()
                self?.errorExpectation.fulfill()
            }
        )

        let mockError = CheckoutError.internal(underlying: NSError(domain: "TestError", code: 0, userInfo: nil), recoverable: false)
        viewController.eventHandlers.checkoutDidFail?(mockError)

        await fulfillment(of: [errorExpectation, callbackInvokedExpectation], timeout: 1.0)
    }

    func testErrorCallbackNotInvokedWhenNil() {
        XCTAssertNil(viewController.eventHandlers.checkoutDidFail)

        let mockError = CheckoutError.internal(underlying: NSError(domain: "TestError", code: 0, userInfo: nil), recoverable: false)
        viewController.eventHandlers.checkoutDidFail?(mockError) // Should not crash

        XCTAssertTrue(true, "Should not crash when callback is nil")
    }

    // MARK: - Cancel Callback Tests

    @MainActor
    func testCancelCallbackInvoked() async {
        cancelExpectation = expectation(description: "Cancel callback should be invoked")
        let callbackInvokedExpectation = expectation(description: "Cancel callback invoked")

        viewController.eventHandlers = EventHandlers(
            checkoutDidCancel: { [weak self] in
                callbackInvokedExpectation.fulfill()
                self?.cancelExpectation.fulfill()
            }
        )

        viewController.eventHandlers.checkoutDidCancel?()

        await fulfillment(of: [cancelExpectation, callbackInvokedExpectation], timeout: 1.0)
    }

    func testCancelCallbackNotInvokedWhenNil() {
        XCTAssertNil(viewController.eventHandlers.checkoutDidCancel)

        viewController.eventHandlers.checkoutDidCancel?() // Should not crash

        XCTAssertTrue(true, "Should not crash when callback is nil")
    }

    // MARK: - Delegate Tests

    @MainActor
    func testCheckoutCompleteCallback() {
        var completeInvoked = false
        viewController.eventHandlers = EventHandlers(
            checkoutDidComplete: { _ in completeInvoked = true }
        )

        let mockEvent = createEmptyCheckoutCompleteEvent(id: "test-order-123")
        viewController.eventHandlers.checkoutDidComplete?(mockEvent)

        XCTAssertTrue(completeInvoked, "Complete callback should be invoked")
    }

    @MainActor
    func testCheckoutFailCallback() {
        var failInvoked = false
        viewController.eventHandlers = EventHandlers(
            checkoutDidFail: { _ in failInvoked = true }
        )

        let mockError = CheckoutError.internal(underlying: NSError(domain: "TestError", code: 0, userInfo: nil), recoverable: false)
        viewController.eventHandlers.checkoutDidFail?(mockError)

        XCTAssertTrue(failInvoked, "Fail callback should be invoked")
    }

    @MainActor
    func testCheckoutCancelCallback() {
        var cancelInvoked = false
        viewController.eventHandlers = EventHandlers(
            checkoutDidCancel: { cancelInvoked = true }
        )

        viewController.eventHandlers.checkoutDidCancel?()

        XCTAssertTrue(cancelInvoked, "Cancel callback should be invoked")
    }

    @MainActor
    func testCheckoutDidCancelDelegateBehavior() {
        var cancelInvoked = false
        viewController.eventHandlers = EventHandlers(
            checkoutDidCancel: { cancelInvoked = true }
        )

        viewController.checkoutDidCancel()

        XCTAssertTrue(cancelInvoked, "Cancel callback should be invoked")
    }
}
