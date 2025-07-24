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

// MARK: - Cart Models

@available(iOS 17.0, *)
extension StorefrontAPI {
    class Types {
        typealias ID = GraphQLScalars.ID
        typealias Cart = StorefrontAPI.Cart
        typealias UserError = StorefrontAPI.CartUserError
        typealias Product = StorefrontAPI.Product
        typealias ProductVariant = StorefrontAPI.ProductVariant
        typealias Shop = StorefrontAPI.Shop
        typealias Money = StorefrontAPI.MoneyV2
        typealias Address = StorefrontAPI.Address
        typealias ApplePayPayment = StorefrontAPI.ApplePayPayment
        typealias CardBrand = StorefrontAPI.CardBrand
    }

    /// Represents a cart in the Storefront API
    struct Cart: Codable {
        let id: Types.ID
        let checkoutUrl: GraphQLScalars.URL
        let totalQuantity: Int
        let buyerIdentity: CartBuyerIdentity?
        let deliveryGroups: CartDeliveryGroupConnection
        let delivery: CartDelivery?
        let lines: BaseCartLineConnection
        let cost: CartCost
        let discountCodes: [CartDiscountCode]
        let discountAllocations: [CartDiscountAllocation]
    }

    /// Cart discount code
    struct CartDiscountCode: Codable {
        let code: String
        let applicable: Bool
    }

    /// Cart buyer identity
    struct CartBuyerIdentity: Codable {
        let email: String?
        let phone: String?
    }

    /// Cart delivery information
    struct CartDelivery: Codable {
        let addresses: [CartSelectableAddress]
    }

    /// Cart selectable address
    struct CartSelectableAddress: Codable {
        let id: Types.ID
        let selected: Bool
        let address: CartDeliveryAddress?
    }

    /// Cart delivery address
    /// Note: This is a GraphQL response type that uses countryCode/provinceCode
    /// instead of country/province like the input Address type
    struct CartDeliveryAddress: Codable {
        let address1: String?
        let address2: String?
        let city: String?
        let countryCode: String?
        let firstName: String?
        let lastName: String?
        let phone: String?
        let provinceCode: String?
        let zip: String?
    }

    /// Cart cost breakdown
    struct CartCost: Codable {
        let totalAmount: MoneyV2
        let subtotalAmount: MoneyV2?
        let totalTaxAmount: MoneyV2?
        let totalDutyAmount: MoneyV2?
    }

    /// Money representation
    struct MoneyV2: Codable {
        let amount: Decimal
        let currencyCode: String

        init(amount: Decimal, currencyCode: String) {
            self.amount = amount
            self.currencyCode = currencyCode
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            // Handle amount as either String or Number
            if let amountString = try? container.decode(String.self, forKey: .amount) {
                guard let decimalAmount = Decimal(string: amountString) else {
                    throw DecodingError.dataCorruptedError(
                        forKey: .amount,
                        in: container,
                        debugDescription: "Unable to decode amount string '\(amountString)' as Decimal"
                    )
                }
                amount = decimalAmount
            } else {
                // Fallback to direct Decimal decoding
                amount = try container.decode(Decimal.self, forKey: .amount)
            }

            currencyCode = try container.decode(String.self, forKey: .currencyCode)
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            // Encode amount as string to match GraphQL Decimal scalar format
            try container.encode("\(amount)", forKey: .amount)
            try container.encode(currencyCode, forKey: .currencyCode)
        }

        private enum CodingKeys: String, CodingKey {
            case amount
            case currencyCode
        }
    }

    // MARK: - Cart Lines

    /// Connection type for cart lines
    struct BaseCartLineConnection: Codable {
        let nodes: [BaseCartLine]
    }

    /// Cart discount allocation
    enum CartDiscountAllocation: Codable {
        case automatic(CartAutomaticDiscountAllocation)
        case code(CartCodeDiscountAllocation)
        case custom(CartCustomDiscountAllocation)

        private enum CodingKeys: String, CodingKey {
            case __typename
        }

        private enum TypeName: String, Codable {
            case cartAutomaticDiscountAllocation = "CartAutomaticDiscountAllocation"
            case cartCodeDiscountAllocation = "CartCodeDiscountAllocation"
            case cartCustomDiscountAllocation = "CartCustomDiscountAllocation"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let typename = try container.decode(TypeName.self, forKey: .__typename)

            switch typename {
            case .cartAutomaticDiscountAllocation:
                let allocation = try CartAutomaticDiscountAllocation(from: decoder)
                self = .automatic(allocation)
            case .cartCodeDiscountAllocation:
                let allocation = try CartCodeDiscountAllocation(from: decoder)
                self = .code(allocation)
            case .cartCustomDiscountAllocation:
                let allocation = try CartCustomDiscountAllocation(from: decoder)
                self = .custom(allocation)
            }
        }

        func encode(to encoder: Encoder) throws {
            switch self {
            case let .automatic(allocation):
                try allocation.encode(to: encoder)
            case let .code(allocation):
                try allocation.encode(to: encoder)
            case let .custom(allocation):
                try allocation.encode(to: encoder)
            }
        }
    }

    /// Automatic discount allocation
    struct CartAutomaticDiscountAllocation: Codable {
        let discountApplication: CartDiscountApplication
        let discountedAmount: MoneyV2
        let targetType: DiscountApplicationTargetType
    }

