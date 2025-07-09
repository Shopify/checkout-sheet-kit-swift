//
//  ShopifyAcceleratedCheckouts+Errors.swift
//  ShopifyAcceleratedCheckouts
//
//  Created by Kieran Barrie Osgood on 02/07/2025.
//

import Foundation

extension ShopifyAcceleratedCheckouts {
    enum InvariantMessages: String {
        case nilCart = "cart is nil."
        case nilDisplayName = "displayName is nil."
        case nilPayment = "payment is nil."
        case nilPaymentData = "paymentData is nil."
        case nilEmail = "email is nil."
        case nilShippingMethodID = "shippingMethodID is nil."
        case nilShippingMethod = "shippingMethod is nil."
        case nilBillingAddress = "billingAddress is nil."
        case nilLastDigits = "lastDigits is nil."
        case nilPostalAddress = "postalAddress is nil."
        case nilBillingContact = "billingContact is nil."
        case nilShippingContact = "shippingContact is nil."
    }

    enum Error: LocalizedError {
        case invariant(message: InvariantMessages)

        func toString() -> String {
            switch self {
            case let .invariant(message):
                return message.rawValue
            }
        }
    }
}
