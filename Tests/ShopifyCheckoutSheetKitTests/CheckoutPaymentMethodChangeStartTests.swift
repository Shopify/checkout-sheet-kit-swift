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

class CheckoutPaymentMethodChangeStartTests: XCTestCase {
    // MARK: - Response Payload Codable Tests

    func testDecodeResponsePayloadWithCart() throws {
        let json = """
        {
            "cart": \(createTestCartJSON())
        }
        """
        let data = json.data(using: .utf8)!

        let payload = try JSONDecoder().decode(CheckoutPaymentMethodChangeStartResponsePayload.self, from: data)

        XCTAssertNotNil(payload.cart)
        XCTAssertEqual(payload.cart?.id, "gid://shopify/Cart/test-cart-123")
    }

    func testDecodeResponsePayloadWithNilCart() throws {
        let json = """
        {
            "cart": null
        }
        """
        let data = json.data(using: .utf8)!

        let payload = try JSONDecoder().decode(CheckoutPaymentMethodChangeStartResponsePayload.self, from: data)

        XCTAssertNil(payload.cart)
        XCTAssertNil(payload.errors)
    }

    func testDecodeResponsePayloadWithEmptyObject() throws {
        let json = "{}"
        let data = json.data(using: .utf8)!

        let payload = try JSONDecoder().decode(CheckoutPaymentMethodChangeStartResponsePayload.self, from: data)

        XCTAssertNil(payload.cart)
        XCTAssertNil(payload.errors)
    }

    func testDecodeResponsePayloadWithErrors() throws {
        let json = createTestPaymentMethodChangeStartResponseJSON(
            errors: [createTestResponseErrorJSON(code: "INVALID_CARD", message: "Card declined")]
        )
        let data = json.data(using: .utf8)!

        let payload = try JSONDecoder().decode(CheckoutPaymentMethodChangeStartResponsePayload.self, from: data)

        XCTAssertNil(payload.cart)
        XCTAssertEqual(payload.errors?.count, 1)
        XCTAssertEqual(payload.errors?.first?.code, "INVALID_CARD")
        XCTAssertEqual(payload.errors?.first?.message, "Card declined")
        XCTAssertNil(payload.errors?.first?.fieldTarget)
    }

    func testDecodeResponsePayloadWithErrorsAndFieldTarget() throws {
        let json = createTestPaymentMethodChangeStartResponseJSON(
            errors: [createTestResponseErrorJSON(code: "INVALID_EXPIRY", message: "Invalid expiry date", fieldTarget: "expiryMonth")]
        )
        let data = json.data(using: .utf8)!

        let payload = try JSONDecoder().decode(CheckoutPaymentMethodChangeStartResponsePayload.self, from: data)

        XCTAssertEqual(payload.errors?.first?.fieldTarget, "expiryMonth")
    }
}
