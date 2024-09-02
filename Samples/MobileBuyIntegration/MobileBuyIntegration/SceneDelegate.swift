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

import Combine
import ShopifyCheckoutSheetKit
import SwiftUI
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    var cancellables: Set<AnyCancellable> = []

    let cartController = UIHostingController(rootView: CartView())
    let productGridController = UIHostingController(rootView: ProductGrid())
    let productGalleryController = UIHostingController(rootView: ProductGalleryView())
    let settingsController = UIHostingController(rootView: SettingsView())

    func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let tabBarController = UITabBarController()

        /// Branding Logo
        /// TODO: Fetch this from the Storefront API for the configured storefront
        let logoImageView = UIImageView(image: UIImage(named: "logo"))
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.widthAnchor.constraint(equalToConstant: 90).isActive = true

        /// Catalog grid view
        productGridController.tabBarItem.image = UIImage(systemName: "square.grid.2x2")
        productGridController.tabBarItem.title = "Catalog"
        productGridController.navigationItem.titleView = logoImageView

        /// Product Gallery
        productGalleryController.tabBarItem.image = UIImage(systemName: "appwindow.swipe.rectangle")
        productGalleryController.tabBarItem.title = "Products"
        productGalleryController.navigationItem.titleView = logoImageView
        productGalleryController.navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "cart"),
            style: .plain,
            target: self,
            action: #selector(present)
        )

        /// Cart
        cartController.tabBarItem.image = UIImage(systemName: "cart")
        cartController.tabBarItem.title = "Cart"
        cartController.navigationItem.title = "Cart"

		tabBarController.viewControllers = [
			UINavigationController(
				rootViewController: loginController
			),
			UINavigationController(
				rootViewController: catalogController
			),
			UINavigationController(
				rootViewController: cartController
			)
		]

		if #available(iOS 15.0, *) {
			let settingsController = UIHostingController(rootView: SettingsView())
			settingsController.tabBarItem.image = UIImage(systemName: "gearshape.2")
			settingsController.tabBarItem.title = "Settings"

        subscribeToCartUpdates()

        tabBarController.viewControllers = [
            /// Catalog grid screen
            UINavigationController(rootViewController: productGridController),

            /// Product gallery screen
            UINavigationController(rootViewController: productGalleryController),

            /// Cart screen
            UINavigationController(rootViewController: cartController),

            /// Settings screen
            UINavigationController(rootViewController: settingsController)
        ]

        /// Subscribe to color scheme changes on the settings screen
        NotificationCenter.default.addObserver(self, selector: #selector(colorSchemeChanged), name: .colorSchemeChanged, object: nil)

        let window = createWindow(windowScene: windowScene, rootViewController: tabBarController)

        CheckoutController.shared = CheckoutController(window: window)

        self.window = window
    }

    @objc public func present() {
        if let url = CartManager.shared.cart?.checkoutUrl {
            presentCheckout(url)
        }
    }

    private func createWindow(windowScene: UIWindowScene, rootViewController: UIViewController) -> UIWindow {
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = rootViewController
        window.makeKeyAndVisible()
        window.tintColor = ColorPalette.primaryColor
        window.overrideUserInterfaceStyle = ShopifyCheckoutSheetKit.configuration.colorScheme.userInterfaceStyle
        return window
    }

    private func subscribeToCartUpdates() {
        CartManager.shared.$cart
            .sink { cart in
                if let cart = cart, cart.lines.nodes.count > 0 {
                    self.cartController.tabBarItem.badgeValue = "\(cart.totalQuantity)"
                } else {
                    self.cartController.tabBarItem.badgeValue = nil
                }
            }
            .store(in: &cancellables)
    }

    func scene(_: UIScene, continue userActivity: NSUserActivity) {
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

    public func presentCheckout(_ url: URL) {
        CheckoutController.shared?.present(checkout: url)
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

extension UIWindow {
    /// Function to get the top most view controller from the window's rootViewController
    func topMostViewController() -> UIViewController? {
        guard var topController = rootViewController else {
            return nil
        }

        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }

        return topController
    }
}
