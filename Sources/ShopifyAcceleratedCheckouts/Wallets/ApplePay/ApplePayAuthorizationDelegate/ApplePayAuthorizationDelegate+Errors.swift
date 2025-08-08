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

import PassKit

/// NOTE: localizedDescriptions should be under 128 characters to avoid truncation
/// https://developer.apple.com/design/human-interface-guidelines/apple-pay/
@available(iOS 16.0, *)
extension ApplePayAuthorizationDelegate {
    enum ValidationErrors {
        static func emailInvalid(message: String) -> Error {
            return PKPaymentRequest.paymentContactInvalidError(
                withContactField: PKContactField.emailAddress,
                localizedDescription: message
            )
        }

        static func phoneNumberInvalid(message: String) -> Error {
            return PKPaymentRequest.paymentContactInvalidError(
                withContactField: PKContactField.phoneNumber,
                localizedDescription: message
            )
        }

        static func nameInvalid(message: String) -> Error {
            return PKPaymentRequest.paymentContactInvalidError(
                withContactField: PKContactField.name,
                localizedDescription: message
            )
        }

        static func deliveryAddressInvalid(field: String, message: String) -> Error {
            return PKPaymentRequest.paymentShippingAddressInvalidError(
                withKey: field,
                localizedDescription: message
            )
        }

        static func billingAddressInvalid(field: String, message: String) -> Error {
            return PKPaymentRequest.paymentBillingAddressInvalidError(
                withKey: field,
                localizedDescription: message
            )
        }

        static let addressUnserviceableError = PKPaymentError(
            .shippingAddressUnserviceableError)
    }
}
