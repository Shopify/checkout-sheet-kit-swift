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

class CheckoutViewControllerTests: XCTestCase {
    var checkoutURL: URL!
    var delegate: CheckoutDelegateWrapper!
    var checkoutViewController: CheckoutViewController!

    override func setUp() {
        super.setUp()
        checkoutURL = URL(string: "https://www.shopify.com")
        delegate = CheckoutDelegateWrapper()
        checkoutViewController = CheckoutViewController(checkout: checkoutURL, delegate: delegate)
    }

    func testInit() {
        XCTAssertNotNil(checkoutViewController)
    }

    func testNavigationBarHiddenDefaultsToFalse() {
        let viewController = CheckoutViewController(checkout: checkoutURL)
        XCTAssertFalse(viewController.isNavigationBarHidden)
    }

    func testNavigationBarHiddenTrue() {
        let viewController = CheckoutViewController(checkout: checkoutURL)
        viewController.isNavigationBarHidden = true
        XCTAssertTrue(viewController.isNavigationBarHidden)
    }

    func testNavigationBarHiddenFalse() {
        let viewController = CheckoutViewController(checkout: checkoutURL)
        viewController.isNavigationBarHidden = false
        XCTAssertFalse(viewController.isNavigationBarHidden)
    }
}

class ShopifyCheckoutTests: XCTestCase {
    var checkoutURL: URL!
    var checkoutSheet: ShopifyCheckout!

    override func setUp() {
        super.setUp()
        checkoutURL = URL(string: "https://www.shopify.com")
        checkoutSheet = ShopifyCheckout(checkout: checkoutURL)
    }

    /// Lifecycle events

    func testOnCancel() {
        var cancelActionCalled = false

        checkoutSheet.onCancel {
            cancelActionCalled = true
        }
        checkoutSheet.delegate.checkoutDidCancel()
        XCTAssertTrue(cancelActionCalled)
    }

    func testOnStart() {
        var actionCalled = false
        var actionData: CheckoutStartEvent?
        let event = createTestCheckoutStartEvent()

        checkoutSheet.onStart { event in
            actionCalled = true
            actionData = event
        }
        checkoutSheet.delegate.checkoutDidStart(event: event)
        XCTAssertTrue(actionCalled)
        XCTAssertNotNil(actionData)
    }

    func testOnComplete() {
        var actionCalled = false
        var actionData: CheckoutCompleteEvent?
        let event = createEmptyCheckoutCompleteEvent()

        checkoutSheet.onComplete { event in
            actionCalled = true
            actionData = event
        }
        checkoutSheet.delegate.checkoutDidComplete(event: event)
        XCTAssertTrue(actionCalled)
        XCTAssertNotNil(actionData)
    }

    func testOnFail() {
        var actionCalled = false
        var actionData: CheckoutError?
        let error: CheckoutError = .checkoutUnavailable(message: "error", code: CheckoutUnavailable.httpError(statusCode: 500), recoverable: false)

        checkoutSheet.onFail { failure in
            actionCalled = true
            actionData = failure
        }

        checkoutSheet.delegate.checkoutDidFail(error: error)
        XCTAssertTrue(actionCalled)
        XCTAssertNotNil(actionData)
    }

    func testOnLinkClick() {
        var actionCalled = false
        var actionData: URL?

        checkoutSheet.onLinkClick { url in
            actionCalled = true
            actionData = url
        }
        checkoutSheet.delegate.checkoutDidClickLink(url: URL(string: "https://shopify.com")!)
        XCTAssertTrue(actionCalled)
        XCTAssertNotNil(actionData)
    }

    func testOnAddressChangeStart() {
        var actionCalled = false
        var actionData: CheckoutAddressChangeStartEvent?
        let event = createTestCheckoutAddressChangeStartEvent()

        checkoutSheet.onAddressChangeStart { event in
            actionCalled = true
            actionData = event
        }
        checkoutSheet.delegate.checkoutDidStartAddressChange(event: event)
        XCTAssertTrue(actionCalled)
        XCTAssertNotNil(actionData)
    }

