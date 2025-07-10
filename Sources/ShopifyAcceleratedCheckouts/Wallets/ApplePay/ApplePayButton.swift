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
    private var label: PayWithApplePayButtonLabel = .plain

    public init(
        identifier: CheckoutIdentifier,
        eventHandlers: EventHandlers = EventHandlers()
    ) {
        self.identifier = identifier.parse()
        self.eventHandlers = eventHandlers
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
                eventHandlers: eventHandlers
            )
        }
    }

    public func withLabel(_ label: PayWithApplePayButtonLabel) -> some View {
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
    private var label: PayWithApplePayButtonLabel = .plain

    /// The view controller for the Apple Pay button
    private var controller: ApplePayViewController

    /// Initializes an Apple Pay button
    /// - Parameters:
    ///   - identifier: The identifier to use for checkout
    ///   - label: The label to display on the Apple Pay button
    ///   - configuration: The configuration for Apple Pay
    ///   - checkoutSuccessHandler: The handler to call on successful checkout
    ///   - checkoutErrorHandler: The handler to call on checkout error
    ///   - checkoutCancelHandler: The handler to call on checkout cancel
    ///   - shouldRecoverFromErrorHandler: The handler to determine error recovery
    ///   - clickLinkHandler: The handler to call when links are clicked
    ///   - webPixelEventHandler: The handler to call for web pixel events
    init(
        identifier: CheckoutIdentifier,
        label: PayWithApplePayButtonLabel,
        configuration: ApplePayConfigurationWrapper,
        eventHandlers: EventHandlers = EventHandlers()
    ) {
        controller = ApplePayViewController(
            identifier: identifier,
            configuration: configuration
        )
        controller.onComplete = eventHandlers.checkoutDidComplete
        controller.onFail = eventHandlers.checkoutDidFail
        controller.onCancel = eventHandlers.checkoutDidCancel
        controller.onShouldRecoverFromError = eventHandlers.shouldRecoverFromError
        controller.onClickLink = eventHandlers.checkoutDidClickLink
        controller.onWebPixelEvent = eventHandlers.checkoutDidEmitWebPixelEvent
        self.label = label
    }

    var body: some View {
        PayWithApplePayButton(
            label,
            action: {
                Task { await controller.startPayment() }
            },
            fallback: {
                // content == nil ? Text("errors.applepay.unsupported") : content
                Text("errors.applepay.unsupported".localizedString)
            }
        )
        .walletButtonStyle()
    }
}

// MARK: - Mock for Previews

@available(iOS 17.0, *)
let mockCommonConfiguration = ShopifyAcceleratedCheckouts.Configuration(
    storefrontDomain: "my-shop.myshopify.com",
    storefrontAccessToken: "asdb"
)

@available(iOS 17.0, *)
let mockApplePayConfiguration = ShopifyAcceleratedCheckouts.ApplePayConfiguration(
    merchantIdentifier: "merchantid",
    supportedNetworks: [.amex, .discover, .masterCard, .visa],
    contactFields: [.email, .phone]
)

@available(iOS 17.0, *)
let mockShopSettings = ShopSettings(
    name: "My Shop",
    primaryDomain: Domain(
        host: mockCommonConfiguration.storefrontDomain,
        url: "https://\(mockCommonConfiguration.storefrontDomain)"
    ),
    paymentSettings: PaymentSettings(
        countryCode: "US"
    )
)

@available(iOS 17.0, *)
let mockConfiguration = ApplePayConfigurationWrapper(
    common: mockCommonConfiguration,
    applePay: mockApplePayConfiguration,
    shopSettings: mockShopSettings
)

@available(iOS 17.0, *)
let mockLocale = Locale(identifier: "en")

@available(iOS 17.0, *)
let mockController = MockApplePayViewController(
    identifier: .cart(cartID: "gid://Shopify/Cart/12345"),
    configuration: mockConfiguration
)

@available(iOS 17.0, *)
@Observable class MockApplePayViewController: ApplePayViewController {
    override init(identifier: CheckoutIdentifier, configuration: ApplePayConfigurationWrapper) {
        super.init(identifier: identifier, configuration: configuration)
    }

    override func createOrfetchCart() async throws -> StorefrontAPI.Types.Cart {
        // Return nil for mock preview
        return StorefrontAPI.Cart(
            id: GraphQLScalars.ID("test-cart-id"),
            checkoutUrl: GraphQLScalars.URL(URL("")!),
            totalQuantity: 1,
            buyerIdentity: nil,
            deliveryGroups: StorefrontAPI.CartDeliveryGroupConnection(nodes: []),
            delivery: nil,
            lines: StorefrontAPI.BaseCartLineConnection(nodes: []),
            cost: StorefrontAPI.CartCost(
                totalAmount: StorefrontAPI.MoneyV2(amount: 0, currencyCode: "USD"),
                subtotalAmount: StorefrontAPI.MoneyV2(amount: 0, currencyCode: "USD"),
                totalTaxAmount: nil,
                totalDutyAmount: nil
            ),
            discountCodes: [],
            discountAllocations: []
        )
    }

    override func startPayment() async {
        print("Mock: startPayment called")
    }
}

@available(iOS 17.0, *)
#Preview("Plain Button") {
    ApplePayButton(
        identifier: .cart(cartID: "gid://Shopify/Cart/12345"),
        eventHandlers: EventHandlers()
    )
    .aspectRatio(contentMode: .fit)
    .environment(mockController as ApplePayViewController)
    .environment(\.locale, mockLocale)
    .environment(mockCommonConfiguration)
    .environment(mockApplePayConfiguration)
    .environment(mockShopSettings)
}

@available(iOS 17.0, *)
#Preview("Fallback Message") {
    Text("errors.applepay.unsupported".localizedString)
        .environment(\.locale, mockLocale)
}
