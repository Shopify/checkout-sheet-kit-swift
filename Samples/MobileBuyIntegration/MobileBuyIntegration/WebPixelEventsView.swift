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
import SwiftUI
import ShopifyCheckoutSheetKit

@available(iOS 15.0, *)
struct WebPixelsEventsView: View {
	@State private var events: [GenericEvent] = []

	private let logger: WebPixelsStorageManager = WebPixelsStorageManager()

	var body: some View {
		VStack {
			List(events, id: \.id) { event in
				NavigationLink(destination: EventDetailView(event: event)) {
					VStack(alignment: .leading) {
						if event.name != nil {
							Text(event.name)
								.font(.system(size: 14))
								.fontWeight(.bold)
						}

						if event.timestamp != nil {
							Text(event.timestamp.formatDate())
								.font(.system(size: 12))
						}
					}.padding(4)
				}
			}
			.refreshable {
				events = readEvents()
			}
			.navigationTitle("Events")
			.navigationBarItems(
				trailing: Button(action: clearLogs) {
					Text("Clear")
				}
			)
			.onAppear {
				events = readEvents()
			}
		}
	}

	private func clearLogs() {
		logger.dropAllEvents()
		events = readEvents()
	}

	private func readEvents() -> [GenericEvent] {
		return logger.getEvents()
	}
}

struct EventDetailView: View {
	let event: GenericEvent

	var body: some View {
		List {
			HStack {
				Text("Name")
					.font(.system(size: 13))
					.fontWeight(.bold)
				Spacer()
				Text(event.name)
					.font(.subheadline)
			}
			HStack {
				Text("Timestamp")
					.font(.system(size: 13))
					.fontWeight(.bold)
				Spacer()
				Text(event.timestamp.formatDate())
					.font(.subheadline)
			}

			VStack(alignment: .leading) {
				Text("Context")
					.font(.system(size: 13))
					.fontWeight(.bold)

				if event.context != nil {
					Text(event.context!.formatJSON())
						.font(.system(size: 11))
				}
			}

			VStack(alignment: .leading) {
				Text("Data")
					.font(.system(size: 13))
					.fontWeight(.bold)

				if event.data != nil {
					Text(event.data!.formatJSON())
						.font(.system(size: 11))
				}
			}

			VStack(alignment: .leading) {
				Text("Custom data")
					.font(.system(size: 13))
					.fontWeight(.bold)
				if event.customData != nil {
					Text(event.customData!.formatJSON())
						.font(.system(size: 11))

				}
			}
		}
		.navigationTitle("Event details")
	}
}

extension String {
	func formatDate(fromFormat: String = "yyyy-MM-dd'T'HH:mm:ss.SSSZ", toFormat: String = "MMM d, hh:mm:ss") -> String {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = fromFormat
		dateFormatter.locale = Locale(identifier: "en_US_POSIX")
		guard let date = dateFormatter.date(from: self) else {
			return self
		}

		dateFormatter.dateFormat = toFormat
		return dateFormatter.string(from: date)
	}

	func formatJSON() -> String {
		return self.replacingOccurrences(of: "\\n", with: "\n").replacingOccurrences(of: "\\\"", with: "\"")
	}
}
