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

import XCTest

@testable import ShopifyCheckoutSheetKit

class NullEncodingValidationTests: XCTestCase {
    // MARK: - Helper

    private func toString(_ instance: some Encodable) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]
        let data = try encoder.encode(instance)
        return String(data: data, encoding: .utf8)!
    }

    // MARK: - Response Payload Tests

    func test_encode_responsePayloads_includeAllNullableKeys() throws {
        let testCases: [(name: String, instance: any Encodable, expected: String)] = [
            (
                "CheckoutSubmitStartResponsePayload",
                CheckoutSubmitStartResponsePayload(),
                """
                {
                  "cart" : null,
                  "errors" : null,
                  "payment" : null
                }
                """
            ),
            (
                "CheckoutAddressChangeStartResponsePayload",
                CheckoutAddressChangeStartResponsePayload(),
                """
                {
                  "cart" : null,
                  "errors" : null
                }
                """
            ),
            (
                "CheckoutPaymentMethodChangeStartResponsePayload",
                CheckoutPaymentMethodChangeStartResponsePayload(),
                """
                {
                  "cart" : null,
                  "errors" : null
                }
                """
            )
        ]

        for (name, instance, expected) in testCases {
            try XCTContext.runActivity(named: name) { _ in
                XCTAssertEqual(try toString(instance), expected)
            }
        }
    }

    // MARK: - Input Type Tests

    func test_encode_inputTypes_includeAllNullableKeys() throws {
        let testCases: [(name: String, instance: any Encodable, expected: String)] = [
            (
                "CartInput",
                CartInput(),
                """
                {
                  "buyerIdentity" : null,
                  "delivery" : null,
                  "discountCodes" : null,
                  "paymentInstruments" : null
                }
                """
            ),
            (
                "CartDeliveryInput",
                CartDeliveryInput(),
                """
                {
                  "addresses" : null
                }
                """
            ),
            (
                "CartSelectableAddressInput",
                CartSelectableAddressInput(address: CartDeliveryAddressInput()),
                """
                {
                  "address" : {
                    "address1" : null,
                    "address2" : null,
                    "city" : null,
                    "company" : null,
                    "countryCode" : null,
                    "firstName" : null,
                    "lastName" : null,
                    "phone" : null,
                    "provinceCode" : null,
                    "zip" : null
                  },
                  "selected" : null
                }
                """
            ),
            (
                "CartDeliveryAddressInput",
                CartDeliveryAddressInput(),
                """
                {
                  "address1" : null,
                  "address2" : null,
                  "city" : null,
                  "company" : null,
                  "countryCode" : null,
                  "firstName" : null,
                  "lastName" : null,
                  "phone" : null,
                  "provinceCode" : null,
                  "zip" : null
                }
                """
            ),
            (
                "CartBuyerIdentityInput",
                CartBuyerIdentityInput(),
                """
                {
                  "countryCode" : null,
                  "email" : null,
                  "phone" : null
                }
                """
            ),
            (
                "ResponseError",
                ResponseError(code: "TEST", message: "Test error"),
                """
                {
                  "code" : "TEST",
                  "fieldTarget" : null,
                  "message" : "Test error"
                }
                """
            )
        ]

        for (name, instance, expected) in testCases {
            try XCTContext.runActivity(named: name) { _ in
                XCTAssertEqual(try toString(instance), expected)
            }
        }
    }

    // MARK: - Data Type Tests

    func test_encode_dataTypes_includeAllNullableKeys() throws {
        let testCases: [(name: String, instance: any Encodable, expected: String)] = [
            (
                "OrderConfirmation",
                OrderConfirmation(
                    order: OrderConfirmation.Order(id: "test-order"),
                    isFirstOrder: false
                ),
                """
                {
                  "isFirstOrder" : false,
                  "number" : null,
                  "order" : {
                    "id" : "test-order"
                  },
                  "url" : null
                }
                """
            ),
            (
                "MerchandiseImage",
                MerchandiseImage(url: "https://example.com/image.png"),
                """
                {
                  "altText" : null,
                  "url" : "https://example.com/image.png"
                }
                """
            ),
            (
                "CartBuyerIdentity",
                CartBuyerIdentity(),
                """
                {
                  "countryCode" : null,
                  "customer" : null,
                  "email" : null,
                  "phone" : null
                }
                """
            ),
            (
                "Customer",
                Customer(),
                """
                {
                  "email" : null,
                  "firstName" : null,
                  "id" : null,
                  "lastName" : null,
                  "phone" : null
                }
                """
            ),
            (
                "MailingAddress",
                MailingAddress(),
                """
                {
                  "address1" : null,
                  "address2" : null,
                  "city" : null,
                  "company" : null,
                  "country" : null,
                  "countryCodeV2" : null,
                  "firstName" : null,
                  "lastName" : null,
                  "phone" : null,
                  "province" : null,
                  "zip" : null
                }
                """
            ),
            (
                "CartDeliveryAddress",
                CartDeliveryAddress(),
                """
                {
                  "address1" : null,
                  "address2" : null,
                  "city" : null,
                  "company" : null,
                  "countryCode" : null,
                  "firstName" : null,
                  "lastName" : null,
                  "phone" : null,
                  "provinceCode" : null,
                  "zip" : null
                }
                """
            ),
            (
                "CartDeliveryOption",
                CartDeliveryOption(
                    handle: "test-handle",
                    estimatedCost: Money(amount: "10.00", currencyCode: "USD"),
                    deliveryMethodType: .shipping
                ),
                """
                {
                  "code" : null,
                  "deliveryMethodType" : "SHIPPING",
                  "description" : null,
                  "estimatedCost" : {
                    "amount" : "10.00",
                    "currencyCode" : "USD"
                  },
                  "handle" : "test-handle",
                  "title" : null
                }
                """
            )
        ]

        for (name, instance, expected) in testCases {
            try XCTContext.runActivity(named: name) { _ in
                XCTAssertEqual(try toString(instance), expected)
            }
        }
    }
}
