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
import ShopifyCheckoutSheetKit

class Analytics {
    static func getUserId() -> String {
        // return ID for user used in your existing analytics system
        return "123"
    }

    static func record(_ event: PixelEvent) {
        switch event {
        case let .customEvent(customEvent):
            if let genericEvent = AnalyticsEvent.from(customEvent, userId: getUserId()) {
                Analytics.record(genericEvent)
            }
        case let .standardEvent(standardEvent):
            Analytics.record(AnalyticsEvent.from(standardEvent, userId: getUserId()))
        }
    }

    static func record(_ event: AnalyticsEvent) {
        ShopifyCheckoutSheetKit.configuration.logger.log("[Web Pixel Event (\(event.type)] \(event.name)")
        // send the event to an analytics system, e.g. via an analytics sdk
        appConfiguration.webPixelsLogger.log(event.name)
    }
}

// example type, e.g. that may be defined by an analytics sdk
struct AnalyticsEvent {
    var type: PixelEvent
    var name = ""
    var userId = ""
    var timestamp = ""
    var checkoutTotal: Double? = 0.0

    static func from(_ event: StandardEvent, userId: String) -> AnalyticsEvent {
        return AnalyticsEvent(
            type: .standardEvent(event),
            name: event.name!,
            userId: userId,
            timestamp: event.timestamp!,
            checkoutTotal: event.data?.checkout?.totalPrice?.amount ?? 0.0
        )
    }

    static func from(_ event: CustomEvent, userId: String) -> AnalyticsEvent? {
        guard event.name != nil else {
            print("Failed to parse custom event", event)
            return nil
        }

        return AnalyticsEvent(
            type: .customEvent(event),
            name: event.name!,
            userId: userId,
            timestamp: event.timestamp!,
            checkoutTotal: nil
        )
    }
}
