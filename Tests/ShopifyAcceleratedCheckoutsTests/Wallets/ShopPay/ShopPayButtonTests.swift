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

    private let testConfiguration: ShopifyAcceleratedCheckouts.Configuration = .testConfiguration
    private var validCartIdentifier: CheckoutIdentifier! = .cart(
        cartID: "gid://Shopify/Cart/test-cart-id")
    private var validVariantIdentifier: CheckoutIdentifier! = .variant(
        variantID: "gid://Shopify/ProductVariant/test-variant-id", quantity: 1
    )

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

    func test_shopPayButton_cornerRadius_shouldApplyExpectedValues() throws {
        let testCases: [(input: CGFloat?, expected: CGFloat, description: String)] = [
            (input: 12, expected: 12, description: "custom corner radius"),
            (input: nil, expected: 8, description: "nil corner radius uses default"),
            (input: 0, expected: 0, description: "zero corner radius"),
            (input: -5, expected: 8, description: "negative corner radius uses default"),
            (input: 100, expected: 100, description: "large corner radius")
        ]

        for testCase in testCases {
            try XCTContext.runActivity(named: "Testing \(testCase.description)") { _ in
                let button = ShopPayButton(
                    identifier: validCartIdentifier,
                    eventHandlers: EventHandlers(),
                    cornerRadius: testCase.input
                )
                .environmentObject(testConfiguration)

                let buttonElement = try button.inspect().find(ViewType.Button.self)
                XCTAssertEqual(try buttonElement.cornerRadius(), testCase.expected)
            }
        }
    }

    // MARK: - Identifier Validation Tests

    func test_shopPayButton_withInvalidIdentifiers_shouldRenderEmptyView() throws {
        let testCases: [(CheckoutIdentifier, String)] = [
            (.cart(cartID: ""), "empty cart ID"),
            (.cart(cartID: "invalid://Shopify/Cart/test-id"), "invalid cart ID prefix"),
            (
                .variant(variantID: "gid://Shopify/ProductVariant/test-id", quantity: 0),
                "zero quantity variant"
            ),
            (
                .variant(variantID: "invalid://Shopify/ProductVariant/test-id", quantity: 1),
                "invalid variant ID prefix"
            )
        ]

        for (identifier, description) in testCases {
            try XCTContext.runActivity(named: "Testing \(description)") { _ in
                let button = ShopPayButton(
                    identifier: identifier,
                    eventHandlers: EventHandlers(),
                    cornerRadius: nil
                )
                .environmentObject(testConfiguration)

                XCTAssertNoThrow(try button.inspect().find(ViewType.EmptyView.self))
            }
        }
    }
}
