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

import ShopifyAcceleratedCheckouts
import ShopifyCheckoutSheetKit
import UIKit

func getLogLevel(key: String) -> LogLevel {
    guard
        let rawLogLevel = UserDefaults.standard.string(
            forKey: key
        ),
        let logLevel = LogLevel(rawValue: rawLogLevel)
    else { return .all }

    return logLevel
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _: UIApplication,
        willFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let acceleratedCheckoutsLogLevel: LogLevel = getLogLevel(
            key: AppStorageKeys.acceleratedCheckoutsLogLevel.rawValue
        )
        let checkoutSheetKitLogLevel: LogLevel = getLogLevel(
            key: AppStorageKeys.checkoutSheetKitLogLevel.rawValue
        )

        ShopifyAcceleratedCheckouts.logLevel = acceleratedCheckoutsLogLevel

        ShopifyCheckoutSheetKit.configure {
            /// Checkout color scheme setting
            $0.colorScheme = .web

            /// Customize progress bar color
            $0.tintColor = ColorPalette.primaryColor

            /// Customize sheet color (matches web configuration by default)
            $0.backgroundColor = ColorPalette.backgroundColor

            /// Enable preloading
            $0.preloading.enabled = true

            /// Optional logger used for internal purposes
            $0.logger = FileLogger("log.txt")

            $0.logLevel = checkoutSheetKitLogLevel
        }

        print("[MobileBuyIntegration] AcceleratedCheckout Log level set to \(acceleratedCheckoutsLogLevel)")
        print("[MobileBuyIntegration] CheckoutSheetKit Log level set to \(checkoutSheetKitLogLevel)")

        // Log app authentication configuration status
        if appConfiguration.isAuthenticationConfigured {
            print("[MobileBuyIntegration] App authentication configuration: ✓ Configured")
            if appConfiguration.useAppAuthentication {
                print("[MobileBuyIntegration] App authentication: ✓ Enabled")
            } else {
                print("[MobileBuyIntegration] App authentication: ✗ Disabled (toggle in Settings)")
            }
        } else {
            print("[MobileBuyIntegration] App authentication configuration: ✗ Not configured (set APP_API_KEY, APP_SHARED_SECRET, APP_ACCESS_TOKEN in Storefront.xcconfig)")
        }

        UIBarButtonItem.appearance().tintColor = ColorPalette.primaryColor

        return true
    }

    func application(
        _: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession,
        options _: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default", sessionRole: connectingSceneSession.role)
    }
}
