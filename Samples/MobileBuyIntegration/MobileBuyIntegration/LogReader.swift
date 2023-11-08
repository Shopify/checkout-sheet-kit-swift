import Foundation

class LogReader {
	static let shared = LogReader()

	private let logFileUrl: URL

	private init() {
		let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
		logFileUrl = paths[0].appendingPathComponent("log.txt")
	}

	func readLogs() -> [String?]? {
		do {
			let logContent = try String(contentsOf: logFileUrl, encoding: .utf8)
			var logLines = logContent.split(separator: "\n").map { String($0) }
			logLines = Array(logLines.suffix(10)) // Keep only the last 10 lines
			return logLines.reversed()
		} catch {
			print("Couldn't read the log file")
			return []
		}
	}
}
