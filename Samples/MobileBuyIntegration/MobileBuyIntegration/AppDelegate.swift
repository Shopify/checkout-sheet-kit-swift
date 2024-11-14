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

import UIKit
import ShopifyCheckoutSheetKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
	func application(_ app: UIApplication, willFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {

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

			$0.logLevel = .all
		}

		print("[MobileBuyIntegration] Log level set to .all")

		UIBarButtonItem.appearance().tintColor = ColorPalette.primaryColor

		return true
	}

	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		return UISceneConfiguration(name: "Default", sessionRole: connectingSceneSession.role)
	}
}

struct ColorPalette {
	static let primaryColor = UIColor(red: 37/255, green: 96/255, blue: 79/255, alpha: 1.0)
	static let successColor = UIColor(red: 31/255, green: 59/255, blue: 51/255, alpha: 1.0)
	static let backgroundColor = UIColor(red: 249/255, green: 248/255, blue: 246/255, alpha: 1.0)
}
