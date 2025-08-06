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

/// Protocol for encoding privacy consent into a format suitable for checkout
public protocol ConsentEncoder {
    /// Encodes privacy consent into a string format
    /// - Parameter consent: The privacy consent to encode
    /// - Returns: Encoded consent string, or nil if encoding fails
    func encode(_ consent: Configuration.PrivacyConsent) async throws -> String?
}

/// Errors that can occur during consent encoding
public enum ConsentEncodingError: Error, LocalizedError {
    case networkError(Error)
    case authenticationFailed
    case invalidResponse(String)
    case apiUnavailable
    case invalidShopDomain
    case missingAccessToken

    public var errorDescription: String? {
        switch self {
        case let .networkError(error):
            return "Network error occurred: \(error.localizedDescription)"
        case .authenticationFailed:
            return "Authentication failed. Please check your access token."
        case let .invalidResponse(message):
            return "Invalid response from server: \(message)"
        case .apiUnavailable:
            return "Consent management API is not available"
        case .invalidShopDomain:
            return "Invalid shop domain provided"
        case .missingAccessToken:
            return "Storefront access token is required"
        }
    }
}
