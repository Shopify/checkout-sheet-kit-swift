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

public enum LogLevel: String, CaseIterable {
    case all
    case debug
    case error
    case none
}

public class OSLogger {
    private let logger = OSLog(subsystem: subsystem, category: OSLog.Category.pointsOfInterest)
    private var prefix: String
    var logLevel: LogLevel

    public static let shared = OSLogger()

    public init() {
        prefix = "ShopifyCheckoutSheetKit"
        logLevel = ShopifyCheckoutSheetKit.configuration.logLevel
    }

    public init(prefix: String, logLevel: LogLevel) {
        self.prefix = prefix
        self.logLevel = logLevel
    }

    public func debug(_ message: String) {
        guard shouldEmit(.debug) else { return }

        sendToOSLog("[\(prefix)] (Debug) - \(message)", type: .debug)
    }

    public func info(_ message: String) {
        guard shouldEmit(.debug) else { return }

        sendToOSLog("[\(prefix)] (Info) - \(message)", type: .info)
    }

    public func error(_ message: String) {
        guard shouldEmit(.error) else { return }

        sendToOSLog("[\(prefix)] (Error) - \(message)", type: .error)
    }

    public func fault(_ message: String) {
        guard shouldEmit(.error) else { return }

        sendToOSLog("[\(prefix)] (Fault) - \(message)", type: .fault)
    }

    /// Capturing `os_log` output is not possible
    /// This indirection lets us capture messages in `LoggerTests.swift`
    internal func sendToOSLog(_ message: String, type: OSLogType) {
        os_log("%@", log: logger, type: type, message)
    }

    private func shouldEmit(_ choice: LogLevel) -> Bool {
        if logLevel == .none {
            return false
        }

        return logLevel == .all || logLevel == choice
    }
}

public protocol Logger {
    func log(_ message: String)
    func clearLogs()
}

public class NoOpLogger: Logger {
    public func log(_: String) {}

    public func clearLogs() {}
}
