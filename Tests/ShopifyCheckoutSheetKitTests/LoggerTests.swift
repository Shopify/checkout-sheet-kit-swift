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
import XCTest

@testable import ShopifyCheckoutSheetKit

class TestableOSLogger: OSLogger {
    private(set) var capturedMessages: [(message: String, type: OSLogType)] = []
    private let testPrefix: String
    override init() {
        testPrefix = "ShopifyCheckoutSheetKit"
        super.init()
    }

    override init(prefix: String, logLevel: LogLevel) {
        testPrefix = prefix
        super.init(prefix: prefix, logLevel: logLevel)
    }

    override func sendToOSLog(_ message: String, type: OSLogType) {
        capturedMessages.append((message: message, type: type))
    }
}

final class OSLoggerTests: XCTestCase {
    var originalConfiguration: Configuration!

    override func setUp() {
        super.setUp()
        originalConfiguration = ShopifyCheckoutSheetKit.configuration
    }

    override func tearDown() {
        ShopifyCheckoutSheetKit.configuration = originalConfiguration
        super.tearDown()
    }

    func test_sharedLogger_whenAccessed_shouldExist() {
        XCTAssertNotNil(OSLogger.shared)
    }

    func test_defaultInitializer_withNoParameters_shouldMaintainBackwardsCompatibility() {
        let logger = OSLogger()
        XCTAssertNotNil(logger)
    }

    func test_logLevelNone_withAllLogCalls_shouldBlockAllLogging() {
        let logger = TestableOSLogger(prefix: "ShopifyCheckoutSheetKit", logLevel: .none)

        logger.info("test info")
        logger.debug("test debug")
        logger.error("test error")
        logger.fault("test fault")

        XCTAssertEqual(logger.capturedMessages.count, 0)
    }

    func test_logLevelAll_withAllLogCalls_shouldAllowAllLogging() {
        let logger = TestableOSLogger(prefix: "ShopifyCheckoutSheetKit", logLevel: .all)

        logger.info("test info")
        logger.debug("test debug")
        logger.error("test error")
        logger.fault("test fault")

        XCTAssertEqual(logger.capturedMessages.count, 4)
        XCTAssertEqual(
            logger.capturedMessages[0].message, "[ShopifyCheckoutSheetKit] (Info) - test info"
        )
        XCTAssertEqual(logger.capturedMessages[0].type, OSLogType.info)
        XCTAssertEqual(
            logger.capturedMessages[1].message, "[ShopifyCheckoutSheetKit] (Debug) - test debug"
        )
        XCTAssertEqual(logger.capturedMessages[1].type, OSLogType.debug)
        XCTAssertEqual(
            logger.capturedMessages[2].message, "[ShopifyCheckoutSheetKit] (Error) - test error"
        )
        XCTAssertEqual(logger.capturedMessages[2].type, OSLogType.error)
        XCTAssertEqual(
            logger.capturedMessages[3].message, "[ShopifyCheckoutSheetKit] (Fault) - test fault"
        )
        XCTAssertEqual(logger.capturedMessages[3].type, OSLogType.fault)
    }

    func test_logLevelDebug_withAllLogCalls_shouldAllowDebugAndInfo() {
        let logger = TestableOSLogger(prefix: "ShopifyCheckoutSheetKit", logLevel: .debug)

        logger.info("test info")
        logger.debug("test debug")
        logger.error("test error")
        logger.fault("test fault")

        XCTAssertEqual(logger.capturedMessages.count, 2)
        XCTAssertEqual(
            logger.capturedMessages[0].message, "[ShopifyCheckoutSheetKit] (Info) - test info"
        )
        XCTAssertEqual(
            logger.capturedMessages[1].message, "[ShopifyCheckoutSheetKit] (Debug) - test debug"
        )
    }

    func test_logLevelError_withAllLogCalls_shouldAllowErrorAndFault() {
        let logger = TestableOSLogger(prefix: "ShopifyCheckoutSheetKit", logLevel: .error)

        logger.info("test info")
        logger.debug("test debug")
        logger.error("test error")
        logger.fault("test fault")

        XCTAssertEqual(logger.capturedMessages.count, 2)
        XCTAssertEqual(
            logger.capturedMessages[0].message, "[ShopifyCheckoutSheetKit] (Error) - test error"
        )
        XCTAssertEqual(
            logger.capturedMessages[1].message, "[ShopifyCheckoutSheetKit] (Fault) - test fault"
        )
    }

