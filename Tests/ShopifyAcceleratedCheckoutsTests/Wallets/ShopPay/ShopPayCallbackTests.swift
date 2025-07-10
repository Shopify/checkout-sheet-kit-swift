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

    var sut: ShopPayViewController!
    var mockConfiguration: ShopifyAcceleratedCheckouts.Configuration!
    var mockIdentifier: CheckoutIdentifier!
    var successExpectation: XCTestExpectation!
    var errorExpectation: XCTestExpectation!
    var cancelExpectation: XCTestExpectation!

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        mockConfiguration = ShopifyAcceleratedCheckouts.Configuration(
            shopDomain: "test-shop.myshopify.com",
            storefrontAccessToken: "test-token"
        )

        mockIdentifier = .cart(cartID: "gid://Shopify/Cart/test-cart-id")

        // Create SUT
        sut = ShopPayViewController(
            identifier: mockIdentifier,
            configuration: mockConfiguration
        )
    }

    override func tearDown() {
        sut = nil
        mockConfiguration = nil
        mockIdentifier = nil
        successExpectation = nil
        errorExpectation = nil
        cancelExpectation = nil
        super.tearDown()
    }

    // MARK: - Success Callback Tests

    func testSuccessCallbackInvoked() async {
        successExpectation = expectation(description: "Success callback should be invoked")
        var callbackInvoked = false

        sut.eventHandlers = EventHandlers(
            checkoutSuccessHandler: { [weak self] in
                callbackInvoked = true
                self?.successExpectation.fulfill()
            }
        )

        sut.eventHandlers.checkoutSuccessHandler?()

        await fulfillment(of: [successExpectation], timeout: 1.0)
        XCTAssertTrue(callbackInvoked, "Success callback should have been invoked")
    }

    func testSuccessCallbackNotInvokedWhenNil() {
        XCTAssertNil(sut.eventHandlers.checkoutSuccessHandler)

        sut.eventHandlers.checkoutSuccessHandler?() // Should not crash

        XCTAssertTrue(true, "Should not crash when callback is nil")
    }

    // MARK: - Error Callback Tests

    func testErrorCallbackInvoked() async {
        errorExpectation = expectation(description: "Error callback should be invoked")
        var callbackInvoked = false

        sut.eventHandlers = EventHandlers(
            checkoutErrorHandler: { [weak self] in
                callbackInvoked = true
                self?.errorExpectation.fulfill()
            }
        )

        sut.eventHandlers.checkoutErrorHandler?()

        await fulfillment(of: [errorExpectation], timeout: 1.0)
        XCTAssertTrue(callbackInvoked, "Error callback should have been invoked")
    }

    func testErrorCallbackNotInvokedWhenNil() {
        XCTAssertNil(sut.eventHandlers.checkoutErrorHandler)

        sut.eventHandlers.checkoutErrorHandler?() // Should not crash

        XCTAssertTrue(true, "Should not crash when callback is nil")
    }

    // MARK: - Cancel Callback Tests

    func testCancelCallbackInvoked() async {
        cancelExpectation = expectation(description: "Cancel callback should be invoked")
        var callbackInvoked = false

        sut.eventHandlers = EventHandlers(
            checkoutCancelHandler: { [weak self] in
                callbackInvoked = true
                self?.cancelExpectation.fulfill()
            }
        )

        sut.eventHandlers.checkoutCancelHandler?()

        await fulfillment(of: [cancelExpectation], timeout: 1.0)
        XCTAssertTrue(callbackInvoked, "Cancel callback should have been invoked")
    }

    func testCancelCallbackNotInvokedWhenNil() {
        XCTAssertNil(sut.eventHandlers.checkoutCancelHandler)

        sut.eventHandlers.checkoutCancelHandler?() // Should not crash

        XCTAssertTrue(true, "Should not crash when callback is nil")
    }

    // MARK: - Delegate Tests

    func testCheckoutCompleteCallback() {
        var completeInvoked = false
        sut.eventHandlers = EventHandlers(
            checkoutSuccessHandler: { completeInvoked = true }
        )

        sut.eventHandlers.checkoutSuccessHandler?()

        XCTAssertTrue(completeInvoked, "Complete callback should be invoked")
    }

    func testCheckoutFailCallback() {
        var failInvoked = false
        sut.eventHandlers = EventHandlers(
            checkoutErrorHandler: { failInvoked = true }
        )

        sut.eventHandlers.checkoutErrorHandler?()

        XCTAssertTrue(failInvoked, "Fail callback should be invoked")
    }

    func testCheckoutCancelCallback() {
        var cancelInvoked = false
        sut.eventHandlers = EventHandlers(
            checkoutCancelHandler: { cancelInvoked = true }
        )

        sut.eventHandlers.checkoutCancelHandler?()

        XCTAssertTrue(cancelInvoked, "Cancel callback should be invoked")
    }

    func testCheckoutDidCancelDelegateBehavior() {
        var cancelInvoked = false
        sut.eventHandlers = EventHandlers(
            checkoutCancelHandler: { cancelInvoked = true }
        )

        sut.checkoutDidCancel()

        XCTAssertTrue(cancelInvoked, "Cancel callback should be invoked")
    }
}
