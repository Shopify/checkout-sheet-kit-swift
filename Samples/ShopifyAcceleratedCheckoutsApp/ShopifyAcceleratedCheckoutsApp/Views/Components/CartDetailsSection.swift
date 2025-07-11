//
//  CartDetailsSection.swift
//  ShopifyAcceleratedCheckoutsApp
//

import Apollo
import SwiftUI

struct CartDetailsSection: View {
    let cart: Cart

    var cartTypeTitle: String {
        let variants = cart.lines.nodes.compactMap { $0.merchandise.asProductVariant }

        let hasPhysical = variants.contains { $0.requiresShipping }
        let hasDigital = variants.contains { !$0.requiresShipping }

        if hasPhysical, hasDigital {
            return "Physical & Digital\nCart"
        }
        if hasPhysical {
            return "Physical Cart"
        }
        if hasDigital {
            return "Digital Cart"
        }

        return "Cart"
    }

    var body: some View {
        VStack(spacing: 20) {
            Text(cartTypeTitle)
                .fontWeight(.bold)
                .font(.largeTitle)
                .multilineTextAlignment(.center)
                .padding(.top)

            VStack(alignment: .leading, spacing: 12) {
                Text("Cart Contents")
                    .font(.headline)
                    .padding(.horizontal)

                ForEach(cart.lines.nodes, id: \.id) { line in
                    if let variant = line.merchandise.asProductVariant {
                        CartItemRow(line: line, variant: variant)
                            .font(.caption)
                    }
                }

                // Cart Total
                HStack {
                    Text("Total:")
                        .font(.headline)
                    Spacer()
                    Text(formatPrice(cart.cost.totalAmount))
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            }
        }
    }

    private func formatPrice(_ price: CartTotalAmount) -> String {
        PriceFormatter.format(amount: price.amount, currencyCode: price.currencyCode.rawValue)
    }
}
