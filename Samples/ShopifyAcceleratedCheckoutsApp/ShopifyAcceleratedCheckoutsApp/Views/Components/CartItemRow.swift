//
//  CartItemRow.swift
//  ShopifyAcceleratedCheckoutsApp
//

import Apollo
import Foundation
import SwiftUI

struct CartItemRow: View {
    let line: CartLine
    let variant: CartProductVariant

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Product Image
            ProductImage(imageUrl: variant.image?.url, size: 60)

            VStack(alignment: .leading, spacing: 4) {
                Text(variant.product.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                VariantTitle(title: variant.title)

                ProductTypeLabel(requiresShipping: variant.requiresShipping)

                Text("Qty: \(line.quantity)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(formatLinePrice(line.cost.totalAmount))
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let unitPriceAmount = Decimal(string: variant.price.amount), unitPriceAmount > 0 {
                    Text("(\(formatUnitPrice(variant.price)) each)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal)
    }

    private func formatLinePrice(_ price: CartLineTotalAmount) -> String {
        PriceFormatter.format(amount: price.amount, currencyCode: price.currencyCode.rawValue)
    }

    private func formatUnitPrice(_ price: CartProductPrice)
        -> String
    {
        PriceFormatter.format(amount: price.amount, currencyCode: price.currencyCode.rawValue)
    }
}
