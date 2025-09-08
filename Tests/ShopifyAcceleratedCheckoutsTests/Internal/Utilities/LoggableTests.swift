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
@testable import ShopifyCheckoutSheetKit
import XCTest

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
final class LoggableTests: XCTestCase {
    private var originalLogger: OSLogger!

    override func setUp() {
        super.setUp()
        originalLogger = ShopifyAcceleratedCheckouts.logger
    }

    override func tearDown() {
        ShopifyAcceleratedCheckouts.logger = originalLogger
        super.tearDown()
    }

    func test_logDebug_withMessage_shouldFormatCorrectly() {
        let testLogger = TestableOSLogger()
        ShopifyAcceleratedCheckouts.logger = testLogger
        let helper = LoggableTestHelper()

        helper.logDebug("Test debug message")

        XCTAssertEqual(testLogger.capturedMessages.count, 1)

        let pattern = #/\[ShopifyAcceleratedCheckouts\] \(Debug\) - \[LoggableTests\.swift:test_logDebug_withMessage_shouldFormatCorrectly\(\):\d+\] Test debug message/#

        XCTAssertRegex(
            testLogger.capturedMessages[0].message,
            pattern,
            "Log message format incorrect: \(testLogger.capturedMessages[0].message)"
        )

        XCTAssertEqual(testLogger.capturedMessages[0].type, .debug)
    }

    func test_logInfo_withMessage_shouldFormatCorrectly() {
        let testLogger = TestableOSLogger()
        ShopifyAcceleratedCheckouts.logger = testLogger
        let helper = LoggableTestHelper()

        helper.logInfo("Test info message")

        XCTAssertEqual(testLogger.capturedMessages.count, 1)

        let pattern = #/\[ShopifyAcceleratedCheckouts\] \(Info\) - \[LoggableTests\.swift:test_logInfo_withMessage_shouldFormatCorrectly\(\):\d+\] Test info message/#

        XCTAssertRegex(
            testLogger.capturedMessages[0].message,
            pattern,
            "Log message format incorrect: \(testLogger.capturedMessages[0].message)"
        )

        XCTAssertEqual(testLogger.capturedMessages[0].type, .info)
    }

    func test_logError_withMessage_shouldFormatCorrectly() {
        let testLogger = TestableOSLogger()
        ShopifyAcceleratedCheckouts.logger = testLogger
        let helper = LoggableTestHelper()

        helper.logError("Test error message")

        XCTAssertEqual(testLogger.capturedMessages.count, 1)

        let pattern = #/\[ShopifyAcceleratedCheckouts\] \(Error\) - \[LoggableTests\.swift:test_logError_withMessage_shouldFormatCorrectly\(\):\d+\] Test error message/#

        XCTAssertRegex(
            testLogger.capturedMessages[0].message,
            pattern,
            "Log message format incorrect: \(testLogger.capturedMessages[0].message)"
        )

        XCTAssertEqual(testLogger.capturedMessages[0].type, .error)
    }

    func test_logFault_withMessage_shouldFormatCorrectly() {
        let testLogger = TestableOSLogger()
        ShopifyAcceleratedCheckouts.logger = testLogger
        let helper = LoggableTestHelper()

        helper.logFault("Test fault message")

        XCTAssertEqual(testLogger.capturedMessages.count, 1)

        let pattern = #/\[ShopifyAcceleratedCheckouts\] \(Fault\) - \[LoggableTests\.swift:test_logFault_withMessage_shouldFormatCorrectly\(\):\d+\] Test fault message/#

        XCTAssertRegex(
            testLogger.capturedMessages[0].message,
            pattern,
            "Log message format incorrect: \(testLogger.capturedMessages[0].message)"
        )

        XCTAssertEqual(testLogger.capturedMessages[0].type, .fault)
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
