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

// MARK: - Main Payload Types

/// Payload for embedded checkout state change events (Schema 2025-04)
public struct CheckoutStatePayload: Codable {
    public let flowType: FlowType
    public let cart: EmbeddedCartInfo?
    public let buyer: EmbeddedBuyerInfo?
    public let delivery: EmbeddedDeliveryInfo?
    public let payment: EmbeddedPaymentMethod?
}

/// Payload for embedded checkout completion events (Schema 2025-04)
public struct CheckoutCompletePayload: Codable {
    public let flowType: FlowType
    public let orderID: String?
    public let cart: EmbeddedCartInfo?
    public let buyer: EmbeddedBuyerInfo?
    public let delivery: EmbeddedDeliveryInfo?
    public let payment: EmbeddedPaymentMethod?

    public init(orderID: String?) {
        flowType = .embedded
        self.orderID = orderID
        cart = nil
        buyer = nil
        delivery = nil
        payment = nil
    }
}

/// Payload for embedded checkout web pixel events (Schema 2025-04)
public struct WebPixelsPayload: Codable {
    public let flowType: FlowType
    public let type: PixelEventType
    public let name: String
    public let timestamp: String
    public let data: AnyCodable?
}

// MARK: - Supporting Data Types

/// Information about the shopping cart
public struct EmbeddedCartInfo: Codable {
    public let token: String?
    public let lines: [EmbeddedCartLine]?
    public let totalAmount: EmbeddedMoneyAmount?
    public let subtotalAmount: EmbeddedMoneyAmount?
    public let taxAmount: EmbeddedMoneyAmount?
    public let shippingAmount: EmbeddedMoneyAmount?
}

/// Individual cart line item
public struct EmbeddedCartLine: Codable {
    public let id: String
    public let quantity: Int
    public let merchandise: EmbeddedMerchandise
    public let totalAmount: EmbeddedMoneyAmount?
}

/// Product merchandise information
public struct EmbeddedMerchandise: Codable {
    public let id: String
    public let title: String?
    public let image: EmbeddedImageInfo?
    public let product: EmbeddedProductInfo?
}

/// Product information
public struct EmbeddedProductInfo: Codable {
    public let id: String
    public let title: String?
    public let vendor: String?
    public let type: String?
}

/// Image information
public struct EmbeddedImageInfo: Codable {
    public let url: String?
    public let altText: String?
}

/// Money amount with currency
public struct EmbeddedMoneyAmount: Codable {
    public let amount: String
    public let currencyCode: String
}

/// Buyer information
public struct EmbeddedBuyerInfo: Codable {
    public let email: String?
    public let phone: String?
    public let acceptsMarketing: Bool?
    public let firstName: String?
    public let lastName: String?
}

/// Delivery information
public struct EmbeddedDeliveryInfo: Codable {
    public let address: EmbeddedAddressInfo?
    public let method: DeliveryMethodType?
    public let instructions: String?
}

/// Address information
public struct EmbeddedAddressInfo: Codable {
    public let address1: String?
    public let address2: String?
    public let city: String?
    public let company: String?
    public let country: String?
    public let countryCode: String?
    public let firstName: String?
    public let lastName: String?
    public let phone: String?
    public let province: String?
    public let provinceCode: String?
    public let zip: String?
}

/// Payment method information
public struct EmbeddedPaymentMethod: Codable {
    public let type: String?
    public let details: AnyCodable?
}

// MARK: - Enums

/// Flow type for embedded checkout (Schema 2025-04)
public enum FlowType: String, Codable {
    case embedded
    case checkout
}

/// Delivery method types
public enum DeliveryMethodType: String, Codable {
    case shipping
    case pickup
    case delivery
}

/// Web pixel event types
public enum PixelEventType: String, Codable {
    case standard
    case custom
    case advancedDom = "advanced-dom"
}

// MARK: - Error Models

public struct ErrorPayload: Codable {
    public let flowType: FlowType
    public let group: String
    public let type: String
    public let code: String?
    public let reason: String?
}

public struct AuthenticationErrorPayload: Codable {
    public let group: String = "authentication"
    public let code: String
    public let reason: String?
}

public struct KillswitchErrorPayload: Codable {
    public let group: String = "killswitch"
    public let reason: String?
}

// MARK: - CheckoutOptions

/// Options for configuring embedded checkout behavior
public struct CheckoutOptions {
    /// Authentication configuration for embedded checkout
    public let appAuthentication: AppAuthentication?

    public init(appAuthentication: AppAuthentication? = nil) {
        self.appAuthentication = appAuthentication
    }
}

/// Authentication methods for embedded checkout
public enum AppAuthentication {
    /// Token-based authentication for partner access
    case token(String)
}

// MARK: - Helper Types

/// A type-erased wrapper for any Codable value, used for handling arbitrary JSON values
public struct AnyCodable: Codable {
    public let value: Any

    public init(_ value: (some Any)?) {
        self.value = value ?? ()
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self.init(())
        } else if let bool = try? container.decode(Bool.self) {
            self.init(bool)
        } else if let int = try? container.decode(Int.self) {
            self.init(int)
        } else if let double = try? container.decode(Double.self) {
            self.init(double)
        } else if let string = try? container.decode(String.self) {
            self.init(string)
        } else if let array = try? container.decode([AnyCodable].self) {
            self.init(array.map { $0.value })
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.init(Dictionary(uniqueKeysWithValues: dictionary.map { key, value in
                (key, value.value)
            }))
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case is Void:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            let anyArray = array.map(AnyCodable.init)
            try container.encode(anyArray)
        case let dictionary as [String: Any]:
            let anyDictionary = Dictionary(uniqueKeysWithValues: dictionary.map { key, value in
                (key, AnyCodable(value))
            })
            try container.encode(anyDictionary)
        default:
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable value cannot be encoded")
            throw EncodingError.invalidValue(value, context)
        }
    }
}