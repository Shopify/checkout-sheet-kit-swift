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

public final class AddressChangeRequested: BaseRPCRequest<AddressChangeRequestedParams, CartDelivery> {
    public override class var method: String { "checkout.addressChangeRequested" }

    public override func validate(payload: ResponsePayload) throws {
        let addresses = payload.addresses
        guard !addresses.isEmpty else {
            throw EventResponseError.validationFailed("At least one address is required")
        }

        for (index, selectableAddress) in addresses.enumerated() {
            let address = selectableAddress.address

            if let countryCode = address.countryCode, countryCode.isEmpty {
                throw EventResponseError.validationFailed(
                    "Country code cannot be empty at index \(index)"
                )
            }
        }
    }
}

public struct AddressChangeRequestedParams: Codable {
    public let addressType: String
    public let selectedAddress: IncomingAddress?
}

/// Address structure from incoming JSON-RPC request
public struct IncomingAddress: Codable {
    public let firstName: String?
    public let lastName: String?
    public let name: String?
    public let address1: String?
    public let address2: String?
    public let city: String?
    public let countryCode: String?
    public let postalCode: String?
    public let zoneCode: String?
    public let phone: String?
    /// TODO; DELETE THESE PROPERTIES ONCE WEB IS SENDING OVER THE ORIGINAL CARTDELIVERY AGAIN
    public let oneTimeUse: Bool?
    public let coordinates: Coordinates?

    public struct Coordinates: Codable {
        public let latitude: Double
        public let longitude: Double
    }
}

/// https://shopify.dev/docs/api/storefront/latest/objects/CartDelivery
public struct CartDelivery: Codable {
    public let addresses: [CartSelectableAddress]

    public init(addresses: [CartSelectableAddress]) {
        self.addresses = addresses
    }
}

/// https://shopify.dev/docs/api/storefront/latest/objects/CartSelectableAddress
public struct CartSelectableAddress: Codable {
    public let address: CartAddress
    /// Possible other properties, oneTimeUse, selected, id

    public init(address: CartAddress) {
        self.address = address
    }
}

/// https://shopify.dev/docs/api/storefront/latest/objects/CartAddress
public struct CartAddress: Codable {
    public let firstName: String?
    public let lastName: String?
    public let address1: String?
    public let address2: String?
    public let city: String?
    public let countryCode: String?
    public let phone: String?
    public let provinceCode: String?
    public let zip: String?

    public init(
        firstName: String? = nil,
        lastName: String? = nil,
        address1: String? = nil,
        address2: String? = nil,
        city: String? = nil,
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
        self.countryCode = countryCode
        self.phone = phone
        self.provinceCode = provinceCode
        self.zip = zip
    }
}
