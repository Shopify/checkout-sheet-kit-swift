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
import SwiftUI

struct ButtonSet: View {
    let cart: Cart?
    let firstVariantQuantity: Int

    var body: some View {
        VStack(spacing: 16) {
            if let cartID = cart?.id {
                CheckoutSection(title: "AcceleratedCheckoutButtons(cartID:)") {
                    // Cart-based checkout example with event handlers
                    AcceleratedCheckoutButtons(cartID: cartID)
                        .onComplete {
                            print("✅ Checkout completed successfully")
                        }
                        .onFail {
                            print("❌ Checkout failed")
                        }
                        .onCancel {
                            print("🚫 Checkout cancelled")
                        }
                        .onShouldRecoverFromError { error in
                            print("🔄 Should recover from error: \(error)")
                            // Return true to attempt recovery, false to fail
                            return true
                        }
                        .onClickLink { url in
                            print("🔗 Link clicked: \(url)")
                        }
                        .onWebPixelEvent { _ in
                            print("📊 Web pixel event received")
                        }
                }
            }

            if let merchandise = cart?.lines.nodes.first?.merchandise,
               let productVariant = merchandise.asProductVariant
            {
                CheckoutSection(title: "AcceleratedCheckoutButtons(variantID: quantity:)") {
                    // Variant-based checkout with separate handlers
                    AcceleratedCheckoutButtons(
                        variantID: productVariant.id,
                        quantity: firstVariantQuantity
                    )
                    .withWallets([.applepay, .shoppay])
                    .onComplete {
                        print("✅ Variant checkout completed")
                    }
                    .onFail {
                        print("❌ Variant checkout failed")
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
                    .onWebPixelEvent { _ in
                        print("📊 Variant - Web pixel event received")
                    }
                }
            }
        }
    }
}

// MARK: - Local Components

private struct CheckoutSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        Section {
            VStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                content()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}
