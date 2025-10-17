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

/// Web pixels event structure
public struct WebPixelsEvent: Decodable {
    let name: String
    let event: WebPixelsEventBody
}

/// Web pixels event body structure
public struct WebPixelsEventBody: Decodable {
    let id: String
    let name: String
    let timestamp: String
    let type: String
    let customData: String?
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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        timestamp = try container.decode(String.self, forKey: .timestamp)
        type = try container.decode(String.self, forKey: .type)
        context = try container.decode(Context.self, forKey: .context)

        switch type {
        case "standard":
            data = try container.decodeIfPresent([String: Any].self, forKey: .data)
            customData = nil
        case "custom":
            let customDataValue = try container.decode([String: Any].self, forKey: .customData)
            let jsonData = try JSONSerialization.data(withJSONObject: customDataValue)
            customData = String(data: jsonData, encoding: .utf8)!
            data = nil
        default:
            customData = nil
            data = nil
        }
    }
}

/// Parameters for web pixels events
public struct WebPixelsParams: Decodable {
    public let name: String
    public let event: WebPixelsEventBody

    public init(from decoder: Decoder) throws {
        // The params contains the WebPixelsEvent structure
        let webPixelsEvent = try WebPixelsEvent(from: decoder)
        name = webPixelsEvent.name
        event = webPixelsEvent.event
    }

    /// Convert the event body to a PixelEvent enum
    public var pixelEvent: PixelEvent? {
        switch event.type {
        case "standard":
            let standardEvent = StandardEvent(from: event)
            return .standardEvent(standardEvent)
        case "custom":
            let customEvent = CustomEvent(from: event)
            return .customEvent(customEvent)
        default:
            return nil
        }
    }
}

/// Request for web pixels events
public final class WebPixelsRequest: BaseRPCRequest<WebPixelsParams, EmptyResponse> {
    override public static var method: String { "webPixels" }

    /// Convenience getter to access the pixel event
    public var pixelEvent: PixelEvent? {
        return params.pixelEvent
    }
}
