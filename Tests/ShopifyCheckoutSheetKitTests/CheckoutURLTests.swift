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

class CheckoutURLTests: XCTestCase {

    func testIsMultipassURL() {
        let multipassURL = URL(string: "https://shopify.com/multipass")!
        let nonMultipassURL = URL(string: "https://shopify.com/checkout")!

        XCTAssertTrue(CheckoutURL(from: multipassURL).isMultipassURL())
        XCTAssertFalse(CheckoutURL(from: nonMultipassURL).isMultipassURL())
    }

    func testIsConfirmationPage() {
        let confirmationURL = URL(string: "https://shopify.com/thank-you")!
        let legacyConfirmationURL = URL(string: "https://shopify.com/thank_you")!
        let nonConfirmationURL = URL(string: "https://shopify.com/checkout")!

        XCTAssertTrue(CheckoutURL(from: confirmationURL).isConfirmationPage())
        XCTAssertTrue(CheckoutURL(from: legacyConfirmationURL).isConfirmationPage())
        XCTAssertFalse(CheckoutURL(from: nonConfirmationURL).isConfirmationPage())
    }

    func testIsMailOrTelLink() {
        let mailURL = URL(string: "mailto:someone@shopify.com")!
        let telURL = URL(string: "tel:+1234567890")!
        let httpURL = URL(string: "https://shopify.com")!

        XCTAssertTrue(CheckoutURL(from: mailURL).isMailOrTelLink())
        XCTAssertTrue(CheckoutURL(from: telURL).isMailOrTelLink())
        XCTAssertFalse(CheckoutURL(from: httpURL).isMailOrTelLink())
    }

    func testIsDeepLink() {
        let secureURL = URL(string: "https://shopify.com")!
        let nonSecureURL = URL(string: "http://shopify.com")!
        let deeplink = URL(string: "app://deep/link")!

        XCTAssertFalse(CheckoutURL(from: secureURL).isDeepLink())
        XCTAssertFalse(CheckoutURL(from: nonSecureURL).isDeepLink())
        XCTAssertTrue(CheckoutURL(from: deeplink).isDeepLink())
    }
}
