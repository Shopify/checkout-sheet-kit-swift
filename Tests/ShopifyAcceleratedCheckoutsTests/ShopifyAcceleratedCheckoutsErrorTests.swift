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

@available(iOS 16.0, *)
final class ShopifyAcceleratedCheckoutsErrorTests: XCTestCase {
    // MARK: - cartAcquisition Error Tests

    func test_cartAcquisitionError_withAllIdentifierTypes_shouldGenerateCorrectErrorMessages() {
        struct TestCase {
            let identifier: CheckoutIdentifier
            let underlyingError: Error?
            let expectedErrorPattern: String
            let description: String
        }

        let networkError = NSError(domain: "NetworkError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Network failed"])

        let testCases: [TestCase] = [
            TestCase(
                identifier: .cart(cartID: "gid://Shopify/Cart/test-id"),
                underlyingError: nil,
                expectedErrorPattern: "unable to get cart for CheckoutIdentifier: cart(cartID: \"gid://Shopify/Cart/test-id\") error: nil",
                description: "cart identifier without error"
            ),
            TestCase(
                identifier: .cart(cartID: "gid://Shopify/Cart/test-id"),
                underlyingError: networkError,
                expectedErrorPattern: "unable to get cart for CheckoutIdentifier: cart(cartID: \"gid://Shopify/Cart/test-id\") error: Optional(\"Network failed\")",
                description: "cart identifier with error"
            ),
            TestCase(
                identifier: .variant(variantID: "gid://Shopify/ProductVariant/test-id", quantity: 2),
                underlyingError: nil,
                expectedErrorPattern: "unable to get cart for CheckoutIdentifier: variant(variantID: \"gid://Shopify/ProductVariant/test-id\", quantity: 2) error: nil",
                description: "variant identifier without error"
            ),
            TestCase(
                identifier: .variant(variantID: "gid://Shopify/ProductVariant/test-id", quantity: 2),
                underlyingError: networkError,
                expectedErrorPattern: "unable to get cart for CheckoutIdentifier: variant(variantID: \"gid://Shopify/ProductVariant/test-id\", quantity: 2) error: Optional(\"Network failed\")",
                description: "variant identifier with error"
            ),
            TestCase(
                identifier: .invariant(reason: "Invalid checkout data"),
                underlyingError: nil,
                expectedErrorPattern: "unable to get cart for CheckoutIdentifier: invariant(reason: \"Invalid checkout data\") error: nil",
                description: "invariant identifier without error"
            )
        ]

        for testCase in testCases {
            let error = ShopifyAcceleratedCheckouts.Error.cartAcquisition(identifier: testCase.identifier, error: testCase.underlyingError)
            let errorString = error.toString()
            XCTAssertEqual(errorString, testCase.expectedErrorPattern, "Failed for \(testCase.description)")
        }
    }

    // MARK: - invariant Error Tests

    func test_invariantError_withExpectedValue_shouldGenerateCorrectErrorMessage() {
        let error = ShopifyAcceleratedCheckouts.Error.invariant(expected: "valid cart")

        let errorString = error.toString()
        XCTAssertEqual(errorString, "received nil, expected: valid cart")
    }
}
