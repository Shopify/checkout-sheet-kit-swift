//
//  ApplePayAuthorizationDelegate+Errors.swift
//  ShopifyAcceleratedCheckouts
//
//  Created by Kieran Barrie Osgood on 05/06/2025.
//

import PassKit

/// NOTE: localizedDescriptions should be under 128 characters to avoid truncation
/// https://developer.apple.com/design/human-interface-guidelines/apple-pay/
@available(iOS 17.0, *)
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
