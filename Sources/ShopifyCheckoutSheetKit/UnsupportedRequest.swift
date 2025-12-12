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

/// Empty response for requests that don't return data
internal struct EmptyResponse: Codable {}

/// Parameters for unsupported/unknown methods - captures raw JSON
internal struct UnsupportedParams: Decodable {
    let raw: [String: Any]

    init(from decoder: Decoder) throws {
        // Try to capture the raw JSON as a dictionary
        // If it fails, just use an empty dictionary
        if let container = try? decoder.singleValueContainer(),
           let dict = try? container.decode([String: AnyCodable].self)
        {
            raw = dict.mapValues { $0.value }
        } else {
            raw = [:]
        }
    }

    init(raw: [String: Any] = [:]) {
        self.raw = raw
    }

    /// Helper type to decode Any values
    private struct AnyCodable: Decodable {
        let value: Any

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()

            if let bool = try? container.decode(Bool.self) {
                value = bool
            } else if let int = try? container.decode(Int.self) {
                value = int
            } else if let double = try? container.decode(Double.self) {
                value = double
            } else if let string = try? container.decode(String.self) {
                value = string
            } else if let array = try? container.decode([AnyCodable].self) {
                value = array.map { $0.value }
            } else if let dict = try? container.decode([String: AnyCodable].self) {
                value = dict.mapValues { $0.value }
            } else if container.decodeNil() {
                value = NSNull()
            } else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to decode value")
            }
        }
    }
}

/// Request handler for unsupported/unknown JSON-RPC methods
/// This class may be used to represent Notification and Respondable events
struct UnsupportedRequest: Codable {
    public let id: String?
    public let method: String
}
