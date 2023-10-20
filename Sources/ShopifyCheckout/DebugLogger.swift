import Foundation

public class DebugLogger {
	private var events = [Event]()

	public init() {}

	public func log(_ name: String, info: [String: String] = [:]) {
		events.append(Event(name: name, info: info))
	}

	public func dump() throws -> URL {
		let encoder = JSONEncoder()

		encoder.dateEncodingStrategy = .iso8601
		encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]

		let url = FileManager.default.temporaryDirectory
			.appendingPathComponent("\(UUID().uuidString).log.json")

		try encoder.encode(events).write(to: url)

		return url
	}
}

extension DebugLogger {
	struct Event: Encodable {
		let time = Date()

		let name: String

		let info: [String: String]
	}
}

extension DebugLogger {
	public static func log(_ name: String, info: [String: String] = [:]) {
		configuration.debug.logger?.log(name, info: info)
	}
}
