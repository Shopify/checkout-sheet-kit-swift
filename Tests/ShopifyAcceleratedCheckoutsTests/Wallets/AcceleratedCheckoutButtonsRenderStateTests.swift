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
import SwiftUI
import XCTest

@available(iOS 17.0, *)
final class AcceleratedCheckoutButtonsRenderStateTests: XCTestCase {
    // MARK: - Render State Change Callback Tests

    func testOnRenderStateChange_CalledWithErrorStateForInvalidCartID() {
        // Given: Invalid cart ID and expectation for callback
        let invalidCartID = "invalid-cart-id"
        let expectation = XCTestExpectation(description: "onRenderStateChange called with error state")
        var receivedStates: [RenderState] = []

        // When: Creating AcceleratedCheckoutButtons with invalid ID and onRenderStateChange in SwiftUI environment
        let testView = AcceleratedCheckoutButtons(cartID: invalidCartID)
            .onRenderStateChange { state in
                receivedStates.append(state)
                if state == .error {
                    expectation.fulfill()
                }
            }
            .environment(ShopifyAcceleratedCheckouts.Configuration.testConfiguration)

        // Render the view to trigger onAppear
        let hostingController = UIHostingController(rootView: testView)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = hostingController
        window.makeKeyAndVisible()

        // Then: Callback should eventually be called with error state
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(receivedStates.contains(.error), "onRenderStateChange should be called with .error state for invalid cart ID")
    }

    func testOnRenderStateChange_CalledWithErrorStateForEmptyCartID() {
        // Given: Empty cart ID and expectation for callback
        let emptyCartID = ""
        let expectation = XCTestExpectation(description: "onRenderStateChange called with error state")
        var receivedStates: [RenderState] = []

        // When: Creating AcceleratedCheckoutButtons with empty cart ID in SwiftUI environment
        let testView = AcceleratedCheckoutButtons(cartID: emptyCartID)
            .onRenderStateChange { state in
                receivedStates.append(state)
                if state == .error {
                    expectation.fulfill()
                }
            }
            .environment(ShopifyAcceleratedCheckouts.Configuration.testConfiguration)

        // Render the view to trigger onAppear
        let hostingController = UIHostingController(rootView: testView)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = hostingController
        window.makeKeyAndVisible()

        // Then: Callback should be called with error state
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(receivedStates.contains(.error), "onRenderStateChange should be called with .error state for empty cart ID")
    }

    func testOnRenderStateChange_CalledWithErrorStateForInvalidVariantID() {
        // Given: Invalid variant ID and expectation for callback
        let invalidVariantID = "invalid-variant-id"
        let expectation = XCTestExpectation(description: "onRenderStateChange called with error state")
        var receivedStates: [RenderState] = []

        // When: Creating AcceleratedCheckoutButtons with invalid variant ID in SwiftUI environment
        let testView = AcceleratedCheckoutButtons(variantID: invalidVariantID, quantity: 1)
            .onRenderStateChange { state in
                receivedStates.append(state)
                if state == .error {
                    expectation.fulfill()
                }
            }
            .environment(ShopifyAcceleratedCheckouts.Configuration.testConfiguration)

        // Render the view to trigger onAppear
        let hostingController = UIHostingController(rootView: testView)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = hostingController
        window.makeKeyAndVisible()

        // Then: Callback should be called with error state
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(receivedStates.contains(.error), "onRenderStateChange should be called with .error state for invalid variant ID")
    }

    func testOnRenderStateChange_CalledWithErrorStateForZeroQuantity() {
        // Given: Valid variant ID but zero quantity
        let validVariantID = "gid://shopify/ProductVariant/test-variant-id"
        let expectation = XCTestExpectation(description: "onRenderStateChange called with error state")
        var receivedStates: [RenderState] = []

        // When: Creating AcceleratedCheckoutButtons with zero quantity in SwiftUI environment
        let testView = AcceleratedCheckoutButtons(variantID: validVariantID, quantity: 0)
            .onRenderStateChange { state in
                receivedStates.append(state)
                if state == .error {
                    expectation.fulfill()
                }
            }
            .environment(ShopifyAcceleratedCheckouts.Configuration.testConfiguration)

        // Render the view to trigger onAppear
        let hostingController = UIHostingController(rootView: testView)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = hostingController
        window.makeKeyAndVisible()

        // Then: Callback should be called with error state
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(receivedStates.contains(.error), "onRenderStateChange should be called with .error state for zero quantity")
    }

    func testOnRenderStateChange_CalledWithLoadingStateForValidCartID() {
        // Given: Valid cart ID and expectation for callback
        let validCartID = "gid://shopify/Cart/test-cart-id"
        let expectation = XCTestExpectation(description: "onRenderStateChange called with loading state")
        var receivedStates: [RenderState] = []

        // When: Creating AcceleratedCheckoutButtons with valid cart ID in SwiftUI environment
        let testView = AcceleratedCheckoutButtons(cartID: validCartID)
            .onRenderStateChange { state in
                receivedStates.append(state)
                if state == .loading {
                    expectation.fulfill()
                }
            }
            .environment(ShopifyAcceleratedCheckouts.Configuration.testConfiguration)

        // Render the view to trigger onAppear
        let hostingController = UIHostingController(rootView: testView)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = hostingController
        window.makeKeyAndVisible()

        // Then: Callback should be called with loading state initially
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(receivedStates.contains(.loading), "onRenderStateChange should be called with .loading state for valid cart ID")
    }

