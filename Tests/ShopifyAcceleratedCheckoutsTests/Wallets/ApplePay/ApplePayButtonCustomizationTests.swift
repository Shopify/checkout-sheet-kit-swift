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

import PassKit
@testable import ShopifyAcceleratedCheckouts
import SwiftUI
import XCTest

@available(iOS 16.0, *)
final class ApplePayButtonCustomizationTests: XCTestCase {
    func testApplePayButtonTypeModifierStoresPassKitButtonType() {
        let view = AcceleratedCheckoutButtons(cartID: "gid://Shopify/Cart/test-cart-id")
            .applePayButtonType(.buy)

        XCTAssertEqual(storedApplePayButtonType(in: view)?.rawValue, PKPaymentButtonType.buy.rawValue)
    }

    func testApplePayButtonStyleModifierStoresPassKitButtonStyle() {
        let view = AcceleratedCheckoutButtons(cartID: "gid://Shopify/Cart/test-cart-id")
            .applePayButtonStyle(.black)

        XCTAssertEqual(storedApplePayButtonStyle(in: view)?.rawValue, PKPaymentButtonStyle.black.rawValue)
    }

    func testDeprecatedApplePayLabelModifierMapsToPassKitButtonType() {
        let view = AcceleratedCheckoutButtons(cartID: "gid://Shopify/Cart/test-cart-id")
            .applePayLabel(.buy)

        XCTAssertEqual(storedApplePayButtonType(in: view)?.rawValue, PKPaymentButtonType.buy.rawValue)
    }

    func testDeprecatedApplePayStyleModifierMapsToPassKitButtonStyle() {
        let view = AcceleratedCheckoutButtons(cartID: "gid://Shopify/Cart/test-cart-id")
            .applePayStyle(.black)

        XCTAssertEqual(storedApplePayButtonStyle(in: view)?.rawValue, PKPaymentButtonStyle.black.rawValue)
    }

    func testDeprecatedApplePayLabelModifierMapsSupportedLabelsToPassKitButtonTypes() {
        let mappings: [(PayWithApplePayButtonLabel, PKPaymentButtonType)] = [
            (.plain, .plain),
            (.buy, .buy),
            (.setUp, .setUp),
            (.inStore, .inStore),
            (.donate, .donate),
            (.checkout, .checkout),
            (.book, .book),
            (.subscribe, .subscribe),
            (.reload, .reload),
            (.addMoney, .addMoney),
            (.topUp, .topUp),
            (.order, .order),
            (.rent, .rent),
            (.support, .support),
            (.contribute, .contribute),
            (.tip, .tip),
            (.continue, .continue)
        ]

        for (label, expectedType) in mappings {
            let view = AcceleratedCheckoutButtons(cartID: "gid://Shopify/Cart/test-cart-id")
                .applePayLabel(label)

            XCTAssertEqual(storedApplePayButtonType(in: view)?.rawValue, expectedType.rawValue)
        }
    }

    func testDeprecatedApplePayStyleModifierMapsSupportedStylesToPassKitButtonStyles() {
        let mappings: [(PayWithApplePayButtonStyle, PKPaymentButtonStyle)] = [
            (.automatic, .automatic),
            (.black, .black),
            (.white, .white),
            (.whiteOutline, .whiteOutline)
        ]

        for (style, expectedStyle) in mappings {
            let view = AcceleratedCheckoutButtons(cartID: "gid://Shopify/Cart/test-cart-id")
                .applePayStyle(style)

            XCTAssertEqual(storedApplePayButtonStyle(in: view)?.rawValue, expectedStyle.rawValue)
        }
    }

    func testApplePayButtonPassesPassKitValuesToInternalButton() {
        let button = ApplePayButton(
            identifier: .cart(cartID: "gid://Shopify/Cart/test-cart-id"),
            cornerRadius: nil,
            buttonType: .buy,
            buttonStyle: .whiteOutline
        )

        XCTAssertEqual(storedButtonType(in: button)?.rawValue, PKPaymentButtonType.buy.rawValue)
        XCTAssertEqual(storedButtonStyle(in: button)?.rawValue, PKPaymentButtonStyle.whiteOutline.rawValue)
    }

    func testInternalApplePayButtonStoresPassKitValuesDirectly() {
        let button = Internal_ApplePayButton(
            identifier: .cart(cartID: "gid://Shopify/Cart/test-cart-id"),
            buttonType: .buy,
            buttonStyle: .whiteOutline,
            configuration: .testConfiguration,
            cornerRadius: nil
        )

        XCTAssertEqual(storedButtonType(in: button)?.rawValue, PKPaymentButtonType.buy.rawValue)
        XCTAssertEqual(storedButtonStyle(in: button)?.rawValue, PKPaymentButtonStyle.whiteOutline.rawValue)
    }

    func testApplePayButtonRepresentableStoresPassKitValuesDirectly() {
        let representable = ApplePayButtonRepresentable(
            buttonType: .buy,
            buttonStyle: .whiteOutline,
            cornerRadius: 8,
            action: {}
        )

        XCTAssertEqual(storedButtonType(in: representable)?.rawValue, PKPaymentButtonType.buy.rawValue)
        XCTAssertEqual(storedButtonStyle(in: representable)?.rawValue, PKPaymentButtonStyle.whiteOutline.rawValue)
    }

    func testInternalApplePayButtonIdentityChangesWhenButtonTypeChanges() {
        let plainButton = Internal_ApplePayButton(
            identifier: .cart(cartID: "gid://Shopify/Cart/test-cart-id"),
            buttonType: .plain,
            buttonStyle: .automatic,
            configuration: .testConfiguration,
            cornerRadius: nil
        )
        let buyButton = Internal_ApplePayButton(
            identifier: .cart(cartID: "gid://Shopify/Cart/test-cart-id"),
            buttonType: .buy,
            buttonStyle: .automatic,
            configuration: .testConfiguration,
            cornerRadius: nil
        )

        XCTAssertNotEqual(
            plainButton.buttonIdentity(colorScheme: .light),
            buyButton.buttonIdentity(colorScheme: .light)
        )
    }

    private func storedApplePayButtonType(in view: AcceleratedCheckoutButtons) -> PKPaymentButtonType? {
        return childValue(named: "applePayButtonType", in: view)
    }

    private func storedApplePayButtonStyle(in view: AcceleratedCheckoutButtons) -> PKPaymentButtonStyle? {
        return childValue(named: "applePayButtonStyle", in: view)
    }

    private func storedButtonType(in value: some Any) -> PKPaymentButtonType? {
        return childValue(named: "buttonType", in: value)
    }

    private func storedButtonStyle(in value: some Any) -> PKPaymentButtonStyle? {
        return childValue(named: "buttonStyle", in: value)
    }

    private func childValue<Value>(named name: String, in value: some Any) -> Value? {
        return Mirror(reflecting: value).children.first { child in
            child.label == name
        }?.value as? Value
    }
}
