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

/// Internal RPC request class for submit start
internal class CheckoutSubmitStartRPCRequest: BaseRPCRequest<
    CheckoutSubmitStart.Params,
    CheckoutSubmitStartResponsePayload
> {
    override class var method: String { "checkout.submitStart" }
}

/// Event triggered when the checkout submit process starts.
/// This allows native apps to provide payment tokens or modify the cart before submission.
public struct CheckoutSubmitStart: CheckoutRequestInternal, CheckoutRequestDecodable {
    public typealias ResponsePayload = CheckoutSubmitStartResponsePayload

    public static let method = "checkout.submitStart"

    public var id: String { rpcRequest.id ?? "" }
    public var cart: Cart { rpcRequest.params.cart }
    public var checkout: Checkout { rpcRequest.params.checkout }

    internal let rpcRequest: CheckoutSubmitStartRPCRequest

    internal init(rpcRequest: CheckoutSubmitStartRPCRequest) {
        self.rpcRequest = rpcRequest
    }

    var _internalRPCRequest: (any RPCRequest)? { rpcRequest }

    internal struct Params: Codable {
        let cart: Cart
        let checkout: Checkout
    }

    internal static func decode(from data: Data, webview: WKWebView) throws -> CheckoutSubmitStart {
        let rpcRequest = try JSONDecoder().decode(CheckoutSubmitStartRPCRequest.self, from: data)
        rpcRequest.webview = webview
        return CheckoutSubmitStart(rpcRequest: rpcRequest)
    }
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
