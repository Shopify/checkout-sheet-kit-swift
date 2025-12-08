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
        let expected = """
        {
          "cart" : null,
          "errors" : null,
          "payment" : null
        }
        """
        XCTAssertEqual(try toString(mock), expected)
    }

    func testCheckoutAddressChangeStartResponsePayloadEncodesAllKeys() throws {
        let mock = CheckoutAddressChangeStartResponsePayload()
        let expected = """
        {
          "cart" : null,
          "errors" : null
        }
        """
        XCTAssertEqual(try toString(mock), expected)
    }

    func testCheckoutPaymentMethodChangeStartResponsePayloadEncodesAllKeys() throws {
        let mock = CheckoutPaymentMethodChangeStartResponsePayload()
        let expected = """
        {
          "cart" : null,
          "errors" : null
        }
        """
        XCTAssertEqual(try toString(mock), expected)
    }

    // MARK: - Input Type Tests

    func testCartInputEncodesAllKeys() throws {
        let mock = CartInput()
        let expected = """
        {
          "buyerIdentity" : null,
          "delivery" : null,
          "discountCodes" : null,
          "paymentInstruments" : null
        }
        """
        XCTAssertEqual(try toString(mock), expected)
    }

    func testCartDeliveryInputEncodesAllKeys() throws {
        let mock = CartDeliveryInput()
        let expected = """
        {
          "addresses" : null
        }
        """
        XCTAssertEqual(try toString(mock), expected)
    }

    func testCartSelectableAddressInputEncodesAllKeys() throws {
        let mock = CartSelectableAddressInput(address: CartDeliveryAddressInput())
        let expected = """
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
        XCTAssertEqual(try toString(mock), expected)
    }

    func testCartDeliveryAddressInputEncodesAllKeys() throws {
        let mock = CartDeliveryAddressInput()
        let expected = """
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
        XCTAssertEqual(try toString(mock), expected)
    }

    func testCartBuyerIdentityInputEncodesAllKeys() throws {
        let mock = CartBuyerIdentityInput()
        let expected = """
        {
          "countryCode" : null,
          "email" : null,
          "phone" : null
        }
        """
        XCTAssertEqual(try toString(mock), expected)
    }

    func testResponseErrorEncodesAllKeys() throws {
        let mock = ResponseError(code: "TEST", message: "Test error")
        let expected = """
        {
          "code" : "TEST",
          "fieldTarget" : null,
          "message" : "Test error"
        }
        """
        XCTAssertEqual(try toString(mock), expected)
    }

    // MARK: - Data Type Tests

    func testOrderConfirmationEncodesAllKeys() throws {
        let mock = OrderConfirmation(
            order: OrderConfirmation.Order(id: "test-order"),
            isFirstOrder: false
        )
        let expected = """
        {
          "isFirstOrder" : false,
          "number" : null,
          "order" : {
            "id" : "test-order"
          },
          "url" : null
        }
        """
        XCTAssertEqual(try toString(mock), expected)
    }

    func testMerchandiseImageEncodesAllKeys() throws {
        let mock = MerchandiseImage(url: "https://example.com/image.png")
        let expected = """
        {
          "altText" : null,
          "url" : "https://example.com/image.png"
        }
        """
        XCTAssertEqual(try toString(mock), expected)
    }

    func testCartBuyerIdentityEncodesAllKeys() throws {
        let mock = CartBuyerIdentity()
        let expected = """
        {
          "countryCode" : null,
          "customer" : null,
          "email" : null,
          "phone" : null
        }
        """
        XCTAssertEqual(try toString(mock), expected)
    }

    func testCustomerEncodesAllKeys() throws {
        let mock = Customer()
        let expected = """
        {
          "email" : null,
          "firstName" : null,
          "id" : null,
          "lastName" : null,
          "phone" : null
        }
        """
        XCTAssertEqual(try toString(mock), expected)
    }

    func testMailingAddressEncodesAllKeys() throws {
        let mock = MailingAddress()
        let expected = """
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
        XCTAssertEqual(try toString(mock), expected)
    }

    func testCartDeliveryAddressEncodesAllKeys() throws {
        let mock = CartDeliveryAddress()
        let expected = """
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
        XCTAssertEqual(try toString(mock), expected)
    }

    func testCartDeliveryOptionEncodesAllKeys() throws {
        let mock = CartDeliveryOption(
            handle: "test-handle",
            estimatedCost: Money(amount: "10.00", currencyCode: "USD"),
            deliveryMethodType: .shipping
        )
        let expected = """
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
        XCTAssertEqual(try toString(mock), expected)
    }
}
