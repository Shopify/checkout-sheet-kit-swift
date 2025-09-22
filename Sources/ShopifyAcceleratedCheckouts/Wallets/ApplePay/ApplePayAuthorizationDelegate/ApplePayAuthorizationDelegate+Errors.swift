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

        static var addressUnserviceableError: Error {
            PKPaymentRequest.paymentShippingAddressUnserviceableError(
                withLocalizedDescription: "Invalid shipping address"
            )
        }

        static func shippingCountryNotSupported(supportedCountries: Set<String>) -> Error {
            let message = formatCountryListMessage(supportedCountries: supportedCountries)
            return PKPaymentRequest.paymentShippingAddressInvalidError(
                withKey: "country",
                localizedDescription: message
            )
        }

        /// Apple Pay guideline: Keep error messages at 85 characters or fewer to avoid truncation in the UI
        private static let applePayErrorMessageMaxLength = 85

        private static func formatCountryListMessage(supportedCountries: Set<String>) -> String {
            let sortedCountries = supportedCountries.sorted()

            // Try with all countries first
            let allCountriesList = sortedCountries.joined(separator: ", ")
            let fullMessage = "errors.unsupported.country.list".localizedString(with: allCountriesList)

            if fullMessage.count <= applePayErrorMessageMaxLength {
                return fullMessage
            }

            // Otherwise, list as many as we can fit with "and others"
            // We need to calculate based on the localized template
            let templateWithOthers = "errors.unsupported.country.list.with.others".localizedString
            // Get the base length by substituting an empty string
            let baseLength = String(format: templateWithOthers, "").count
            let availableSpace = applePayErrorMessageMaxLength - baseLength

            var includedCountries: [String] = []
            var currentLength = 0

            for country in sortedCountries {
                let neededLength = country.count + (includedCountries.isEmpty ? 0 : 2) // +2 for ", "
                if currentLength + neededLength <= availableSpace {
                    includedCountries.append(country)
                    currentLength += neededLength
                } else {
                    break
                }
            }

            if includedCountries.isEmpty, !sortedCountries.isEmpty {
                // Edge case: even the first country doesn't fit
                includedCountries.append(sortedCountries[0])
            }

            let countriesListWithOthers = includedCountries.joined(separator: ", ")
            return "errors.unsupported.country.list.with.others".localizedString(with: countriesListWithOthers)
        }
    }
}
