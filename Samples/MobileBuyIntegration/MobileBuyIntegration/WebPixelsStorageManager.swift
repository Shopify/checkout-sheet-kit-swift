import SQLite
import Foundation
import ShopifyCheckoutSheetKit

class WebPixelsStorageManager {
	private var database: Connection?
	private let webPixels = Table("WebPixels")
	private let id = Expression<Int64>("id")
	private let name = Expression<String?>("name")
	private let timestamp = Expression<String?>("timestamp")
	private let context = Expression<String?>("context")
	private let customData = Expression<String?>("customData")
	private let data = Expression<String?>("data")

	init() {
		do {
			let path = NSSearchPathForDirectoriesInDomains(
				.documentDirectory, .userDomainMask, true
			).first!

			database = try Connection("\(path)/webpixels.sqlite3")

			try database?.run(webPixels.create(ifNotExists: true) { table in
				table.column(id, primaryKey: .autoincrement)
				table.column(name)
				table.column(timestamp)
				table.column(context)
				table.column(customData)
				table.column(data)
			})
		} catch {
			print("Couldn't open the database: \(error)")
		}
	}

	private func mapToGenericEvent(event: CustomEvent) -> GenericEvent {
		return GenericEvent(from: event)
	}

	private func mapToGenericEvent(event: StandardEvent) -> GenericEvent {
		return GenericEvent(from: event)
	}

	public func getEvents() -> [GenericEvent] {
		var events: [GenericEvent] = []

		do {
			for row in try database!.prepare(webPixels) {
				let eventObject = GenericEvent(
					id: String(row[id]),
					timestamp: row[timestamp]!,
					name: row[name]!,
					context: row[context],
					data: row[data],
					customData: row[customData]
				)
				events.append(eventObject)
			}
		} catch {
			print("Couldn't retrieve events: \(error)")
		}

		return events.reversed()
	}

	private func unwrappedString<T>(_ value: T?) -> String {
		if let value = value {
			return String(describing: value)
		} else {
			return ""
		}
	}

	public func addEvent(_ pixelEvent: PixelEvent) {
		var event: GenericEvent

		switch(pixelEvent) {
		case .standardEvent(let standardEvent):
			event = mapToGenericEvent(event: standardEvent)
		case .customEvent(let customEvent):
			event = mapToGenericEvent(event: customEvent)
		}

		do {
			let insert = webPixels.insert(
				name <- event.name,
				timestamp <- event.timestamp,
				context <- unwrappedString(event.context!),
				customData <- unwrappedString(event.customData),
				data <- unwrappedString(event.data!)
			)

			try database?.run(insert)
		} catch {
			print("Couldn't insert event: \(error)")
		}
	}

	public func dropAllEvents() {
		do {
			try database?.run(webPixels.delete())
		} catch {
			print("Couldn't clear the table: \(error)")
		}
	}
}

class GenericEvent {
	var id: String
	var timestamp: String
	var name: String
	var context: String?
	var data: String?
	var customData: String?

	init(from standardEvent: StandardEvent) {
		self.id = standardEvent.id ?? ""
		self.name = standardEvent.name ?? ""
		self.timestamp = standardEvent.timestamp ?? ""
		self.customData = nil
		self.data = convertToJSONString(event: standardEvent.data)
		self.context = convertToJSONString(event: standardEvent.context)
	}

	init(from customEvent: CustomEvent) {
		self.id = customEvent.id ?? ""
		self.name = customEvent.name ?? ""
		self.timestamp = customEvent.timestamp ?? ""
		self.data = nil
		self.context = convertToJSONString(event: customEvent.context)
		self.customData = customEvent.customData
	}

	init(id: String?, timestamp: String, name: String, context: String?, data: String?, customData: String?) {
		self.id = id ?? ""
		self.timestamp = timestamp
		self.name = name
		self.context = context
		self.data = data
		self.customData = customData
	}

	func convertToJSONString<T: Codable>(event: T?) -> String {
		guard let event = event else {
			return ""
		}

		let encoder = JSONEncoder()
		encoder.outputFormatting = .prettyPrinted
		encoder.keyEncodingStrategy = .convertToSnakeCase
		encoder.dateEncodingStrategy = .iso8601

		guard let jsonData = try? encoder.encode(event) else {
			return ""
		}

		let jsonString = String(data: jsonData, encoding: .utf8) ?? ""

		return jsonString.replacingOccurrences(of: "\\n", with: "\n").replacingOccurrences(of: "\\\"", with: "\"")
	}
}
