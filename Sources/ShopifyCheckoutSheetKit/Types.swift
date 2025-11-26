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

// MARK: - Order Confirmation

// Common data types shared between lifecycle events

public struct OrderConfirmation: Codable {
    public let url: String?
    public let order: Order
    public let number: String?
    public let isFirstOrder: Bool

    public struct Order: Codable {
        public let id: String
    }
}

// MARK: - Cart

/// Represents a shopping cart in the checkout flow
public struct Cart: Codable {
    public let id: String
    public let lines: [CartLine]
    public let cost: CartCost
    public let buyerIdentity: CartBuyerIdentity
    public let deliveryGroups: [CartDeliveryGroup]
    public let discountCodes: [CartDiscountCode]
    public let appliedGiftCards: [AppliedGiftCard]
    public let discountAllocations: [CartDiscountAllocation]
    public let delivery: CartDelivery
}

public struct CartLine: Codable {
    public let id: String
    public let quantity: Int
    public let merchandise: CartLineMerchandise
    public let cost: CartLineCost
    public let discountAllocations: [CartDiscountAllocation]
}

public struct CartLineCost: Codable {
    public let amountPerQuantity: Money
    public let subtotalAmount: Money
    public let totalAmount: Money
}

public struct CartLineMerchandise: Codable {
    public let id: String
    public let title: String
    public let product: Product
    public let image: MerchandiseImage?
    public let selectedOptions: [SelectedOption]

    public struct Product: Codable {
        public let id: String
        public let title: String
    }
}

public struct MerchandiseImage: Codable {
    public let url: String
    public let altText: String?
}

public struct SelectedOption: Codable {
    public let name: String
    public let value: String
}

public struct CartDiscountAllocation: Codable {
    public let discountedAmount: Money
    public let discountApplication: DiscountApplication
    public let targetType: DiscountApplicationTargetType
}

public struct DiscountApplication: Codable {
    public let allocationMethod: AllocationMethod
    public let targetSelection: TargetSelection
    public let targetType: DiscountApplicationTargetType
    public let value: DiscountValue

    public enum AllocationMethod: String, Codable {
        case across = "ACROSS"
        case each = "EACH"
    }

    public enum TargetSelection: String, Codable {
        case all = "ALL"
        case entitled = "ENTITLED"
        case explicit = "EXPLICIT"
    }
}

public enum DiscountApplicationTargetType: String, Codable {
    case lineItem = "LINE_ITEM"
    case shippingLine = "SHIPPING_LINE"
}

public struct CartCost: Codable {
    public let subtotalAmount: Money
    public let totalAmount: Money
}

public struct CartBuyerIdentity: Codable {
    public let email: String?
    public let phone: String?
    public let customer: Customer?
    public let countryCode: String?
}

public struct Customer: Codable {
    public let id: String?
    public let firstName: String?
    public let lastName: String?
    public let email: String?
    public let phone: String?
}

public struct CartDeliveryGroup: Codable {
    public let deliveryAddress: MailingAddress
    public let deliveryOptions: [CartDeliveryOption]
    public let selectedDeliveryOption: CartDeliveryOption?
    public let groupType: CartDeliveryGroupType
}

public struct MailingAddress: Codable {
    public let address1: String?
    public let address2: String?
    public let city: String?
    public let province: String?
    public let country: String?
    public let countryCodeV2: String?
    public let zip: String?
    public let firstName: String?
    public let lastName: String?
    public let phone: String?
    public let company: String?
}

public struct CartDeliveryOption: Codable {
    public let code: String?
    public let title: String?
    public let description: String?
    public let handle: String
    public let estimatedCost: Money
    public let deliveryMethodType: CartDeliveryMethodType
}

public enum CartDeliveryMethodType: String, Codable {
    case shipping = "SHIPPING"
    case pickup = "PICKUP"
    case pickupPoint = "PICKUP_POINT"
    case local = "LOCAL"
    case none = "NONE"
}

public enum CartDeliveryGroupType: String, Codable {
    case subscription = "SUBSCRIPTION"
    case oneTimePurchase = "ONE_TIME_PURCHASE"
}

public struct CartDelivery: Codable {
    public let addresses: [CartSelectableAddress]

    public init(addresses: [CartSelectableAddress]) {
        self.addresses = addresses
    }
}

/// Represents a delivery address union type from the Storefront API
/// https://shopify.dev/docs/api/storefront/latest/unions/CartAddress
public enum CartAddress: Codable {
    case deliveryAddress(CartDeliveryAddress)

    public init(from decoder: Decoder) throws {
        // Protocol is versioned - for current version, always CartDeliveryAddress
        let address = try CartDeliveryAddress(from: decoder)
        self = .deliveryAddress(address)
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case let .deliveryAddress(address):
            try address.encode(to: encoder)
        }
    }
}

public struct CartSelectableAddress: Codable {
    public let address: CartAddress

    public init(address: CartAddress) {
        self.address = address
    }
}

public struct CartDeliveryAddress: Codable {
    public let address1: String?
    public let address2: String?
    public let city: String?
    public let company: String?
    public let countryCode: String?
    public let firstName: String?
    public let lastName: String?
    public let phone: String?
    public let provinceCode: String?
    public let zip: String?

    public init(
        firstName: String? = nil,
        lastName: String? = nil,
        address1: String? = nil,
        address2: String? = nil,
        city: String? = nil,
        company: String? = nil,
        countryCode: String? = nil,
        phone: String? = nil,
        provinceCode: String? = nil,
        zip: String? = nil
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.address1 = address1
        self.address2 = address2
        self.city = city
        self.company = company
        self.countryCode = countryCode
        self.phone = phone
        self.provinceCode = provinceCode
        self.zip = zip
    }
}

