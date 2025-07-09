//
//  ApplePayConfiguration.swift
//  ShopifyAcceleratedCheckouts
//

import PassKit

@available(iOS 17.0, *)
public extension ShopifyAcceleratedCheckouts {
    /// Contact field types that can be required during Apple Pay checkout.
    enum RequiredContactFields {
        case email
        case phone
    }

    /// Configuration options for Apple Pay integration within Shopify Accelerated Checkouts.
    ///
    /// This class encapsulates all necessary settings for enabling Apple Pay as a payment method,
    /// including merchant identification, supported payment networks, and required contact information.
    @Observable class ApplePayConfiguration {
        /// The merchant identifier for Apple Pay transactions.
        ///
        /// This value must match one of the merchant identifiers specified by the Merchant IDs
        /// entitlement key in the app's entitlements.
        ///
        /// - See: [Apple Developer Documentation - merchantIdentifier](https://developer.apple.com/documentation/passkit_apple_pay_and_wallet/pkpaymentrequest/1619305-merchantidentifier)
        public let merchantIdentifier: String

        /// Payment card networks supported for Apple Pay transactions.
        ///
        /// Only card types included in this array will be displayed as available payment
        /// options in the Apple Pay payment sheet.
        public let supportedNetworks: [PKPaymentNetwork]

        /// Contact information fields required during the Apple Pay payment flow.
        ///
        /// Fields specified in this array will be marked as required in the payment sheet.
        /// When a user is authenticated and their email or phone number has been provided
        /// through the `buyerIdentity` mutation, these values will be pre-populated in the
        /// payment sheet, allowing the required fields to remain empty in this configuration.
        ///
        /// - Note: Configure this property based on your shop's customer account requirements.
        ///         For shops requiring customer accounts, include `.email` in the array.
        public let contactFields: [RequiredContactFields]

        /// Creates a new Apple Pay configuration.
        ///
        /// - Parameters:
        ///   - merchantIdentifier: The merchant identifier registered with Apple.
        ///   - supportedNetworks: Array of payment card networks to accept.
        ///   - contactFields: Contact information fields to require from the customer.
        public init(
            merchantIdentifier: String,
            supportedNetworks: [PKPaymentNetwork],
            contactFields: [RequiredContactFields]
        ) {
            self.merchantIdentifier = merchantIdentifier
            self.supportedNetworks = supportedNetworks
            self.contactFields = contactFields
        }
    }
}

/// Internal wrapper that combines Apple Pay configuration with common checkout settings.
///
/// This class is used internally to bundle the Apple Pay-specific configuration
/// with the general accelerated checkout configuration and shop settings.
class ApplePayConfigurationWrapper {
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
}
