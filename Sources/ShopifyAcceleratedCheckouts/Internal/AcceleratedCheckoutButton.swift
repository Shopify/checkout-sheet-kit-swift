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

import PassKit
import UIKit
import ShopifyCheckoutSheetKit
import Common

/// A button component that renders wallet-specific checkout buttons and handles checkout presentation.
/// This is the main public API that merchants should use for programmatic accelerated checkouts.
@available(iOS 17.0, *)
public class AcceleratedCheckoutButton: UIView {

    // MARK: - Public Properties

    public weak var delegate: AcceleratedCheckoutDelegate?

    public var cornerRadius: CGFloat = Theme.acceleratedCheckoutButtonCornerRadius {
        didSet {
            updateButtonAppearance()
        }
    }

    public override var isUserInteractionEnabled: Bool {
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

    required init?(coder: NSCoder) {
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
            button.bottomAnchor.constraint(equalTo: bottomAnchor),
            button.heightAnchor.constraint(equalToConstant: 48)
        ])

        setupButtonForWallet()
        updateButtonAppearance()
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
        // Configure Apple Pay button appearance
        button.setTitle("", for: .normal)
        button.backgroundColor = Theme.applePayButtonColor

        // Add Apple Pay logo/text if needed
        if let applePayImage = createApplePayButtonImage() {
            button.setImage(applePayImage, for: .normal)
            button.imageView?.contentMode = .scaleAspectFit
            button.imageView?.tintColor = Theme.applePayButtonTextColor
        } else {
            button.setTitle("Apple Pay", for: .normal)
            button.setTitleColor(Theme.applePayButtonTextColor, for: .normal)
            button.titleLabel?.font = Theme.applePayButtonTextFont
        }
    }

    private func setupShopPayButton() {
        // Configure Shop Pay button appearance
        button.backgroundColor = Theme.shopPayButtonColor
        button.setTitle("Shop Pay", for: .normal)
        button.setTitleColor(Theme.shopPayButtonTextColor, for: .normal)
        button.titleLabel?.font = Theme.shopPayButtonTextFont
    }

    private func createApplePayButtonImage() -> UIImage? {
        // Create a simple Apple Pay text image - in a real implementation,
        // you might want to use the official Apple Pay button assets
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 30))
        return renderer.image { context in
            let text = "Apple Pay"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .medium),
                .foregroundColor: UIColor.white
            ]
            let attributedText = NSAttributedString(string: text, attributes: attributes)
            let textSize = attributedText.size()
            let textRect = CGRect(
                x: (100 - textSize.width) / 2,
                y: (30 - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            attributedText.draw(in: textRect)
        }
    }

    private func updateButtonAppearance() {
        button.layer.cornerRadius = Theme.acceleratedCheckoutButtonCornerRadius
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
                underlyingError: nil
            )
            delegate?.checkoutDidFail(error: error)
            return
        }

        // Create and present the checkout
        presentCheckout(from: presentingViewController)
    }

    private func presentCheckout(from viewController: UIViewController) {
        let checkoutController: AcceleratedCheckoutViewController

        switch identifier {
        case let .cart(cartID):
            checkoutController = AcceleratedCheckoutViewController(
                wallet: wallet,
                cartID: cartID,
                delegate: delegate
            )
        case let .variant(variantID, quantity):
            checkoutController = AcceleratedCheckoutViewController(
                wallet: wallet,
                variantID: variantID,
                quantity: quantity,
                delegate: delegate
            )
        case .invariant:
            let error = CheckoutError.checkoutUnavailable(
                message: "Invalid checkout identifier",
                underlyingError: nil
            )
            delegate?.checkoutDidFail(error: error)
            return
        }

        viewController.present(checkoutController, animated: true)
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
