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
import SwiftUI
import ShopifyCheckoutSheetKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

	var window: UIWindow?

	var cartController: CartViewController?
	var productController: ProductViewController?

	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options: UIScene.ConnectionOptions) {
		guard let windowScene = (scene as? UIWindowScene) else { return }

		let tabBarController = UITabBarController()

		/// Catalog
		productController = ProductViewController()
		productController?.tabBarItem.image = UIImage(systemName: "books.vertical")
		productController?.tabBarItem.title = "Browse"
		productController?.navigationItem.title = "Product details"

		/// Cart
		cartController = CartViewController()
		cartController?.tabBarItem.image = UIImage(systemName: "cart")
		cartController?.tabBarItem.title = "Cart"
		cartController?.navigationItem.title = "Cart"

		tabBarController.viewControllers = [
			UINavigationController(
				rootViewController: productController!
			),
			UINavigationController(
				rootViewController: cartController!
			)
		]

		if #available(iOS 15.0, *) {
			let settingsController = UIHostingController(rootView: SettingsView())
			settingsController.tabBarItem.image = UIImage(systemName: "gearshape.2")
			settingsController.tabBarItem.title = "Settings"

			tabBarController.viewControllers?.append(UINavigationController(
				rootViewController: settingsController
			))
		}

		let window = UIWindow(windowScene: windowScene)
		window.rootViewController = tabBarController
		window.makeKeyAndVisible()

		NotificationCenter.default.addObserver(self, selector: #selector(colorSchemeChanged), name: .colorSchemeChanged, object: nil)

		window.overrideUserInterfaceStyle = ShopifyCheckoutSheetKit.configuration.colorScheme.userInterfaceStyle

		self.window = window
	}

	func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
		guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
			  let incomingURL = userActivity.webpageURL else {
			return
		}

		handleUniversalLink(url: incomingURL)
	}

	func handleUniversalLink(url: URL) {
		// The URL host must match the StorefrontDomain defined in our env
		guard let host = url.host, host == appConfiguration.storefrontDomain else { return }

		let storefrontUrl = StorefrontURL(from: url)

		switch true {
		case appConfiguration.universalLinks.handleCheckoutInApp && storefrontUrl.isCheckout() && !storefrontUrl.isThankYouPage():
			if let vc = cartController {
				ShopifyCheckoutSheetKit.present(checkout: url, from: vc, delegate: vc)
			}
		case appConfiguration.universalLinks.handleAllURLsInApp:
			if storefrontUrl.isCart() {
				navigateToCart()
			} else if let slug = storefrontUrl.getProductSlug() {
				navigateToProduct(with: slug)
			}
		default:
			// Open all other links in Safari
			UIApplication.shared.open(url)
		}
	}

	private func getRootViewController() -> UINavigationController? {
		return window?.rootViewController as? UINavigationController
	}

	private func getNavigationController(forTab index: Int) -> UINavigationController? {
		guard let tabBarVC = window?.rootViewController as? UITabBarController else {
			return nil
		}
		return tabBarVC.viewControllers?[index] as? UINavigationController
	}

	func navigateToCart() {
		if let tabBarVC = window?.rootViewController as? UITabBarController {
			tabBarVC.selectedIndex = 1
		}
	}


	func navigateToProduct(with handle: String) {
		if let pdp = self.productController {
			pdp.getProductByHandle(handle)
		}

		if let tabBarVC = window?.rootViewController as? UITabBarController {
			tabBarVC.selectedIndex = 0
		}
	}

	@objc func colorSchemeChanged() {
		window?.overrideUserInterfaceStyle = ShopifyCheckoutSheetKit.configuration.colorScheme.userInterfaceStyle
	}
}

extension Notification.Name {
	static let colorSchemeChanged = Notification.Name("colorSchemeChanged")
}

extension Configuration.ColorScheme {
	var userInterfaceStyle: UIUserInterfaceStyle {
		switch self {
		case .light:
			return .light
		case .dark:
			return .dark
		default:
			return .unspecified
		}
	}
}

public struct StorefrontURL {
    public let url: URL

    private let slug = "([\\w\\d_-]+)"

    init(from url: URL) {
        self.url = url
    }

    public func isThankYouPage() -> Bool {
        return url.path.range(of: "/thank[-_]you", options: .regularExpression) != nil
    }

    public func isCheckout() -> Bool {
		return url.path.contains("/checkout")
	}

	public func isCart() -> Bool {
		return url.path.contains("/cart")
	}

	public func isCollection() -> Bool {
		return url.path.range(of: "/collections/\(slug)", options: .regularExpression) != nil
	}

	public func isProduct() -> Bool {
		return url.path.range(of: "/products/\(slug)", options: .regularExpression) != nil
	}

	public func getProductSlug() -> String? {
		guard isProduct() else { return nil }

		let pattern = "/products/([\\w_-]+)"
		if let match = url.path.range(of: pattern, options: .regularExpression, range: nil, locale: nil) {
			let slug = url.path[match].components(separatedBy: "/").last
			return slug
		}
		return nil
	}
}
