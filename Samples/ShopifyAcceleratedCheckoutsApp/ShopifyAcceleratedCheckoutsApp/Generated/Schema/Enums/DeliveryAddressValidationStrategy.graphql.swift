// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront {
    /// Defines the types of available validation strategies for delivery addresses.
    enum DeliveryAddressValidationStrategy: String, EnumType {
        /// Only the country code is validated.
        case countryCodeOnly = "COUNTRY_CODE_ONLY"
        /// Strict validation is performed, i.e. all fields in the address are validated
        /// according to Shopify's checkout rules. If the address fails validation, the cart will not be updated.
        case strict = "STRICT"
    }
}
