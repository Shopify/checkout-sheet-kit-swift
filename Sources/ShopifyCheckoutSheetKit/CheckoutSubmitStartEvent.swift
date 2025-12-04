Sources/ShopifyCheckoutSheetKit/CheckoutSubmitStartEvent.swift/*
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

import Foundation
import WebKit

/// Event triggered when the checkout submit process starts.
/// This allows native apps to provide payment tokens or modify the cart before submission.
public struct CheckoutSubmitStartEvent: CheckoutRequest, CheckoutRequestDecodable {
    public typealias Params = CheckoutSubmitStartParams
    public typealias ResponsePayload = CheckoutSubmitStartResponsePayload

    public static let method = "checkout.submitStart"

    internal final class SubmitStartRequest: BaseRPCRequest<Params, ResponsePayload> {
        override static var method: String { CheckoutSubmitStartEvent.method }
    }

    typealias Request = SubmitStartRequest

    public var id: String { rpcRequest.id }
    public var cart: Cart { rpcRequest.params.cart }
    public var checkout: Checkout { rpcRequest.params.checkout }

    internal let rpcRequest: Request

    public func respondWith(payload: ResponsePayload) throws {
        try rpcRequest.respondWith(payload: payload)
    }

    public func respondWith(json jsonString: String) throws {
        try rpcRequest.respondWith(json: jsonString)
    }
}

public struct CheckoutSubmitStartParams: Codable {
    let cart: Cart
    let checkout: Checkout
}

public struct CheckoutSubmitStartResponsePayload: Codable {
    public let payment: PaymentTokenInput?
    public let cart: CartInput?
    public let errors: [ResponseError]?

    public init(payment: PaymentTokenInput? = nil, cart: CartInput? = nil, errors: [ResponseError]? = nil) {
        self.payment = payment
        self.cart = cart
        self.errors = errors
    }
}

// MARK: - Testing Support

extension CheckoutSubmitStartEvent {
    /// Creates a test instance for unit testing purposes.
    /// - Parameters:
    ///   - id: The request ID
    ///   - cart: The cart being submitted
    ///   - checkout: The checkout session information
    /// - Returns: A test instance of CheckoutSubmitStartEvent
    /// - Note: Only use in test targets
    public static func testInstance(
        id: String,
        cart: Cart,
        checkout: Checkout
    ) -> CheckoutSubmitStartEvent {
        let params = CheckoutSubmitStartParams(cart: cart, checkout: checkout)
        let request = SubmitStartRequest(id: id, params: params)
        return CheckoutSubmitStartEvent(rpcRequest: request)
    }
}
