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

public enum CheckoutErrorCode: String, Codable {
    case invalidPayload = "INVALID_PAYLOAD"
    case invalidSignature = "INVALID_SIGNATURE"
    case notAuthorized = "NOT_AUTHORIZED"
    case payloadExpired = "PAYLOAD_EXPIRED"
    case customerAccountRequired = "CUSTOMER_ACCOUNT_REQUIRED"
    case storefrontPasswordRequired = "STOREFRONT_PASSWORD_REQUIRED"
    case cartCompleted = "CART_COMPLETED"
    case invalidCart = "INVALID_CART"
    case killswitchEnabled = "KILLSWITCH_ENABLED"
    case unrecoverableFailure = "UNRECOVERABLE_FAILURE"
    case policyViolation = "POLICY_VIOLATION"
    case vaultedPaymentError = "VAULTED_PAYMENT_ERROR"
    case checkoutLiquidNotMigrated = "CHECKOUT_LIQUID_NOT_MIGRATED"
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
        case let .checkoutExpired(_, _, recoverable),
             let .checkoutUnavailable(_, _, recoverable),
             let .configurationError(_, _, recoverable),
             let .sdkError(_, recoverable):
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
