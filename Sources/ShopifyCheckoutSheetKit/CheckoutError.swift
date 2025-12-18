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

/// `CheckoutError` represents scenarios where Shopify Checkout may error
///
/// Each error relates to a different portion of Web Shopify Checkout, except `.internal` which is an internal swift error
/// When the error is not `.internal` it is useful to first confirm where the issue exists in your Storefront
/// within a browser, to exclude Checkout Kit from the investigation
///
/// Every event has a "recoverable" property that indicates this error may be recoverable when retried in a fallback browser experience
/// This may have a degraded experience, implement CheckoutDelegate.shouldRecoverFromError to opt out
public enum CheckoutError: Error {
    /// Issued when an internal error within Shopify Checkout SDK
    /// In event of an sdkError you could use the stacktrace to inform you of how to proceed,
    /// if the issue persists, it is recommended to open a bug report in:
    /// http://github.com/Shopify/checkout-sheet-kit-swift/issues
    case `internal`(underlying: Error, recoverable: Bool = true)

    /// Issued when the storefront configuration has caused an error.
    case misconfiguration(message: String, code: ErrorCode, recoverable: Bool = false)

    /// Issued when checkout has encountered a unrecoverable error (for example server side error)
    /// if the issue persists, it is recommended to open a bug report:
    /// http://github.com/Shopify/checkout-sheet-kit-swift/issues
    case unavailable(message: String, code: CheckoutUnavailable, recoverable: Bool)

    /// Issued when checkout is no longer available and will no longer be available with the checkout url supplied.
    /// This may happen when the user has paused on checkout for a long period (hours) and then attempted to proceed again with the same checkout url
    /// In event of checkoutExpired, a new checkout url will need to be generated
    case expired(message: String, code: ErrorCode, recoverable: Bool = false)

    public var isRecoverable: Bool {
        switch self {
        case let .expired(_, _, recoverable),
             let .unavailable(_, _, recoverable),
             let .misconfiguration(_, _, recoverable),
             let .internal(_, recoverable):
            return recoverable
        }
    }

    public var message: String {
        switch self {
        case let .internal(underlying, _): return underlying.localizedDescription
        case let .expired(message, _, _): return message
        case let .unavailable(message, _, _): return message
        case let .misconfiguration(message, _, _): return message
        }
    }

    public enum ErrorCode: String, Codable {
        /// misconfiguration: recoverable:false
        case payloadExpired = "PAYLOAD_EXPIRED"
        case invalidPayload = "INVALID_PAYLOAD"
        case invalidSignature = "INVALID_SIGNATURE"
        case notAuthorized = "NOT_AUTHORIZED"
        case customerAccountRequired = "CUSTOMER_ACCOUNT_REQUIRED"
        case storefrontPasswordRequired = "STOREFRONT_PASSWORD_REQUIRED"

        /// unavailable: recoverable:false
        case killswitchEnabled = "KILLSWITCH_ENABLED"
        case unrecoverableFailure = "UNRECOVERABLE_FAILURE"
        case policyViolation = "POLICY_VIOLATION"
        case vaultedPaymentError = "VAULTED_PAYMENT_ERROR"

        /// expired: recoverable:false
        case cartCompleted = "CART_COMPLETED"
        case invalidCart = "INVALID_CART"
    }

    public enum CheckoutUnavailable {
        case clientError(code: ErrorCode)
        case httpError(statusCode: Int)
    }
}