    /// Code discount allocation
    struct CartCodeDiscountAllocation: Codable {
        let code: String
        let discountApplication: CartDiscountApplication
        let discountedAmount: MoneyV2
        let targetType: DiscountApplicationTargetType
    }

    /// Custom discount allocation
    struct CartCustomDiscountAllocation: Codable {
        let discountApplication: CartDiscountApplication
        let discountedAmount: MoneyV2
        let targetType: DiscountApplicationTargetType
    }

    /// Cart discount application
    struct CartDiscountApplication: Codable {
        let targetSelection: DiscountApplicationTargetSelection
        let targetType: DiscountApplicationTargetType
        let value: PricingValue
    }

    /// Discount application target selection
    enum DiscountApplicationTargetSelection: String, Codable {
        case all = "ALL"
        case entitled = "ENTITLED"
        case explicit = "EXPLICIT"
    }

    /// Discount application target type
    enum DiscountApplicationTargetType: String, Codable {
        case lineItem = "LINE_ITEM"
        case shipping = "SHIPPING"
    }

    /// Pricing value (union type for percentage or fixed amount)
    enum PricingValue: Codable {
        case percentage(PricingPercentageValue)
        case fixedAmount(MoneyV2)

        private enum CodingKeys: String, CodingKey {
            case __typename
        }

        private enum TypeName: String, Codable {
            case pricingPercentageValue = "PricingPercentageValue"
            case moneyV2 = "MoneyV2"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let typename = try container.decode(TypeName.self, forKey: .__typename)

            switch typename {
            case .pricingPercentageValue:
                let percentage = try PricingPercentageValue(from: decoder)
                self = .percentage(percentage)
            case .moneyV2:
                let amount = try MoneyV2(from: decoder)
                self = .fixedAmount(amount)
            }
        }

        func encode(to encoder: Encoder) throws {
            switch self {
            case let .percentage(percentage):
                try percentage.encode(to: encoder)
            case let .fixedAmount(amount):
                try amount.encode(to: encoder)
            }
        }
    }

    /// Pricing percentage value
    struct PricingPercentageValue: Codable {
        let percentage: Double
    }

    /// Base cart line
    struct BaseCartLine: Codable {
        let id: Types.ID
        let quantity: Int
        let merchandise: ProductVariant?
        let cost: CartLineCost
        let discountAllocations: [CartDiscountAllocation]
    }

    /// Cart line cost
    struct CartLineCost: Codable {
        let totalAmount: MoneyV2
        let subtotalAmount: MoneyV2
    }

    // MARK: - Product Models

    /// Product variant
    struct ProductVariant: Codable {
        let id: Types.ID
        let title: String
        let price: MoneyV2
        let product: Product
        let requiresShipping: Bool
    }

    /// Product
    struct Product: Codable {
        let id: Types.ID?
        let title: String
        let vendor: String?
        let featuredImage: Image?
        let variants: ProductVariantConnection?
    }

    /// Product variant connection
    struct ProductVariantConnection: Codable {
        let nodes: [ProductVariant]
    }

    /// Product connection
    struct ProductConnection: Codable {
        let nodes: [Product]
    }

    /// Image
    struct Image: Codable {
        let url: GraphQLScalars.URL
    }

    // MARK: - Shop

    /// Shop information
    struct Shop: Codable {
        let name: String
        let description: String?
        let primaryDomain: ShopDomain
        let shipsToCountries: [String]
        let paymentSettings: ShopPaymentSettings
        let moneyFormat: String
    }

    /// Shop domain
    struct ShopDomain: Codable {
        let host: String
        let sslEnabled: Bool
        let url: GraphQLScalars.URL
    }

    /// Shop payment settings
    struct ShopPaymentSettings: Codable {
        let supportedDigitalWallets: [String]
        let acceptedCardBrands: [CardBrand]
        let countryCode: String
    }

    /// Card brands supported by Shopify's payment system
    enum CardBrand: String, Codable, CaseIterable {
        case americanExpress = "AMERICAN_EXPRESS"
        case dinersClub = "DINERS_CLUB"
        case discover = "DISCOVER"
        case jcb = "JCB"
        case mastercard = "MASTERCARD"
        case visa = "VISA"
    }

    // MARK: - Delivery Groups

    /// Connection type for delivery groups
    struct CartDeliveryGroupConnection: Codable {
        let nodes: [CartDeliveryGroup]
    }

    /// Cart delivery group
    struct CartDeliveryGroup: Codable {
        let id: Types.ID
        let groupType: CartDeliveryGroupType
        let deliveryOptions: [CartDeliveryOption]
        let selectedDeliveryOption: CartDeliveryOption?
    }

    /// Cart delivery group type
    enum CartDeliveryGroupType: String, Codable {
        case oneTimePurchase = "ONE_TIME_PURCHASE"
        case subscription = "SUBSCRIPTION"
    }

    /// Cart delivery option
    struct CartDeliveryOption: Codable {
        let handle: String
        let title: String
        let code: String?
        let deliveryMethodType: DeliveryMethodType
        let description: String?
        let estimatedCost: MoneyV2
    }

    /// Delivery method type
    enum DeliveryMethodType: String, Codable {
        case local = "LOCAL"
        case none = "NONE"
        case pickupPoint = "PICKUP_POINT"
        case pickUp = "PICK_UP"
        case retail = "RETAIL"
        case shipping = "SHIPPING"
    }

    // MARK: - User Errors

    /// Cart user error
    struct CartUserError: Codable, Error {
        let code: CartErrorCode?
        let message: String
        let field: [String]?
    }

