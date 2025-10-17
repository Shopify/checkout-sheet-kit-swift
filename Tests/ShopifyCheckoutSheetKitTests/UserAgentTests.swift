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
        let version = MetaData.version
        let acceleratedCheckoutsUA = UserAgent.string(
            type: .standard,
            colorScheme: .automatic,
            entryPoint: .acceleratedCheckouts
        )
        XCTAssertEqual(acceleratedCheckoutsUA, "ShopifyCheckoutSDK/\(version) (\(schemaVersion);automatic;standard) AcceleratedCheckouts")
    }

    func test_string_withAcceleratedCheckoutsAndReactNativePlatform_shouldReturnUserAgentWithPlatform() {
        let schemaVersion = MetaData.schemaVersion
        let version = MetaData.version
        let acceleratedCheckoutsUA = UserAgent.string(
            type: .standard,
            colorScheme: .automatic,
            platform: .reactNative,
            entryPoint: .acceleratedCheckouts
        )
        XCTAssertEqual(acceleratedCheckoutsUA, "ShopifyCheckoutSDK/\(version) (\(schemaVersion);automatic;standard) ReactNative AcceleratedCheckouts")
    }

    func test_string_withoutEntryPoint_shouldReturnBasicUserAgent() {
        let schemaVersion = MetaData.schemaVersion
        let version = MetaData.version
        let checkoutSheetKitUA = UserAgent.string(
            type: .standard,
            colorScheme: .automatic
        )
        XCTAssertEqual(checkoutSheetKitUA, "ShopifyCheckoutSDK/\(version) (\(schemaVersion);automatic;standard)")
    }

    func test_string_withRecoveryTypeAndDarkColorScheme_shouldReturnRecoveryUserAgent() {
        let schemaVersion = MetaData.schemaVersion
        let version = MetaData.version
        let recoveryUA = UserAgent.string(
            type: .recovery,
            colorScheme: .dark,
            entryPoint: .acceleratedCheckouts
        )
        XCTAssertEqual(recoveryUA, "ShopifyCheckoutSDK/\(version) (noconnect;dark;standard_recovery) AcceleratedCheckouts")
    }

    func test_applicationName_shouldContainChromeVersion() {
        let userAgent = CheckoutBridge.applicationName

        XCTAssertTrue(
            userAgent.contains("Chrome/"),
            "User agent must contain Chrome version for Google Pay support"
        )
    }

    func test_applicationName_shouldMeetMinimumChromeVersionForGooglePay() {
        let userAgent = CheckoutBridge.applicationName
        let chromeVersionPattern = #"Chrome/(\d+)"#

        guard let regex = try? NSRegularExpression(pattern: chromeVersionPattern),
              let match = regex.firstMatch(in: userAgent, range: NSRange(userAgent.startIndex..., in: userAgent)),
              let versionRange = Range(match.range(at: 1), in: userAgent),
              let versionNumber = Int(userAgent[versionRange])
        else {
            XCTFail("Chrome version not found in user agent")
            return
        }

        XCTAssertGreaterThanOrEqual(
            versionNumber,
            137,
            "Chrome version must be >= 137 for Google Pay"
        )
    }
}
