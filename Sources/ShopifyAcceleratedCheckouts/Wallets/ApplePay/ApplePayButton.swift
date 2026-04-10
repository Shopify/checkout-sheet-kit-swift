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
import SwiftUI

/// A view that displays an Apple Pay button for checkout
@available(iOS 16.0, *)
@available(macOS, unavailable)
struct ApplePayButton: View {
    /// The configuration for Apple Pay
    @EnvironmentObject
    private var configuration: ShopifyAcceleratedCheckouts.Configuration

    /// The shop settings
    @EnvironmentObject
    private var shopSettings: ShopSettings

    @EnvironmentObject
    private var applePayConfiguration: ShopifyAcceleratedCheckouts.ApplePayConfiguration

    /// The identifier to use for checkout
    private let identifier: CheckoutIdentifier

    /// The event handlers for checkout events
    private let eventHandlers: EventHandlers

    /// The Apple Pay button label style
    private var label: PayWithApplePayButtonLabel = .plain

    /// The Apple Pay button style
    private var style: PayWithApplePayButtonStyle = .automatic

    /// The corner radius for the button
    private let cornerRadius: CGFloat?

    init(
        identifier: CheckoutIdentifier,
        eventHandlers: EventHandlers = EventHandlers(),
        cornerRadius: CGFloat?,
        style: PayWithApplePayButtonStyle = .automatic
    ) {
        self.identifier = identifier.parse()
        self.eventHandlers = eventHandlers
        self.cornerRadius = cornerRadius
        self.style = style
    }

    var body: some View {
        switch identifier {
        case .invariant:
            EmptyView()
        default:
            Internal_ApplePayButton(
                identifier: identifier,
                label: label,
                style: style,
                configuration: ApplePayConfigurationWrapper(
                    common: configuration,
                    applePay: applePayConfiguration,
                    shopSettings: shopSettings
                ),
                eventHandlers: eventHandlers,
                cornerRadius: cornerRadius
            )
        }
    }

    func applePayStyle(_ style: PayWithApplePayButtonStyle) -> some View {
        var view = self
        view.style = style
        return view
    }

    func label(_ label: PayWithApplePayButtonLabel) -> some View {
        var view = self
        view.label = label
        return view
    }
}

/// A view that displays an Apple Pay button for checkout
/// This is an internal view to allow Environment injection of the shared configuration app wide
@available(iOS 16.0, *)
@available(macOS, unavailable)
struct Internal_ApplePayButton: View {
    private let label: PayWithApplePayButtonLabel
    private let style: PayWithApplePayButtonStyle
    private let controller: ApplePayViewController
    private let cornerRadius: CGFloat?
    @Environment(\.colorScheme) private var colorScheme

    init(
        identifier: CheckoutIdentifier,
        label: PayWithApplePayButtonLabel,
        style: PayWithApplePayButtonStyle,
        configuration: ApplePayConfigurationWrapper,
        eventHandlers: EventHandlers = EventHandlers(),
        cornerRadius: CGFloat?
    ) {
        controller = ApplePayViewController(
            identifier: identifier,
            configuration: configuration
        )
        self.label = label
        self.style = style
        self.cornerRadius = cornerRadius
        controller.onCheckoutComplete = eventHandlers.checkoutDidComplete
        controller.onCheckoutFail = eventHandlers.checkoutDidFail
        controller.onCheckoutCancel = eventHandlers.checkoutDidCancel
        controller.onShouldRecoverFromError = eventHandlers.shouldRecoverFromError
        controller.onCheckoutClickLink = eventHandlers.checkoutDidClickLink
        controller.onCheckoutWebPixelEvent = eventHandlers.checkoutDidEmitWebPixelEvent
    }

    var body: some View {
        if PKPaymentAuthorizationController.canMakePayments() {
            ApplePayButtonRepresentable(
                buttonType: label.pkPaymentButtonType,
                buttonStyle: style.pkPaymentButtonStyle,
                cornerRadius: cornerRadius ?? 8,
                action: { Task { await controller.onPress() } }
            )
            .id("\(colorScheme)-\(style.pkPaymentButtonStyle.rawValue)")
            .frame(height: 48)
        } else {
            Text("errors.applePay.unsupported".localizedString)
        }
    }
}

// MARK: - Type Conversions

@available(iOS 16.0, *)
extension PayWithApplePayButtonStyle {
    var pkPaymentButtonStyle: PKPaymentButtonStyle {
        switch self {
        case .black: .black
        case .white: .white
        case .whiteOutline: .whiteOutline
        case .automatic: .automatic
        default: .automatic
        }
    }
}

@available(iOS 16.0, *)
extension PayWithApplePayButtonLabel {
    var pkPaymentButtonType: PKPaymentButtonType {
        switch self {
        case .buy: .buy
        case .setUp: .setUp
        case .inStore: .inStore
        case .donate: .donate
        case .checkout: .checkout
        case .book: .book
        case .subscribe: .subscribe
        case .reload: .reload
        case .addMoney: .addMoney
        case .topUp: .topUp
        case .order: .order
        case .rent: .rent
        case .support: .support
        case .contribute: .contribute
        case .tip: .tip
        default: .plain
        }
    }
}
