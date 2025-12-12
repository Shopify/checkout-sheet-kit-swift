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

/// Event triggered when the checkout requests address change.
/// This allows native apps to provide address selection.
public struct CheckoutAddressChangeStartEvent: CheckoutRequest, CheckoutRequestDecodable {
    public typealias Params = CheckoutAddressChangeStartParams
    public typealias ResponsePayload = CheckoutAddressChangeStartResponsePayload
    public static let method = "checkout.addressChangeStart"
    internal final class AddressChangeRequest: BaseRPCRequest<Params, ResponsePayload> {
        override static var method: String { CheckoutAddressChangeStartEvent.method }
    }

    typealias Request = AddressChangeRequest
    var rpcRequest: Request

    public var id: String { rpcRequest.id }
    public var addressType: String { rpcRequest.params.addressType }
    public var cart: Cart { rpcRequest.params.cart }

    public func respondWith(payload: ResponsePayload) throws {
        try rpcRequest.respondWith(payload: payload)
    }

    public func respondWith(json jsonString: String) throws {
        try rpcRequest.respondWith(json: jsonString)
    }
}

public struct CheckoutAddressChangeStartParams: Codable {
    let addressType: String
    let cart: Cart
}

public struct CheckoutAddressChangeStartResponsePayload: Codable {
    public private(set) var cart: Cart?
    public private(set) var errors: [ResponseError]?

    public init(cart: Cart? = nil, errors: [ResponseError]? = nil) {
        self.cart = cart
        self.errors = errors
    }
}

// MARK: - Testing Support

extension CheckoutAddressChangeStartEvent {
    /// Creates a test instance for unit testing purposes.
    /// - Parameters:
    ///   - id: The request ID
    ///   - addressType: The type of address being changed (e.g., "shipping", "billing")
    ///   - cart: The cart associated with the address change
    /// - Returns: A test instance of CheckoutAddressChangeStartEvent
    /// - Note: Only use in test targets
    public static func testInstance(
        id: String,
        addressType: String,
        cart: Cart
    ) -> CheckoutAddressChangeStartEvent {
        let params = CheckoutAddressChangeStartParams(addressType: addressType, cart: cart)
        let request = AddressChangeRequest(id: id, params: params)
        return CheckoutAddressChangeStartEvent(rpcRequest: request)
    }
}
