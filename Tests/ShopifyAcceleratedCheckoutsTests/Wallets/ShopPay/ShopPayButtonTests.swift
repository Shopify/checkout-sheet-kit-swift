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

import SwiftUI
import ViewInspector
import XCTest

@testable import ShopifyAcceleratedCheckouts

@available(iOS 17.0, *)
class ShopPayButtonTests: XCTestCase {
    // MARK: - Test Setup

    private var testConfiguration: ShopifyAcceleratedCheckouts.Configuration!
    private var validCartIdentifier: CheckoutIdentifier!
    private var validVariantIdentifier: CheckoutIdentifier!
    private var invalidIdentifier: CheckoutIdentifier!

    override func setUp() {
        super.setUp()
        testConfiguration = .testConfiguration
        validCartIdentifier = .cart(cartID: "gid://Shopify/Cart/test-cart-id")
        validVariantIdentifier = .variant(
            variantID: "gid://Shopify/ProductVariant/test-variant-id", quantity: 1)
        invalidIdentifier = .invariant
    }

    override func tearDown() {
        testConfiguration = nil
        validCartIdentifier = nil
        validVariantIdentifier = nil
        invalidIdentifier = nil
        super.tearDown()
    }

    // MARK: - ShopPayButton Tests

    func test_shopPayButton_withValidCartIdentifier_shouldRenderLogo() throws {
        let button = ShopPayButton(
            identifier: validCartIdentifier,
            eventHandlers: EventHandlers(),
            cornerRadius: nil
        )
        .environmentObject(testConfiguration)

        // Assert the Shop Pay logo image is present in the button
        let buttonElement = try button.inspect().find(ViewType.Button.self)
        let logoImage = try buttonElement.labelView().hStack().image(0)
        XCTAssertEqual(try logoImage.actualImage().name(), "shop-pay-logo")
    }

    func test_shopPayButton_withValidVariantIdentifier_shouldRenderLogo() throws {
        let button = ShopPayButton(
            identifier: validVariantIdentifier,
            eventHandlers: EventHandlers(),
            cornerRadius: nil
        )
        .environmentObject(testConfiguration)

        // Assert the Shop Pay logo image is present in the button
        let buttonElement = try button.inspect().find(ViewType.Button.self)
        let logoImage = try buttonElement.labelView().hStack().image(0)
        XCTAssertEqual(try logoImage.actualImage().name(), "shop-pay-logo")
    }

    func test_shopPayButton_withInvalidIdentifier_shouldRenderEmptyView() throws {
        let button = ShopPayButton(
            identifier: invalidIdentifier,
            eventHandlers: EventHandlers(),
            cornerRadius: nil
        )
        .environmentObject(testConfiguration)

        XCTAssertNoThrow(try button.inspect().find(ViewType.EmptyView.self))
        XCTAssertThrowsError(try button.inspect().find(ViewType.Button.self))
    }

    // MARK: - ShopPayButton Rendering Tests

    func test_shopPayButton_shouldHaveShopPayBlueBackground() throws {
        let button = ShopPayButton(
            identifier: validCartIdentifier,
            eventHandlers: EventHandlers(),
            cornerRadius: nil
        )
        .environmentObject(testConfiguration)

        let buttonElement = try button.inspect().find(ViewType.Button.self)
        let hStack = try buttonElement.labelView().hStack()
        let background = try hStack.background()

        XCTAssertEqual(try background.color().value(), Color.shopPayBlue)
    }

    func test_shopPayButton_withCustomCornerRadius_shouldApplyCornerRadius() throws {
        let customCornerRadius: CGFloat = 12
        let button = ShopPayButton(
            identifier: validCartIdentifier,
            eventHandlers: EventHandlers(),
            cornerRadius: customCornerRadius
        )
        .environmentObject(testConfiguration)

        let buttonElement = try button.inspect().find(ViewType.Button.self)
        XCTAssertEqual(try buttonElement.cornerRadius(), 12)
    }

