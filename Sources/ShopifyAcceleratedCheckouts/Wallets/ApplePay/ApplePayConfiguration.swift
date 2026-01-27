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
import PassKit

@available(iOS 16.0, *)
extension ShopifyAcceleratedCheckouts {
    /// Contact field types that can be required during Apple Pay checkout.
    public enum RequiredContactFields: String {
        case email
        case phone
    }

    /// Configuration options for Apple Pay integration within Shopify Accelerated Checkouts.
    ///
    /// This class encapsulates all necessary settings for enabling Apple Pay as a payment method,
    /// including merchant identification and required contact information. Supported payment networks
    /// are automatically determined based on the merchant's Shopify configuration.
    public class ApplePayConfiguration: ObservableObject, Copyable {
        /// The merchant identifier for Apple Pay transactions.
        ///
        /// This value must match one of the merchant identifiers specified by the Merchant IDs
        /// entitlement key in the app's entitlements.
        ///
        /// - See: [Apple Developer Documentation - merchantIdentifier](https://developer.apple.com/documentation/passkit_apple_pay_and_wallet/pkpaymentrequest/1619305-merchantidentifier)
        public let merchantIdentifier: String

        /// Contact fields required by the checkout.
        ///
        /// - Important: These fields have no effect when `cart.buyerIdentity` or `cart.customer`
        /// are populated.
        ///
        /// These fields act as a hint to the SDK about what contact information is required
        /// to complete checkout. The SDK will selectively request fields during Apple Pay
        /// based on the carts buyerIdentity.
        ///
        /// **Behavior:**
        /// - If a contactField exists in `cart.buyerIdentity` or `cart.buyerIdentity.customer`
        ///   that field will NOT be requested from the Apple Pay sheet.
        /// - If you include a contactField that is NOT already available from buyerIdentity,
        ///   it will be requested in the Apple Payment Sheet.
        ///
        /// **Usage:**
        /// - Include `.email` if your shop requires customer accounts.
        /// - Include `.phone` if your shop requires a phone number for shipping addresses.
        /// - If you want the User to specify an email / phone inside the Apple Payment Sheet
        ///   to collect email/phone, omit these fields from the `cart.buyerIdentity`.
        ///
        public let contactFields: [RequiredContactFields]

        /// Countries supported for Apple Pay shipping addresses.
        ///
        /// This property allows merchants to restrict which countries are available for
        /// shipping addresses during the Apple Pay checkout flow. Uses ISO 3166-1 alpha-2
        /// country codes (e.g., "US", "CA", "GB").
        ///
        /// When nil or empty, all countries are allowed.
        ///
        /// - Note: This restriction is separate from the merchant's general shipping capabilities.
        public let supportedShippingCountries: Set<String>?

        /// Creates a new Apple Pay configuration.
        ///
        /// - Parameters:
        ///   - merchantIdentifier: The merchant identifier registered with Apple.
        ///   - contactFields: Contact information fields to require from the customer.
        ///   - supportedShippingCountries: Optional set of ISO 3166-1 alpha-2 country codes to restrict
        ///                                 shipping addresses. Defaults to nil (all countries allowed).
        /// - Note: Supported payment networks are automatically determined based on the
        ///         merchant's accepted card brands configuration in Shopify.
        public init(
            merchantIdentifier: String,
            contactFields: [RequiredContactFields],
            supportedShippingCountries: Set<String>? = nil
        ) {
            self.merchantIdentifier = merchantIdentifier
            self.contactFields = contactFields
            self.supportedShippingCountries = supportedShippingCountries
        }

        package required init(copy: ApplePayConfiguration) {
            merchantIdentifier = copy.merchantIdentifier
            contactFields = copy.contactFields
            supportedShippingCountries = copy.supportedShippingCountries
        }
    }
}

/// Internal wrapper that combines Apple Pay configuration with common checkout settings.
///
/// This class is used internally to bundle the Apple Pay-specific configuration
/// with the general accelerated checkout configuration and shop settings.
@available(iOS 16.0, *)
class ApplePayConfigurationWrapper: Copyable {
    var common: ShopifyAcceleratedCheckouts.Configuration
    var applePay: ShopifyAcceleratedCheckouts.ApplePayConfiguration
    var shopSettings: ShopSettings

    init(
        common: ShopifyAcceleratedCheckouts.Configuration,
        applePay: ShopifyAcceleratedCheckouts.ApplePayConfiguration,
        shopSettings: ShopSettings
    ) {
        self.common = common
        self.applePay = applePay
        self.shopSettings = shopSettings
    }

    package required init(copy: ApplePayConfigurationWrapper) {
        common = copy.common.copy()
        applePay = copy.applePay.copy()
        shopSettings = copy.shopSettings
    }
}
