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
import WebKit

public final class CheckoutCardChangeRequested: BaseRPCRequest<CheckoutCardChangeRequestedParams, CheckoutCardChangeResult> {
    override public static var method: String { "checkout.cardChangeRequested" }

    override public func validate(payload: ResponsePayload) throws {
        let card = payload.card

        guard card.last4.count == 4 else {
            throw CheckoutEventResponseError.validationFailed("Card last4 must be exactly 4 digits")
        }

        guard !card.brand.isEmpty else {
            throw CheckoutEventResponseError.validationFailed("Card brand cannot be empty")
        }

        let billing = payload.billing

        if !billing.useDeliveryAddress {
            guard let address = billing.address else {
                throw CheckoutEventResponseError.validationFailed("Billing address is required when useDeliveryAddress is false")
            }

            if let countryCode = address.countryCode, countryCode.isEmpty {
                throw CheckoutEventResponseError.validationFailed("Country code cannot be empty")
            }
        }
    }
}

public struct CheckoutCardChangeRequestedParams: Codable {
    public let currentCard: CurrentCard?

    public struct CurrentCard: Codable {
        public let last4: String
        public let brand: String
    }
}

public struct CheckoutCardChangeResult: Codable {
    public let card: Card
    public let billing: BillingInfo

    public init(card: Card, billing: BillingInfo) {
        self.card = card
        self.billing = billing
    }

    public struct Card: Codable {
        public let last4: String
        public let brand: String

        public init(last4: String, brand: String) {
            self.last4 = last4
            self.brand = brand
        }
    }

    public struct BillingInfo: Codable {
        public let useDeliveryAddress: Bool
        public let address: BillingAddress?

        public init(useDeliveryAddress: Bool, address: BillingAddress? = nil) {
            self.useDeliveryAddress = useDeliveryAddress
            self.address = address
        }
    }

    public struct BillingAddress: Codable {
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
            address1: String? = nil,
            address2: String? = nil,
            city: String? = nil,
            company: String? = nil,
            countryCode: String? = nil,
            firstName: String? = nil,
            lastName: String? = nil,
            phone: String? = nil,
            provinceCode: String? = nil,
            zip: String? = nil
        ) {
            self.address1 = address1
            self.address2 = address2
            self.city = city
            self.company = company
            self.countryCode = countryCode
            self.firstName = firstName
            self.lastName = lastName
            self.phone = phone
            self.provinceCode = provinceCode
            self.zip = zip
        }
    }
}
