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
import Combine

/// A SceneDelgate is a bit of a legacy concept since the introduction of the SwiftUI App Lifecycle in iOS 14.
/// This implementation can updated to use SwiftUI's @main attribute like so:
///
/// @main
/// struct MySwiftUIApp: App {
///   var body: some Scene {
///     WindowGroup {
///		  ContentView()
///     }
///   }
/// }
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

	var window: UIWindow?

	public static var cartController = CheckoutViewHostingController(rootView: CartView())
	var productController: ProductView?
	var productGrid: ProductGrid?

	var cancellables: Set<AnyCancellable> = []

	 func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let tabBarController = UITabBarController()

		/// Branding Logo
		/// TODO: Fetch this from the Storefront API for the configured storefront
        let logoImageView = UIImageView(image: UIImage(named: "logo"))
		logoImageView.contentMode = .scaleAspectFit
		logoImageView.widthAnchor.constraint(equalToConstant: 90).isActive = true
		logoImageView.heightAnchor.constraint(equalToConstant: 50).isActive = true

		/// Catalog grid view
		productGrid = ProductGrid()
		let productGridController = UIHostingController(rootView: productGrid)
        productGridController.tabBarItem.image = UIImage(systemName: "square.grid.2x2")
        productGridController.tabBarItem.title = "Catalog"
        productGridController.navigationItem.titleView = logoImageView

        /// Product Gallery
        let productView = ProductGalleryView()
        let productGalleryController = UIHostingController(rootView: productView)
        productGalleryController.tabBarItem.image = UIImage(systemName: "appwindow.swipe.rectangle")
        productGalleryController.tabBarItem.title = "Products"
        productGalleryController.navigationItem.titleView = logoImageView

        /// Cart
        SceneDelegate.cartController.tabBarItem.image = UIImage(systemName: "cart")
        SceneDelegate.cartController.tabBarItem.title = "Cart"
		SceneDelegate.cartController.navigationItem.title = "Cart"

		subscribeToCartUpdates()

        tabBarController.viewControllers = [
			/// Catalog grid screen
			UINavigationController(rootViewController: productGridController),

			/// Product gallery screen
            UINavigationController(rootViewController: productGalleryController),

            /// Cart screen
            UINavigationController(rootViewController: SceneDelegate.cartController)
        ]

        if #available(iOS 15.0, *) {
            let settingsController = UIHostingController(rootView: SettingsView(appConfiguration: appConfiguration))
            settingsController.tabBarItem.image = UIImage(systemName: "gearshape.2")
            settingsController.tabBarItem.title = "Settings"

            tabBarController.viewControllers?.append(UINavigationController(
                rootViewController: settingsController
            ))
        }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
				window.tintColor = ColorPalette.primaryColor

        // Set up Notification and interface style
        NotificationCenter.default.addObserver(self, selector: #selector(colorSchemeChanged), name: .colorSchemeChanged, object: nil)
        window.overrideUserInterfaceStyle = ShopifyCheckoutSheetKit.configuration.colorScheme.userInterfaceStyle

        self.window = window
    }

    private func subscribeToCartUpdates() {
        CartManager.shared.$cart
            .sink { cart in
                if let cart = cart, cart.lines.nodes.count > 0 {
					SceneDelegate.cartController.tabBarItem.badgeValue = "\(cart.totalQuantity)"
                } else {
                    SceneDelegate.cartController.tabBarItem.badgeValue = nil
                }
            }
            .store(in: &cancellables)
    }

	func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
		guard
			userActivity.activityType == NSUserActivityTypeBrowsingWeb,
			let incomingURL = userActivity.webpageURL,

			/// Ensure URL host matches our Storefront domain
			let host = incomingURL.host, host == appConfiguration.storefrontDomain
		else {
			return
		}

		handleUniversalLink(url: incomingURL)
	}

	func handleUniversalLink(url: URL) {
		let storefrontUrl = StorefrontURL(from: url)

		switch true {
		/// Checkout URLs
		case appConfiguration.universalLinks.checkout && storefrontUrl.isCheckout() && !storefrontUrl.isThankYouPage():
			presentCheckout(url)
		/// Cart URLs
		case appConfiguration.universalLinks.cart && storefrontUrl.isCart():
			navigateToCart()
		/// Product URLs
		case appConfiguration.universalLinks.products:
			if let slug = storefrontUrl.getProductSlug() {
				navigateToProduct(with: slug)
			}
		/// Open everything else in Safari
		default:
			UIApplication.shared.open(url)
		}
	}

	private func presentCheckout(_ url: URL) {
		ShopifyCheckoutSheetKit.present(checkout: url, from: SceneDelegate.cartController, delegate: SceneDelegate.cartController)
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
		ProductCache.shared.getProduct(handle: handle, completion: { _ in })

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

class CheckoutViewHostingController: UIHostingController<CartView>, CheckoutDelegate {
    override init(rootView: CartView) {
        super.init(rootView: rootView)
    }

    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Implementing CheckoutDelegate methods
    func checkoutDidComplete() {
		CartManager.shared.resetCart()
    }

    func checkoutDidCancel() {
        dismiss(animated: true, completion: nil)
    }

    func checkoutDidFail(error: Error) {
        print("Checkout failed: \(error.localizedDescription)")
        // Handle checkout failure logic
    }

    func checkoutDidFail(error: ShopifyCheckoutSheetKit.CheckoutError) {
		print("Checkout failed: \(error.localizedDescription)")
        // Handle checkout failure logic
	}

	func checkoutDidEmitWebPixelEvent(event: ShopifyCheckoutSheetKit.PixelEvent) {
		print("Checkout pixel event")
        // Handle pixel event
	}
}
