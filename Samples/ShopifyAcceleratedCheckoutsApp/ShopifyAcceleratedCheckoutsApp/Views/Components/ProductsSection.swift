//
//  ProductsSection.swift
//  ShopifyAcceleratedCheckoutsApp
//

import Apollo
import SwiftUI

struct ProductsSection: View {
    let products: [Product]
    @Binding var selectedVariants: [String: Int]
    let isLoadingProducts: Bool
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Products")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)

            if isLoadingProducts {
                LoadingProducts()
            } else if products.isEmpty {
                EmptyProducts(onRetry: onRetry)
            } else {
                ForEach(products, id: \.id) { product in
                    ForEach(product.variants.nodes, id: \.id) { variant in
                        ProductRow(
                            product: product,
                            variant: variant,
                            quantity: selectedVariants[variant.id] ?? 0,
                            onQuantityChange: { newQuantity in
                                if newQuantity > 0 {
                                    selectedVariants[variant.id] = newQuantity
                                } else {
                                    selectedVariants.removeValue(forKey: variant.id)
                                }
                            }
                        )
                        .animation(
                            .standard,
                            value: selectedVariants[variant.id] ?? 0
                        )
                    }
                }
            }
        }
    }
}
