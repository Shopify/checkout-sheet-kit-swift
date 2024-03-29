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
import os.log

public protocol Logger {
	func log(_ message: String)
	func clearLogs()
}

public class NoOpLogger: Logger {
	public func log(_ message: String) {}

	public func clearLogs() {}
}

internal protocol ProductionLogger {
	func logError(_ error: Error, _ message: String)
}

internal struct InternalLogger: ProductionLogger {
	public func logError(_ error: Error, _ message: String) {
		let logMessage = "[ShopifyCheckoutSheetKit] \(message): \(error.localizedDescription) (Please report this to the Shopify team at https://github.com/Shopify/checkout-sheet-kit-swift)"
		os_log(.error, "%{public}@", logMessage)
	}
}
