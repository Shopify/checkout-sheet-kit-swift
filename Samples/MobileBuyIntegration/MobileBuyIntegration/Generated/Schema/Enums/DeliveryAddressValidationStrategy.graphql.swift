// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) import ApolloAPI

extension Storefront {
    /// Controls how delivery addresses are validated during cart operations. The default validation checks only the country code, while strict validation verifies all address fields against Shopify's checkout rules and rejects invalid addresses.
    ///
    /// Used by [`DeliveryAddressInput`](https://shopify.dev/docs/api/storefront/current/input-objects/DeliveryAddressInput) when setting buyer identity preferences, and by [`CartSelectableAddressInput`](https://shopify.dev/docs/api/storefront/current/input-objects/CartSelectableAddressInput) and [`CartSelectableAddressUpdateInput`](https://shopify.dev/docs/api/storefront/current/input-objects/CartSelectableAddressUpdateInput) when managing cart delivery addresses.
    enum DeliveryAddressValidationStrategy: String, EnumType {
        /// Only the country code is validated.
        case countryCodeOnly = "COUNTRY_CODE_ONLY"
        /// Strict validation is performed, i.e. all fields in the address are validated
        /// according to Shopify's checkout rules. If the address fails validation, the cart will not be updated.
        case strict = "STRICT"
    }
}
