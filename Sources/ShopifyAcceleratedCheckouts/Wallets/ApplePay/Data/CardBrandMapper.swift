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

import PassKit

@available(iOS 15.0, *)
enum CardBrandMapper {
    /// Maps Shopify's CardBrand enum values to Apple Pay's PKPaymentNetwork values
    /// - Parameter shopifyCardBrand: The card brand from Shopify's acceptedCardBrands
    /// - Returns: The corresponding PKPaymentNetwork, or nil if the brand is not supported by Apple Pay
    static func mapToPKPaymentNetwork(_ shopifyCardBrand: StorefrontAPI.CardBrand) -> PKPaymentNetwork? {
        switch shopifyCardBrand {
        case .americanExpress:
            return .amex
        case .discover:
            return .discover
        case .jcb:
            return .JCB
        case .mastercard:
            return .masterCard
        case .visa:
            return .visa
        case .dinersClub:
            // Diners Club is not supported by Apple Pay
            return nil
        }
    }

    /// Maps an array of Shopify card brands to PKPaymentNetwork values
    /// - Parameter shopifyCardBrands: Array of card brands from Shopify
    /// - Returns: Array of PKPaymentNetwork values, filtering out any unsupported brands
    static func mapToPKPaymentNetworks(_ shopifyCardBrands: [StorefrontAPI.CardBrand]) -> [PKPaymentNetwork] {
        shopifyCardBrands.compactMap { mapToPKPaymentNetwork($0) }
    }
}
