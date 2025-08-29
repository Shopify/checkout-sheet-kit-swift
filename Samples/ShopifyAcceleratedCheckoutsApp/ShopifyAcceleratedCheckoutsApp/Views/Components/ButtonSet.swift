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

import Apollo
import ShopifyAcceleratedCheckouts
import ShopifyCheckoutSheetKit
import SwiftUI

struct ButtonSet: View {
    @Binding var cart: Cart?
    let firstVariantQuantity: Int
    let onComplete: () -> Void

    @State private var cartRenderState: RenderState = .loading
    @State private var variantRenderState: RenderState = .loading

    var body: some View {
        VStack(spacing: 16) {
            if let cartID = cart?.id {
                CheckoutSection(
                    title: "AcceleratedCheckoutButtons(cartID:)",
                    renderState: $cartRenderState
                ) {
                    // Cart-based checkout example with event handlers
                    AcceleratedCheckoutButtons(cartID: cartID)
                        .applePayLabel(.plain)
                        .onComplete { event in
                            print(
                                "✅ Checkout completed successfully. Order ID: \(event.orderDetails.id)"
                            )
                            onComplete()
                        }
                        .onFail { error in
                            print("❌ Checkout failed: \(error)")
                        }
                        .onCancel {
                            print("🚫 Checkout cancelled")
                        }
                        .onClickLink { url in
                            print("🔗 Link clicked: \(url)")
                        }
                        .onWebPixelEvent { event in
                            let eventName: String = {
                                switch event {
                                case let .customEvent(customEvent):
                                    return customEvent.name ?? "Unknown custom event"
                                case let .standardEvent(standardEvent):
                                    return standardEvent.name ?? "Unknown standard event"
                                }
                            }()
                            print("📊 Web pixel event: \(eventName)")
                        }
                        .onRenderStateChange {
                            cartRenderState = $0
                        }
                }
            }

            if let merchandise = cart?.lines.nodes.first?.merchandise,
               let productVariant = merchandise.asProductVariant
            {
                CheckoutSection(
                    title: "AcceleratedCheckoutButtons(variantID: quantity:)",
                    renderState: $variantRenderState
                ) {
                    // Variant-based checkout with separate handlers and custom corner radius
                    AcceleratedCheckoutButtons(
                        variantID: productVariant.id,
                        quantity: firstVariantQuantity
                    )
                    .applePayLabel(.buy)
                    .cornerRadius(24)
                    .wallets([.applePay, .shopPay])
                    .onComplete { event in
                        print("✅ Variant checkout completed")
                        print("   Order ID: \(event.orderDetails.id)")
                    }
                    .onFail { error in
                        print("❌ Variant checkout failed: \(error)")
                    }
                    .onCancel {
                        print("🚫 Variant checkout cancelled")
                    }
                    .onShouldRecoverFromError { error in
                        print("🔄 Variant - Should recover from error: \(error)")
                        return false // Example: don't recover for variant checkout
                    }
                    .onClickLink { url in
                        print("🔗 Variant - Link clicked: \(url)")
                    }
                    .onWebPixelEvent { event in
                        let eventName: String = {
                            switch event {
                            case let .customEvent(customEvent):
                                return customEvent.name ?? "Unknown custom event"
                            case let .standardEvent(standardEvent):
                                return standardEvent.name ?? "Unknown standard event"
                            }
                        }()
                        print("📊 Variant - Web pixel event: \(eventName)")
                    }
                    .onRenderStateChange {
                        variantRenderState = $0
                    }
                }
            }
        }
    }
}

// MARK: - Local Components

private struct CheckoutSection<Content: View>: View {
    let title: String
    @Binding var renderState: RenderState
    @ViewBuilder let content: () -> Content

    var body: some View {
        Section {
            VStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                if case .loading = renderState {
                    VStack(spacing: 12) {
                        SkeletonButton(cornerRadius: 8)
                        SkeletonButton(cornerRadius: 8)
                    }
                }

                if case .error = renderState {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                            .font(.title2)
                        Text("Unable to load checkout buttons")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(height: 44)
                }

                content()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}