public struct CartDiscountCode: Codable {
    public let code: String
    public let applicable: Bool
}

public struct AppliedGiftCard: Codable {
    public let amountUsed: Money
    public let balance: Money
    public let lastCharacters: String
    public let presentmentAmountUsed: Money
}

public struct Money: Codable {
    public let amount: String
    public let currencyCode: String
}

public struct PricingPercentageValue: Codable {
    public let percentage: Double
}

public enum DiscountValue: Codable {
    case money(Money)
    case percentage(PricingPercentageValue)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let money = try? container.decode(Money.self) {
            self = .money(money)
            return
        }

        if let percentage = try? container.decode(PricingPercentageValue.self) {
            self = .percentage(percentage)
            return
        }

        throw DecodingError.typeMismatch(
            DiscountValue.self,
            DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Unable to decode DiscountValue"
            )
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case let .money(money):
            try container.encode(money)
        case let .percentage(percentage):
            try container.encode(percentage)
        }
    }
}

// MARK: - Cart Input Types

/// Cart input types for updating cart state from embedder responses.
///
/// Mirrors the [Storefront API CartInput](https://shopify.dev/docs/api/storefront/latest/input-objects/CartInput).
public struct CartInput: Codable {
    /// The delivery-related fields for the cart.
    public let delivery: CartDeliveryInput?

    /// The customer associated with the cart.
    public let buyerIdentity: CartBuyerIdentityInput?

    /// The case-insensitive discount codes that the customer added at checkout.
    public let discountCodes: [String]?

    public init(
        delivery: CartDeliveryInput? = nil,
        buyerIdentity: CartBuyerIdentityInput? = nil,
        discountCodes: [String]? = nil
    ) {
        self.delivery = delivery
        self.buyerIdentity = buyerIdentity
        self.discountCodes = discountCodes
    }
}

/// Delivery-related fields for the cart.
public struct CartDeliveryInput: Codable {
    /// Selectable addresses presented to the buyer.
    public let addresses: [CartSelectableAddressInput]?

    public init(addresses: [CartSelectableAddressInput]? = nil) {
        self.addresses = addresses
    }
}

/// A selectable delivery address with optional selection settings.
public struct CartSelectableAddressInput: Codable {
    /// Exactly one kind of delivery address.
    public let address: CartDeliveryAddressInput

    /// Whether this address is selected as the active delivery address.
    public let selected: Bool?

    public init(address: CartDeliveryAddressInput, selected: Bool? = nil) {
        self.address = address
        self.selected = selected
    }
}

/// A delivery address for a cart.
///
/// Based on [Storefront API MailingAddressInput](https://shopify.dev/docs/api/storefront/latest/input-objects/MailingAddressInput).
public struct CartDeliveryAddressInput: Codable {
    /// The first line of the address. Typically the street address or PO Box number.
    public let address1: String?

    /// The second line of the address. Typically the number of the apartment, suite, or unit.
    public let address2: String?

    /// The name of the city, district, village, or town.
    public let city: String?

    /// The name of the customer's company or organization.
    public let company: String?

    /// The two-letter country code (ISO 3166-1 alpha-2 format, e.g., "US", "CA").
    public let countryCode: String?

    /// The first name of the customer.
    public let firstName: String?

    /// The last name of the customer.
    public let lastName: String?

    /// The phone number for the address. Formatted using E.164 standard (e.g., +16135551111).
    public let phone: String?

    /// The code for the region of the address, such as the province or state (e.g., "ON" for Ontario, or "CA" for California).
    public let provinceCode: String?

    /// The zip or postal code of the address.
    public let zip: String?

    public init(
        firstName: String? = nil,
        lastName: String? = nil,
        address1: String? = nil,
        address2: String? = nil,
        city: String? = nil,
        company: String? = nil,
        countryCode: String? = nil,
        phone: String? = nil,
        provinceCode: String? = nil,
        zip: String? = nil
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.address1 = address1
        self.address2 = address2
        self.city = city
        self.company = company
        self.countryCode = countryCode
        self.phone = phone
        self.provinceCode = provinceCode
        self.zip = zip
    }
}

/// The customer associated with the cart.
///
/// Based on [Storefront API CartBuyerIdentityInput](https://shopify.dev/docs/api/storefront/latest/input-objects/CartBuyerIdentityInput).
public struct CartBuyerIdentityInput: Codable {
    /// The email address of the buyer that is interacting with the cart / checkout.
    public let email: String?

    /// The phone number of the buyer that is interacting with the cart / checkout.
    public let phone: String?

    /// The country where the buyer is located. Two-letter country code (ISO 3166-1 alpha-2, e.g. US, GB, CA).
    public let countryCode: String?

    public init(email: String? = nil, phone: String? = nil, countryCode: String? = nil) {
        self.email = email
        self.phone = phone
        self.countryCode = countryCode
    }
}

/// Application-level error in cart response payload
public struct ResponseError: Codable {
    public let code: String
    public let message: String
    public let fieldTarget: String?

    public init(code: String, message: String, fieldTarget: String? = nil) {
        self.code = code
        self.message = message
        self.fieldTarget = fieldTarget
    }
}

// MARK: - Payment Token Types

/// Payment token input structure for checkout submission.
public struct CartPaymentTokenInput: Codable {
    public let token: String
    public let tokenType: String
    public let tokenProvider: String

    public init(token: String, tokenType: String, tokenProvider: String) {
        self.token = token
        self.tokenType = tokenType
        self.tokenProvider = tokenProvider
    }
}

// MARK: - Checkout Session

/// Checkout session information.
public struct Checkout: Codable {
    /// The checkout session identifier
    public let id: String

    public init(id: String) {
        self.id = id
    }
}