    /// Cart error codes
    enum CartErrorCode: String, Codable {
        case addressFieldContainsEmojis = "ADDRESS_FIELD_CONTAINS_EMOJIS"
        case addressFieldContainsHtmlTags = "ADDRESS_FIELD_CONTAINS_HTML_TAGS"
        case addressFieldContainsUrl = "ADDRESS_FIELD_CONTAINS_URL"
        case addressFieldDoesNotMatchExpectedPattern = "ADDRESS_FIELD_DOES_NOT_MATCH_EXPECTED_PATTERN"
        case addressFieldIsRequired = "ADDRESS_FIELD_IS_REQUIRED"
        case addressFieldIsTooLong = "ADDRESS_FIELD_IS_TOO_LONG"
        case cartTooLarge = "CART_TOO_LARGE"
        case invalid = "INVALID"
        case invalidCompanyLocation = "INVALID_COMPANY_LOCATION"
        case invalidDeliveryAddressId = "INVALID_DELIVERY_ADDRESS_ID"
        case invalidDeliveryGroup = "INVALID_DELIVERY_GROUP"
        case invalidDeliveryOption = "INVALID_DELIVERY_OPTION"
        case invalidIncrement = "INVALID_INCREMENT"
        case invalidMerchandiseLine = "INVALID_MERCHANDISE_LINE"
        case invalidMetafields = "INVALID_METAFIELDS"
        case invalidZipCodeForCountry = "INVALID_ZIP_CODE_FOR_COUNTRY"
        case invalidZipCodeForProvince = "INVALID_ZIP_CODE_FOR_PROVINCE"
        case lessThan = "LESS_THAN"
        case maximumExceeded = "MAXIMUM_EXCEEDED"
        case minimumNotMet = "MINIMUM_NOT_MET"
        case missingCustomerAccessToken = "MISSING_CUSTOMER_ACCESS_TOKEN"
        case missingDiscountCode = "MISSING_DISCOUNT_CODE"
        case missingNote = "MISSING_NOTE"
        case noteTooLong = "NOTE_TOO_LONG"
        case onlyOneDeliveryAddressCanBeSelected = "ONLY_ONE_DELIVERY_ADDRESS_CAN_BE_SELECTED"
        case pendingDeliveryGroups = "PENDING_DELIVERY_GROUPS"
        case provinceNotFound = "PROVINCE_NOT_FOUND"
        case sellingPlanNotApplicable = "SELLING_PLAN_NOT_APPLICABLE"
        case serviceUnavailable = "SERVICE_UNAVAILABLE"
        case tooManyDeliveryAddresses = "TOO_MANY_DELIVERY_ADDRESSES"
        case unspecifiedAddressError = "UNSPECIFIED_ADDRESS_ERROR"
        case validationCustom = "VALIDATION_CUSTOM"
        case variantRequiresSellingPlan = "VARIANT_REQUIRES_SELLING_PLAN"
        case zipCodeNotSupported = "ZIP_CODE_NOT_SUPPORTED"

        // Legacy/compatibility cases
        case tooManyLineItems = "TOO_MANY_LINE_ITEMS"
        case notApplicable = "NOT_APPLICABLE"
        case notEnoughStock = "NOT_ENOUGH_STOCK"
        case insufficientBalance = "INSUFFICIENT_BALANCE"
        case deliveryAddressSizeExceeded = "DELIVERY_ADDRESS_SIZE_EXCEEDED"
        case paymentMethodUnavailable = "PAYMENT_METHOD_UNAVAILABLE"

        // Payment-specific errors that might be expected in the error handler
        case invalidPayment = "INVALID_PAYMENT"
        case invalidPaymentEmptyCart = "INVALID_PAYMENT_EMPTY_CART"
        case paymentMethodNotSupported = "PAYMENT_METHOD_NOT_SUPPORTED"
        case paymentsCreditCardBaseExpired = "PAYMENTS_CREDIT_CARD_BASE_EXPIRED"
        case paymentsCreditCardBaseGatewayNotSupported = "PAYMENTS_CREDIT_CARD_BASE_GATEWAY_NOT_SUPPORTED"
        case paymentsCreditCardGeneric = "PAYMENTS_CREDIT_CARD_GENERIC"
        case paymentsCreditCardMonthInclusion = "PAYMENTS_CREDIT_CARD_MONTH_INCLUSION"
        case paymentsCreditCardNumberInvalid = "PAYMENTS_CREDIT_CARD_NUMBER_INVALID"
        case paymentsCreditCardNumberInvalidFormat = "PAYMENTS_CREDIT_CARD_NUMBER_INVALID_FORMAT"
        case paymentsCreditCardVerificationValueBlank = "PAYMENTS_CREDIT_CARD_VERIFICATION_VALUE_BLANK"
        case paymentsCreditCardVerificationValueInvalidForCardType = "PAYMENTS_CREDIT_CARD_VERIFICATION_VALUE_INVALID_FOR_CARD_TYPE"
        case paymentsCreditCardYearExpired = "PAYMENTS_CREDIT_CARD_YEAR_EXPIRED"
        case paymentsCreditCardYearInvalidExpiryYear = "PAYMENTS_CREDIT_CARD_YEAR_INVALID_EXPIRY_YEAR"

