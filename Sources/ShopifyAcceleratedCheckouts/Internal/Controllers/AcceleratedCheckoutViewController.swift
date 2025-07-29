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
import ShopifyCheckoutSheetKit
import UIKit

/// Internal view controller that manages accelerated checkout flows for different wallet types.
/// This controller coordinates between Apple Pay and Shop Pay implementations.
/// Merchants should use AcceleratedCheckoutButton instead of this class directly.
@available(iOS 17.0, *)
internal class AcceleratedCheckoutViewController: UIViewController {
    private let wallet: Wallet
    private let identifier: CheckoutIdentifier
    private let configuration: ShopifyAcceleratedCheckouts.Configuration
    private weak var delegate: AcceleratedCheckoutDelegate?
    
    private var applePayViewController: ApplePayViewController?
    private var shopPayViewController: ShopPayViewController?
    private var currentRenderState: RenderState = .loading {
        didSet {
            delegate?.renderStateDidChange(state: currentRenderState)
        }
    }
    
    /// Internal initializer for accelerated checkout view controller with a cart ID
    /// - Parameters:
    ///   - wallet: The wallet type to present (ApplePay or ShopPay)
    ///   - cartID: The cart ID to checkout (must start with gid://shopify/Cart/)
    ///   - delegate: The delegate to handle checkout events
    internal init(wallet: Wallet, cartID: String, delegate: AcceleratedCheckoutDelegate? = nil) {
        self.wallet = wallet
        self.identifier = CheckoutIdentifier.cart(cartID: cartID).parse()
        self.delegate = delegate
        
        guard let configuration = ShopifyAcceleratedCheckouts.currentConfiguration else {
            fatalError("ShopifyAcceleratedCheckouts must be configured before use. Call ShopifyAcceleratedCheckouts.configure() first.")
        }
        self.configuration = configuration
        
        super.init(nibName: nil, bundle: nil)
        
        if case .invariant = identifier {
            currentRenderState = .error
        }
    }
    
    /// Internal initializer for accelerated checkout view controller with a variant ID
    /// - Parameters:
    ///   - wallet: The wallet type to present (ApplePay or ShopPay)
    ///   - variantID: The variant ID to checkout (must start with gid://shopify/ProductVariant/)
    ///   - quantity: The quantity of the variant to checkout
    ///   - delegate: The delegate to handle checkout events
    internal init(wallet: Wallet, variantID: String, quantity: Int, delegate: AcceleratedCheckoutDelegate? = nil) {
        self.wallet = wallet
        self.identifier = CheckoutIdentifier.variant(variantID: variantID, quantity: quantity).parse()
        self.delegate = delegate
        
        guard let configuration = ShopifyAcceleratedCheckouts.currentConfiguration else {
            fatalError("ShopifyAcceleratedCheckouts must be configured before use. Call ShopifyAcceleratedCheckouts.configure() first.")
        }
        self.configuration = configuration
        
        super.init(nibName: nil, bundle: nil)
        
        if case .invariant = identifier {
            currentRenderState = .error
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    internal override func viewDidLoad() {
        super.viewDidLoad()
        setupWalletController()
    }
    
    internal override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startCheckout()
    }
    
    private func setupWalletController() {
        guard identifier.isValid() else {
            currentRenderState = .error
            return
        }
        
        currentRenderState = .loading
        
        switch wallet {
        case .applePay:
            setupApplePayController()
        case .shopPay:
            setupShopPayController()
        }
    }
    
    private func setupApplePayController() {
        Task {
            do {
                // Load shop settings first
                let storefront = StorefrontAPI(
                    storefrontDomain: configuration.storefrontDomain,
                    storefrontAccessToken: configuration.storefrontAccessToken
                )
                let shop = try await storefront.shop()
                let shopSettings = ShopSettings(from: shop)
                
                // Create Apple Pay configuration with default settings
                let applePayConfiguration = ShopifyAcceleratedCheckouts.ApplePayConfiguration(
                    merchantIdentifier: "merchant.com.shopify.accelerated-checkout", // Default, should be configurable
                    contactFields: [.email]
                )
                
                let applePayConfig = ApplePayConfigurationWrapper(
                    common: configuration,
                    applePay: applePayConfiguration,
                    shopSettings: shopSettings
                )
                
                await MainActor.run {
                    let controller = ApplePayViewController(
                        identifier: identifier,
                        configuration: applePayConfig
                    )
                    
                    // Bridge Apple Pay callbacks to our delegate
                    controller.onCheckoutComplete = { [weak self] event in
                        self?.delegate?.checkoutDidComplete(event: event)
                    }
                    
                    controller.onCheckoutFail = { [weak self] error in
                        self?.delegate?.checkoutDidFail(error: error)
                    }
                    
                    controller.onCheckoutCancel = { [weak self] in
                        self?.delegate?.checkoutDidCancel()
                    }
                    
                    controller.onShouldRecoverFromError = { [weak self] error in
                        return self?.delegate?.shouldRecoverFromError(error: error) ?? false
                    }
                    
                    controller.onCheckoutClickLink = { [weak self] url in
                        self?.delegate?.checkoutDidClickLink(url: url)
                    }
                    
                    controller.onCheckoutWebPixelEvent = { [weak self] event in
                        self?.delegate?.checkoutDidEmitWebPixelEvent(event: event)
                    }
                    
                    self.applePayViewController = controller
                    self.currentRenderState = .rendered
                }
            } catch {
                await MainActor.run {
                    self.currentRenderState = .error
                }
                print("Failed to setup Apple Pay controller: \(error)")
            }
        }
    }
    
    private func setupShopPayController() {
        let eventHandlers = EventHandlers(
            checkoutDidComplete: { [weak self] event in
                self?.delegate?.checkoutDidComplete(event: event)
            },
            checkoutDidFail: { [weak self] error in
                self?.delegate?.checkoutDidFail(error: error)
            },
            checkoutDidCancel: { [weak self] in
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
        
        let controller = ShopPayViewController(
            identifier: identifier,
            configuration: configuration,
            eventHandlers: eventHandlers
        )
        
        self.shopPayViewController = controller
        currentRenderState = .rendered
    }
    
    private func startCheckout() {
        guard currentRenderState == .rendered else { return }
        
        Task {
            do {
                switch wallet {
                case .applePay:
                    await applePayViewController?.startPayment()
                case .shopPay:
                    try await shopPayViewController?.present()
                }
            } catch {
                await MainActor.run {
                    self.currentRenderState = .error
                    if let checkoutError = error as? CheckoutError {
                        self.delegate?.checkoutDidFail(error: checkoutError)
                    } else {
                        let checkoutError = CheckoutError.checkoutUnavailable(message: error.localizedDescription, code: .httpError(statusCode: 500), recoverable: false)
                        self.delegate?.checkoutDidFail(error: checkoutError)
                    }
                }
            }
        }
    }
}

// MARK: - Static Availability Methods

@available(iOS 17.0, *)
extension AcceleratedCheckoutViewController {
    /// Internal method to check if the specified wallet is available for use
    /// - Parameter wallet: The wallet type to check
    /// - Returns: true if the wallet can be presented, false otherwise
    internal static func canPresent(wallet: Wallet) -> Bool {
        switch wallet {
        case .applePay:
            return PKPaymentAuthorizationController.canMakePayments()
        case .shopPay:
            return true // Shop Pay is always available as it falls back to web checkout
        }
    }
}