    func test_sharedLogger_withConfigurationLogLevel_shouldMaintainBackwardsCompatibility() {
        ShopifyCheckoutSheetKit.configuration.logLevel = .all
        OSLogger.shared.info("test message")
    }

    func test_messageFormatting_withDifferentLogLevels_shouldFormatExactly() {
        let logger = TestableOSLogger(prefix: "ShopifyCheckoutSheetKit", logLevel: .all)

        logger.info("user action completed")
        logger.debug("processing checkout data")
        logger.error("network request failed")
        logger.fault("critical system error")

        XCTAssertEqual(logger.capturedMessages.count, 4)
        XCTAssertEqual(
            logger.capturedMessages[0].message,
            "[ShopifyCheckoutSheetKit] (Info) - user action completed"
        )
        XCTAssertEqual(
            logger.capturedMessages[1].message,
            "[ShopifyCheckoutSheetKit] (Debug) - processing checkout data"
        )
        XCTAssertEqual(
            logger.capturedMessages[2].message,
            "[ShopifyCheckoutSheetKit] (Error) - network request failed"
        )
        XCTAssertEqual(
            logger.capturedMessages[3].message,
            "[ShopifyCheckoutSheetKit] (Fault) - critical system error"
        )
    }

    func test_customPrefix_withLoggerInitialization_shouldUseCustomPrefix() {
        let customLogger = TestableOSLogger(prefix: "CustomModule", logLevel: .all)

        customLogger.info("custom module message")
        customLogger.error("custom error")

        XCTAssertEqual(customLogger.capturedMessages.count, 2)
        XCTAssertEqual(
            customLogger.capturedMessages[0].message,
            "[CustomModule] (Info) - custom module message"
        )
        XCTAssertEqual(
            customLogger.capturedMessages[1].message,
            "[CustomModule] (Error) - custom error"
        )
    }

    func test_logLevelNone_withAllMessageTypes_shouldBlockAllMessagesRegardlessOfType() {
        let logger = TestableOSLogger(prefix: "Test", logLevel: .none)

        logger.info("should not log")
        logger.debug("should not log")
        logger.error("should not log")
        logger.fault("should not log")

        XCTAssertEqual(logger.capturedMessages.count, 0, "LogLevel.none should block all messages")
    }

    func test_logLevelDebug_withAllMessageTypes_shouldAllowDebugAndInfoOnly() {
        let logger = TestableOSLogger(prefix: "Test", logLevel: .debug)

        logger.info("info message")
        logger.debug("debug message")
        logger.error("error message")
        logger.fault("fault message")

        XCTAssertEqual(logger.capturedMessages.count, 2, "Debug level should only allow debug and info messages")
        XCTAssertTrue(logger.capturedMessages[0].message.contains("(Info) - info message"))
        XCTAssertTrue(logger.capturedMessages[1].message.contains("(Debug) - debug message"))
    }

    func test_logLevelError_withAllMessageTypes_shouldAllowErrorAndFaultOnly() {
        let logger = TestableOSLogger(prefix: "Test", logLevel: .error)

        logger.info("should be blocked")
        logger.debug("should be blocked")
        logger.error("should be allowed")
        logger.fault("should be allowed")

        XCTAssertEqual(logger.capturedMessages.count, 2, "Error level should only allow error and fault messages")
        XCTAssertTrue(logger.capturedMessages[0].message.contains("(Error) - should be allowed"))
        XCTAssertTrue(logger.capturedMessages[1].message.contains("(Fault) - should be allowed"))
    }
}

final class NoOpLoggerTests: XCTestCase {
    func test_noOpLogger_whenUsed_shouldImplementLoggerProtocol() {
        let logger: ShopifyCheckoutSheetKit.Logger = NoOpLogger()
        logger.log("test message")
        logger.clearLogs()
    }

    func test_noOpLogger_withLogCalls_shouldNotThrow() {
        let logger = NoOpLogger()

        XCTAssertNoThrow(logger.log("test message"))
        XCTAssertNoThrow(logger.clearLogs())
    }
}
