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
    let event: PixelEvent
}

public struct PixelEvent: Decodable {
    let id: String
    let name: String
    let timestamp: String
    let type: String
    let customData: [String: Any]?
    let data: [String: Any]?
    let context: [String: Any]?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case timestamp
        case type
        case customData
        case data
        case context
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        timestamp = try container.decode(String.self, forKey: .timestamp)
        type = try container.decode(String.self, forKey: .type)
        context = try container.decode([String: Any].self, forKey: .context)

        switch type {
        case "standard":
            data = try container.decode([String: Any].self, forKey: .data)
            customData = nil
            break
        case "custom":
            customData = try container.decode([String: Any].self, forKey: .customData)
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

        if let data = messageBody.data(using: .utf8) {
            let analyticsEvent = try JSONDecoder().decode(AnalyticsEvent.self, from: data)
            return analyticsEvent.event
        }

        return nil
    }
}
