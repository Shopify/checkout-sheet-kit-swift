import Foundation
import ShopifyCheckoutKit

class FileLogger: Logger {
	private var fileHandle: FileHandle?

	public init() {
		let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
		let logFileUrl = paths[0].appendingPathComponent("log.txt")

		if !FileManager.default.fileExists(atPath: logFileUrl.path) {
			FileManager.default.createFile(atPath: logFileUrl.path, contents: nil, attributes: nil)
		}

		do {
			fileHandle = try FileHandle(forWritingTo: logFileUrl)
		} catch let error as NSError {
			print("Couldn't open the log file. Error: \(error)")
		}
	}

	public func log(_ message: String) {
		guard let fileHandle = fileHandle else {
			print("File handle is nil")
			return
		}

		let date = Date()
		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .none
		dateFormatter.timeStyle = .medium
		let timeString = dateFormatter.string(from: date)

		let logMessage = "\(timeString): \(message)\n"
		if let data = logMessage.data(using: .utf8) {
			fileHandle.seekToEndOfFile()
			fileHandle.write(data)
		}
	}
}
