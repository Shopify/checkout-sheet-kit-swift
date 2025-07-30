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

enum Screen: Int, CaseIterable {
    case catalog
    case products
    case cart
    case settings
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    var cancellables: Set<AnyCancellable> = []
    private var catalogCartButton: CartBarButtonView?
    private var productsCartButton: CartBarButtonView?

    let swiftuiCartController = UIHostingController(rootView: CartView())
    let productGridController = UIHostingController(rootView: ProductGridView())
    let productGalleryController = UIHostingController(rootView: ProductGalleryView())
    let settingsController = UIHostingController(rootView: SettingsView())

    func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let tabBarController = UITabBarController()

        setupControllers()
        subscribeToCartUpdates()
        subscribeToColorSchemeChanges()

        var viewControllers: [UIViewController?] = Array(repeating: nil, count: Screen.allCases.count)

        /// Catalog screen
        viewControllers[Screen.catalog.rawValue] = UINavigationController(rootViewController: productGridController)

        /// Product gallery screen
        viewControllers[Screen.products.rawValue] = UINavigationController(rootViewController: productGalleryController)

        /// Cart screen (SwiftUI)
        viewControllers[Screen.cart.rawValue] = UINavigationController(rootViewController: swiftuiCartController)

        /// Settings screen
        viewControllers[Screen.settings.rawValue] = UINavigationController(rootViewController: settingsController)

        tabBarController.viewControllers = viewControllers.compactMap { $0 }

        let window = createWindow(windowScene: windowScene, rootViewController: tabBarController)

        CheckoutController.shared = CheckoutController(window: window)

        self.window = window
    }

    private func subscribeToColorSchemeChanges() {
        /// Subscribe to color scheme changes on the settings screen
        NotificationCenter.default.addObserver(self, selector: #selector(colorSchemeChanged), name: .colorSchemeChanged, object: nil)
    }

    private func setupControllers() {
        /// Branding Logo
        let logoImageView = UIImageView(image: UIImage(named: "logo"))
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.widthAnchor.constraint(equalToConstant: 90).isActive = true

        /// Catalog grid view
        productGridController.tabBarItem.image = UIImage(systemName: "square.grid.2x2")
        productGridController.tabBarItem.title = "Catalog"
        productGridController.navigationItem.titleView = logoImageView
        catalogCartButton = CartBarButtonView()
        catalogCartButton?.addTarget(self, action: #selector(presentCartSheet), for: .touchUpInside)
        productGridController.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: catalogCartButton!)

        /// Product Gallery
        productGalleryController.tabBarItem.image = UIImage(systemName: "appwindow.swipe.rectangle")
        productGalleryController.tabBarItem.title = "Products"
        productGalleryController.navigationItem.titleView = logoImageView
        productsCartButton = CartBarButtonView()
        productsCartButton?.addTarget(self, action: #selector(presentCartSheet), for: .touchUpInside)
        productGalleryController.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: productsCartButton!)

        /// Cart (SwiftUI)
        swiftuiCartController.tabBarItem.image = UIImage(systemName: "cart")
        swiftuiCartController.tabBarItem.title = "Cart"
        swiftuiCartController.navigationItem.title = "Cart (SwiftUI)"

        /// Settings
        settingsController.tabBarItem.image = UIImage(systemName: "gearshape.2")
        settingsController.tabBarItem.title = "Settings"
    }

    @objc public func present() {
        if let url = CartManager.shared.cart?.checkoutUrl {
            presentCheckout(url)
        }
    }

    @objc public func presentCartSheet() {
        let cartViewController = CartViewController()

        // Wrap in navigation controller for better presentation
        let navigationController = UINavigationController(rootViewController: cartViewController)
        navigationController.modalPresentationStyle = .pageSheet

        // Add close button
        cartViewController.navigationItem.title = "Cart (UIKit)"
        cartViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(dismissCartSheet)
        )

        // Present from the top-most view controller
        if let topViewController = window?.topMostViewController() {
            print("🟦 SceneDelegate presenting CartViewController navigation controller from: \(topViewController)")
            topViewController.present(navigationController, animated: true)
        }
    }

    @objc private func dismissCartSheet() {
        window?.topMostViewController()?.dismiss(animated: true)
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
                let badgeValue: String? = (cart?.lines.nodes.count ?? 0) > 0 ? "\(cart?.totalQuantity ?? 0)" : nil

                DispatchQueue.main.async {
                    // Update tab bar badge
                    self.swiftuiCartController.tabBarItem.badgeValue = badgeValue

                    // Update navigation bar badges
                    self.catalogCartButton?.setBadgeValue(badgeValue)
                    self.productsCartButton?.setBadgeValue(badgeValue)
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
            navigateTo(.cart)
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

    func navigateTo(_ screen: Screen) {
        if let tabBarVC = window?.rootViewController as? UITabBarController {
            tabBarVC.selectedIndex = screen.rawValue
        }
    }

    func navigateToProduct(with handle: String) {
        ProductCache.shared.getProduct(handle: handle, completion: { _ in })
        navigateTo(.catalog)
    }

    @objc func colorSchemeChanged() {
        window?.overrideUserInterfaceStyle = ShopifyCheckoutSheetKit.configuration.colorScheme.userInterfaceStyle
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

class CartBarButtonView: UIButton {
    private var badgeLabel: UILabel?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton()
    }

    private func setupButton() {
        setImage(UIImage(systemName: "cart"), for: .normal)
        frame = CGRect(x: 0, y: 0, width: 34, height: 34)

        // Create badge label
        badgeLabel = UILabel()
        badgeLabel?.backgroundColor = .systemRed
        badgeLabel?.textColor = .white
        badgeLabel?.alpha = 0.8
        badgeLabel?.font = .systemFont(ofSize: 10, weight: .medium)
        badgeLabel?.textAlignment = .center
        badgeLabel?.layer.cornerRadius = 10
        badgeLabel?.layer.masksToBounds = true
        badgeLabel?.isHidden = true
        badgeLabel?.translatesAutoresizingMaskIntoConstraints = false

        addSubview(badgeLabel!)

        // Position badge in top-right corner
        NSLayoutConstraint.activate([
            badgeLabel!.topAnchor.constraint(equalTo: topAnchor, constant: -10),
            badgeLabel!.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 10),
            badgeLabel!.widthAnchor.constraint(greaterThanOrEqualToConstant: 20),
            badgeLabel!.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    func setBadgeValue(_ value: String?) {
        if let value, !value.isEmpty {
            badgeLabel?.text = value
            badgeLabel?.isHidden = false
        } else {
            badgeLabel?.isHidden = true
        }
    }
}
