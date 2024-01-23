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

class LogReader {
	static let shared = LogReader("log.txt")

	private let logFileUrl: URL

	private init(_ filename: String) {
		let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
		logFileUrl = paths[0].appendingPathComponent(filename)
	}

	func readLogs(limit: Int = 100) -> [String?]? {
		do {
			let logContent = try String(contentsOf: logFileUrl, encoding: .utf8)
			var logLines = logContent.split(separator: "\n").map { String($0) }
			logLines = Array(logLines.suffix(limit))
			return logLines.reversed()
		} catch {
			print("Couldn't read the log file")
			return []
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

	func readLogs(limit: Int = 100) -> [String?]? {
		do {
			let logContent = try String(contentsOf: logFileUrl, encoding: .utf8)
			var logLines = logContent.split(separator: "\n").map { String($0) }
			logLines = Array(logLines.suffix(limit))
			return logLines.reversed()
		} catch {
			print("Couldn't read the log file")
			return []
		}
	}
}
