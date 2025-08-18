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
    private var namespaces: [String] = []
    private weak var parent: OSLogger?
    private var children = NSHashTable<OSLogger>.weakObjects()
    
    package var logLevel: LogLevel {
        didSet {
            propagateLogLevel(logLevel)
        }
    }

    public static var shared = OSLogger()

    public init() {
        prefix = "ShopifyCheckoutSheetKit"
        logLevel = ShopifyCheckoutSheetKit.configuration.logLevel
    }

    public init(prefix: String, logLevel: LogLevel) {
        self.prefix = prefix
        self.logLevel = logLevel
    }
    
    public func extend(_ namespace: String) -> OSLogger {
        let childLogger = OSLogger(prefix: prefix, logLevel: logLevel)
        childLogger.namespaces = self.namespaces + [namespace]
        childLogger.parent = self
        children.add(childLogger)
        return childLogger
    }
    
    private func propagateLogLevel(_ newLevel: LogLevel) {
        for child in children.allObjects {
            child.logLevel = newLevel
        }
    }
    
    private var namespacesString: String {
        namespaces.isEmpty ? "" : "[\(namespaces.joined(separator: "]["))]"
    }

    public func debug(_ message: String) {
        guard shouldEmit(.debug) else { return }
        
        let fullMessage = "[\(prefix)]\(namespacesString) (Debug) - \(message)"
        sendToOSLog(fullMessage, type: .debug)
    }

    public func info(_ message: String) {
        guard shouldEmit(.debug) else { return }
        
        let fullMessage = "[\(prefix)]\(namespacesString) (Info) - \(message)"
        sendToOSLog(fullMessage, type: .info)
    }

    public func error(_ message: String) {
        guard shouldEmit(.error) else { return }
        
        let fullMessage = "[\(prefix)]\(namespacesString) (Error) - \(message)"
        sendToOSLog(fullMessage, type: .error)
    }

    public func fault(_ message: String) {
        guard shouldEmit(.error) else { return }
        
        let fullMessage = "[\(prefix)]\(namespacesString) (Fault) - \(message)"
        sendToOSLog(fullMessage, type: .fault)
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
