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

import Common
import XCTest

class UserAgentTests: XCTestCase {
    func test_string_withAcceleratedCheckoutsEntryPoint_shouldReturnCorrectUserAgent() {
        let schemaVersion = UserAgent.schemaVersion
        let acceleratedCheckoutsUA = UserAgent.string(
            type: .standard,
            colorScheme: .automatic,
            entryPoint: .acceleratedCheckouts
        )
        XCTAssertEqual(acceleratedCheckoutsUA, "ShopifyCheckoutSDK/3.2.0 (\(schemaVersion);automatic;standard;entry:AcceleratedCheckouts)")
    }

    func test_string_withAcceleratedCheckoutsAndReactNativePlatform_shouldReturnUserAgentWithPlatform() {
        let schemaVersion = UserAgent.schemaVersion
        let acceleratedCheckoutsUA = UserAgent.string(
            type: .standard,
            colorScheme: .automatic,
            platform: .reactNative,
            entryPoint: .acceleratedCheckouts
        )
        XCTAssertEqual(acceleratedCheckoutsUA, "ShopifyCheckoutSDK/3.2.0 (\(schemaVersion);automatic;standard;entry:AcceleratedCheckouts) ReactNative")
    }

    func test_string_withoutEntryPoint_shouldReturnBasicUserAgent() {
        let schemaVersion = UserAgent.schemaVersion
        let checkoutSheetKitUA = UserAgent.string(
            type: .standard,
            colorScheme: .automatic
        )
        XCTAssertEqual(checkoutSheetKitUA, "ShopifyCheckoutSDK/3.2.0 (\(schemaVersion);automatic;standard)")
    }

    func test_string_withRecoveryTypeAndDarkColorScheme_shouldReturnRecoveryUserAgent() {
        let schemaVersion = UserAgent.schemaVersion
        let recoveryUA = UserAgent.string(
            type: .recovery,
            colorScheme: .dark,
            entryPoint: .acceleratedCheckouts
        )
        XCTAssertEqual(recoveryUA, "ShopifyCheckoutSDK/3.2.0 (noconnect;dark;standard_recovery;entry:AcceleratedCheckouts)")
    }

    func test_string_withAllParameters_shouldReturnCompleteUserAgent() {
        let schemaVersion = UserAgent.schemaVersion
        let fullUA = UserAgent.string(
            type: .standard,
            colorScheme: .light,
            platform: .reactNative,
            entryPoint: .checkoutSheetKit
        )
        XCTAssertEqual(fullUA, "ShopifyCheckoutSDK/3.2.0 (\(schemaVersion);light;standard;entry:CheckoutSheetKit) ReactNative")
    }
}
