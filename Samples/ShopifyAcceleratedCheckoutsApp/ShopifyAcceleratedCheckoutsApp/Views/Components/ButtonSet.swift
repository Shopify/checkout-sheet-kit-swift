//
//  ButtonSet.swift
//  ShopifyAcceleratedCheckoutsApp
//

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
