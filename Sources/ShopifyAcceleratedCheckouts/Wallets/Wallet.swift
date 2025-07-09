//
//  Wallet.swift
//  ShopifyAcceleratedCheckouts
//
//  Created by Kieran Barrie Osgood on 01/07/2025.
//

import ShopifyCheckoutSheetKit
import SwiftUI

/// Possible Wallets `AcceleratedCheckouts` can render via the `.withWallets` modifier.
public enum Wallet {
    case applepay
    case shoppay
}

/// Event handlers for wallet buttons
public struct EventHandlers {
    public var checkoutSuccessHandler: (() -> Void)?
    public var checkoutErrorHandler: (() -> Void)?
    public var checkoutCancelHandler: (() -> Void)?
    public var shouldRecoverFromErrorHandler: ((ShopifyCheckoutSheetKit.CheckoutError) -> Bool)?
    public var clickLinkHandler: ((URL) -> Void)?
    public var webPixelEventHandler: ((ShopifyCheckoutSheetKit.PixelEvent) -> Void)?

    public init(
        checkoutSuccessHandler: (() -> Void)? = nil,
        checkoutErrorHandler: (() -> Void)? = nil,
        checkoutCancelHandler: (() -> Void)? = nil,
        shouldRecoverFromErrorHandler: ((ShopifyCheckoutSheetKit.CheckoutError) -> Bool)? = nil,
        clickLinkHandler: ((URL) -> Void)? = nil,
        webPixelEventHandler: ((ShopifyCheckoutSheetKit.PixelEvent) -> Void)? = nil
    ) {
        self.checkoutSuccessHandler = checkoutSuccessHandler
        self.checkoutErrorHandler = checkoutErrorHandler
        self.checkoutCancelHandler = checkoutCancelHandler
        self.shouldRecoverFromErrorHandler = shouldRecoverFromErrorHandler
        self.clickLinkHandler = clickLinkHandler
        self.webPixelEventHandler = webPixelEventHandler
    }
}

extension View {
    func walletButtonStyle(bg: Color = Color.black) -> some View {
        frame(height: 48)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ContentFadeButtonStyle: ButtonStyle {
    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
