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

@testable import ShopifyCheckoutSheetKit
import XCTest

class UserAgentTests: XCTestCase {
    func test_string_withAcceleratedCheckoutsEntryPoint_shouldReturnCorrectUserAgent() {
        let schemaVersion = MetaData.schemaVersion
        let acceleratedCheckoutsUA = UserAgent.string(
            type: .standard,
            colorScheme: .automatic,
            entryPoint: .acceleratedCheckouts
        )
        XCTAssertEqual(acceleratedCheckoutsUA, "ShopifyCheckoutSDK/4.0.0-rc.1 (\(schemaVersion);automatic;standard) AcceleratedCheckouts")
    }

    func test_string_withAcceleratedCheckoutsAndReactNativePlatform_shouldReturnUserAgentWithPlatform() {
        let schemaVersion = MetaData.schemaVersion
        let acceleratedCheckoutsUA = UserAgent.string(
            type: .standard,
            colorScheme: .automatic,
            platform: .reactNative,
            entryPoint: .acceleratedCheckouts
        )
        XCTAssertEqual(acceleratedCheckoutsUA, "ShopifyCheckoutSDK/4.0.0-rc.1 (\(schemaVersion);automatic;standard) ReactNative AcceleratedCheckouts")
    }

    func test_string_withoutEntryPoint_shouldReturnBasicUserAgent() {
        let schemaVersion = MetaData.schemaVersion
        let checkoutSheetKitUA = UserAgent.string(
            type: .standard,
            colorScheme: .automatic
        )
        XCTAssertEqual(checkoutSheetKitUA, "ShopifyCheckoutSDK/4.0.0-rc.1 (\(schemaVersion);automatic;standard)")
    }

    func test_string_withRecoveryTypeAndDarkColorScheme_shouldReturnRecoveryUserAgent() {
        let recoveryUA = UserAgent.string(
            type: .recovery,
            colorScheme: .dark,
            entryPoint: .acceleratedCheckouts
        )
        XCTAssertEqual(recoveryUA, "ShopifyCheckoutSDK/4.0.0-rc.1 (noconnect;dark;standard_recovery) AcceleratedCheckouts")
    }
}
