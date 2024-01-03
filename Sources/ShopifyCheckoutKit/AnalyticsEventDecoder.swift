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

struct AnalyticsEvent: Decodable {
    let name: String
    let event: AnalyticsEventBody
}

struct AnalyticsEventBody: Decodable {
    let id: String
    let name: String
    let timestamp: String
    let type: String
    let customData: CustomData?
    let data: [String: Any]?
    let context: Context?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case timestamp
        case type
        case customData
        case data
        case context
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        timestamp = try container.decode(String.self, forKey: .timestamp)
        type = try container.decode(String.self, forKey: .type)
        context = try container.decode(Context.self, forKey: .context)

        switch type {
        case "standard":
            data = try container.decode([String: Any].self, forKey: .data)
            customData = nil
            break
        case "custom":
            customData = try? container.decode(CustomData.self, forKey: .customData)
            data = nil
            break
        default:
            customData = nil
            data = nil
            break
        }

    }
}

class AnalyticsEventDecoder {
    enum AnalyticsCodingKeys: String, CodingKey {
        case name
        case event
    }

    func decode(from container: KeyedDecodingContainer<CheckoutBridge.WebEvent.CodingKeys>, using decoder: Decoder) throws -> PixelEvent? {
        let messageBody = try container.decode(String.self, forKey: .body)

        guard let data = messageBody.data(using: .utf8) else {
            return nil
        }

        let analyticsEvent = try JSONDecoder().decode(AnalyticsEvent.self, from: data)

        switch analyticsEvent.event.type {
        case "standard":
            return createStandardEvent(from: analyticsEvent.event)
        case "custom":
            let customEvent = CustomEvent(from: analyticsEvent.event)
            return .customEvent(customEvent)
        default:
            return nil
        }
    }

    func createStandardEvent(from analyticsEventBody: AnalyticsEventBody) -> PixelEvent? {
        switch analyticsEventBody.name {
        case "cart_viewed":
            let event = PixelEventsCartViewed(from: analyticsEventBody)
            return .pixelEventsCartViewed(event)
        case "checkout_address_info_submitted":
            let event = PixelEventsCheckoutAddressInfoSubmitted(from: analyticsEventBody)
            return .pixelEventsCheckoutAddressInfoSubmitted(event)
        case "checkout_completed":
            let event = PixelEventsCheckoutCompleted(from: analyticsEventBody)
            return .pixelEventsCheckoutCompleted(event)
        case "checkout_contact_info_submitted":
            let event = PixelEventsCheckoutContactInfoSubmitted(from: analyticsEventBody)
            return .pixelEventsCheckoutContactInfoSubmitted(event)
        case "checkout_shipping_info_submitted":
            let event = PixelEventsCheckoutShippingInfoSubmitted(from: analyticsEventBody)
            return .pixelEventsCheckoutShippingInfoSubmitted(event)
        case "checkout_started":
            let event = PixelEventsCheckoutStarted(from: analyticsEventBody)
            return .pixelEventsCheckoutStarted(event)
        case "collection_viewed":
            let event = PixelEventsCollectionViewed(from: analyticsEventBody)
            return .pixelEventsCollectionViewed(event)
        case "page_viewed":
            let event = PixelEventsPageViewed(from: analyticsEventBody)
            return .pixelEventsPageViewed(event)
        case "payment_info_submitted":
            let event = PixelEventsPaymentInfoSubmitted(from: analyticsEventBody)
            return .pixelEventsPaymentInfoSubmitted(event)
        case "product_added_to_cart":
            let event = PixelEventsProductAddedToCart(from: analyticsEventBody)
            return .pixelEventsProductAddedToCart(event)
        case "product_removed_from_cart":
            let event = PixelEventsProductRemovedFromCart(from: analyticsEventBody)
            return .pixelEventsProductRemovedFromCart(event)
        case "product_viewed":
            let event = PixelEventsProductViewed(from: analyticsEventBody)
            return .pixelEventsProductViewed(event)
        case "search_submitted":
            let event = PixelEventsSearchSubmitted(from: analyticsEventBody)
            return .pixelEventsSearchSubmitted(event)
        default:
            return nil
        }
    }

}
