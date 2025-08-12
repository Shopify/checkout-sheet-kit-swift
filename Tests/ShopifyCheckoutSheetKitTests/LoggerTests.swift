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

    func testSharedLoggerExists() {
        XCTAssertNotNil(OSLogger.shared)
    }

    func testDefaultInitializerBackwardsCompatibility() {
        let logger = OSLogger()
        XCTAssertNotNil(logger)
    }

    func testLogLevelNoneBlocksAllLogging() {
        ShopifyCheckoutSheetKit.configuration.logLevel = .none

        let logger = TestableOSLogger()

        logger.info("test info")
        logger.debug("test debug")
        logger.error("test error")
        logger.fault("test fault")

        XCTAssertEqual(logger.capturedMessages.count, 0)
    }

    func testLogLevelAllAllowsAllLogging() {
        ShopifyCheckoutSheetKit.configuration.logLevel = .all

        let logger = TestableOSLogger()

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

    func testLogLevelDebugAllowsDebugAndInfo() {
        ShopifyCheckoutSheetKit.configuration.logLevel = .debug

        let logger = TestableOSLogger()

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

    func testLogLevelErrorAllowsErrorAndFault() {
        ShopifyCheckoutSheetKit.configuration.logLevel = .error

        let logger = TestableOSLogger()

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

    func testSharedLoggerBackwardsCompatibility() {
        ShopifyCheckoutSheetKit.configuration.logLevel = .all
        OSLogger.shared.info("test message")
    }

    func testExactMessageFormatting() {
        ShopifyCheckoutSheetKit.configuration.logLevel = .all

        let logger = TestableOSLogger()

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
}

final class NoOpLoggerTests: XCTestCase {
    func testNoOpLoggerImplementsLoggerProtocol() {
        let logger: ShopifyCheckoutSheetKit.Logger = NoOpLogger()
        logger.log("test message")
        logger.clearLogs()
    }

    func testNoOpLoggerDoesNotThrow() {
        let logger = NoOpLogger()

        XCTAssertNoThrow(logger.log("test message"))
        XCTAssertNoThrow(logger.clearLogs())
    }
}
