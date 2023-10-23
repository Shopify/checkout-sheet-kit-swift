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
