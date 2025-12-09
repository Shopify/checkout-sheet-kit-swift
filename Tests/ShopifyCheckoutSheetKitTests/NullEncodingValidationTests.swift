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

    func testCheckoutSubmitStartResponsePayloadEncodesAllKeys() throws {
        let mock = CheckoutSubmitStartResponsePayload()
        XCTAssertEqual(try toString(mock), """
        {
          "cart" : null,
          "errors" : null,
          "payment" : null
        }
        """)
    }

    func testCheckoutAddressChangeStartResponsePayloadEncodesAllKeys() throws {
        let mock = CheckoutAddressChangeStartResponsePayload()
        XCTAssertEqual(try toString(mock), """
        {
          "cart" : null,
          "errors" : null
        }
        """)
    }

    func testCheckoutPaymentMethodChangeStartResponsePayloadEncodesAllKeys() throws {
        let mock = CheckoutPaymentMethodChangeStartResponsePayload()
        XCTAssertEqual(try toString(mock), """
        {
          "cart" : null,
          "errors" : null
        }
        """)
    }

    // MARK: - Input Type Tests

    func testCartInputEncodesAllKeys() throws {
        let mock = CartInput()
        XCTAssertEqual(try toString(mock), """
        {
          "buyerIdentity" : null,
          "delivery" : null,
          "discountCodes" : null,
          "paymentInstruments" : null
        }
        """)
    }

    func testCartDeliveryInputEncodesAllKeys() throws {
        let mock = CartDeliveryInput()
        XCTAssertEqual(try toString(mock), """
        {
          "addresses" : null
        }
        """)
    }

    func testCartSelectableAddressInputEncodesAllKeys() throws {
        let mock = CartSelectableAddressInput(address: CartDeliveryAddressInput())
        XCTAssertEqual(try toString(mock), """
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
        """)
    }

    func testCartDeliveryAddressInputEncodesAllKeys() throws {
        let mock = CartDeliveryAddressInput()
        XCTAssertEqual(try toString(mock), """
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
        """)
    }

    func testCartBuyerIdentityInputEncodesAllKeys() throws {
        let mock = CartBuyerIdentityInput()
        XCTAssertEqual(try toString(mock), """
        {
          "countryCode" : null,
          "email" : null,
          "phone" : null
        }
        """)
    }

    func testResponseErrorEncodesAllKeys() throws {
        let mock = ResponseError(code: "TEST", message: "Test error")
        XCTAssertEqual(try toString(mock), """
        {
          "code" : "TEST",
          "fieldTarget" : null,
          "message" : "Test error"
        }
        """)
    }

    // MARK: - Data Type Tests

    func testOrderConfirmationEncodesAllKeys() throws {
        let mock = OrderConfirmation(
            order: OrderConfirmation.Order(id: "test-order"),
            isFirstOrder: false
        )
        XCTAssertEqual(try toString(mock), """
        {
          "isFirstOrder" : false,
          "number" : null,
          "order" : {
            "id" : "test-order"
          },
          "url" : null
        }
        """)
    }

    func testMerchandiseImageEncodesAllKeys() throws {
        let mock = MerchandiseImage(url: "https://example.com/image.png")
        XCTAssertEqual(try toString(mock), """
        {
          "altText" : null,
          "url" : "https://example.com/image.png"
        }
        """)
    }

    func testCartBuyerIdentityEncodesAllKeys() throws {
        let mock = CartBuyerIdentity()
        XCTAssertEqual(try toString(mock), """
        {
          "countryCode" : null,
          "customer" : null,
          "email" : null,
          "phone" : null
        }
        """)
    }

    func testCustomerEncodesAllKeys() throws {
        let mock = Customer()
        XCTAssertEqual(try toString(mock), """
        {
          "email" : null,
          "firstName" : null,
          "id" : null,
          "lastName" : null,
          "phone" : null
        }
        """)
    }

    func testMailingAddressEncodesAllKeys() throws {
        let mock = MailingAddress()
        XCTAssertEqual(try toString(mock), """
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
        """)
    }

    func testCartDeliveryAddressEncodesAllKeys() throws {
        let mock = CartDeliveryAddress()
        XCTAssertEqual(try toString(mock), """
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
        """)
    }

    func testCartDeliveryOptionEncodesAllKeys() throws {
        let mock = CartDeliveryOption(
            handle: "test-handle",
            estimatedCost: Money(amount: "10.00", currencyCode: "USD"),
            deliveryMethodType: .shipping
        )
        XCTAssertEqual(try toString(mock), """
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
        """)
    }
}