    func testOnPaymentMethodChangeStart() {
        var actionCalled = false
        var actionData: CheckoutPaymentMethodChangeStartEvent?
        let event = createTestCheckoutPaymentMethodChangeStartEvent()

        checkoutSheet.onPaymentMethodChangeStart { event in
            actionCalled = true
            actionData = event
        }
        checkoutSheet.delegate.checkoutDidStartPaymentMethodChange(event: event)
        XCTAssertTrue(actionCalled)
        XCTAssertNotNil(actionData)
    }
}

class CheckoutConfigurableTests: XCTestCase {
    var checkoutURL: URL!
    var checkoutSheet: ShopifyCheckout!

    override func setUp() {
        super.setUp()
        checkoutURL = URL(string: "https://www.shopify.com")
        checkoutSheet = ShopifyCheckout(checkout: checkoutURL)
    }

    /// Configuration modifiers

    func testBackgroundColor() {
        let color = UIColor.red
        checkoutSheet.backgroundColor(color)
        XCTAssertEqual(ShopifyCheckoutSheetKit.configuration.backgroundColor, color)
    }

    func testColorScheme() {
        let colorScheme = ShopifyCheckoutSheetKit.Configuration.ColorScheme.light
        checkoutSheet.colorScheme(colorScheme)
        XCTAssertEqual(ShopifyCheckoutSheetKit.configuration.colorScheme, colorScheme)
    }

    func testTintColor() {
        let color = UIColor.blue
        checkoutSheet.tintColor(color)
        XCTAssertEqual(ShopifyCheckoutSheetKit.configuration.tintColor, color)
    }

    func testTitle() {
        let title = "Test Title"
        checkoutSheet.title(title)
        XCTAssertEqual(ShopifyCheckoutSheetKit.configuration.title, title)
    }

    func testCloseButtonTintColor() {
        let color = UIColor.green
        checkoutSheet.closeButtonTintColor(color)
        XCTAssertEqual(ShopifyCheckoutSheetKit.configuration.closeButtonTintColor, color)
    }

    func testCloseButtonTintColorNil() {
        checkoutSheet.closeButtonTintColor(nil)
        XCTAssertNil(ShopifyCheckoutSheetKit.configuration.closeButtonTintColor)
    }

    func testAuthWithToken() {
        let token = "test-auth-token"
        let authenticated = checkoutSheet.auth(token: token)

        guard case let .token(actualToken) = authenticated.options.authentication else {
            XCTFail("Expected authentication to be .token, but was \(authenticated.options.authentication)")
            return
        }

        XCTAssertEqual(actualToken, token)
    }

    func testAuthWithNil() {
        let unauthenticated = checkoutSheet.auth(token: nil)

        guard case .none = unauthenticated.options.authentication else {
            XCTFail("Expected authentication to be .none, but was \(unauthenticated.options.authentication)")
            return
        }
    }

    func testAuthClearsTokenWhenSetToNil() {
        // First set a token
        let token = "initial-token"
        let authenticated = checkoutSheet.auth(token: token)

        guard case let .token(actualToken) = authenticated.options.authentication else {
            XCTFail("Expected authentication to be .token")
            return
        }
        XCTAssertEqual(actualToken, token)

        // Then clear it by passing nil
        let cleared = authenticated.auth(token: nil)

        guard case .none = cleared.options.authentication else {
            XCTFail("Expected authentication to be .none after clearing, but was \(cleared.options.authentication)")
            return
        }
    }

    func testNavigationBarHiddenDefaultsToFalse() {
        XCTAssertFalse(checkoutSheet.isNavigationBarHidden)
    }

    func testNavigationBarHiddenModifierTrue() {
        let modified: ShopifyCheckout = checkoutSheet.navigationBarHidden(true)
        XCTAssertTrue(modified.isNavigationBarHidden)
    }

    func testNavigationBarHiddenModifierFalse() {
        let modified: ShopifyCheckout = checkoutSheet.navigationBarHidden(false)
        XCTAssertFalse(modified.isNavigationBarHidden)
    }
}
