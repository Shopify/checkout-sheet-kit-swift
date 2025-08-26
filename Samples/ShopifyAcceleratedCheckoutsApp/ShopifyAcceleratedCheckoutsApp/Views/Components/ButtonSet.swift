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

    // Create CheckoutDelegate implementations
    private var cartCheckoutDelegate: CheckoutDelegate {
        CartCheckoutDelegate(onComplete: onComplete)
    }

    private var variantCheckoutDelegate: CheckoutDelegate {
        VariantCheckoutDelegate()
    }

    var body: some View {
        VStack(spacing: 16) {
            if let cartID = cart?.id {
                CheckoutSection(
                    title: "AcceleratedCheckoutButtons(cartID:)",
                    renderState: $cartRenderState
                ) {
                    // Cart-based checkout example with CheckoutDelegate
                    AcceleratedCheckoutButtons(cartID: cartID)
                        .applePayLabel(.plain)
                        .checkout(delegate: cartCheckoutDelegate)
                        .onRenderStateChange { state in
                            cartRenderState = state
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
                    // Variant-based checkout with CheckoutDelegate and custom corner radius
                    AcceleratedCheckoutButtons(
                        variantID: productVariant.id,
                        quantity: firstVariantQuantity
                    )
                    .applePayLabel(.buy)
                    .cornerRadius(24)
                    .wallets([.applePay, .shopPay])
                    .checkout(delegate: variantCheckoutDelegate)
                    .onRenderStateChange { state in
                        variantRenderState = state
                    }
                }
            }
        }
    }
}

// MARK: - CheckoutDelegate Implementations

/// CheckoutDelegate implementation for cart-based checkout
class CartCheckoutDelegate: CheckoutDelegate {
    private let onComplete: () -> Void

    init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }

    func checkoutDidComplete(event: CheckoutCompletedEvent) {
        print("✅ Checkout completed successfully. Order ID: \(event.orderDetails.id)")
        onComplete()
    }

    func checkoutDidFail(error: CheckoutError) {
        print("❌ Checkout failed: \(error)")
    }

    func checkoutDidCancel() {
        print("🚫 Checkout cancelled")
    }

    func shouldRecoverFromError(error: CheckoutError) -> Bool {
        print("🔄 Should recover from error: \(error)")
        // Return true to attempt recovery, false to fail
        return true
    }

    func checkoutDidClickLink(url: URL) {
        print("🔗 Link clicked: \(url)")
    }

    func checkoutDidEmitWebPixelEvent(event: PixelEvent) {
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
}

/// CheckoutDelegate implementation for variant-based checkout
class VariantCheckoutDelegate: CheckoutDelegate {
    func checkoutDidComplete(event: CheckoutCompletedEvent) {
        print("✅ Variant checkout completed")
        print("   Order ID: \(event.orderDetails.id)")
    }

    func checkoutDidFail(error: CheckoutError) {
        print("❌ Variant checkout failed: \(error)")
    }

    func checkoutDidCancel() {
        print("🚫 Variant checkout cancelled")
    }

    func shouldRecoverFromError(error: CheckoutError) -> Bool {
        print("🔄 Variant - Should recover from error: \(error)")
        return false // Example: don't recover for variant checkout
    }

    func checkoutDidClickLink(url: URL) {
        print("🔗 Variant - Link clicked: \(url)")
    }

    func checkoutDidEmitWebPixelEvent(event: PixelEvent) {
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