        // Catch-all for unknown values
        case unknownValue = "UNKNOWN_VALUE"

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            self = CartErrorCode(rawValue: value) ?? .unknownValue
        }
    }

    // MARK: - Mutation Payloads

    struct CartPayload: Codable {
        let cart: Cart?
        let userErrors: [CartUserError]
    }

    /// Cart create payload
    typealias CartCreatePayload = CartPayload

    /// Cart buyer identity update payload
    typealias CartBuyerIdentityUpdatePayload = CartPayload

    /// Cart delivery addresses add payload
    typealias CartDeliveryAddressesAddPayload = CartPayload

    /// Cart delivery addresses update payload
    typealias CartDeliveryAddressesUpdatePayload = CartPayload

    /// Cart selected delivery options update payload
    typealias CartSelectedDeliveryOptionsUpdatePayload = CartPayload

    /// Cart payment update payload
    typealias CartPaymentUpdatePayload = CartPayload

    /// Cart remove personal data payload
    typealias CartRemovePersonalDataPayload = CartPayload

    /// Cart prepare for completion payload
    struct CartPrepareForCompletionPayload: Codable {
        let result: CartPrepareForCompletionResult?
        let userErrors: [CartUserError]
    }

    /// Cart prepare for completion result (union type)
    enum CartPrepareForCompletionResult: Codable {
        case ready(CartStatusReady)
        case throttled(CartThrottled)
        case notReady(CartStatusNotReady)

        private enum CodingKeys: String, CodingKey {
            case __typename
        }

        private enum TypeName: String, Codable {
            case cartStatusReady = "CartStatusReady"
            case cartThrottled = "CartThrottled"
            case cartStatusNotReady = "CartStatusNotReady"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let typename = try container.decode(TypeName.self, forKey: .__typename)

            switch typename {
            case .cartStatusReady:
                let ready = try CartStatusReady(from: decoder)
                self = .ready(ready)
            case .cartThrottled:
                let throttled = try CartThrottled(from: decoder)
                self = .throttled(throttled)
            case .cartStatusNotReady:
                let notReady = try CartStatusNotReady(from: decoder)
                self = .notReady(notReady)
            }
        }

        func encode(to encoder: Encoder) throws {
            switch self {
            case let .ready(ready):
                try ready.encode(to: encoder)
            case let .throttled(throttled):
                try throttled.encode(to: encoder)
            case let .notReady(notReady):
                try notReady.encode(to: encoder)
            }
        }
    }

    /// Cart status ready
    struct CartStatusReady: Codable {
        let cart: Cart?
        let checkoutURL: GraphQLScalars.URL?
    }

    /// Cart throttled
    struct CartThrottled: Codable {
        let pollAfter: GraphQLScalars.DateTime
    }

    /// Cart status not ready
    struct CartStatusNotReady: Codable {
        let cart: Cart?
        let errors: [CompletionError]
    }

    /// Completion error
    struct CompletionError: Codable {
        let code: CompletionErrorCode
        let message: String
    }

    /// Completion error codes
    enum CompletionErrorCode: String, Codable {
        case error = "ERROR"
        case inventoryLocationNotFound = "INVENTORY_LOCATION_NOT_FOUND"
        case paymentAmountTooSmall = "PAYMENT_AMOUNT_TOO_SMALL"
        case paymentCallIssuer = "PAYMENT_CALL_ISSUER"
        case paymentCardDeclined = "PAYMENT_CARD_DECLINED"
        case paymentError = "PAYMENT_ERROR"
        case paymentGatewayNotEnabledForShop = "PAYMENT_GATEWAY_NOT_ENABLED_FOR_SHOP"
        case paymentInsufficientFunds = "PAYMENT_INSUFFICIENT_FUNDS"
        case paymentInvalidAmount = "PAYMENT_INVALID_AMOUNT"
        case paymentInvalidBillingAddress = "PAYMENT_INVALID_BILLING_ADDRESS"
        case paymentInvalidCreditCard = "PAYMENT_INVALID_CREDIT_CARD"
        case paymentInvalidCurrency = "PAYMENT_INVALID_CURRENCY"
        case paymentInvalidPaymentMethod = "PAYMENT_INVALID_PAYMENT_METHOD"
        case paymentTransientError = "PAYMENT_TRANSIENT_ERROR"
        case billingAddressInvalid = "BILLING_ADDRESS_INVALID"
        case checkoutCompletionTargetInvalid = "CHECKOUT_COMPLETION_TARGET_INVALID"
        case colorInvalid = "COLOR_INVALID"
        case deliveryAddress1Invalid = "DELIVERY_ADDRESS1_INVALID"
        case deliveryAddress1Missing = "DELIVERY_ADDRESS1_MISSING"
        case deliveryAddress1TooLong = "DELIVERY_ADDRESS1_TOO_LONG"
        case deliveryAddress2Invalid = "DELIVERY_ADDRESS2_INVALID"
        case deliveryAddress2Required = "DELIVERY_ADDRESS2_REQUIRED"
        case deliveryAddress2TooLong = "DELIVERY_ADDRESS2_TOO_LONG"
        case deliveryAddressInvalid = "DELIVERY_ADDRESS_INVALID"
        case deliveryAddressMissing = "DELIVERY_ADDRESS_MISSING"
        case deliveryAddressRequired = "DELIVERY_ADDRESS_REQUIRED"
        case deliveryOptionInvalid = "DELIVERY_OPTION_INVALID"
        case deliveryOptionsMissing = "DELIVERY_OPTIONS_MISSING"
        case deliveryPostalCodeInvalid = "DELIVERY_POSTAL_CODE_INVALID"
        case deliveryPostalCodeRequired = "DELIVERY_POSTAL_CODE_REQUIRED"
        case deliveryZoneNotFound = "DELIVERY_ZONE_NOT_FOUND"
        case deliveryZoneRequiredForCountry = "DELIVERY_ZONE_REQUIRED_FOR_COUNTRY"
        case deliveryCityInvalid = "DELIVERY_CITY_INVALID"
        case deliveryCityRequired = "DELIVERY_CITY_REQUIRED"
        case deliveryCityTooLong = "DELIVERY_CITY_TOO_LONG"
        case deliveryCompanyInvalid = "DELIVERY_COMPANY_INVALID"
        case deliveryCompanyRequired = "DELIVERY_COMPANY_REQUIRED"
        case deliveryCompanyTooLong = "DELIVERY_COMPANY_TOO_LONG"
        case deliveryCountryRequired = "DELIVERY_COUNTRY_REQUIRED"
        case deliveryFirstNameInvalid = "DELIVERY_FIRST_NAME_INVALID"
        case deliveryFirstNameRequired = "DELIVERY_FIRST_NAME_REQUIRED"
        case deliveryFirstNameTooLong = "DELIVERY_FIRST_NAME_TOO_LONG"
        case deliveryInvalidPostalCodeForCountry = "DELIVERY_INVALID_POSTAL_CODE_FOR_COUNTRY"
        case deliveryInvalidPostalCodeForZone = "DELIVERY_INVALID_POSTAL_CODE_FOR_ZONE"
        case deliveryLastNameInvalid = "DELIVERY_LAST_NAME_INVALID"
        case deliveryLastNameTooLong = "DELIVERY_LAST_NAME_TOO_LONG"
        case deliveryNoDeliveryAvailable = "DELIVERY_NO_DELIVERY_AVAILABLE"
        case deliveryNoDeliveryAvailableForMerchandiseLine = "DELIVERY_NO_DELIVERY_AVAILABLE_FOR_MERCHANDISE_LINE"
        case deliveryOptionsPhoneNumberInvalid = "DELIVERY_OPTIONS_PHONE_NUMBER_INVALID"
        case deliveryOptionsPhoneNumberRequired = "DELIVERY_OPTIONS_PHONE_NUMBER_REQUIRED"
        case deliveryPhoneNumberInvalid = "DELIVERY_PHONE_NUMBER_INVALID"
        case deliveryPhoneNumberRequired = "DELIVERY_PHONE_NUMBER_REQUIRED"
        case emailInvalid = "EMAIL_INVALID"
        case firstNameInvalid = "FIRST_NAME_INVALID"
        case firstNameRequired = "FIRST_NAME_REQUIRED"
        case firstNameTooLong = "FIRST_NAME_TOO_LONG"
        case functionInvalid = "FUNCTION_INVALID"
        case invalidAddress = "INVALID_ADDRESS"
        case lastNameInvalid = "LAST_NAME_INVALID"
        case lastNameRequired = "LAST_NAME_REQUIRED"
        case lastNameTooLong = "LAST_NAME_TOO_LONG"
        case deliveryLastNameRequired = "DELIVERY_LAST_NAME_REQUIRED"
        case noDeliveryGroupSelected = "NO_DELIVERY_GROUP_SELECTED"
        case paymentBillingAddressInvalid = "PAYMENT_BILLING_ADDRESS_INVALID"
        case paymentInvalid = "PAYMENT_INVALID"
        case paymentMethodInvalid = "PAYMENT_METHOD_INVALID"
        case paymentMethodRequired = "PAYMENT_METHOD_REQUIRED"
        case phoneInvalid = "PHONE_INVALID"
        case unknown = "UNKNOWN"
    }

    /// Cart submit for completion payload
    struct CartSubmitForCompletionPayload: Codable {
        let result: CartSubmitForCompletionResult?
        let userErrors: [CartUserError]
    }

    /// Cart submit for completion result (union type)
    enum CartSubmitForCompletionResult: Codable {
        case success(SubmitSuccess)
        case failed(SubmitFailed)
        case alreadyAccepted(SubmitAlreadyAccepted)
        case throttled(SubmitThrottled)

        private enum CodingKeys: String, CodingKey {
            case __typename
        }

        private enum TypeName: String, Codable {
            case submitSuccess = "SubmitSuccess"
            case submitFailed = "SubmitFailed"
            case submitAlreadyAccepted = "SubmitAlreadyAccepted"
            case submitThrottled = "SubmitThrottled"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let typename = try container.decode(TypeName.self, forKey: .__typename)

            switch typename {
            case .submitSuccess:
                let success = try SubmitSuccess(from: decoder)
                self = .success(success)
            case .submitFailed:
                let failed = try SubmitFailed(from: decoder)
                self = .failed(failed)
            case .submitAlreadyAccepted:
                let accepted = try SubmitAlreadyAccepted(from: decoder)
                self = .alreadyAccepted(accepted)
            case .submitThrottled:
                let throttled = try SubmitThrottled(from: decoder)
                self = .throttled(throttled)
            }
        }

        func encode(to encoder: Encoder) throws {
            switch self {
            case let .success(success):
                try success.encode(to: encoder)
            case let .failed(failed):
                try failed.encode(to: encoder)
            case let .alreadyAccepted(accepted):
                try accepted.encode(to: encoder)
            case let .throttled(throttled):
                try throttled.encode(to: encoder)
            }
        }
    }

    /// Submit success
    struct SubmitSuccess: Codable {
        let redirectUrl: GraphQLScalars.URL
    }

    /// Submit failed
    struct SubmitFailed: Codable {
        let checkoutUrl: GraphQLScalars.URL?
        let errors: [SubmissionError]
    }

    /// Submit already accepted
    struct SubmitAlreadyAccepted: Codable {
        let attemptId: String
    }

    /// Submit throttled
    struct SubmitThrottled: Codable {
        let pollAfter: GraphQLScalars.DateTime
    }

    /// Submission error
    struct SubmissionError: Codable {
        let code: SubmissionErrorCode
        let message: String
    }

    /// Submission error codes for cart submit
    enum SubmissionErrorCode: String, Codable {
        // Buyer identity errors
        case buyerIdentityEmailIsInvalid = "BUYER_IDENTITY_EMAIL_IS_INVALID"
        case buyerIdentityEmailRequired = "BUYER_IDENTITY_EMAIL_REQUIRED"
        case buyerIdentityPhoneIsInvalid = "BUYER_IDENTITY_PHONE_IS_INVALID"

        // Delivery address errors
        case deliveryAddressRequired = "DELIVERY_ADDRESS_REQUIRED"
        case deliveryAddress1Invalid = "DELIVERY_ADDRESS1_INVALID"
        case deliveryAddress1Required = "DELIVERY_ADDRESS1_REQUIRED"
        case deliveryAddress1TooLong = "DELIVERY_ADDRESS1_TOO_LONG"
        case deliveryAddress2Invalid = "DELIVERY_ADDRESS2_INVALID"
        case deliveryAddress2Required = "DELIVERY_ADDRESS2_REQUIRED"
        case deliveryAddress2TooLong = "DELIVERY_ADDRESS2_TOO_LONG"
        case deliveryCityInvalid = "DELIVERY_CITY_INVALID"
        case deliveryCityRequired = "DELIVERY_CITY_REQUIRED"
        case deliveryCityTooLong = "DELIVERY_CITY_TOO_LONG"
        case deliveryCompanyInvalid = "DELIVERY_COMPANY_INVALID"
        case deliveryCompanyRequired = "DELIVERY_COMPANY_REQUIRED"
        case deliveryCompanyTooLong = "DELIVERY_COMPANY_TOO_LONG"
        case deliveryCountryRequired = "DELIVERY_COUNTRY_REQUIRED"
        case deliveryFirstNameInvalid = "DELIVERY_FIRST_NAME_INVALID"
        case deliveryFirstNameRequired = "DELIVERY_FIRST_NAME_REQUIRED"
        case deliveryFirstNameTooLong = "DELIVERY_FIRST_NAME_TOO_LONG"
        case deliveryInvalidPostalCodeForCountry = "DELIVERY_INVALID_POSTAL_CODE_FOR_COUNTRY"
        case deliveryInvalidPostalCodeForZone = "DELIVERY_INVALID_POSTAL_CODE_FOR_ZONE"
        case deliveryLastNameInvalid = "DELIVERY_LAST_NAME_INVALID"
        case deliveryLastNameRequired = "DELIVERY_LAST_NAME_REQUIRED"
        case deliveryLastNameTooLong = "DELIVERY_LAST_NAME_TOO_LONG"
        case deliveryNoDeliveryAvailable = "DELIVERY_NO_DELIVERY_AVAILABLE"
        case deliveryNoDeliveryAvailableForMerchandiseLine = "DELIVERY_NO_DELIVERY_AVAILABLE_FOR_MERCHANDISE_LINE"
        case deliveryOptionsPhoneNumberInvalid = "DELIVERY_OPTIONS_PHONE_NUMBER_INVALID"
        case deliveryOptionsPhoneNumberRequired = "DELIVERY_OPTIONS_PHONE_NUMBER_REQUIRED"
        case deliveryPhoneNumberInvalid = "DELIVERY_PHONE_NUMBER_INVALID"
        case deliveryPhoneNumberRequired = "DELIVERY_PHONE_NUMBER_REQUIRED"
        case deliveryPostalCodeInvalid = "DELIVERY_POSTAL_CODE_INVALID"
        case deliveryPostalCodeRequired = "DELIVERY_POSTAL_CODE_REQUIRED"
        case deliveryZoneNotFound = "DELIVERY_ZONE_NOT_FOUND"
        case deliveryZoneRequiredForCountry = "DELIVERY_ZONE_REQUIRED_FOR_COUNTRY"

        // General error
        case error = "ERROR"

        // Payment errors
        case paymentCardDeclined = "PAYMENT_CARD_DECLINED"

        // Merchandise errors
        case merchandiseLineLimitReached = "MERCHANDISE_LINE_LIMIT_REACHED"
        case merchandiseNotApplicable = "MERCHANDISE_NOT_APPLICABLE"
        case merchandiseNotEnoughStockAvailable = "MERCHANDISE_NOT_ENOUGH_STOCK_AVAILABLE"
        case merchandiseOutOfStock = "MERCHANDISE_OUT_OF_STOCK"
        case merchandiseProductNotPublished = "MERCHANDISE_PRODUCT_NOT_PUBLISHED"

        // Delivery group errors
        case noDeliveryGroupSelected = "NO_DELIVERY_GROUP_SELECTED"

        // Payment address errors
        case paymentsAddress1Invalid = "PAYMENTS_ADDRESS1_INVALID"
        case paymentsAddress1Required = "PAYMENTS_ADDRESS1_REQUIRED"
        case paymentsAddress1TooLong = "PAYMENTS_ADDRESS1_TOO_LONG"
        case paymentsAddress2Invalid = "PAYMENTS_ADDRESS2_INVALID"
        case paymentsAddress2Required = "PAYMENTS_ADDRESS2_REQUIRED"
        case paymentsAddress2TooLong = "PAYMENTS_ADDRESS2_TOO_LONG"
        case paymentsBillingAddressZoneNotFound = "PAYMENTS_BILLING_ADDRESS_ZONE_NOT_FOUND"
        case paymentsBillingAddressZoneRequiredForCountry = "PAYMENTS_BILLING_ADDRESS_ZONE_REQUIRED_FOR_COUNTRY"
        case paymentsCityInvalid = "PAYMENTS_CITY_INVALID"
        case paymentsCityRequired = "PAYMENTS_CITY_REQUIRED"
        case paymentsCityTooLong = "PAYMENTS_CITY_TOO_LONG"
        case paymentsCompanyInvalid = "PAYMENTS_COMPANY_INVALID"
        case paymentsCompanyRequired = "PAYMENTS_COMPANY_REQUIRED"
        case paymentsCompanyTooLong = "PAYMENTS_COMPANY_TOO_LONG"
        case paymentsCountryRequired = "PAYMENTS_COUNTRY_REQUIRED"
        case paymentsCreditCardBaseExpired = "PAYMENTS_CREDIT_CARD_BASE_EXPIRED"
        case paymentsCreditCardBaseGatewayNotSupported = "PAYMENTS_CREDIT_CARD_BASE_GATEWAY_NOT_SUPPORTED"
        case paymentsCreditCardBaseInvalidStartDateOrIssueNumberForDebit = "PAYMENTS_CREDIT_CARD_BASE_INVALID_START_DATE_OR_ISSUE_NUMBER_FOR_DEBIT"
        case paymentsCreditCardBrandNotSupported = "PAYMENTS_CREDIT_CARD_BRAND_NOT_SUPPORTED"
        case paymentsCreditCardFirstNameBlank = "PAYMENTS_CREDIT_CARD_FIRST_NAME_BLANK"
        case paymentsCreditCardGeneric = "PAYMENTS_CREDIT_CARD_GENERIC"
        case paymentsCreditCardLastNameBlank = "PAYMENTS_CREDIT_CARD_LAST_NAME_BLANK"
        case paymentsCreditCardMonthInclusion = "PAYMENTS_CREDIT_CARD_MONTH_INCLUSION"
        case paymentsCreditCardNameInvalid = "PAYMENTS_CREDIT_CARD_NAME_INVALID"
        case paymentsCreditCardNumberInvalid = "PAYMENTS_CREDIT_CARD_NUMBER_INVALID"
        case paymentsCreditCardNumberInvalidFormat = "PAYMENTS_CREDIT_CARD_NUMBER_INVALID_FORMAT"
        case paymentsCreditCardSessionId = "PAYMENTS_CREDIT_CARD_SESSION_ID"
        case paymentsCreditCardVerificationValueBlank = "PAYMENTS_CREDIT_CARD_VERIFICATION_VALUE_BLANK"
        case paymentsCreditCardVerificationValueInvalidForCardType = "PAYMENTS_CREDIT_CARD_VERIFICATION_VALUE_INVALID_FOR_CARD_TYPE"
        case paymentsCreditCardYearExpired = "PAYMENTS_CREDIT_CARD_YEAR_EXPIRED"
        case paymentsCreditCardYearInvalidExpiryYear = "PAYMENTS_CREDIT_CARD_YEAR_INVALID_EXPIRY_YEAR"
        case paymentsFirstNameInvalid = "PAYMENTS_FIRST_NAME_INVALID"
        case paymentsFirstNameRequired = "PAYMENTS_FIRST_NAME_REQUIRED"
        case paymentsFirstNameTooLong = "PAYMENTS_FIRST_NAME_TOO_LONG"
        case paymentsInvalidPostalCodeForCountry = "PAYMENTS_INVALID_POSTAL_CODE_FOR_COUNTRY"
        case paymentsInvalidPostalCodeForZone = "PAYMENTS_INVALID_POSTAL_CODE_FOR_ZONE"
        case paymentsLastNameInvalid = "PAYMENTS_LAST_NAME_INVALID"
        case paymentsLastNameRequired = "PAYMENTS_LAST_NAME_REQUIRED"
        case paymentsLastNameTooLong = "PAYMENTS_LAST_NAME_TOO_LONG"
        case paymentsMethodRequired = "PAYMENTS_METHOD_REQUIRED"
        case paymentsMethodUnavailable = "PAYMENTS_METHOD_UNAVAILABLE"
        case paymentsPhoneNumberInvalid = "PAYMENTS_PHONE_NUMBER_INVALID"
        case paymentsPhoneNumberRequired = "PAYMENTS_PHONE_NUMBER_REQUIRED"
        case paymentsPostalCodeInvalid = "PAYMENTS_POSTAL_CODE_INVALID"
        case paymentsPostalCodeRequired = "PAYMENTS_POSTAL_CODE_REQUIRED"
        case paymentsShopifyPaymentsRequired = "PAYMENTS_SHOPIFY_PAYMENTS_REQUIRED"
        case paymentsUnacceptablePaymentAmount = "PAYMENTS_UNACCEPTABLE_PAYMENT_AMOUNT"
        case paymentsWalletContentMissing = "PAYMENTS_WALLET_CONTENT_MISSING"

        // Redirect and tax errors
        case redirectToCheckoutRequired = "REDIRECT_TO_CHECKOUT_REQUIRED"
        case taxesDeliveryGroupIdNotFound = "TAXES_DELIVERY_GROUP_ID_NOT_FOUND"
        case taxesLineIdNotFound = "TAXES_LINE_ID_NOT_FOUND"
        case taxesMustBeDefined = "TAXES_MUST_BE_DEFINED"

        // Validation errors
        case validationCustom = "VALIDATION_CUSTOM"

        // Catch-all for unknown values
        case unknownValue = "UNKNOWN_VALUE"

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            self = SubmissionErrorCode(rawValue: value) ?? .unknownValue
        }
    }

    // MARK: - Query Response Wrappers

    /// Response wrapper for cart query
    struct CartQueryResponse: Codable {
        let cart: Cart?
    }

    /// Response wrapper for products query
    struct ProductsQueryResponse: Codable {
        let products: ProductConnection
    }

    /// Response wrapper for shop query
    struct ShopQueryResponse: Codable {
        let shop: Shop
    }

    // MARK: - Input Types

    /// Unified address structure for input operations
    struct Address {
        let address1: String?
        let address2: String?
        let city: String?
        let country: String?
        let firstName: String?
        let lastName: String?
        let phone: String?
        let province: String?
        let zip: String?

        init(
            address1: String? = nil,
            address2: String? = nil,
            city: String? = nil,
            country: String? = nil,
            firstName: String? = nil,
            lastName: String? = nil,
            phone: String? = nil,
            province: String? = nil,
            zip: String? = nil
        ) {
            self.address1 = address1
            self.address2 = address2
            self.city = city
            self.country = country
            self.firstName = firstName
            self.lastName = lastName
            self.phone = phone
            self.province = province
            self.zip = zip
        }
    }

    /// Type alias for Apple Pay billing address (uses same structure as Address)
    typealias ApplePayBillingAddress = Address

    /// Type alias for delivery address (uses same structure as Address)
    typealias DeliveryAddress = Address

    /// Apple Pay payment data
    struct ApplePayPayment {
        let billingAddress: ApplePayBillingAddress
        let ephemeralPublicKey: String
        let publicKeyHash: String
        let transactionId: String
        let data: String
        let signature: String
        let version: String
        let lastDigits: String
    }

    // MARK: - Address Conversion
}

