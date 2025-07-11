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

struct CartDetailsSection: View {
    @Binding var cart: Cart

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
