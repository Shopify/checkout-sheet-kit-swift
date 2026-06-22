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
    func test_applePayButtonType_withPassKitButtonTypeModifier_shouldStorePassKitButtonType() {
        let view = AcceleratedCheckoutButtons(cartID: "gid://Shopify/Cart/test-cart-id")
            .applePayButtonType(.buy)

        XCTAssertEqual(storedApplePayButtonType(in: view)?.rawValue, PKPaymentButtonType.buy.rawValue)
    }

    func test_applePayButtonStyle_withPassKitButtonStyleModifier_shouldStorePassKitButtonStyle() {
        let view = AcceleratedCheckoutButtons(cartID: "gid://Shopify/Cart/test-cart-id")
            .applePayButtonStyle(.black)

        XCTAssertEqual(storedApplePayButtonStyle(in: view)?.rawValue, PKPaymentButtonStyle.black.rawValue)
    }

    func test_applePayLabel_withDeprecatedLabelModifier_shouldStoreMappedPassKitButtonType() {
        let view = AcceleratedCheckoutButtons(cartID: "gid://Shopify/Cart/test-cart-id")
            .applePayLabel(.buy)

        XCTAssertEqual(storedApplePayButtonType(in: view)?.rawValue, PKPaymentButtonType.buy.rawValue)
    }

    func test_applePayStyle_withDeprecatedStyleModifier_shouldStoreMappedPassKitButtonStyle() {
        let view = AcceleratedCheckoutButtons(cartID: "gid://Shopify/Cart/test-cart-id")
            .applePayStyle(.black)

        XCTAssertEqual(storedApplePayButtonStyle(in: view)?.rawValue, PKPaymentButtonStyle.black.rawValue)
    }

    func test_applePayLabel_withSupportedDeprecatedLabels_shouldMapToPassKitButtonTypes() {
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

    func test_applePayStyle_withSupportedDeprecatedStyles_shouldMapToPassKitButtonStyles() {
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

    func test_applePayButton_withPassKitValues_shouldPassValuesToInternalButton() {
        let button = ApplePayButton(
            identifier: .cart(cartID: "gid://Shopify/Cart/test-cart-id"),
            cornerRadius: nil,
            label: .buy,
            style: .whiteOutline
        )

        XCTAssertEqual(storedButtonType(in: button)?.rawValue, PKPaymentButtonType.buy.rawValue)
        XCTAssertEqual(storedButtonStyle(in: button)?.rawValue, PKPaymentButtonStyle.whiteOutline.rawValue)
    }

    func test_internalApplePayButton_withPassKitValues_shouldStoreValuesDirectly() {
        let button = Internal_ApplePayButton(
            identifier: .cart(cartID: "gid://Shopify/Cart/test-cart-id"),
            label: .buy,
            style: .whiteOutline,
            configuration: .testConfiguration,
            cornerRadius: nil
        )

        XCTAssertEqual(storedButtonType(in: button)?.rawValue, PKPaymentButtonType.buy.rawValue)
        XCTAssertEqual(storedButtonStyle(in: button)?.rawValue, PKPaymentButtonStyle.whiteOutline.rawValue)
    }

    func test_applePayButtonRepresentable_withPassKitValues_shouldStoreValuesDirectly() {
        let representable = ApplePayButtonRepresentable(
            buttonType: .buy,
            buttonStyle: .whiteOutline,
            cornerRadius: 8,
            action: {}
        )

        XCTAssertEqual(storedRepresentableButtonType(in: representable)?.rawValue, PKPaymentButtonType.buy.rawValue)
        XCTAssertEqual(storedRepresentableButtonStyle(in: representable)?.rawValue, PKPaymentButtonStyle.whiteOutline.rawValue)
    }

    func test_buttonIdentity_withDifferentButtonTypes_shouldChangeIdentity() {
        let plainButton = Internal_ApplePayButton(
            identifier: .cart(cartID: "gid://Shopify/Cart/test-cart-id"),
            label: .plain,
            style: .automatic,
            configuration: .testConfiguration,
            cornerRadius: nil
        )
        let buyButton = Internal_ApplePayButton(
            identifier: .cart(cartID: "gid://Shopify/Cart/test-cart-id"),
            label: .buy,
            style: .automatic,
            configuration: .testConfiguration,
            cornerRadius: nil
        )

        XCTAssertNotEqual(
            plainButton.buttonIdentity(colorScheme: .light),
            buyButton.buttonIdentity(colorScheme: .light)
        )
    }

    private func storedApplePayButtonType(in view: AcceleratedCheckoutButtons) -> PKPaymentButtonType? {
        return childValue(named: "applePayLabel", in: view)
    }

    private func storedApplePayButtonStyle(in view: AcceleratedCheckoutButtons) -> PKPaymentButtonStyle? {
        return childValue(named: "applePayStyle", in: view)
    }

    private func storedButtonType(in value: some Any) -> PKPaymentButtonType? {
        return childValue(named: "label", in: value)
    }

    private func storedButtonStyle(in value: some Any) -> PKPaymentButtonStyle? {
        return childValue(named: "style", in: value)
    }

    private func storedRepresentableButtonType(in value: some Any) -> PKPaymentButtonType? {
        return childValue(named: "buttonType", in: value)
    }

    private func storedRepresentableButtonStyle(in value: some Any) -> PKPaymentButtonStyle? {
        return childValue(named: "buttonStyle", in: value)
    }

    private func childValue<Value>(named name: String, in value: some Any) -> Value? {
        return Mirror(reflecting: value).children.first { child in
            child.label == name
        }?.value as? Value
    }
}
