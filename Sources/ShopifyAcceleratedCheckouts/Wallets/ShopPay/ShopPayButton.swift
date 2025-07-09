//
//  ShopPayButton.swift
//  ShopifyAcceleratedCheckouts
//

import ShopifyCheckoutSheetKit
import SwiftUI

struct ShopPayButton: View {
    @Environment(ShopifyAcceleratedCheckouts.Configuration.self)
    private var configuration: ShopifyAcceleratedCheckouts.Configuration

    let identifier: CheckoutIdentifier
    let eventHandlers: EventHandlers

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
            Internal_ShopPayButton(
                identifier: identifier,
                configuration: configuration,
                eventHandlers: eventHandlers
            )
        }
    }
}

struct Internal_ShopPayButton: View {
    private var controller: ShopPayViewController

    init(
        identifier: CheckoutIdentifier,
        configuration: ShopifyAcceleratedCheckouts.Configuration,
        eventHandlers: EventHandlers = EventHandlers()
    ) {
        controller = ShopPayViewController(
            identifier: identifier,
            configuration: configuration,
            eventHandlers: eventHandlers
        )
    }

    var body: some View {
        Button(
            action: {
                Task { try? await controller.action() }
            },
            label: {
                HStack {
                    SwiftUI.Image("shop-pay-logo", bundle: .module)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 24)
                        .frame(maxWidth: .infinity)
                }
                .frame(height: 48)
                // This ensures that the blue background is clickable
                .background(Color.shopPayBlue)
            }
        )
        .walletButtonStyle(bg: Color.shopPayBlue)
        .buttonStyle(ContentFadeButtonStyle())
    }
}

#Preview {
    ShopPayButton(identifier: .variant(variantID: "123", quantity: 1), eventHandlers: EventHandlers())
        .padding()
        .environment(mockCommonConfiguration)
}
