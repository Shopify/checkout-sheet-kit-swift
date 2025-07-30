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
import PassKit
import ShopifyCheckoutSheetKit
import SwiftUI
import UIKit

/// Protocol for handling custom presentation of accelerated checkout flows
public protocol AcceleratedCheckoutPresentationDelegate: AnyObject {
    /// Called when the accelerated checkout needs to present a view controller
    /// - Parameters:
    ///   - viewController: The checkout view controller to present
    ///   - animated: Whether the presentation should be animated
    func present(_ viewController: UIViewController, animated: Bool)
}

/// A button component that renders wallet-specific checkout buttons and handles checkout presentation.
/// This is the main public API that merchants should use for programmatic accelerated checkouts.
@available(iOS 17.0, *)
public class AcceleratedCheckoutButton: UIView {
    // MARK: - Public Properties

    public weak var delegate: AcceleratedCheckoutDelegate?

    /// Delegate for handling custom presentation behavior
    public weak var presentationDelegate: AcceleratedCheckoutPresentationDelegate?

    // Override intrinsic content size to ensure consistent 48pt height
    override public var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 48)
    }

    public var cornerRadius: CGFloat = Theme.acceleratedCheckoutButtonCornerRadius {
        didSet {
            updateButtonAppearance()
        }
    }

    override public var isUserInteractionEnabled: Bool {
        didSet {
            updateButtonAppearance()
        }
    }

    // MARK: - Private Properties

    private let wallet: Wallet
    private let identifier: CheckoutIdentifier
    private var button: UIButton!
    private var currentRenderState: RenderState = .loading {
        didSet {
            updateButtonState()
            delegate?.renderStateDidChange(state: currentRenderState)
        }
    }

    // MARK: - Factory Methods

    /// Creates an Apple Pay button for the specified cart
    /// - Parameters:
    ///   - cartID: The cart ID to checkout (must start with gid://shopify/Cart/)
    /// - Returns: A configured AcceleratedCheckoutButton for Apple Pay
    public static func applePay(cartID: String) -> AcceleratedCheckoutButton {
        return AcceleratedCheckoutButton(wallet: .applePay, identifier: .cart(cartID: cartID))
    }

    /// Creates an Apple Pay button for the specified product variant
    /// - Parameters:
    ///   - variantID: The variant ID to checkout (must start with gid://shopify/ProductVariant/)
    ///   - quantity: The quantity to add to cart
    /// - Returns: A configured AcceleratedCheckoutButton for Apple Pay
    public static func applePay(variantID: String, quantity: Int) -> AcceleratedCheckoutButton {
        return AcceleratedCheckoutButton(wallet: .applePay, identifier: .variant(variantID: variantID, quantity: quantity))
    }

    /// Creates a Shop Pay button for the specified cart
    /// - Parameters:
    ///   - cartID: The cart ID to checkout (must start with gid://shopify/Cart/)
    /// - Returns: A configured AcceleratedCheckoutButton for Shop Pay
    public static func shopPay(cartID: String) -> AcceleratedCheckoutButton {
        return AcceleratedCheckoutButton(wallet: .shopPay, identifier: .cart(cartID: cartID))
    }

    /// Creates a Shop Pay button for the specified product variant
    /// - Parameters:
    ///   - variantID: The variant ID to checkout (must start with gid://shopify/ProductVariant/)
    ///   - quantity: The quantity to add to cart
    /// - Returns: A configured AcceleratedCheckoutButton for Shop Pay
    public static func shopPay(variantID: String, quantity: Int) -> AcceleratedCheckoutButton {
        return AcceleratedCheckoutButton(wallet: .shopPay, identifier: .variant(variantID: variantID, quantity: quantity))
    }

    // MARK: - Initialization

    private init(wallet: Wallet, identifier: CheckoutIdentifier) {
        self.wallet = wallet
        self.identifier = identifier.parse()

        super.init(frame: .zero)

        if case .invariant = self.identifier {
            currentRenderState = .error
        }

        setupButton()
        checkAvailability()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented. Use factory methods like AcceleratedCheckoutButton.applePay(cartID:)")
    }

    // MARK: - Setup

    private func setupButton() {
        // Create the underlying button
        button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)

        addSubview(button)

        // Pin button to fill the view
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: topAnchor),
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        setupButtonForWallet()
        updateButtonAppearance()

        // Force the AcceleratedCheckoutButton container to have 48pt height
        // Do this after wallet setup to ensure it applies correctly
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 48)
        ])

        // Call this to ensure the constraint takes effect
        invalidateIntrinsicContentSize()
    }

    private func setupButtonForWallet() {
        switch wallet {
        case .applePay:
            setupApplePayButton()
        case .shopPay:
            setupShopPayButton()
        }
    }

    private func setupApplePayButton() {
        // Use SwiftUI's PayWithApplePayButton embedded in UIHostingController
        button.removeFromSuperview()

        // Create SwiftUI view that matches the working SwiftUI implementation
        let swiftUIButton = PayWithApplePayButton(.plain) {
            // Trigger the button tap action
            self.buttonTapped()
        }
        .frame(height: 48)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: CGFloat(cornerRadius)))

        // Embed in UIHostingController
        let hostingController = UIHostingController(rootView: swiftUIButton)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear

        addSubview(hostingController.view)

        // Create a dummy button for the button property (needed for state management)
        let dummyButton = UIButton()
        button = dummyButton

        // Pin hosting controller view to fill the AcceleratedCheckoutButton
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func setupShopPayButton() {
        // Configure Shop Pay button appearance with logo
        button.backgroundColor = Theme.shopPayButtonColor
        button.setTitle("", for: .normal)

        // Use the Shop Pay logo image from the bundle
        if let shopPayImage = UIImage(named: "shop-pay-logo", in: .module, compatibleWith: nil) {
            // Resize the image to fit properly in the button (similar to SwiftUI version height: 24)
            let targetSize = CGSize(width: shopPayImage.size.width * (24.0 / shopPayImage.size.height), height: 24)
            let resizedImage = shopPayImage.resized(to: targetSize)

            button.setImage(resizedImage, for: .normal)
            button.imageView?.contentMode = .scaleAspectFit
            button.imageView?.tintColor = nil // Don't tint the logo, use original colors

            // Center the image in the button
            button.imageEdgeInsets = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        } else {
            // Fallback to text if image is not available
            button.setTitle("Shop Pay", for: .normal)
            button.setTitleColor(Theme.shopPayButtonTextColor, for: .normal)
            button.titleLabel?.font = Theme.shopPayButtonTextFont
        }
    }

    private func updateButtonAppearance() {
        // Apply corner radius based on button type
        if button is PKPaymentButton {
            // For PKPaymentButton, apply corner radius to its container
            button.superview?.layer.cornerRadius = cornerRadius
        } else {
            // For regular buttons, apply directly
            button.layer.cornerRadius = cornerRadius
        }
        button.alpha = isUserInteractionEnabled ? 1.0 : 0.6
    }

    private func updateButtonState() {
        switch currentRenderState {
        case .loading:
            button.isEnabled = false
            button.alpha = 0.6
        case .rendered:
            button.isEnabled = true
            button.alpha = isUserInteractionEnabled ? 1.0 : 0.6
        case .error:
            button.isEnabled = false
            button.alpha = 0.3
        }
    }

    // MARK: - Availability Check

    private func checkAvailability() {
        guard AcceleratedCheckoutViewController.canPresent(wallet: wallet) else {
            currentRenderState = .error
            return
        }

        guard identifier.isValid() else {
            currentRenderState = .error
            return
        }

        // For now, assume it's always available after basic checks
        // In a real implementation, you might want to check shop settings
        currentRenderState = .rendered
    }

    // MARK: - Button Action

    @objc private func buttonTapped() {
        guard currentRenderState == .rendered else { return }

        // Find the presenting view controller
        guard let presentingViewController = findViewController() else {
            let error = CheckoutError.checkoutUnavailable(
                message: "Unable to find presenting view controller",
                code: .clientError(code: .unknown),
                recoverable: false
            )
            delegate?.checkoutDidFail(error: error)
            return
        }

        // Create and present the checkout
        presentCheckout(from: presentingViewController)
    }

    private func presentCheckout(from viewController: UIViewController) {
        guard let configuration = ShopifyAcceleratedCheckouts.currentConfiguration else { return }

        let presentingVC = presentationDelegate as? UIViewController ?? viewController

        // Create common event handlers
        let eventHandlers = EventHandlers(
            checkoutDidComplete: { [weak self] event in
                self?.delegate?.checkoutDidComplete(event: event)
            },
            checkoutDidFail: { [weak self] error in
                self?.delegate?.checkoutDidFail(error: error)
            },
            checkoutDidCancel: { [weak self] in
                presentingVC.dismiss(animated: true)
                self?.delegate?.checkoutDidCancel()
            },
            shouldRecoverFromError: { [weak self] error in
                return self?.delegate?.shouldRecoverFromError(error: error) ?? false
            },
            checkoutDidClickLink: { [weak self] url in
                self?.delegate?.checkoutDidClickLink(url: url)
            },
            checkoutDidEmitWebPixelEvent: { [weak self] event in
                self?.delegate?.checkoutDidEmitWebPixelEvent(event: event)
            }
        )

        // Present both wallets directly to avoid visual glitches
        switch wallet {
        case .shopPay:
            let shopPayViewController = ShopPayViewController(
                identifier: identifier,
                configuration: configuration,
                eventHandlers: eventHandlers
            )

            Task {
                do {
                    try await shopPayViewController.present(from: presentingVC)
                } catch {
                    await MainActor.run {
                        let checkoutError = CheckoutError.checkoutUnavailable(
                            message: error.localizedDescription,
                            code: .httpError(statusCode: 500),
                            recoverable: false
                        )
                        self.delegate?.checkoutDidFail(error: checkoutError)
                    }
                }
            }

        case .applePay:
            presentApplePayDirectly(from: presentingVC, configuration: configuration, eventHandlers: eventHandlers)
        }
    }

    private func presentApplePayDirectly(from _: UIViewController, configuration: ShopifyAcceleratedCheckouts.Configuration, eventHandlers: EventHandlers) {
        Task {
            do {
                // Get shop settings for Apple Pay configuration
                let storefront = StorefrontAPI(
                    storefrontDomain: configuration.storefrontDomain,
                    storefrontAccessToken: configuration.storefrontAccessToken
                )
                let shop = try await storefront.shop()
                let shopSettings = ShopSettings(from: shop)

                let applePayConfiguration = ShopifyAcceleratedCheckouts.ApplePayConfiguration(
                    merchantIdentifier: "merchant.com.shopify.accelerated-checkout",
                    contactFields: [.email]
                )

                let applePayConfig = ApplePayConfigurationWrapper(
                    common: configuration,
                    applePay: applePayConfiguration,
                    shopSettings: shopSettings
                )

                let controller = await MainActor.run {
                    let controller = ApplePayViewController(
                        identifier: self.identifier,
                        configuration: applePayConfig
                    )

                    // Bridge Apple Pay callbacks using reusable event handlers
                    controller.onCheckoutComplete = eventHandlers.checkoutDidComplete
                    controller.onCheckoutFail = eventHandlers.checkoutDidFail
                    controller.onCheckoutCancel = eventHandlers.checkoutDidCancel
                    controller.onShouldRecoverFromError = eventHandlers.shouldRecoverFromError
                    controller.onCheckoutClickLink = eventHandlers.checkoutDidClickLink
                    controller.onCheckoutWebPixelEvent = eventHandlers.checkoutDidEmitWebPixelEvent

                    return controller
                }

                await controller.startPayment()
            } catch {
                await MainActor.run {
                    let checkoutError = CheckoutError.checkoutUnavailable(
                        message: error.localizedDescription,
                        code: .httpError(statusCode: 500),
                        recoverable: false
                    )
                    self.delegate?.checkoutDidFail(error: checkoutError)
                }
            }
        }
    }

    // MARK: - Utility

    private func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while responder != nil {
            if let viewController = responder as? UIViewController {
                return viewController
            }
            responder = responder?.next
        }
        return nil
    }
}

// MARK: - Configuration

@available(iOS 17.0, *)
extension AcceleratedCheckoutButton: AcceleratedCheckoutConfigurable {
    /// Sets the corner radius for the checkout button
    /// - Parameter cornerRadius: The corner radius to apply (negative values will use default)
    /// - Returns: Self for method chaining
    public func cornerRadius(_ cornerRadius: CGFloat) -> Self {
        self.cornerRadius = cornerRadius >= 0 ? cornerRadius : Theme.acceleratedCheckoutButtonCornerRadius
        return self
    }
}

// MARK: - UIImage Extension

extension UIImage {
    fileprivate func resized(to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
