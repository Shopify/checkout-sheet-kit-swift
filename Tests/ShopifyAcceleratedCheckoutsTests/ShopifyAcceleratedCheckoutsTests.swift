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

@testable import ShopifyAcceleratedCheckouts
@testable import ShopifyCheckoutSheetKit

@available(iOS 17.0, *)
class ShopifyAcceleratedCheckoutsTests: XCTestCase {
    var originalLogLevel: LogLevel!

    override func setUp() {
        super.setUp()
        originalLogLevel = ShopifyAcceleratedCheckouts.logLevel
    }

    override func tearDown() {
        ShopifyAcceleratedCheckouts.logLevel = originalLogLevel
        super.tearDown()
    }

    func test_apiVersion_whenAccessed_shouldBePublic() {
        XCTAssertEqual(ShopifyAcceleratedCheckouts.apiVersion, "2025-04")
    }

    func test_logLevel_withDefaultConfiguration_shouldDefaultToError() {
        XCTAssertEqual(
            ShopifyAcceleratedCheckouts.logLevel,
            LogLevel.error,
            "Default logLevel should be .error"
        )
        XCTAssertNotNil(ShopifyAcceleratedCheckouts.logger)
        XCTAssertEqual(
            ShopifyAcceleratedCheckouts.logger.logLevel,
            LogLevel.error,
            "Default logger logLevel should be .error"
        )
    }

    func test_configuration_onLogLevelChange_usesExistingInstance() {
        let originalLogger = ShopifyAcceleratedCheckouts.logger
        let originalLogLevel = ShopifyAcceleratedCheckouts.logger.logLevel

        ShopifyAcceleratedCheckouts.logLevel = originalLogLevel
        let newLogger = ShopifyAcceleratedCheckouts.logger

        XCTAssertTrue(
            originalLogger === newLogger,
            "Changing log level should create a new logger instance"
        )
    }

    func test_logger_withDifferentLogLevels_shouldHaveCorrectLogLevel() {
        ShopifyAcceleratedCheckouts.logLevel = .all
        XCTAssertEqual(
            ShopifyAcceleratedCheckouts.logger.logLevel, .all, "Logger should have .all log level"
        )

        ShopifyAcceleratedCheckouts.logLevel = .debug
        XCTAssertEqual(
            ShopifyAcceleratedCheckouts.logger.logLevel, .debug,
            "Logger should have .debug log level"
        )

        ShopifyAcceleratedCheckouts.logLevel = .error
        XCTAssertEqual(
            ShopifyAcceleratedCheckouts.logger.logLevel, .error,
            "Logger should have .error log level"
        )

        ShopifyAcceleratedCheckouts.logLevel = .none
        XCTAssertEqual(
            ShopifyAcceleratedCheckouts.logger.logLevel, .none, "Logger should have .none log level"
        )
    }
}
