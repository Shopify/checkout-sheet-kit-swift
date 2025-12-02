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

/// RPC request for payment method change start events from checkout.
///
/// This event is triggered when the buyer initiates a payment method change in checkout.
/// The app can respond with updated payment method information.
public final class CheckoutPaymentMethodChangeStart: CheckoutRequest, RPCMessage {
    private let rpcRequest: BaseRPCRequest<CheckoutPaymentMethodChangeStartParams, CheckoutPaymentMethodChangeStartResponsePayload>

    public static let method: String = "checkout.paymentMethodChangeStart"
    public var method: String { Self.method }
    public var id: String { rpcRequest.id }
    public var params: CheckoutPaymentMethodChangeStartParams { rpcRequest.params }

    internal init(rpcRequest: BaseRPCRequest<CheckoutPaymentMethodChangeStartParams, CheckoutPaymentMethodChangeStartResponsePayload>) {
        self.rpcRequest = rpcRequest
    }

    // MARK: - RPCMessage conformance

    internal var jsonrpc: String { rpcRequest.jsonrpc }
    internal var isNotification: Bool { rpcRequest.isNotification }
    internal var webview: WKWebView? {
        get { rpcRequest.webview }
        set { rpcRequest.webview = newValue }
    }

    internal required init(id: String?, params: CheckoutPaymentMethodChangeStartParams) {
        self.rpcRequest = BaseRPCRequest(id: id, params: params)
    }

    public func respondWith(payload: CheckoutPaymentMethodChangeStartResponsePayload) throws {
        try rpcRequest.respondWith(payload: payload)
    }

    public func respondWith(json jsonString: String) throws {
        try rpcRequest.respondWith(json: jsonString)
    }

    public func respondWith(error: String) throws {
        try rpcRequest.respondWith(error: error)
    }
}

// MARK: - TypeErasedRPCDecodable conformance
extension CheckoutPaymentMethodChangeStart: TypeErasedRPCDecodable {
    static func decodeErased(from data: Data) throws -> any RPCMessage {
        return try JSONDecoder().decode(CheckoutPaymentMethodChangeStart.self, from: data)
    }
}

public struct CheckoutPaymentMethodChangeStartParams: Codable {
    public let cart: Cart
}

public struct CheckoutPaymentMethodChangeStartResponsePayload: Codable {
    public let cart: CartInput?
    public let errors: [ResponseError]?

    public init(cart: CartInput? = nil, errors: [ResponseError]? = nil) {
        self.cart = cart
        self.errors = errors
    }
}
