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
import UIKit



/// A view that displays an Apple Pay button for checkout
@available(iOS 15.0, *)
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
    private var label: PKPaymentButtonType = .plain

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

    public func label(_ label: PKPaymentButtonType) -> some View {
        var view = self
        view.label = label
        return view
    }
}

/// A view that displays an Apple Pay button for checkout
/// This is an internal view to allow Environment injection of the shared configuration app wide
@available(iOS 15.0, *)
@available(macOS, unavailable)
struct Internal_ApplePayButton: View {
    /// The Apple Pay button label style
    private var label: PKPaymentButtonType = .plain

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
        label: PKPaymentButtonType,
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
        ApplePayButtonRepresentable(
            buttonType: label,
            buttonStyle: .black,
            action: {
                Task { await controller.startPayment() }
            }
        )
        .walletButtonStyle(cornerRadius: cornerRadius)
    }

}

/// UIViewRepresentable wrapper for PKPaymentButton to support iOS 15
@available(iOS 15.0, *)
struct ApplePayButtonRepresentable: UIViewRepresentable {
    let buttonType: PKPaymentButtonType
    let buttonStyle: PKPaymentButtonStyle
    let action: () -> Void

    typealias UIViewType = PKPaymentButton

    func makeUIView(context: UIViewRepresentableContext<ApplePayButtonRepresentable>)
        -> PKPaymentButton
    {
        let button = PKPaymentButton(paymentButtonType: buttonType, paymentButtonStyle: buttonStyle)
        button.addTarget(
            context.coordinator, action: #selector(Coordinator.buttonTapped), for: .touchUpInside)
        return button
    }

    func updateUIView(
        _: PKPaymentButton,
        context: UIViewRepresentableContext<ApplePayButtonRepresentable>
    ) {
        context.coordinator.action = action
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    class Coordinator: NSObject {
        var action: () -> Void

        init(action: @escaping () -> Void) {
            self.action = action
        }

        @objc func buttonTapped() {
            action()
        }
    }
}

/// iOS 15 compatibility label
@available(iOS 15.0, *)
public enum ApplePayButtonLabel: CaseIterable {
    case plain
    case buy
    case setUp
    case inStore
    case donate
    case checkout
    case book
    case subscribe
    case reload
    case addMoney
    case topUp
    case order
    case rent
    case support
    case contribute
    case tip
    
    func toPKPaymentButtonType() -> PKPaymentButtonType {
        switch self {
        case .plain: return .plain
        case .buy: return .buy
        case .setUp: return .setUp
        case .inStore: return .inStore
        case .checkout: return .checkout
        case .donate: return .donate
        case .reload: return .reload
        case .addMoney: return .addMoney
        case .topUp: return .topUp
        case .order: return .order
        case .book: return .book
        case .subscribe: return .subscribe
        case .rent: return .rent
        case .support: return .support
        case .contribute: return .contribute
        case .tip: return .tip
        default: return .plain
        }
    }
}
