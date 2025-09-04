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

/// Protocol for components that need logging with automatic namespace detection
@available(iOS 16.0, *)
protocol Loggable {}

/// Default implementation for Loggable protocol
@available(iOS 16.0, *)
extension Loggable {
    /// Returns the name of the conforming class
    ///
    /// Usage:
    /// ```swift
    /// class MyClass : Loggable {
    ///     func foo() {
    ///         print(logNameSpace) // prints: 'MyClass'
    ///     }
    /// }
    /// ```
    private var namespace: String {
        String(describing: type(of: self))
    }

    private func createLogLocation(method: String, fileID: String, line: Int) -> String {
        let fileName = fileID.split(separator: "/").last.map { String($0) } ?? fileID
        return "\(fileName):\(method):\(line)"
    }

    private func createLogLine(_ message: String, method: String, fileID: String, line: Int)
        -> String
    {
        return "[\(createLogLocation(method: method, fileID: fileID, line: line))] \(message)"
    }

    /// Log a debug message with automatic namespace
    func logDebug(
        _ message: String,
        method: String = #function,
        fileID: String = #fileID,
        line: Int = #line
    ) {
        ShopifyAcceleratedCheckouts.logger.debug(
            createLogLine(message, method: method, fileID: fileID, line: line)
        )
    }

    /// Log an info message with automatic namespace
    func logInfo(
        _ message: String,
        method: String = #function,
        fileID: String = #fileID,
        line: Int = #line
    ) {
        ShopifyAcceleratedCheckouts.logger.info(
            createLogLine(message, method: method, fileID: fileID, line: line)
        )
    }

    /// Log an error message with automatic namespace
    func logError(
        _ message: String,
        method: String = #function,
        fileID: String = #fileID,
        line: Int = #line
    ) {
        ShopifyAcceleratedCheckouts.logger.error(
            createLogLine(message, method: method, fileID: fileID, line: line)
        )
    }

    /// Log a fault message with automatic namespace
    func logFault(
        _ message: String,
        method: String = #function,
        fileID: String = #fileID,
        line: Int = #line
    ) {
        ShopifyAcceleratedCheckouts.logger.fault(
            createLogLine(message, method: method, fileID: fileID, line: line)
        )
    }
}
