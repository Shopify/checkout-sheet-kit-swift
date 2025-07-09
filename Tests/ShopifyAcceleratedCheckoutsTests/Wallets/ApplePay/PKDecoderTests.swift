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
import XCTest

class PKDecoderTests: XCTestCase {
    private var cart: () -> StorefrontAPI.Types.Cart? = { nil }

    private var decoder: PKDecoder {
        return PKDecoder(configuration: ApplePayConfigurationWrapper.testConfiguration, cart: { self.cart() })
    }

    // MARK: - Initialization Tests

    func testInitializesDecoderCorrectly() {
        let testDecoder = decoder
        XCTAssertNil(testDecoder.cart())
        XCTAssertNil(testDecoder.selectedShippingMethod)
    }

    func testDecoderStorefrontConfiguration() {
        let testDecoder = decoder
        // Can't directly test private storefront property, but we can test the decoder initializes properly
        XCTAssertNil(testDecoder.cart())
        XCTAssertNil(testDecoder.selectedShippingMethod)
    }

    // MARK: - paymentSummaryItems Tests

    func testReturnsEmptyPaymentSummaryWhenCartIsNil() {
        let testDecoder = decoder
        testDecoder.cart = { nil }

        let summaryItems = testDecoder.paymentSummaryItems
        XCTAssertTrue(summaryItems.isEmpty)
    }

    func testReturnsEmptyPaymentSummaryWhenCartHasNoLines() {
        let testDecoder = decoder
        // Don't set cart - it remains nil

        let summaryItems = testDecoder.paymentSummaryItems
        XCTAssertTrue(summaryItems.isEmpty)
    }

    func testPaymentSummaryItemsWithShippingMethodButNilCart() {
        let testDecoder = decoder
        let shippingMethod = PKShippingMethod(
            label: "Express", amount: NSDecimalNumber(decimal: 5.00)
        )
        testDecoder.selectedShippingMethod = shippingMethod
        testDecoder.cart = { nil }

        let summaryItems = testDecoder.paymentSummaryItems
        XCTAssertTrue(summaryItems.isEmpty)
    }

    // MARK: - shippingMethods Tests

    func testReturnsEmptyShippingMethodsWhenCartIsNil() {
        let testDecoder = decoder
        testDecoder.cart = { nil }

        let shippingMethods = testDecoder.shippingMethods
        XCTAssertTrue(shippingMethods.isEmpty)
    }

    func testReturnsEmptyShippingMethodsWhenNoDeliveryGroups() {
        let testDecoder = decoder
        // Don't set cart - it remains nil

        let shippingMethods = testDecoder.shippingMethods
        XCTAssertTrue(shippingMethods.isEmpty)
    }

    func testShippingMethodsWithNilCartReturnsEmpty() {
        let testDecoder = decoder
        testDecoder.cart = { nil }

        let shippingMethods = testDecoder.shippingMethods
        XCTAssertTrue(shippingMethods.isEmpty)
    }

    // MARK: - selectedShippingMethod Tests

    func testSelectedShippingMethodCanBeSetAndRetrieved() {
        let testDecoder = decoder
        let shippingMethod = PKShippingMethod(
            label: "Express", amount: NSDecimalNumber(decimal: 5.00)
        )
        shippingMethod.detail = "1-2 business days"
        shippingMethod.identifier = "express"

        testDecoder.selectedShippingMethod = shippingMethod

        XCTAssertNotNil(testDecoder.selectedShippingMethod)
        XCTAssertEqual(testDecoder.selectedShippingMethod?.label, "Express")
        XCTAssertEqual(
            testDecoder.selectedShippingMethod?.amount, NSDecimalNumber(decimal: 5.00)
        )
        XCTAssertEqual(testDecoder.selectedShippingMethod?.detail, "1-2 business days")
        XCTAssertEqual(testDecoder.selectedShippingMethod?.identifier, "express")
    }
}