@available(iOS 17.0, *)
extension StorefrontAPI.Address {
    /// Convert to dictionary for GraphQL input with countryCode/provinceCode fields
    var graphQLInput: [String: Any?] {
        return [
            "address1": address1,
            "address2": address2,
            "city": city,
            "countryCode": country,
            "firstName": firstName,
            "lastName": lastName,
            "phone": phone,
            "provinceCode": province,
            "zip": zip
        ]
    }
}

/// Represents shop settings data fetched from the Storefront API
/// https://shopify.dev/docs/api/storefront/2025-07/objects/Shop
@available(iOS 17.0, *)
@Observable class ShopSettings {
    /// Clear cached shop settings
    static func clearCache() {
        Task { await QueryCache.shared.clearCache() }
    }

    /// The shop's name (merchant name for display)
    let name: String

    /// The shop's primary domain information
    let primaryDomain: Domain

    /// Payment-related settings for the shop
    let paymentSettings: PaymentSettings

    init(
        name: String,
        primaryDomain: Domain,
        paymentSettings: PaymentSettings
    ) {
        self.name = name
        self.primaryDomain = primaryDomain
        self.paymentSettings = paymentSettings
    }

    /// Convenience initializer to create from StorefrontAPI.Shop response
    convenience init(from shop: StorefrontAPI.Shop) {
        // Extract payment settings
        // Use countryCode from paymentSettings, fallback to first country in shipsToCountries if needed
        let countryCode = shop.paymentSettings.countryCode.isEmpty ?
            (shop.shipsToCountries.first ?? "US") :
            shop.paymentSettings.countryCode

        let paymentSettings = PaymentSettings(
            countryCode: countryCode,
            acceptedCardBrands: shop.paymentSettings.acceptedCardBrands
        )

        // Extract primary domain
        let primaryDomain = Domain(
            host: shop.primaryDomain.host,
            url: shop.primaryDomain.url.url.absoluteString
        )

        self.init(
            name: shop.name,
            primaryDomain: primaryDomain,
            paymentSettings: paymentSettings
        )
    }
}

/// Payment settings for the shop
@available(iOS 17.0, *)
class PaymentSettings {
    /// The shop's country code (e.g., "US", "CA")
    let countryCode: String

    /// Card brands accepted by the merchant
    let acceptedCardBrands: [StorefrontAPI.CardBrand]

    init(countryCode: String, acceptedCardBrands: [StorefrontAPI.CardBrand] = []) {
        self.countryCode = countryCode
        self.acceptedCardBrands = acceptedCardBrands
    }
}

/// Domain information for the shop
@available(iOS 17.0, *)
class Domain {
    /// The host name of the domain (e.g., "example.myshopify.com")
    let host: String

    /// The full URL of the domain (e.g., "https://example.myshopify.com")
    let url: String

    init(host: String, url: String) {
        self.host = host
        self.url = url
    }
}
