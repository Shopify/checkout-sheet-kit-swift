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

public enum CheckoutErrorCode: Codable, Equatable {
    case invalidPayload
    case invalidSignature
    case notAuthorized
    case payloadExpired
    case customerAccountRequired
    case storefrontPasswordRequired
    case cartCompleted
    case invalidCart
    case killswitchEnabled
    case unrecoverableFailure
    case policyViolation
    case vaultedPaymentError
    case unknown(String)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)

        switch rawValue {
        case "INVALID_PAYLOAD": self = .invalidPayload
        case "INVALID_SIGNATURE": self = .invalidSignature
        case "NOT_AUTHORIZED": self = .notAuthorized
        case "PAYLOAD_EXPIRED": self = .payloadExpired
        case "CUSTOMER_ACCOUNT_REQUIRED": self = .customerAccountRequired
        case "STOREFRONT_PASSWORD_REQUIRED": self = .storefrontPasswordRequired
        case "CART_COMPLETED": self = .cartCompleted
        case "INVALID_CART": self = .invalidCart
        case "KILLSWITCH_ENABLED": self = .killswitchEnabled
        case "UNRECOVERABLE_FAILURE": self = .unrecoverableFailure
        case "POLICY_VIOLATION": self = .policyViolation
        case "VAULTED_PAYMENT_ERROR": self = .vaultedPaymentError
        default: self = .unknown(rawValue)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .invalidPayload: try container.encode("INVALID_PAYLOAD")
        case .invalidSignature: try container.encode("INVALID_SIGNATURE")
        case .notAuthorized: try container.encode("NOT_AUTHORIZED")
        case .payloadExpired: try container.encode("PAYLOAD_EXPIRED")
        case .customerAccountRequired: try container.encode("CUSTOMER_ACCOUNT_REQUIRED")
        case .storefrontPasswordRequired: try container.encode("STOREFRONT_PASSWORD_REQUIRED")
        case .cartCompleted: try container.encode("CART_COMPLETED")
        case .invalidCart: try container.encode("INVALID_CART")
        case .killswitchEnabled: try container.encode("KILLSWITCH_ENABLED")
        case .unrecoverableFailure: try container.encode("UNRECOVERABLE_FAILURE")
        case .policyViolation: try container.encode("POLICY_VIOLATION")
        case .vaultedPaymentError: try container.encode("VAULTED_PAYMENT_ERROR")
        case .unknown(let value): try container.encode(value)
        }
    }
}

public enum CheckoutUnavailable {
    case clientError(code: CheckoutErrorCode)
    case httpError(statusCode: Int)
}

/// A type representing Shopify Checkout specific errors.
/// "recoverable" indicates that though the request has failed, it should be retried in a fallback browser experience.
public enum CheckoutError: Swift.Error {
    /// Issued when an internal error within Shopify Checkout SDK
    /// In event of an sdkError you could use the stacktrace to inform you of how to proceed,
    /// if the issue persists, it is recommended to open a bug report in http://github.com/Shopify/checkout-sheet-kit-swift
    case sdkError(underlying: Swift.Error, recoverable: Bool = true)

    /// Issued when the storefront configuration has caused an error.
    /// Note that the Checkout Sheet Kit only supports stores migrated for extensibility.
    case configurationError(message: String, code: CheckoutErrorCode, recoverable: Bool = false)

    /// Issued when checkout has encountered a unrecoverable error (for example server side error)
    /// if the issue persists, it is recommended to open a bug report in http://github.com/Shopify/checkout-sheet-kit-swift
    case checkoutUnavailable(message: String, code: CheckoutUnavailable, recoverable: Bool)

    /// Issued when checkout is no longer available and will no longer be available with the checkout url supplied.
    /// This may happen when the user has paused on checkout for a long period (hours) and then attempted to proceed again with the same checkout url
    /// In event of checkoutExpired, a new checkout url will need to be generated
    case checkoutExpired(message: String, code: CheckoutErrorCode, recoverable: Bool = false)

    public var isRecoverable: Bool {
        switch self {
        case .checkoutExpired(_, _, let recoverable),
            .checkoutUnavailable(_, _, let recoverable),
            .configurationError(_, _, let recoverable),
            .sdkError(_, let recoverable):
            return recoverable
        }
    }
}

public struct CheckoutErrorEvent: CheckoutNotification {
    public static let method = "checkout.error"
    public let code: CheckoutErrorCode
    public let message: String

    public init(code: CheckoutErrorCode, message: String) {
        self.code = code
        self.message = message
    }
}
