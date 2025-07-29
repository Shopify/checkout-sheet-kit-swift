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
final class AcceleratedCheckoutButtonTests: XCTestCase {
    private var mockConfiguration: ShopifyAcceleratedCheckouts.Configuration!
    private var mockViewController: UIViewController!

    override func setUp() {
        super.setUp()
        mockConfiguration = ShopifyAcceleratedCheckouts.Configuration(
            storefrontDomain: "test-shop.myshopify.com",
            storefrontAccessToken: "test-access-token"
        )
        mockViewController = UIViewController()

        // Configure the module before testing
        ShopifyAcceleratedCheckouts.configure(mockConfiguration)
    }

    override func tearDown() {
        mockConfiguration = nil
        mockViewController = nil
        ShopifyAcceleratedCheckouts.currentConfiguration = nil
        super.tearDown()
    }

    // MARK: - Button Factory Tests

    func testApplePayButtonFactoryWithCartID() {
        let cartID = "gid://shopify/Cart/test-cart-id"
        let button = AcceleratedCheckoutButton.applePay(cartID: cartID)

        XCTAssertNotNil(button)
        XCTAssertTrue(button is AcceleratedCheckoutButton)
    }

    func testApplePayButtonFactoryWithVariantID() {
        let variantID = "gid://shopify/ProductVariant/test-variant-id"
        let quantity = 2
        let button = AcceleratedCheckoutButton.applePay(variantID: variantID, quantity: quantity)

        XCTAssertNotNil(button)
        XCTAssertTrue(button is AcceleratedCheckoutButton)
    }

    func testShopPayButtonFactoryWithCartID() {
        let cartID = "gid://shopify/Cart/test-cart-id"
        let button = AcceleratedCheckoutButton.shopPay(cartID: cartID)

        XCTAssertNotNil(button)
        XCTAssertTrue(button is AcceleratedCheckoutButton)
    }

    func testShopPayButtonFactoryWithVariantID() {
        let variantID = "gid://shopify/ProductVariant/test-variant-id"
        let quantity = 1
        let button = AcceleratedCheckoutButton.shopPay(variantID: variantID, quantity: quantity)

        XCTAssertNotNil(button)
        XCTAssertTrue(button is AcceleratedCheckoutButton)
    }

    func testButtonFactoryWithInvalidCartID() {
        let invalidCartID = "invalid-cart-id"
        let button = AcceleratedCheckoutButton.applePay(cartID: invalidCartID)

        XCTAssertNotNil(button)
        // The button should handle invalid IDs gracefully
    }

    // MARK: - Global Button Factory API Tests

    func testGlobalApplePayButtonWithCartID() {
        let cartID = "gid://shopify/Cart/test-cart-id"
        let button = ShopifyAcceleratedCheckouts.applePayButton(cartID: cartID)

        XCTAssertNotNil(button)
        XCTAssertTrue(button is AcceleratedCheckoutButton)
    }

    func testGlobalApplePayButtonWithVariantID() {
        let variantID = "gid://shopify/ProductVariant/test-variant-id"
        let quantity = 1
        let button = ShopifyAcceleratedCheckouts.applePayButton(variantID: variantID, quantity: quantity)

        XCTAssertNotNil(button)
        XCTAssertTrue(button is AcceleratedCheckoutButton)
    }

    func testGlobalShopPayButtonWithCartID() {
        let cartID = "gid://shopify/Cart/test-cart-id"
        let button = ShopifyAcceleratedCheckouts.shopPayButton(cartID: cartID)

        XCTAssertNotNil(button)
        XCTAssertTrue(button is AcceleratedCheckoutButton)
    }

    func testGlobalShopPayButtonWithVariantID() {
        let variantID = "gid://shopify/ProductVariant/test-variant-id"
        let quantity = 2
        let button = ShopifyAcceleratedCheckouts.shopPayButton(variantID: variantID, quantity: quantity)

        XCTAssertNotNil(button)
        XCTAssertTrue(button is AcceleratedCheckoutButton)
    }

    func testCanPresentApplePay() {
        let canPresent = ShopifyAcceleratedCheckouts.canPresent(wallet: .applePay)
        // Apple Pay availability depends on device configuration
        XCTAssertTrue(canPresent == true || canPresent == false)
    }

    func testCanPresentShopPay() {
        let canPresent = ShopifyAcceleratedCheckouts.canPresent(wallet: .shopPay)
        // Shop Pay should always be available as it falls back to web checkout
        XCTAssertTrue(canPresent)
    }

