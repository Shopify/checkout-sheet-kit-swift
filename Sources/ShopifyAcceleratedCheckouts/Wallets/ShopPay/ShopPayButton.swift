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

@available(iOS 17.0, *)
internal struct ShopPayButton: View {
    @Environment(ShopifyAcceleratedCheckouts.Configuration.self)
    private var configuration: ShopifyAcceleratedCheckouts.Configuration

    let identifier: CheckoutIdentifier
    let eventHandlers: EventHandlers

    init(
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

/// Internal_ wrapper component allows `ShopifyAcceleratedCheckouts.Configuration` to be
/// DI into ShopPayViewController at init, avoiding optionality checks through ViewController
@available(iOS 17.0, *)
internal struct Internal_ShopPayButton: View {
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
                Task { try? await controller.present() }
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

@available(iOS 17.0, *)
struct ShopPayButton_Previews: PreviewProvider {
    static var previews: some View {
        let mockCommonConfiguration = ShopifyAcceleratedCheckouts.Configuration(
            storefrontDomain: "test-shop.myshopify.com",
            storefrontAccessToken: "test-token"
        )

        ShopPayButton(
            identifier: .variant(variantID: "gid://Shopify/ProductVariant/123", quantity: 1),
            eventHandlers: EventHandlers()
        )
        .padding()
        .environment(mockCommonConfiguration)
    }
}