    func testOnRenderStateChange_CalledWithLoadingStateForValidVariantID() {
        // Given: Valid variant ID and expectation for callback
        let validVariantID = "gid://shopify/ProductVariant/test-variant-id"
        let expectation = XCTestExpectation(description: "onRenderStateChange called with loading state")
        var receivedStates: [RenderState] = []

        // When: Creating AcceleratedCheckoutButtons with valid variant ID in SwiftUI environment
        let testView = AcceleratedCheckoutButtons(variantID: validVariantID, quantity: 2)
            .onRenderStateChange { state in
                receivedStates.append(state)
                if state == .loading {
                    expectation.fulfill()
                }
            }
            .environment(ShopifyAcceleratedCheckouts.Configuration.testConfiguration)

        // Render the view to trigger onAppear
        let hostingController = UIHostingController(rootView: testView)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = hostingController
        window.makeKeyAndVisible()

        // Then: Callback should be called with loading state initially
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(receivedStates.contains(.loading), "onRenderStateChange should be called with .loading state for valid variant ID")
    }

    // MARK: - Identifier Validation Tests

    func testCheckoutIdentifier_ValidCartIDFormats() {
        // Test valid cart ID formats
        let validCartIDs = [
            "gid://shopify/Cart/test-id",
            "gid://Shopify/Cart/Z2NwLXVzLWV4YW1wbGU6MDEyMzQ1Njc4OTAxMjM0NTY3ODkw?key=example",
            "GID://SHOPIFY/CART/uppercase-test"
        ]

        for cartID in validCartIDs {
            let identifier = CheckoutIdentifier.cart(cartID: cartID)
            XCTAssertTrue(identifier.parse().isValid(), "Cart ID '\(cartID)' should be valid")
        }
    }

    func testCheckoutIdentifier_InvalidCartIDFormats() {
        // Test invalid cart ID formats
        let invalidCartIDs = [
            "",
            "invalid-cart-id",
            "cart/test-id",
            "gid://shopify/Product/test-id", // Wrong type
            "gid://other/Cart/test-id" // Wrong platform
        ]

        for cartID in invalidCartIDs {
            let identifier = CheckoutIdentifier.cart(cartID: cartID)
            XCTAssertFalse(identifier.parse().isValid(), "Cart ID '\(cartID)' should be invalid")
        }
    }

    func testCheckoutIdentifier_ValidVariantIDFormats() {
        // Test valid variant ID formats
        let validVariantIDs = [
            "gid://shopify/ProductVariant/test-id",
            "gid://Shopify/ProductVariant/Z2NwLXVzLWV4YW1wbGU6MDEyMzQ1Njc4OTAxMjM0NTY3ODkw",
            "GID://SHOPIFY/PRODUCTVARIANT/uppercase-test"
        ]

        for variantID in validVariantIDs {
            let identifier = CheckoutIdentifier.variant(variantID: variantID, quantity: 1)
            XCTAssertTrue(identifier.parse().isValid(), "Variant ID '\(variantID)' should be valid")
        }
    }

    func testCheckoutIdentifier_InvalidVariantIDFormats() {
        // Test invalid variant ID formats
        let invalidVariantIDs = [
            "",
            "invalid-variant-id",
            "variant/test-id",
            "gid://shopify/Product/test-id", // Wrong type
            "gid://other/ProductVariant/test-id" // Wrong platform
        ]

        for variantID in invalidVariantIDs {
            let identifier = CheckoutIdentifier.variant(variantID: variantID, quantity: 1)
            XCTAssertFalse(identifier.parse().isValid(), "Variant ID '\(variantID)' should be invalid")
        }
    }

    func testCheckoutIdentifier_InvalidQuantity() {
        // Test that zero or negative quantities are invalid
        let validVariantID = "gid://shopify/ProductVariant/test-id"

        let zeroQuantityIdentifier = CheckoutIdentifier.variant(variantID: validVariantID, quantity: 0)
        XCTAssertFalse(zeroQuantityIdentifier.parse().isValid(), "Zero quantity should be invalid")

        let negativeQuantityIdentifier = CheckoutIdentifier.variant(variantID: validVariantID, quantity: -1)
        XCTAssertFalse(negativeQuantityIdentifier.parse().isValid(), "Negative quantity should be invalid")
    }

    // MARK: - Render State Enum Tests

    func testRenderStateEnum_HasExpectedValues() {
        // Test that all expected render states exist and are distinct
        let loadingState: RenderState = .loading
        let renderedState: RenderState = .rendered
        let errorState: RenderState = .error

        XCTAssertNotEqual(loadingState, renderedState)
        XCTAssertNotEqual(loadingState, errorState)
        XCTAssertNotEqual(renderedState, errorState)
    }

    func testRenderStateEnum_CaseIterable() {
        // Test that we can iterate over all render states
        let allStates: [RenderState] = [.loading, .rendered, .error]

        XCTAssertEqual(allStates.count, 3, "Should have exactly 3 render states")
        XCTAssertTrue(allStates.contains(.loading), "Should contain .loading state")
        XCTAssertTrue(allStates.contains(.rendered), "Should contain .rendered state")
        XCTAssertTrue(allStates.contains(.error), "Should contain .error state")
    }
}
