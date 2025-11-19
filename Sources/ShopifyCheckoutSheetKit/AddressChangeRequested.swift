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

public final class AddressChangeRequested: BaseRPCRequest<AddressChangeRequestedParams, DeliveryAddressChangePayload> {
    override public static var method: String { "checkout.addressChangeRequested" }

    override public func validate(payload: ResponsePayload) throws {
        let addresses = payload.delivery.addresses
        guard !addresses.isEmpty else {
            throw EventResponseError.validationFailed("At least one address is required")
        }

        for (index, selectableAddress) in addresses.enumerated() {
            switch selectableAddress.address {
            case let .deliveryAddress(address):
                if let countryCode = address.countryCode, countryCode.isEmpty {
                    throw EventResponseError.validationFailed(
                        "Country code cannot be empty at index \(index)"
                    )
                }
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
}

public struct DeliveryAddressChangePayload: Codable {
    public let delivery: CartDelivery

    public init(delivery: CartDelivery) {
        self.delivery = delivery
    }
}
