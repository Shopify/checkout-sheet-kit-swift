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
import ShopifyCheckoutSheetKit

class WebPixelsLogger: Logger {
	private var fileHandle: FileHandle?

	public init(_ filename: String) {
		let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
		let logFileUrl = paths[0].appendingPathComponent(filename)

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


class WebPixelsLogReader {
	static let shared = WebPixelsLogReader("analytics.txt")

	private let logFileUrl: URL

	private init(_ filename: String) {
		let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
		logFileUrl = paths[0].appendingPathComponent(filename)
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
