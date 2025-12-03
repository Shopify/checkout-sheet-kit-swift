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

import Foundation
import WebKit

/// Event triggered when the checkout requests payment method change.
/// This allows native apps to provide payment method selection.
public struct CheckoutPaymentMethodChangeStartEvent: CheckoutRequest, CheckoutRequestDecodable {
    public typealias Params = CheckoutPaymentMethodChangeStartParams
    public typealias ResponsePayload = CheckoutPaymentMethodChangeStartResponsePayload

    public static let method = "checkout.paymentMethodChangeStart"
    public var id: String { rpcRequest.id }
    public var cart: Cart { rpcRequest.params.cart }

    internal let rpcRequest: Request

    internal init(rpcRequest: Request) {
        self.rpcRequest = rpcRequest
    }

    public func respondWith(payload: ResponsePayload) throws {
        try rpcRequest.respondWith(payload: payload)
    }

    public func respondWith(json jsonString: String) throws {
        try rpcRequest.respondWith(json: jsonString)
    }

    public func respondWith(error: String) throws {
        try rpcRequest.respondWith(error: error)
    }

    internal static func decode(from data: Data, webview: WKWebView) throws -> CheckoutPaymentMethodChangeStartEvent {
        let rpcRequest = try JSONDecoder().decode(Request.self, from: data)
        rpcRequest.webview = webview
        return CheckoutPaymentMethodChangeStartEvent(rpcRequest: rpcRequest)
    }
}

public struct CheckoutPaymentMethodChangeStartParams: Codable {
    let cart: Cart
}

public struct CheckoutPaymentMethodChangeStartResponsePayload: Codable {
    public let cart: CartInput?
    public let errors: [ResponseError]?

    public init(cart: CartInput? = nil, errors: [ResponseError]? = nil) {
        self.cart = cart
        self.errors = errors
    }
}
