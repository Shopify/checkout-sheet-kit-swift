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
