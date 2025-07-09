//
//  StorefrontAPI+Errors.swift
//  ShopifyAcceleratedCheckouts
//
//  Created by Kieran Barrie Osgood on 08/07/2025.
//

import Foundation

@available(iOS 17.0, *)
extension StorefrontAPI {
    enum CartApiPayload {
        case cartPrepareForCompletion(StorefrontAPI.CartPrepareForCompletionPayload)
        case cartSubmitForCompletion(StorefrontAPI.CartSubmitForCompletionPayload)
    }

    enum WarningType {
        case outOfStock
        case notEnoughStock
    }

    enum Errors: LocalizedError {
        case payload(propertyName: String)
        case notImplemented
        case userError(userErrors: [StorefrontAPI.CartUserError], cart: StorefrontAPI.Types.Cart?)
        case invariant(message: String)
        case response(requestName: String, message: String, payload: CartApiPayload)
        case nilCart(requestName: String)
        case currencyChanged
        case warning(type: WarningType, cart: StorefrontAPI.Types.Cart?)

        var failureReason: String? {
            switch self {
            case let .invariant(message): message
            case .notImplemented: "NOT_IMPLEMENTED"
            case let .payload(propertyName):
                "Request Payload failed to unwrap property: \(propertyName)"
            case let .response(requestName, message, _):
                "Request: \(requestName) Failed. Message: \(message)"
            case let .userError(userErrors, _):
                "Request failed with \(userErrors.count) userErrors."
            case let .nilCart(requestName):
                "Request: \(requestName) failed. Cart is nil"
            case .currencyChanged:
                "The currency has changed since the cart was created"
            case let .warning(type, _):
                "Request failed with \(type) warning."
            }
        }

        var recoverySuggestion: String? {
            switch self {
            case .notImplemented: "Check the implementation of the method"
            case let .payload(propertyName):
                "Check the previous request had a property named: \(propertyName)"
            case let .response(requestName, _, _):
                "Check the API payload for more details: \(requestName)"
            case .invariant: ""
            case let .userError(userErrors, _):
                userErrors
                    .map { "[Field: \(String(describing: $0.field))] [Message: \($0.message)]" }
                    .joined(separator: "\n")
            case let .nilCart(requestName):
                "Check the API payload for more details: \(requestName)"
            case .currencyChanged:
                "The currency has changed since the cart was created"
            case let .warning(type, _):
                "Address the \(type) warning and try again"
            }
        }
    }
}
