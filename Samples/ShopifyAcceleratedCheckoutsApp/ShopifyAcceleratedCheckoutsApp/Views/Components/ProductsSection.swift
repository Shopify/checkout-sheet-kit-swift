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
                ForEach(products.filter {$0.availableForSale}, id: \.id) { product in
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
