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
    public enum RequiredContactFields {
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

        /// Fields specified in this array will be marked as required in the Apple Pay sheet.
        ///
        /// These can be omitted if you already have access to a contact field,
        /// such as the users email / phone number. Instead you may attach it to a cart via
        /// the storefront `buyerIdentityUpdate` mutation, or passing it to
        /// ShopifyAccleratedCheckouts.Configuration.customer.
        ///
        /// When `contactFields` is set `ShopifyAccleratedCheckouts.Configuration.customer`
        /// email / phone are ignored respectively.
        ///
        /// - Note: Configure this property based on your shop's customer account requirements.
        ///         For shops requiring customer accounts, include `.email` in the array.
        public let contactFields: [RequiredContactFields]

        /// Creates a new Apple Pay configuration.
        ///
        /// - Parameters:
        ///   - merchantIdentifier: The merchant identifier registered with Apple.
        ///   - contactFields: Contact information fields to require from the customer.
        /// - Note: Supported payment networks are automatically determined based on the
        ///         merchant's accepted card brands configuration in Shopify.
        public init(
            merchantIdentifier: String,
            contactFields: [RequiredContactFields]
        ) {
            self.merchantIdentifier = merchantIdentifier
            self.contactFields = contactFields
        }

        package required init(copy: ApplePayConfiguration) {
            merchantIdentifier = copy.merchantIdentifier
            contactFields = copy.contactFields
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