    func test_shopPayButton_withNilCornerRadius_shouldUseDefaultCornerRadius() throws {
        let button = ShopPayButton(
            identifier: validCartIdentifier,
            eventHandlers: EventHandlers(),
            cornerRadius: nil
        )
        .environmentObject(testConfiguration)

        let buttonElement = try button.inspect().find(ViewType.Button.self)

        XCTAssertEqual(try buttonElement.cornerRadius(), 8)
    }

    func test_shopPayButton_withZeroCornerRadius_shouldApplyZero() throws {
        let button = ShopPayButton(
            identifier: validCartIdentifier,
            eventHandlers: EventHandlers(),
            cornerRadius: 0
        )
        .environmentObject(testConfiguration)

        let buttonElement = try button.inspect().find(ViewType.Button.self)

        XCTAssertEqual(try buttonElement.cornerRadius(), 0)
    }

    func test_shopPayButton_withNegativeCornerRadius_shouldUseDefaultCornerRadius() throws {
        let button = ShopPayButton(
            identifier: validCartIdentifier,
            eventHandlers: EventHandlers(),
            cornerRadius: -5
        )
        .environmentObject(testConfiguration)

        let buttonElement = try button.inspect().find(ViewType.Button.self)

        XCTAssertEqual(try buttonElement.cornerRadius(), 8)
    }

    func test_shopPayButton_withLargeCornerRadius_shouldHandleGracefully() throws {
        let button = ShopPayButton(
            identifier: validCartIdentifier,
            eventHandlers: EventHandlers(),
            cornerRadius: 100
        )
        .environmentObject(testConfiguration)

        let buttonElement = try button.inspect().find(ViewType.Button.self)

        XCTAssertEqual(try buttonElement.cornerRadius(), 100)
    }

    // MARK: - Identifier Validation Tests

    func test_shopPayButton_withEmptyCartID_shouldRenderEmptyView() throws {
        let emptyCartIdentifier = CheckoutIdentifier.cart(cartID: "")
        let button = ShopPayButton(
            identifier: emptyCartIdentifier,
            eventHandlers: EventHandlers(),
            cornerRadius: nil
        )
        .environmentObject(testConfiguration)

        XCTAssertNoThrow(try button.inspect().find(ViewType.EmptyView.self))
    }

    func test_shopPayButton_withInvalidCartIDPrefix_shouldRenderEmptyView() throws {
        let invalidCartIdentifier = CheckoutIdentifier.cart(
            cartID: "invalid://Shopify/Cart/test-id")
        let button = ShopPayButton(
            identifier: invalidCartIdentifier,
            eventHandlers: EventHandlers(),
            cornerRadius: nil
        )
        .environmentObject(testConfiguration)

        XCTAssertNoThrow(try button.inspect().find(ViewType.EmptyView.self))
    }

    func test_shopPayButton_withZeroQuantityVariant_shouldRenderEmptyView() throws {
        let zeroQuantityIdentifier = CheckoutIdentifier.variant(
            variantID: "gid://Shopify/ProductVariant/test-id",
            quantity: 0
        )
        let button = ShopPayButton(
            identifier: zeroQuantityIdentifier,
            eventHandlers: EventHandlers(),
            cornerRadius: nil
        )
        .environmentObject(testConfiguration)

        XCTAssertNoThrow(try button.inspect().find(ViewType.EmptyView.self))
    }

    func test_shopPayButton_withInvalidVariantIDPrefix_shouldRenderEmptyView() throws {
        let invalidVariantIdentifier = CheckoutIdentifier.variant(
            variantID: "invalid://Shopify/ProductVariant/test-id",
            quantity: 1
        )
        let button = ShopPayButton(
            identifier: invalidVariantIdentifier,
            eventHandlers: EventHandlers(),
            cornerRadius: nil
        )
        .environmentObject(testConfiguration)

        XCTAssertNoThrow(try button.inspect().find(ViewType.EmptyView.self))
    }
}
