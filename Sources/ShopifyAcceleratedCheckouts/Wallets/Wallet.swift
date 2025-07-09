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
