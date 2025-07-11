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
        var callbackInvoked = false

        viewController.eventHandlers = EventHandlers(
            checkoutDidComplete: { [weak self] in
                callbackInvoked = true
                self?.successExpectation.fulfill()
            }
        )

        viewController.eventHandlers.checkoutDidComplete?()

        await fulfillment(of: [successExpectation], timeout: 1.0)
        XCTAssertTrue(callbackInvoked, "Success callback should have been invoked")
    }

    func testSuccessCallbackNotInvokedWhenNil() {
        XCTAssertNil(viewController.eventHandlers.checkoutDidComplete)

        viewController.eventHandlers.checkoutDidComplete?() // Should not crash

        XCTAssertTrue(true, "Should not crash when callback is nil")
    }

    // MARK: - Error Callback Tests

    @MainActor
    func testErrorCallbackInvoked() async {
        errorExpectation = expectation(description: "Error callback should be invoked")
        var callbackInvoked = false

        viewController.eventHandlers = EventHandlers(
            checkoutDidFail: { [weak self] in
                callbackInvoked = true
                self?.errorExpectation.fulfill()
            }
        )

        viewController.eventHandlers.checkoutDidFail?()

        await fulfillment(of: [errorExpectation], timeout: 1.0)
        XCTAssertTrue(callbackInvoked, "Error callback should have been invoked")
    }

    func testErrorCallbackNotInvokedWhenNil() {
        XCTAssertNil(viewController.eventHandlers.checkoutDidFail)

        viewController.eventHandlers.checkoutDidFail?() // Should not crash

        XCTAssertTrue(true, "Should not crash when callback is nil")
    }

    // MARK: - Cancel Callback Tests

    @MainActor
    func testCancelCallbackInvoked() async {
        cancelExpectation = expectation(description: "Cancel callback should be invoked")
        var callbackInvoked = false

        viewController.eventHandlers = EventHandlers(
            checkoutDidCancel: { [weak self] in
                callbackInvoked = true
                self?.cancelExpectation.fulfill()
            }
        )

        viewController.eventHandlers.checkoutDidCancel?()

        await fulfillment(of: [cancelExpectation], timeout: 1.0)
        XCTAssertTrue(callbackInvoked, "Cancel callback should have been invoked")
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
            checkoutDidComplete: { completeInvoked = true }
        )

        viewController.eventHandlers.checkoutDidComplete?()

        XCTAssertTrue(completeInvoked, "Complete callback should be invoked")
    }

    @MainActor
    func testCheckoutFailCallback() {
        var failInvoked = false
        viewController.eventHandlers = EventHandlers(
            checkoutDidFail: { failInvoked = true }
        )

        viewController.eventHandlers.checkoutDidFail?()

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
