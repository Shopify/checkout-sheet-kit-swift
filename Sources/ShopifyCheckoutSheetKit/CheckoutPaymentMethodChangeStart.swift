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

public final class CheckoutPaymentMethodChangeStart: BaseRPCRequest<CheckoutPaymentMethodChangeStartParams, CheckoutPaymentMethodChangeStartResponsePayload> {
    override public static var method: String { "checkout.paymentMethodChangeStart" }

    override public func validate(payload: ResponsePayload) throws {
        guard let cart = payload.cart else {
            return
        }

        guard let instruments = cart.paymentInstruments, !instruments.isEmpty else {
            return
        }

        for (index, instrument) in instruments.enumerated() {
            guard instrument.display.last4.count == 4 else {
                throw CheckoutEventResponseError.validationFailed(
                    "Payment instrument last4 must be exactly 4 characters at index \(index)"
                )
            }

            guard instrument.display.expiry.month >= 1, instrument.display.expiry.month <= 12 else {
                throw CheckoutEventResponseError.validationFailed(
                    "Payment instrument expiryMonth must be between 1 and 12 at index \(index)"
                )
            }

            if let countryCode = instrument.billingAddress.countryCode, !countryCode.isEmpty {
                guard countryCode.count == 2 else {
                    throw CheckoutEventResponseError.validationFailed(
                        "Country code must be exactly 2 characters (ISO 3166-1 alpha-2) at index \(index), got: '\(countryCode)'"
                    )
                }
            }
        }
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
