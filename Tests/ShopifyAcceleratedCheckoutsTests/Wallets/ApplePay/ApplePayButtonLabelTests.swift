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

@testable import ShopifyAcceleratedCheckouts
import XCTest

@available(iOS 17.0, *)
final class ApplePayButtonLabelTests: XCTestCase {
    func testAllCasesHaveStringRepresentations() {
        for label in ApplePayButtonLabel.allCases {
            let reconstructedLabel: ApplePayButtonLabel?

            switch label {
            case .plain: reconstructedLabel = ApplePayButtonLabel(string: "plain")
            case .buy: reconstructedLabel = ApplePayButtonLabel(string: "buy")
            case .addMoney: reconstructedLabel = ApplePayButtonLabel(string: "addmoney")
            case .book: reconstructedLabel = ApplePayButtonLabel(string: "book")
            case .checkout: reconstructedLabel = ApplePayButtonLabel(string: "checkout")
            case .continue: reconstructedLabel = ApplePayButtonLabel(string: "continue")
            case .contribute: reconstructedLabel = ApplePayButtonLabel(string: "contribute")
            case .donate: reconstructedLabel = ApplePayButtonLabel(string: "donate")
            case .inStore: reconstructedLabel = ApplePayButtonLabel(string: "instore")
            case .order: reconstructedLabel = ApplePayButtonLabel(string: "order")
            case .reload: reconstructedLabel = ApplePayButtonLabel(string: "reload")
            case .rent: reconstructedLabel = ApplePayButtonLabel(string: "rent")
            case .setUp: reconstructedLabel = ApplePayButtonLabel(string: "setup")
            case .subscribe: reconstructedLabel = ApplePayButtonLabel(string: "subscribe")
            case .support: reconstructedLabel = ApplePayButtonLabel(string: "support")
            case .tip: reconstructedLabel = ApplePayButtonLabel(string: "tip")
            case .topUp: reconstructedLabel = ApplePayButtonLabel(string: "topup")
            }

            XCTAssertNotNil(reconstructedLabel, "Label \(label) should have a string representation")
            XCTAssertEqual(reconstructedLabel, label, "String conversion should round-trip correctly for \(label)")
        }
    }

    func testStringInitializerCaseInsensitive() {
        XCTAssertEqual(ApplePayButtonLabel(string: "BUY"), .buy)
        XCTAssertEqual(ApplePayButtonLabel(string: "Buy"), .buy)
        XCTAssertEqual(ApplePayButtonLabel(string: "buy"), .buy)
    }

    func testStringInitializerIgnoresNonLetters() {
        XCTAssertEqual(ApplePayButtonLabel(string: "add-money"), .addMoney)
        XCTAssertEqual(ApplePayButtonLabel(string: "add_money"), .addMoney)
        XCTAssertEqual(ApplePayButtonLabel(string: "add money"), .addMoney)
        XCTAssertEqual(ApplePayButtonLabel(string: "set up"), .setUp)
        XCTAssertEqual(ApplePayButtonLabel(string: "set-up"), .setUp)
        XCTAssertEqual(ApplePayButtonLabel(string: "top_up"), .topUp)
        XCTAssertEqual(ApplePayButtonLabel(string: "in store"), .inStore)
    }

    func testStringInitializerReturnsNilForUnknown() {
        XCTAssertNil(ApplePayButtonLabel(string: "unknown"))
        XCTAssertNil(ApplePayButtonLabel(string: "invalid"))
        XCTAssertNil(ApplePayButtonLabel(string: ""))
    }

    func testFromStaticMethodWithDefault() {
        XCTAssertEqual(ApplePayButtonLabel.from("buy"), .buy)
        XCTAssertEqual(ApplePayButtonLabel.from("unknown"), .plain)
        XCTAssertEqual(ApplePayButtonLabel.from("unknown", default: .checkout), .checkout)
        XCTAssertEqual(ApplePayButtonLabel.from(nil), .plain)
        XCTAssertEqual(ApplePayButtonLabel.from(nil, default: .buy), .buy)
    }
}
