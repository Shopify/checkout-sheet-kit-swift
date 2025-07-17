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

/// Possible Wallets `AcceleratedCheckouts` can render via the `.wallets` modifier.
public enum Wallet {
    case applePay
    case shopPay
}

/// Event handlers for wallet buttons
public struct EventHandlers {
    public var checkoutDidComplete: ((CheckoutCompletedEvent) -> Void)?
    public var checkoutDidFail: ((CheckoutError) -> Void)?
    public var checkoutDidCancel: (() -> Void)?
    public var shouldRecoverFromError: ((CheckoutError) -> Bool)?
    public var checkoutDidClickLink: ((URL) -> Void)?
    public var checkoutDidEmitWebPixelEvent: ((PixelEvent) -> Void)?
    public var walletButtonDidFailToRender: ((Wallet, String) -> Void)?

    public init(
        checkoutDidComplete: ((CheckoutCompletedEvent) -> Void)? = nil,
        checkoutDidFail: ((CheckoutError) -> Void)? = nil,
        checkoutDidCancel: (() -> Void)? = nil,
        shouldRecoverFromError: ((CheckoutError) -> Bool)? = nil,
        checkoutDidClickLink: ((URL) -> Void)? = nil,
        checkoutDidEmitWebPixelEvent: ((PixelEvent) -> Void)? = nil,
        walletButtonDidFailToRender: ((Wallet, String) -> Void)? = nil
    ) {
        self.checkoutDidComplete = checkoutDidComplete
        self.checkoutDidFail = checkoutDidFail
        self.checkoutDidCancel = checkoutDidCancel
        self.shouldRecoverFromError = shouldRecoverFromError
        self.checkoutDidClickLink = checkoutDidClickLink
        self.checkoutDidEmitWebPixelEvent = checkoutDidEmitWebPixelEvent
        self.walletButtonDidFailToRender = walletButtonDidFailToRender
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