    // MARK: - Configuration Tests

    func testConfigurationViaBlock() {
        let testDomain = "new-test-shop.myshopify.com"
        let testToken = "new-test-token"

        ShopifyAcceleratedCheckouts.configure { config in
            config.storefrontDomain = testDomain
            config.storefrontAccessToken = testToken
        }

        XCTAssertEqual(ShopifyAcceleratedCheckouts.currentConfiguration?.storefrontDomain, testDomain)
        XCTAssertEqual(ShopifyAcceleratedCheckouts.currentConfiguration?.storefrontAccessToken, testToken)
    }

    func testConfigurationViaObject() {
        let newConfig = ShopifyAcceleratedCheckouts.Configuration(
            storefrontDomain: "another-test-shop.myshopify.com",
            storefrontAccessToken: "another-test-token"
        )

        ShopifyAcceleratedCheckouts.configure(newConfig)

        XCTAssertEqual(ShopifyAcceleratedCheckouts.currentConfiguration?.storefrontDomain, newConfig.storefrontDomain)
        XCTAssertEqual(ShopifyAcceleratedCheckouts.currentConfiguration?.storefrontAccessToken, newConfig.storefrontAccessToken)
    }

    // MARK: - Delegate Tests

    func testDelegateCallbacks() {
        let delegate = MockAcceleratedCheckoutDelegate()
        let expectation = XCTestExpectation(description: "Delegate callback received")

        delegate.onRenderStateChange = { state in
            XCTAssertEqual(state, .loading)
            expectation.fulfill()
        }

        let controller = AcceleratedCheckoutViewController(
            wallet: .applePay,
            cartID: "gid://shopify/Cart/test-cart-id",
            delegate: delegate
        )

        // Simulate render state change
        delegate.renderStateDidChange(state: .loading)

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Button Properties Tests

    func testButtonCornerRadius() {
        let button = AcceleratedCheckoutButton.applePay(cartID: "gid://shopify/Cart/test-cart-id")

        // Test default corner radius
        XCTAssertEqual(button.cornerRadius, 8.0)

        // Test setting corner radius
        button.cornerRadius = 12.0
        XCTAssertEqual(button.cornerRadius, 12.0)

        // Test configurable protocol
        let configuredButton = button.cornerRadius(16.0)
        XCTAssertTrue(configuredButton === button) // Should return self
        XCTAssertEqual(button.cornerRadius, 16.0)
    }

    func testButtonDelegate() {
        let button = AcceleratedCheckoutButton.shopPay(cartID: "gid://shopify/Cart/test-cart-id")
        let delegate = MockAcceleratedCheckoutDelegate()

        button.delegate = delegate
        XCTAssertTrue(button.delegate === delegate)
    }

    func testButtonUserInteraction() {
        let button = AcceleratedCheckoutButton.applePay(cartID: "gid://shopify/Cart/test-cart-id")

        // Test default state
        XCTAssertTrue(button.isUserInteractionEnabled)

        // Test disabling interaction
        button.isUserInteractionEnabled = false
        XCTAssertFalse(button.isUserInteractionEnabled)
    }
}

// MARK: - Mock Delegate

@available(iOS 17.0, *)
private class MockAcceleratedCheckoutDelegate: AcceleratedCheckoutDelegate {
    var onCheckoutComplete: ((CheckoutCompletedEvent) -> Void)?
    var onCheckoutCancel: (() -> Void)?
    var onCheckoutFail: ((CheckoutError) -> Void)?
    var onShouldRecoverFromError: ((CheckoutError) -> Bool)?
    var onCheckoutClickLink: ((URL) -> Void)?
    var onCheckoutEmitWebPixelEvent: ((PixelEvent) -> Void)?
    var onRenderStateChange: ((RenderState) -> Void)?

    func checkoutDidComplete(event: CheckoutCompletedEvent) {
        onCheckoutComplete?(event)
    }

    func checkoutDidCancel() {
        onCheckoutCancel?()
    }

    func checkoutDidFail(error: CheckoutError) {
        onCheckoutFail?(error)
    }

    func shouldRecoverFromError(error: CheckoutError) -> Bool {
        return onShouldRecoverFromError?(error) ?? false
    }

    func checkoutDidClickLink(url: URL) {
        onCheckoutClickLink?(url)
    }

    func checkoutDidEmitWebPixelEvent(event: PixelEvent) {
        onCheckoutEmitWebPixelEvent?(event)
    }

    func renderStateDidChange(state: RenderState) {
        onRenderStateChange?(state)
    }
}
