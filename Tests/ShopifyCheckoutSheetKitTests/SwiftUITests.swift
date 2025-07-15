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
}

class CheckoutSheetTests: XCTestCase {
    var checkoutURL: URL!
    var checkoutSheet: CheckoutSheet!

    override func setUp() {
        super.setUp()
        checkoutURL = URL(string: "https://www.shopify.com")
        checkoutSheet = CheckoutSheet(checkout: checkoutURL)
    }

    /// Lifecycle events

    func testOnCancel() {
        var cancelActionCalled = false

        checkoutSheet = checkoutSheet.onCancel {
            cancelActionCalled = true
        }
        checkoutSheet.eventHandlers.checkoutDidCancel?()
        XCTAssertTrue(cancelActionCalled)
    }

    func testOnComplete() {
        var actionCalled = false
        var actionData: CheckoutCompletedEvent?
        let event = createEmptyCheckoutCompletedEvent()

        checkoutSheet = checkoutSheet.onComplete { event in
            actionCalled = true
            actionData = event
        }
        checkoutSheet.eventHandlers.checkoutDidComplete?(event)
        XCTAssertTrue(actionCalled)
        XCTAssertNotNil(actionData)
    }

    func testOnFail() {
        var actionCalled = false
        var actionData: CheckoutError?
        let error: CheckoutError = .checkoutUnavailable(message: "error", code: CheckoutUnavailable.httpError(statusCode: 500), recoverable: false)

        checkoutSheet = checkoutSheet.onFail { failure in
            actionCalled = true
            actionData = failure
        }

        checkoutSheet.eventHandlers.checkoutDidFail?(error)
        XCTAssertTrue(actionCalled)
        XCTAssertNotNil(actionData)
    }

    func testOnPixelEvent() {
        var actionCalled = false
        var actionData: PixelEvent?
        let standardEvent = StandardEvent(context: nil, id: "testId", name: "checkout_started", timestamp: "2022-01-01T00:00:00Z", data: nil)
        let pixelEvent = PixelEvent.standardEvent(standardEvent)

        checkoutSheet = checkoutSheet.onPixelEvent { event in
            actionCalled = true
            actionData = event
        }
        checkoutSheet.eventHandlers.checkoutDidEmitWebPixelEvent?(pixelEvent)
        XCTAssertTrue(actionCalled)
        XCTAssertNotNil(actionData)
    }

    func testOnLinkClick() {
        var actionCalled = false
        var actionData: URL?

        checkoutSheet = checkoutSheet.onLinkClick { url in
            actionCalled = true
            actionData = url
        }
        checkoutSheet.eventHandlers.checkoutDidClickLink?(URL(string: "https://shopify.com")!)
        XCTAssertTrue(actionCalled)
        XCTAssertNotNil(actionData)
    }

    func testOnShouldRecoverFromError() {
        var actionCalled = false
        let recoverableError: CheckoutError = .checkoutUnavailable(message: "error", code: CheckoutUnavailable.httpError(statusCode: 500), recoverable: true)
        
        checkoutSheet = checkoutSheet.onShouldRecoverFromError { error in
            actionCalled = true
            return error.isRecoverable
        }
        
        let shouldRecover = checkoutSheet.eventHandlers.shouldRecoverFromError?(recoverableError) ?? false
        XCTAssertTrue(actionCalled)
        XCTAssertTrue(shouldRecover)
    }
    
    func testMixedInitializationPath() {
        // Create CheckoutWebViewController with delegate API
        let webViewController = CheckoutWebViewController(checkoutURL: checkoutURL, delegate: nil)
        
        // Simulate SwiftUI updating with EventHandlers
        var eventHandlerCalled = false
        let eventHandlers = EventHandlers(
            checkoutDidComplete: { _ in
                eventHandlerCalled = true
            }
        )
        
        // Update with new event handlers (simulating SwiftUI update)
        webViewController.updateEventHandlers(eventHandlers)
        
        // Verify the wrapper was created and delegate set
        XCTAssertNotNil(webViewController.delegate)
        
        // Trigger the event through the delegate
        let event = createEmptyCheckoutCompletedEvent()
        webViewController.delegate?.checkoutDidComplete(event: event)
        
        // Verify event handler was called
        XCTAssertTrue(eventHandlerCalled)
    }
}

class CheckoutConfigurableTests: XCTestCase {
    var checkoutURL: URL!
    var checkoutSheet: CheckoutSheet!

    override func setUp() {
        super.setUp()
        checkoutURL = URL(string: "https://www.shopify.com")
        checkoutSheet = CheckoutSheet(checkout: checkoutURL)
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
}
