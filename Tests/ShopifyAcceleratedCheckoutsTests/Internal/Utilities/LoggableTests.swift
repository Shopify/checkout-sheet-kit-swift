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

import os.log
import RegexBuilder
@testable import ShopifyAcceleratedCheckouts
import XCTest

// Import ShopifyCheckoutSheetKit separately to access OSLogger for testing
@testable import ShopifyCheckoutSheetKit

// To disambiguate, we'll use the actual types from each module
// ACLogger is the Logger class from ShopifyAcceleratedCheckouts module
// CSKLogger is the Logger protocol from ShopifyCheckoutSheetKit module

// Custom XCTAssertRegex helper for regex pattern matching
@available(iOS 16.0, *)
func XCTAssertRegex(
    _ string: String,
    _ pattern: some RegexComponent,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) {
    if string.firstMatch(of: pattern) == nil {
        let failureMessage = message().isEmpty
            ? "String '\(string)' did not match the expected pattern"
            : message()
        XCTFail(failureMessage, file: file, line: line)
    }
}

// TestableOSLogger to capture log messages for testing
@available(iOS 16.0, *)
private class TestableOSLogger: OSLogger {
    private(set) var capturedMessages: [(message: String, type: OSLogType)] = []

    init(captureMessages _: Bool = true) {
        super.init(prefix: "ShopifyAcceleratedCheckouts", logLevel: .all)
    }

    override internal func sendToOSLog(_ message: String, type: OSLogType) {
        capturedMessages.append((message: message, type: type))
    }
}

@available(iOS 16.0, *)
private class TestableLogger {
    var testableOSLogger: TestableOSLogger
    var osLogger: OSLogger

    init(captureMessages: Bool = true) {
        testableOSLogger = TestableOSLogger(captureMessages: captureMessages)
        osLogger = testableOSLogger
    }

    func setLogLevel(to logLevel: LogLevel) {
        osLogger.logLevel = logLevel
    }
}

@available(iOS 16.0, *)
final class LoggableTests: XCTestCase {
    // Store the original logger to restore after tests
    private var originalOSLogger: OSLogger!

    override func setUp() {
        super.setUp()
        // Store the original OSLogger for restoration
        originalOSLogger = ShopifyAcceleratedCheckouts.logger.osLogger
    }

    override func tearDown() {
        // Restore the original OSLogger
        ShopifyAcceleratedCheckouts.logger.osLogger = originalOSLogger
        super.tearDown()
    }

    func test_logDebug_withMessage_shouldFormatCorrectly() {
        let testLogger = TestableLogger()
        // Replace the OSLogger with our testable version
        ShopifyAcceleratedCheckouts.logger.osLogger = testLogger.testableOSLogger
        let helper = LoggableTestHelper()

        helper.logDebug("Test debug message")

        XCTAssertEqual(testLogger.testableOSLogger.capturedMessages.count, 1)

        let pattern = #/\[ShopifyAcceleratedCheckouts\] \(Debug\) - \[LoggableTests\.swift:test_logDebug_withMessage_shouldFormatCorrectly\(\):\d+\] Test debug message/#

        XCTAssertRegex(
            testLogger.testableOSLogger.capturedMessages[0].message,
            pattern,
            "Log message format incorrect: \(testLogger.testableOSLogger.capturedMessages[0].message)"
        )

        XCTAssertEqual(testLogger.testableOSLogger.capturedMessages[0].type, .debug)
    }

    func test_logInfo_withMessage_shouldFormatCorrectly() {
        let testLogger = TestableLogger()
        // Replace the OSLogger with our testable version
        ShopifyAcceleratedCheckouts.logger.osLogger = testLogger.testableOSLogger
        let helper = LoggableTestHelper()

        helper.logInfo("Test info message")

        XCTAssertEqual(testLogger.testableOSLogger.capturedMessages.count, 1)

        let pattern = #/\[ShopifyAcceleratedCheckouts\] \(Info\) - \[LoggableTests\.swift:test_logInfo_withMessage_shouldFormatCorrectly\(\):\d+\] Test info message/#

        XCTAssertRegex(
            testLogger.testableOSLogger.capturedMessages[0].message,
            pattern,
            "Log message format incorrect: \(testLogger.testableOSLogger.capturedMessages[0].message)"
        )

        XCTAssertEqual(testLogger.testableOSLogger.capturedMessages[0].type, .info)
    }

    func test_logError_withMessage_shouldFormatCorrectly() {
        let testLogger = TestableLogger()
        // Replace the OSLogger with our testable version
        ShopifyAcceleratedCheckouts.logger.osLogger = testLogger.testableOSLogger
        let helper = LoggableTestHelper()

        helper.logError("Test error message")

        XCTAssertEqual(testLogger.testableOSLogger.capturedMessages.count, 1)

        let pattern = #/\[ShopifyAcceleratedCheckouts\] \(Error\) - \[LoggableTests\.swift:test_logError_withMessage_shouldFormatCorrectly\(\):\d+\] Test error message/#

        XCTAssertRegex(
            testLogger.testableOSLogger.capturedMessages[0].message,
            pattern,
            "Log message format incorrect: \(testLogger.testableOSLogger.capturedMessages[0].message)"
        )

        XCTAssertEqual(testLogger.testableOSLogger.capturedMessages[0].type, .error)
    }

    func test_logFault_withMessage_shouldFormatCorrectly() {
        let testLogger = TestableLogger()
        // Replace the OSLogger with our testable version
        ShopifyAcceleratedCheckouts.logger.osLogger = testLogger.testableOSLogger
        let helper = LoggableTestHelper()

        helper.logFault("Test fault message")

        XCTAssertEqual(testLogger.testableOSLogger.capturedMessages.count, 1)

        let pattern = #/\[ShopifyAcceleratedCheckouts\] \(Fault\) - \[LoggableTests\.swift:test_logFault_withMessage_shouldFormatCorrectly\(\):\d+\] Test fault message/#

        XCTAssertRegex(
            testLogger.testableOSLogger.capturedMessages[0].message,
            pattern,
            "Log message format incorrect: \(testLogger.testableOSLogger.capturedMessages[0].message)"
        )

        XCTAssertEqual(testLogger.testableOSLogger.capturedMessages[0].type, .fault)
    }

    func test_namespace_extraction() {
        let simpleClass = SimpleTestClass()
        let genericClass = GenericTestClass<String>()
        let nestedClass = OuterTestClass.InnerTestClass()

        XCTAssertEqual(simpleClass.getNamespace(), "SimpleTestClass")
        XCTAssertEqual(genericClass.getNamespace(), "GenericTestClass<String>")
        XCTAssertEqual(nestedClass.getNamespace(), "InnerTestClass")
    }
}

// Helper class for testing Loggable protocol
@available(iOS 16.0, *)
private class LoggableTestHelper: Loggable {}

// Test classes to verify namespace generation
@available(iOS 16.0, *)
private class SimpleTestClass: Loggable {
    func getNamespace() -> String {
        return namespace
    }
}

@available(iOS 16.0, *)
private class GenericTestClass<T>: Loggable {
    func getNamespace() -> String {
        return namespace
    }
}

@available(iOS 16.0, *)
private class OuterTestClass {
    class InnerTestClass: Loggable {
        func getNamespace() -> String {
            return namespace
        }
    }
}
