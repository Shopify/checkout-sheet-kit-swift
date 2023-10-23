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

import os
import Foundation
import ShopifyCheckout

public class DebugLogger: ShopifyCheckout.Logger {
	static let shared = DebugLogger()

	private struct Event: Encodable {
		let time = Date()

		let message: String

		let info: [String: String?]

		var json: String? {
			(try? JSONEncoder.shared.encode(self)).flatMap({
				String(data: $0, encoding: .utf8)
			})
		}
	}

	private var events = [Event]()

	private let systemLog = os.Logger(
		subsystem: "com.shopify.checkout-sdk.demo", category: "default"
	)

	public func log(_ message: String, info: [String: String?] = [:]) {
		let event = Event(message: message, info: info)
		if !info.isEmpty, let json = JSONEncoder.shared.stringify(info) {
			systemLog.debug("\(message) - \(json)")
		} else {
			systemLog.debug("\(message)")
		}
		events.append(event)
	}

	func flushToDisk() throws -> URL {
		let url = FileManager.default.temporaryDirectory
			.appendingPathComponent("\(UUID().uuidString).log.json")

		try JSONEncoder.shared.encode(events).write(to: url)

		return url
	}
}

extension JSONEncoder {
	fileprivate static let shared: JSONEncoder = {
		let encoder = JSONEncoder()

		encoder.dateEncodingStrategy = .iso8601
		encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]

		return encoder
	}()

	fileprivate func stringify<T: Encodable>(_ value: T) -> String? {
		return (try? encode(value)).flatMap({ String(data: $0, encoding: .utf8) })
	}
}
