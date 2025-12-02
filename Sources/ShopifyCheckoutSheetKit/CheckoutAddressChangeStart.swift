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

/// RPC request for address change start events from checkout.
///
/// This event is triggered when the buyer initiates an address change in checkout.
/// The app can respond with updated address information.
public final class CheckoutAddressChangeStart: CheckoutRequest, RPCMessage {
    private let rpcRequest: BaseRPCRequest<CheckoutAddressChangeStartParams, CheckoutAddressChangeStartResponsePayload>

    public static let method: String = "checkout.addressChangeStart"
    public var method: String { Self.method }

    public var id: String { rpcRequest.id }
    public var params: CheckoutAddressChangeStartParams { rpcRequest.params }

    internal init(rpcRequest: BaseRPCRequest<CheckoutAddressChangeStartParams, CheckoutAddressChangeStartResponsePayload>) {
        self.rpcRequest = rpcRequest
        self.rpcRequest.validator = { [weak self] payload in
            try self?.validate(payload: payload)
        }
    }

    // MARK: - RPCMessage conformance

    internal var jsonrpc: String { rpcRequest.jsonrpc }
    internal var isNotification: Bool { rpcRequest.isNotification }
    internal var webview: WKWebView? {
        get { rpcRequest.webview }
        set { rpcRequest.webview = newValue }
    }

    internal required init(id: String?, params: CheckoutAddressChangeStartParams) {
        rpcRequest = BaseRPCRequest(id: id, params: params)
        rpcRequest.validator = { [weak self] payload in
            try self?.validate(payload: payload)
        }
    }

    public func respondWith(payload: CheckoutAddressChangeStartResponsePayload) throws {
        try rpcRequest.respondWith(payload: payload)
    }

    public func respondWith(json jsonString: String) throws {
        try rpcRequest.respondWith(json: jsonString)
    }

    public func respondWith(error: String) throws {
        try rpcRequest.respondWith(error: error)
    }

    internal func validate(payload: CheckoutAddressChangeStartResponsePayload) throws {
        guard let cart = payload.cart else {
            return
        }

        guard let addresses = cart.delivery?.addresses, !addresses.isEmpty else {
            throw CheckoutEventResponseError.validationFailed("At least one address is required in cart.delivery.addresses")
        }

        for (index, selectableAddress) in addresses.enumerated() {
            guard let countryCode = selectableAddress.address.countryCode, !countryCode.isEmpty else {
                throw CheckoutEventResponseError.validationFailed(
                    "Country code is required at index \(index)"
                )
            }

            if countryCode.count != 2 {
                throw CheckoutEventResponseError.validationFailed(
                    "Country code must be exactly 2 characters (ISO 3166-1 alpha-2) at index \(index), got: '\(countryCode)'"
                )
            }
        }
    }
}

// MARK: - TypeErasedRPCDecodable conformance

extension CheckoutAddressChangeStart: TypeErasedRPCDecodable {
    static func decodeErased(from data: Data) throws -> any RPCMessage {
        return try JSONDecoder().decode(CheckoutAddressChangeStart.self, from: data)
    }
}

public struct CheckoutAddressChangeStartParams: Codable {
    public let addressType: String
    public let cart: Cart
}

public struct CheckoutAddressChangeStartResponsePayload: Codable {
    public let cart: CartInput?
    public let errors: [ResponseError]?

    public init(cart: CartInput? = nil, errors: [ResponseError]? = nil) {
        self.cart = cart
        self.errors = errors
    }
}
