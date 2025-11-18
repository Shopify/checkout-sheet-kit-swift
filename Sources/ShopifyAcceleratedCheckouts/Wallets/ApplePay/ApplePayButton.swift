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

    /// The corner radius for the button
    private let cornerRadius: CGFloat?

    public init(
        identifier: CheckoutIdentifier,
        eventHandlers: EventHandlers = EventHandlers(),
        cornerRadius: CGFloat?
    ) {
        self.identifier = identifier.parse()
        self.eventHandlers = eventHandlers
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        switch identifier {
        case .invariant:
            EmptyView()
        default:
            Internal_ApplePayButton(
                identifier: identifier,
                label: label,
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

    public func label(_ label: PayWithApplePayButtonLabel) -> some View {
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
    /// The Apple Pay button label style
    private var label: PayWithApplePayButtonLabel = .plain

    /// The view controller for the Apple Pay button
    private var controller: ApplePayViewController

    /// The corner radius for the button
    private let cornerRadius: CGFloat?

    /// Initializes an Apple Pay button
    /// - Parameters:
    ///   - identifier: The identifier to use for checkout
    ///   - label: The label to display on the Apple Pay button
    ///   - configuration: The configuration for Apple Pay
    ///   - eventHandlers: The event handlers for checkout events (defaults to EventHandlers())
    init(
        identifier: CheckoutIdentifier,
        label: PayWithApplePayButtonLabel,
        configuration: ApplePayConfigurationWrapper,
        eventHandlers: EventHandlers = EventHandlers(),
        cornerRadius: CGFloat?
    ) {
        controller = ApplePayViewController(
            identifier: identifier,
            configuration: configuration
        )
        self.label = label
        self.cornerRadius = cornerRadius
        Task { @MainActor [controller] in
            controller.onCheckoutComplete = eventHandlers.checkoutDidComplete
            controller.onCheckoutFail = eventHandlers.checkoutDidFail
            controller.onCheckoutCancel = eventHandlers.checkoutDidCancel
            controller.onShouldRecoverFromError = eventHandlers.shouldRecoverFromError
            controller.onCheckoutClickLink = eventHandlers.checkoutDidClickLink
        }
    }

    var body: some View {
        PayWithApplePayButton(
            label,
            action: {
                Task { await controller.onPress() }
            },
            fallback: {
                Text("errors.applePay.unsupported".localizedString)
            }
        )
        .walletButtonStyle(cornerRadius: cornerRadius)
    }
}
