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
import Foundation
import SwiftUI

struct ProductRow: View {
    let product: Product
    let variant: ProductVariant
    let quantity: Int
    let onQuantityChange: (Int) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Product Image - with fallback to product featured image
            ProductImage(
                imageUrl: variant.image?.url ?? product.featuredImage?.url,
                size: 80
            )

            // Content to the right of image
            VStack(alignment: .leading, spacing: 8) {
                // Product title
                Text("\(product.title)")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Variant info and quantity in same row
                HStack(alignment: .center) {
                    ProductInfo(variant: variant)

                    Spacer()

                    QuantityControls(
                        quantity: quantity,
                        onQuantityChange: onQuantityChange
                    )
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

// MARK: - Components

struct ProductInfo: View {
    let variant: ProductVariant

    var formattedPrice: String {
        PriceFormatter.format(
            amount: variant.price.amount,
            currencyCode: variant.price.currencyCode.rawValue
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ProductTypeLabel(requiresShipping: variant.requiresShipping)
                .font(.caption)

            VariantTitle(title: variant.title)

            Text(formattedPrice)
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
}

struct QuantityControls: View {
    let quantity: Int
    let onQuantityChange: (Int) -> Void

    var body: some View {
        if quantity == 0 {
            AddButton {
                withAnimation(.quantityChange) {
                    onQuantityChange(1)
                }
            }
            .transition(.scale.combined(with: .opacity))
        } else {
            QuantityPicker(
                quantity: quantity,
                onQuantityChange: onQuantityChange
            )
            .transition(.scale.combined(with: .opacity))
        }
    }
}

struct AddButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus.circle")
                .font(.title2)
                .foregroundColor(.accentColor)
        }
    }
}

struct QuantityPicker: View {
    let quantity: Int
    let onQuantityChange: (Int) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(
                action: {
                    withAnimation(.quantityChange) {
                        onQuantityChange(quantity - 1)
                    }
                },
                label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundColor(quantity > 1 ? .accentColor : .red)
                }
            )

            Text("\(quantity)")
                .font(.body)
                .fontWeight(.semibold)
                .frame(minWidth: 24)

            Button(
                action: {
                    withAnimation(.quantityChange) {
                        onQuantityChange(quantity + 1)
                    }
                },
                label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(.accentColor)
                }
            )
            .disabled(quantity >= 99)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
}
