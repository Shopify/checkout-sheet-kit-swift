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

/// Protocol for components that need logging with automatic namespace detection
@available(iOS 16.0, *)
internal protocol Loggable {
//    var osLogger: OSLogger { get set }
}

/// Default implementation for Loggable protocol
@available(iOS 16.0, *)
extension Loggable {
    internal var osLogger: OSLogger {
        ShopifyAcceleratedCheckouts.logger.osLogger
    }

    /// Returns the name of the conforming class
    ///
    /// Usage:
    /// ```swift
    /// class MyClass : Loggable {
    ///     func foo() {
    ///         print(namespace) // prints: 'MyClass'
    ///     }
    /// }
    /// ```
    internal var namespace: String {
        String(describing: type(of: self))
    }

    internal func createLogLine(
        _ message: String,
        method: String,
        fileID: String,
        line: Int
    ) -> String {
        let fileName = fileID.split(separator: "/").last.map { String($0) } ?? fileID
        return "[\(fileName):\(method):\(line)] \(message)"
    }

    /// Log a debug message with automatic namespace
    internal func logDebug(
        _ message: String,
        method: String = #function,
        fileID: String = #fileID,
        line: Int = #line
    ) {
        osLogger.debug(
            createLogLine(message, method: method, fileID: fileID, line: line)
        )
    }

    /// Log an info message with automatic namespace
    internal func logInfo(
        _ message: String,
        method: String = #function,
        fileID: String = #fileID,
        line: Int = #line
    ) {
        osLogger.info(
            createLogLine(message, method: method, fileID: fileID, line: line)
        )
    }

    /// Log an error message with automatic namespace
    internal func logError(
        _ message: String,
        method: String = #function,
        fileID: String = #fileID,
        line: Int = #line
    ) {
        osLogger.error(
            createLogLine(message, method: method, fileID: fileID, line: line)
        )
    }

    /// Log a fault message with automatic namespace
    internal func logFault(
        _ message: String,
        method: String = #function,
        fileID: String = #fileID,
        line: Int = #line
    ) {
        osLogger.fault(
            createLogLine(message, method: method, fileID: fileID, line: line)
        )
    }
}

@available(iOS 16.0, *)
internal class Logger: Loggable {
    var osLogger: ShopifyCheckoutSheetKit.OSLogger

    init(prefix: String, logLevel: LogLevel) {
        osLogger = OSLogger(prefix: prefix, logLevel: logLevel)
    }

    func setLogLevel(to logLevel: LogLevel) {
        osLogger.logLevel = logLevel
    }
}
