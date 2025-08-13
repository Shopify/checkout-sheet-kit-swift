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
@available(iOS 17.0, *)
@available(macOS, unavailable)
struct ApplePayButton: View {
    /// The configuration for Apple Pay
    @Environment(ShopifyAcceleratedCheckouts.Configuration.self)
    private var configuration

    /// The shop settings
    @Environment(ShopSettings.self)
    private var shopSettings

    @Environment(ShopifyAcceleratedCheckouts.ApplePayConfiguration.self)
    private var applePayConfiguration

    /// The identifier to use for checkout
    private let identifier: CheckoutIdentifier

    /// The event handlers for checkout events
    private let eventHandlers: EventHandlers

    /// The Apple Pay button label style
    private var label: ApplePayButtonLabel = .plain

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
                    common: configuration, applePay: applePayConfiguration,
                    shopSettings: shopSettings
                ),
                eventHandlers: eventHandlers,
                cornerRadius: cornerRadius
            )
        }
    }

    public func label(_ label: ApplePayButtonLabel) -> some View {
        var view = self
        view.label = label
        return view
    }
}

/// A view that displays an Apple Pay button for checkout
/// This is an internal view to allow Environment injection of the shared configuration app wide
@available(iOS 17.0, *)
@available(macOS, unavailable)
struct Internal_ApplePayButton: View {
    /// The Apple Pay button label style
    private var label: ApplePayButtonLabel = .plain

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
        label: ApplePayButtonLabel,
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
        MainActor.assumeIsolated {
            controller.onCheckoutComplete = eventHandlers.checkoutDidComplete
            controller.onCheckoutFail = eventHandlers.checkoutDidFail
            controller.onCheckoutCancel = eventHandlers.checkoutDidCancel
            controller.onShouldRecoverFromError = eventHandlers.shouldRecoverFromError
            controller.onCheckoutClickLink = eventHandlers.checkoutDidClickLink
            controller.onCheckoutWebPixelEvent = eventHandlers.checkoutDidEmitWebPixelEvent
        }
    }

    var body: some View {
        PayWithApplePayButton(
            label.toPayWithApplePayButtonLabel,
            action: {
                Task { await controller.startPayment() }
            },
            fallback: {
                Text("errors.applePay.unsupported".localizedString)
            }
        )
        .walletButtonStyle(cornerRadius: cornerRadius)
    }
}

/// Used to set the label of the Apple Pay button
/// see `.applePayLabel(label:)`
public enum ApplePayButtonLabel: CaseIterable {
    /// A button with the Apple Pay logo only
    case plain
    /// A button that uses the phrase "Buy with" in conjunction with the Apple Pay logo
    case buy
    /// A button that uses the phrase "Add Money with" in conjunction with the Apple Pay logo
    case addMoney
    /// A button that uses the phrase "Book with" in conjunction with the Apple Pay logo
    case book
    /// A button that uses the phrase "Check out with" in conjunction with the Apple Pay logo
    case checkout
    /// A button that uses the phrase "Continue with" in conjunction with the Apple Pay logo
    case `continue`
    /// A button that uses the phrase "Contribute with" in conjunction with the Apple Pay logo
    case contribute
    /// A button that uses the phrase "Donate with" in conjunction with the Apple Pay logo
    case donate
    /// A button that uses the phrase "Pay with" in conjunction with the Apple Pay logo
    case inStore
    /// A button that uses the phrase "Order with" in conjunction with the Apple Pay logo
    case order
    /// A button that uses the phrase "Reload with" in conjunction with the Apple Pay logo
    case reload
    /// A button that uses the phrase "Rent with" in conjunction with the Apple Pay logo
    case rent
    /// A button that prompts the user to set up Apple Pay
    case setUp
    /// A button that uses the phrase "Subscribe with" in conjunction with the Apple Pay logo
    case subscribe
    /// A button that uses the phrase "Support with" in conjunction with the Apple Pay logo
    case support
    /// A button that uses the phrase "Tip with" in conjunction with the Apple Pay logo
    case tip
    /// A button that uses the phrase "Top Up with" in conjunction with the Apple Pay logo
    case topUp

    /// SwiftUI interop - will be removed when migrating to support iOS 15
    @available(iOS 17.0, *)
    var toPayWithApplePayButtonLabel: PayWithApplePayButtonLabel {
        switch self {
        case .plain: return .plain
        case .buy: return .buy
        case .addMoney: return .addMoney
        case .book: return .book
        case .checkout: return .checkout
        case .continue: return .continue
        case .contribute: return .contribute
        case .donate: return .donate
        case .inStore: return .inStore
        case .order: return .order
        case .reload: return .reload
        case .rent: return .rent
        case .setUp: return .setUp
        case .subscribe: return .subscribe
        case .support: return .support
        case .tip: return .tip
        case .topUp: return .topUp
        }
    }

    @available(iOS 15.0, *)
    var toPKPaymentButtonType: PKPaymentButtonType {
        switch self {
        case .plain: return .plain
        case .buy: return .buy
        case .addMoney: return .addMoney
        case .book: return .book
        case .checkout: return .checkout
        case .continue: return .continue
        case .contribute: return .contribute
        case .donate: return .donate
        case .inStore: return .inStore
        case .order: return .order
        case .reload: return .reload
        case .rent: return .rent
        case .setUp: return .setUp
        case .subscribe: return .subscribe
        case .support: return .support
        case .tip: return .tip
        case .topUp: return .topUp
        }
    }
}

extension ApplePayButtonLabel {
    /// Creates a label from a string (case-insensitive, ignores non-letters). Returns nil if unknown.
    public init?(string: String) {
        let normalized = ApplePayButtonLabel.normalize(string)

        switch normalized {
        case "plain": self = .plain
        case "buy": self = .buy
        case "addmoney": self = .addMoney
        case "book": self = .book
        case "checkout": self = .checkout
        case "continue": self = .continue
        case "contribute": self = .contribute
        case "donate": self = .donate
        case "instore": self = .inStore
        case "order": self = .order
        case "reload": self = .reload
        case "rent": self = .rent
        case "setup": self = .setUp
        case "subscribe": self = .subscribe
        case "support": self = .support
        case "tip": self = .tip
        case "topup": self = .topUp
        default: return nil
        }
    }

    /// Returns a label or the provided default (defaults to `.plain`) if unknown.
    public static func from(_ string: String?, default defaultValue: ApplePayButtonLabel = .plain) -> ApplePayButtonLabel {
        guard let string, let value = ApplePayButtonLabel(string: string) else { return defaultValue }
        return value
    }

    private static func normalize(_ string: String) -> String {
        let lowered = string.lowercased()
        return lowered.replacingOccurrences(of: "[^a-z]", with: "", options: .regularExpression)
    }
}
