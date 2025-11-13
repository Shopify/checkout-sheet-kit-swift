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
import Foundation
import OSLog
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

    let uiKitCartController = CartViewController()
    let swiftUICartController = UIHostingController(rootView: CartView())
    let productGridController = UIHostingController(rootView: ProductGridView())
    let productGalleryController = UIHostingController(rootView: ProductGalleryView())
    let settingsController = UIHostingController(rootView: SettingsView())

    // Store cart button views for badge updates
    private var catalogCartButton: UIView?
    private var galleryCartButton: UIView?

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

        /// Cart screen
        viewControllers[Screen.cart.rawValue] = UINavigationController(rootViewController: swiftUICartController)

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

    private func makeLogoTitleView() -> UIImageView {
        let imageView = UIImageView(image: UIImage(named: "logo"))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.widthAnchor.constraint(equalToConstant: 90).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 32).isActive = true
        return imageView
    }

    private func setupControllers() {
        /// Catalog grid view
        productGridController.tabBarItem.image = UIImage(systemName: "square.grid.2x2")
        productGridController.tabBarItem.title = "Catalog"
        productGridController.navigationItem.titleView = makeLogoTitleView()
        catalogCartButton = createCartButtonWithBadge()
        productGridController.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: catalogCartButton!)

        /// Product Gallery
        productGalleryController.tabBarItem.image = UIImage(systemName: "appwindow.swipe.rectangle")
        productGalleryController.tabBarItem.title = "Products"
        productGalleryController.navigationItem.titleView = makeLogoTitleView()
        galleryCartButton = createCartButtonWithBadge()
        productGalleryController.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: galleryCartButton!)

        /// Cart (UI Kit)
        swiftUICartController.tabBarItem.image = UIImage(systemName: "cart")
        swiftUICartController.tabBarItem.title = "Cart"
        swiftUICartController.navigationItem.title = "Cart (SwiftUI)"

        /// Settings
        settingsController.tabBarItem.image = UIImage(systemName: "gearshape.2")
        settingsController.tabBarItem.title = "Settings"
    }

    @objc public func present() {
        if let url = CartManager.shared.cart?.checkoutUrl {
            presentCheckout(url)
        }
    }

    @objc public func presentUIKitCartInSheet() {
        // Wrap in navigation controller for better presentation
        let navigationController = UINavigationController(rootViewController: uiKitCartController)
        navigationController.modalPresentationStyle = .pageSheet

        // Add close button
        uiKitCartController.navigationItem.title = "Cart (UIKit)"
        uiKitCartController.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(dismissCartSheet)
        )

        // Present from the top-most view controller
        if let topViewController = window?.topMostViewController() {
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
                if let cart, cart.lines.nodes.count > 0 {
                    DispatchQueue.main.async {
                        self.swiftUICartController.tabBarItem.badgeValue = "\(cart.totalQuantity)"
                        self.updateCartButtonBadges(count: Int(cart.totalQuantity))
                    }
                } else {
                    self.swiftUICartController.tabBarItem.badgeValue = nil
                    self.updateCartButtonBadges(count: 0)
                }
            }
            .store(in: &cancellables)
    }

    private func createCartButtonWithBadge() -> UIView {
        let containerView = UIView()
        containerView.frame = CGRect(x: 0, y: 0, width: 44, height: 44)

        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "cart"), for: .normal)
        button.tintColor = ColorPalette.primaryColor
        button.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        button.addTarget(self, action: #selector(presentUIKitCartInSheet), for: .touchUpInside)

        let badgeLabel = UILabel()
        badgeLabel.backgroundColor = .systemRed
        badgeLabel.textColor = .white
        badgeLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        badgeLabel.textAlignment = .center
        badgeLabel.layer.cornerRadius = 10
        badgeLabel.clipsToBounds = true
        badgeLabel.frame = CGRect(x: 25, y: 5, width: 20, height: 20)
        badgeLabel.isHidden = true
        badgeLabel.tag = ElementTags.cartBadgeLabel

        containerView.addSubview(button)
        containerView.addSubview(badgeLabel)

        return containerView
    }

    private func updateCartButtonBadges(count: Int) {
        let badgeText = count > 0 ? "\(count)" : ""
        let shouldShow = count > 0

        // Update catalog cart button badge
        if let catalogButton = catalogCartButton,
           let badgeLabel = catalogButton.viewWithTag(ElementTags.cartBadgeLabel) as? UILabel
        {
            badgeLabel.text = badgeText
            badgeLabel.isHidden = !shouldShow
        }

        // Update gallery cart button badge
        if let galleryButton = galleryCartButton,
           let badgeLabel = galleryButton.viewWithTag(ElementTags.cartBadgeLabel) as? UILabel
        {
            badgeLabel.text = badgeText
            badgeLabel.isHidden = !shouldShow
        }
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

    public func presentBuyNow(checkoutURL: URL) {
        OSLogger.shared.debug("[SceneDelegate] presentBuyNow called with URL: \(checkoutURL)")

        if AuthenticationService.shared.hasConfiguration() {
            OSLogger.shared.debug("[SceneDelegate] Authentication is configured, fetching token for Buy Now")

            _Concurrency.Task {
                do {
                    let token = try await AuthenticationService.shared.fetchAccessToken()
                    let options = CheckoutOptions(authentication: .token(token))
                    OSLogger.shared.debug("[SceneDelegate] Successfully fetched auth token for Buy Now")

                    await MainActor.run {
                        ShopifyCheckoutSheetKit.preload(checkout: checkoutURL, options: options)
                        let embeddedCheckout = ShopifyCheckoutViewController(checkoutURL: checkoutURL, options: options)
                        let navController = UINavigationController(rootViewController: embeddedCheckout)
                        navController.modalPresentationStyle = UIModalPresentationStyle.fullScreen
                        self.window?.topMostViewController()?.present(navController, animated: true)
                    }
                } catch {
                    OSLogger.shared.error("[SceneDelegate] Failed to fetch auth token for Buy Now: \(error.localizedDescription)")

                    // Present without auth on failure
                    await MainActor.run {
                        ShopifyCheckoutSheetKit.preload(checkout: checkoutURL)
                        let embeddedCheckout = ShopifyCheckoutViewController(checkoutURL: checkoutURL)
                        let navController = UINavigationController(rootViewController: embeddedCheckout)
                        navController.modalPresentationStyle = UIModalPresentationStyle.fullScreen
                        self.window?.topMostViewController()?.present(navController, animated: true)
                    }
                }
            }
        } else {
            OSLogger.shared.debug("[SceneDelegate] Authentication not configured, presenting Buy Now without token")
            ShopifyCheckoutSheetKit.preload(checkout: checkoutURL)
            let embeddedCheckout = ShopifyCheckoutViewController(checkoutURL: checkoutURL)
            let navController = UINavigationController(rootViewController: embeddedCheckout)
            navController.modalPresentationStyle = UIModalPresentationStyle.fullScreen
            window?.topMostViewController()?.present(navController, animated: true)
        }
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

enum ElementTags {
    static let cartBadgeLabel = 999
}
