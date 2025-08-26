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

import ShopifyCheckoutSheetKit

/// Public validation error that contains user-friendly error information
@available(iOS 16.0, *)
public struct ValidationError: Error, CustomStringConvertible {
    /// Individual validation error details
    public struct UserError {
        /// Error message from the API
        public let message: String
        /// Field path that caused the error (e.g., ["shippingAddress", "countryCode"])
        public let field: [String]?
        /// Error code identifier (e.g., "INVALID_COUNTRY_CODE")
        public let code: String?

        public init(message: String, field: [String]? = nil, code: String? = nil) {
            self.message = message
            self.field = field
            self.code = code
        }
    }

    /// All validation errors that occurred
    public let userErrors: [UserError]

    /// Combined description of all errors
    public var description: String {
        userErrors.map(\.message).joined(separator: "; ")
    }

    public init(userErrors: [UserError]) {
        self.userErrors = userErrors
    }

    /// Internal initializer to convert from StorefrontAPI type
    internal init(from cartValidationError: StorefrontAPI.CartValidationError) {
        userErrors = cartValidationError.userErrors.map { cartUserError in
            UserError(
                message: cartUserError.message,
                field: cartUserError.field,
                code: cartUserError.code?.rawValue
            )
        }
    }

    // MARK: - Utility methods

    /// All error messages as an array
    public var messages: [String] {
        userErrors.map(\.message)
    }

    /// Check if contains a specific error code
    public func hasErrorCode(_ code: String) -> Bool {
        return userErrors.contains { $0.code == code }
    }

    /// Get errors for a specific field path
    public func errorsForField(_ fieldPath: [String]) -> [UserError] {
        return userErrors.filter { $0.field == fieldPath }
    }
}

/// Error type for Accelerated Checkout validation operations
@available(iOS 16.0, *)
public enum AcceleratedCheckoutError: Error {
    /// Cart validation failed - API correctly rejected input data
    case validation(ValidationError)

    // MARK: - Convenience accessors

    /// Get validation error if this is a validation error
    public var validationError: ValidationError? {
        if case let .validation(error) = self {
            return error
        }
        return nil
    }

    // MARK: - Utility methods

    /// All validation error messages
    public var validationMessages: [String] {
        validationError?.messages ?? []
    }

    /// Check if this is a specific type of validation error
    public func hasValidationErrorCode(_ code: String) -> Bool {
        return validationError?.hasErrorCode(code) ?? false
    }

    /// Check if this represents validation issues
    public var isValidationError: Bool {
        if case .validation = self { return true }
        return false
    }
}
