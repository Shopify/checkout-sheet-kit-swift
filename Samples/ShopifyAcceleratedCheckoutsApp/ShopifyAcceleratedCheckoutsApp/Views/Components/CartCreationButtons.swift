//
//  CartCreationButtons.swift
//  ShopifyAcceleratedCheckoutsApp
//

import Apollo
import SwiftUI

struct CartCreationButtons: View {
    let customCart: Cart?
    let selectedVariants: [String: Int]
    let isCreatingCart: Bool
    let isLoadingProducts: Bool
    let hasProducts: Bool
    let onCreateCart: () -> Void
    let onClearCart: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                if customCart != nil {
                    Button(action: onClearCart) {
                        Label("Clear Cart", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.red, lineWidth: 1)
                            )
                    }
                }

                Button(action: onCreateCart) {
                    HStack {
                        if isCreatingCart {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "cart.fill")
                        }
                        Text(isCreatingCart ? "" : "Create Cart")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        isCreatingCart
                            ? Color.accentColor.opacity(0.8)
                            : (selectedVariants.isEmpty
                                ? Color.gray.opacity(0.3) : Color.accentColor)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .opacity(selectedVariants.isEmpty && !isCreatingCart ? 0.6 : 1.0)
                }
                .disabled(isCreatingCart || selectedVariants.isEmpty)
            }
            .padding(.horizontal)

            if selectedVariants.isEmpty, !isLoadingProducts, hasProducts {
                Text(
                    customCart != nil
                        ? "Select products to create a new cart"
                        : "Select products to create a cart"
                )
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            }
        }
    }
}
