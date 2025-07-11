// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension Storefront {
    /// Possible error codes that can be returned by `CartUserError`.
    enum CartErrorCode: String, EnumType {
        /// The input value is invalid.
        case invalid = "INVALID"
        /// The input value should be less than the maximum value allowed.
        case lessThan = "LESS_THAN"
        /// Merchandise line was not found in cart.
        case invalidMerchandiseLine = "INVALID_MERCHANDISE_LINE"
        /// Missing discount code.
        case missingDiscountCode = "MISSING_DISCOUNT_CODE"
        /// Missing note.
        case missingNote = "MISSING_NOTE"
        /// Delivery group was not found in cart.
        case invalidDeliveryGroup = "INVALID_DELIVERY_GROUP"
        /// Delivery option was not valid.
        case invalidDeliveryOption = "INVALID_DELIVERY_OPTION"
        /// The payment wasn't valid.
        case invalidPayment = "INVALID_PAYMENT"
        /// The payment method is not supported.
        case paymentMethodNotSupported = "PAYMENT_METHOD_NOT_SUPPORTED"
        /// Cannot update payment on an empty cart
        case invalidPaymentEmptyCart = "INVALID_PAYMENT_EMPTY_CART"
        /// Validation failed.
        case validationCustom = "VALIDATION_CUSTOM"
        /// The metafields were not valid.
        case invalidMetafields = "INVALID_METAFIELDS"
        /// The customer access token is required when setting a company location.
        case missingCustomerAccessToken = "MISSING_CUSTOMER_ACCESS_TOKEN"
        /// Company location not found or not allowed.
        case invalidCompanyLocation = "INVALID_COMPANY_LOCATION"
        /// The quantity must be a multiple of the specified increment.
        case invalidIncrement = "INVALID_INCREMENT"
        /// The quantity must be above the specified minimum for the item.
        case minimumNotMet = "MINIMUM_NOT_MET"
        /// The quantity must be below the specified maximum for the item.
        case maximumExceeded = "MAXIMUM_EXCEEDED"
        /// The specified address field is required.
        case addressFieldIsRequired = "ADDRESS_FIELD_IS_REQUIRED"
        /// The specified address field is too long.
        case addressFieldIsTooLong = "ADDRESS_FIELD_IS_TOO_LONG"
        /// The specified address field contains emojis.
        case addressFieldContainsEmojis = "ADDRESS_FIELD_CONTAINS_EMOJIS"
        /// The specified address field contains HTML tags.
        case addressFieldContainsHtmlTags = "ADDRESS_FIELD_CONTAINS_HTML_TAGS"
        /// The specified address field contains a URL.
        case addressFieldContainsUrl = "ADDRESS_FIELD_CONTAINS_URL"
        /// The specified address field does not match the expected pattern.
        case addressFieldDoesNotMatchExpectedPattern = "ADDRESS_FIELD_DOES_NOT_MATCH_EXPECTED_PATTERN"
        /// The given zip code is invalid for the provided province.
        case invalidZipCodeForProvince = "INVALID_ZIP_CODE_FOR_PROVINCE"
        /// The given zip code is invalid for the provided country.
        case invalidZipCodeForCountry = "INVALID_ZIP_CODE_FOR_COUNTRY"
        /// The given zip code is unsupported.
        case zipCodeNotSupported = "ZIP_CODE_NOT_SUPPORTED"
        /// The given province cannot be found.
        case provinceNotFound = "PROVINCE_NOT_FOUND"
        /// A general error occurred during address validation.
        case unspecifiedAddressError = "UNSPECIFIED_ADDRESS_ERROR"
    }
}
