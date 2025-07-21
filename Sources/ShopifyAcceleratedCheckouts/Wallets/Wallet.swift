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
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import ShopifyCheckoutSheetKit
import SwiftUI

public protocol Wallet {
    static var type: WalletType { get }
    static func isAvailable() async -> Bool
    static func unavailableReason() async -> UnavailableReason?
}

// MARK: - Render State Types

public enum RenderState {
    case loading
    case ready(availableWallets: [WalletType])
    case partiallyReady(availableWallets: [WalletType], unavailableReasons: [UnavailableReason])
    case fallback(reason: FallbackReason)
}

public enum WalletType: CaseIterable {
    case applePay
    case shopPay

    public var displayName: String {
        switch self {
        case .applePay: return "Apple Pay"
        case .shopPay: return "Shop Pay"
        }
    }
}

public enum UnavailableReason {
    case applePayNotSetUp
    case applePayNotSupported
    case applePayUnsupportedRegion
    case shopPayNotEnabled
    case shopPayUnsupportedRegion
    case unsupportedCartCurrency
    case networkUnavailable

    public var displayName: String {
        switch self {
        case .applePayNotSetUp:
            return "Apple Pay is not set up on this device"
        case .applePayNotSupported:
            return "Apple Pay is not supported on this device"
        case .applePayUnsupportedRegion:
            return "Apple Pay is not available in this region"
        case .shopPayNotEnabled:
            return "Shop Pay is not enabled for this shop"
        case .shopPayUnsupportedRegion:
            return "Shop Pay is not available in this region"
        case .unsupportedCartCurrency:
            return "Cart currency is not supported"
        case .networkUnavailable:
            return "Network connection is not available"
        }
    }

    public var wallet: WalletType? {
        switch self {
        case .applePayNotSetUp, .applePayNotSupported, .applePayUnsupportedRegion:
            return .applePay
        case .shopPayNotEnabled, .shopPayUnsupportedRegion:
            return .shopPay
        case .unsupportedCartCurrency, .networkUnavailable:
            return nil // Affects all wallets
        }
    }
}

public enum FallbackReason {
    case noWalletsAvailable
    case configurationError(Error)
    case unexpectedError(Error)

    public var displayName: String {
        switch self {
        case .noWalletsAvailable:
            return "No accelerated checkout options are available"
        case .configurationError:
            return "Configuration error occurred"
        case .unexpectedError:
            return "An unexpected error occurred"
        }
    }
}

public typealias RenderStateDidChange = (RenderState) -> Void

/// Event handlers for wallet buttons
public struct EventHandlers {
    public var checkoutDidComplete: ((CheckoutCompletedEvent) -> Void)?
    public var checkoutDidFail: ((CheckoutError) -> Void)?
    public var checkoutDidCancel: (() -> Void)?
    public var shouldRecoverFromError: ((CheckoutError) -> Bool)?
    public var checkoutDidClickLink: ((URL) -> Void)?
    public var checkoutDidEmitWebPixelEvent: ((PixelEvent) -> Void)?
    public var stateDidChange: RenderStateDidChange?

    public init(
        checkoutDidComplete: ((CheckoutCompletedEvent) -> Void)? = nil,
        checkoutDidFail: ((CheckoutError) -> Void)? = nil,
        checkoutDidCancel: (() -> Void)? = nil,
        shouldRecoverFromError: ((CheckoutError) -> Bool)? = nil,
        checkoutDidClickLink: ((URL) -> Void)? = nil,
        checkoutDidEmitWebPixelEvent: ((PixelEvent) -> Void)? = nil,
        stateDidChange: RenderStateDidChange? = nil
    ) {
        self.checkoutDidComplete = checkoutDidComplete
        self.checkoutDidFail = checkoutDidFail
        self.checkoutDidCancel = checkoutDidCancel
        self.shouldRecoverFromError = shouldRecoverFromError
        self.checkoutDidClickLink = checkoutDidClickLink
        self.checkoutDidEmitWebPixelEvent = checkoutDidEmitWebPixelEvent
        self.stateDidChange = stateDidChange
    }
}

extension View {
    func walletButtonStyle(bg: Color = Color.black, cornerRadius: CGFloat? = nil) -> some View {
        let defaultCornerRadius: CGFloat = 8
        let radius = cornerRadius ?? defaultCornerRadius
        return frame(height: 48)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: radius >= 0 ? radius : defaultCornerRadius))
    }
}

struct ContentFadeButtonStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
