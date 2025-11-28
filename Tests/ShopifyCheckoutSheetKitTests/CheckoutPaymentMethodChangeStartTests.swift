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
    // MARK: - Codable Tests

    func testDecodeResponsePayloadWithPaymentInstruments() throws {
        let json = createTestPaymentMethodChangeStartResponseJSON(
            cart: createTestCartInputJSON(
                paymentInstruments: [createTestPaymentInstrumentInputJSON()]
            )
        )
        let data = json.data(using: .utf8)!

        let payload = try JSONDecoder().decode(CheckoutPaymentMethodChangeStartResponsePayload.self, from: data)

        XCTAssertNotNil(payload.cart)
        XCTAssertEqual(payload.cart?.paymentInstruments?.count, 1)
        XCTAssertEqual(payload.cart?.paymentInstruments?.first?.externalReference, "instrument-123")
        XCTAssertEqual(payload.cart?.paymentInstruments?.first?.display.last4, "4242")
        XCTAssertEqual(payload.cart?.paymentInstruments?.first?.display.cardHolderName, "John Doe")
        XCTAssertEqual(payload.cart?.paymentInstruments?.first?.display.brand, .visa)
        XCTAssertEqual(payload.cart?.paymentInstruments?.first?.display.expiry.month, 12)
        XCTAssertEqual(payload.cart?.paymentInstruments?.first?.display.expiry.year, 2025)
        XCTAssertEqual(payload.cart?.paymentInstruments?.first?.billingAddress.countryCode, "US")
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

    func testDecodePaymentInstrumentWithAllBillingAddressFields() throws {
        let json = createTestPaymentInstrumentInputJSONWithFullAddress()
        let data = json.data(using: .utf8)!

        let instrument = try JSONDecoder().decode(CartPaymentInstrumentInput.self, from: data)

        XCTAssertEqual(instrument.billingAddress.firstName, "John")
        XCTAssertEqual(instrument.billingAddress.lastName, "Doe")
        XCTAssertEqual(instrument.billingAddress.address1, "123 Main St")
        XCTAssertEqual(instrument.billingAddress.address2, "Apt 4")
        XCTAssertEqual(instrument.billingAddress.city, "New York")
        XCTAssertEqual(instrument.billingAddress.company, "Acme Inc")
        XCTAssertEqual(instrument.billingAddress.countryCode, "US")
        XCTAssertEqual(instrument.billingAddress.phone, "+16135551111")
        XCTAssertEqual(instrument.billingAddress.provinceCode, "NY")
        XCTAssertEqual(instrument.billingAddress.zip, "10001")
    }

    func testDecodePaymentInstrumentBrandEnum() throws {
        let brands = [
            ("VISA", CardBrand.visa),
            ("MASTERCARD", CardBrand.mastercard),
            ("AMERICAN_EXPRESS", CardBrand.americanExpress),
            ("DISCOVER", CardBrand.discover),
            ("DINERS_CLUB", CardBrand.dinersClub),
            ("JCB", CardBrand.jcb),
            ("MAESTRO", CardBrand.maestro),
            ("UNKNOWN", CardBrand.unknown)
        ]

        for (jsonBrand, expectedBrand) in brands {
            let json = createTestPaymentInstrumentInputJSON(brand: jsonBrand)
            let data = json.data(using: .utf8)!

            let instrument = try JSONDecoder().decode(CartPaymentInstrumentInput.self, from: data)

            XCTAssertEqual(instrument.display.brand, expectedBrand, "Failed for brand: \(jsonBrand)")
        }
    }
}
