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

private let subsystem = "com.shopify.checkoutsheetkit"

public enum LogLevel {
    case all, debug, error, none
}

public class OSLogger {
    private let logger = OSLog(subsystem: subsystem, category: OSLog.Category.pointsOfInterest)

    public static let shared = OSLogger()

    public func info(_ message: String) {
		guard shouldEmit(.debug) else { return }

        os_log("[ShopifyCheckoutSheetKit] (Info) - %@", log: logger, type: .info, message)
    }

    public func debug(_ message: String) {
		guard shouldEmit(.debug) else { return }

        os_log("[ShopifyCheckoutSheetKit] (Debug) - %@", log: logger, type: .debug, message)
    }

    public func error(_ message: String) {
		guard shouldEmit(.error) else { return }

        os_log("[ShopifyCheckoutSheetKit] (Error) - %@", log: logger, type: .error, message)
    }

    public func fault(_ message: String) {
		guard shouldEmit(.error) else { return }

        os_log("[ShopifyCheckoutSheetKit] (Fault) - %@", log: logger, type: .fault, message)
    }

    private func shouldEmit(_ choice: LogLevel) -> Bool {
		let configLevel = ShopifyCheckoutSheetKit.configuration.logLevel

		if configLevel == .none {
			return false
		}

		return configLevel == .all || configLevel == choice
	}
}
