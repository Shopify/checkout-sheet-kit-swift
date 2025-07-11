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
import ShopifyAcceleratedCheckouts
import SwiftUI

typealias MerchandiseID = String
typealias Quantity = Int

struct CartBuilderView: View {
    @Binding var configuration: ShopifyAcceleratedCheckouts.Configuration
    @State var cart: Cart?
    @State var allProducts: [Product] = []
    /// Products picked with the QuantityPicker, prior to Cart creation
    @State var selectedVariants: [MerchandiseID: Quantity] = [:]
    @State var isLoadingProducts: Bool = false
    @State var isCreatingCart: Bool = false
    @State private var scrollToTop = false
    @State private var scrollToCart = false

    var body: some View {
        VStack {
            ScrollView {
                ScrollViewReader { scrollProxy in
                    VStack(spacing: 20) {
                        // Invisible anchor for scrolling to top
                        Color.clear
                            .frame(height: 1)
                            .id("top")

                        // Products Section
                        ProductsSection(
                            products: allProducts,
                            selectedVariants: $selectedVariants,
                            isLoadingProducts: isLoadingProducts,
                            onRetry: { Task { await onLoad() } }
                        )
                        .id("products-section")  // Add ID for scrolling

                        if let cart {
                            CartDetailsSection(cart: cart)
                                .id("cart-details")  // Add ID for scrolling to cart

                            ButtonSet(
                                cart: cart,
                                firstVariantQuantity: cart.lines.nodes.first?.quantity ?? 1
                            )
                            .id("\(cart.id)")
                        }

                        // Bottom padding to ensure content isn't hidden behind sticky buttons
                        Spacer()
                            .frame(height: 100)
                    }
                    .onChange(of: scrollToTop) { _, shouldScroll in
                        if shouldScroll {
                            withAnimation(.easeInOut) {
                                scrollProxy.scrollTo("top", anchor: .top)
                            }
                            scrollToTop = false
                        }
                    }
                    .onChange(of: scrollToCart) { _, shouldScroll in
                        if shouldScroll {
                            withAnimation(.easeInOut) {
                                scrollProxy.scrollTo("cart-details", anchor: .top)
                            }
                            scrollToCart = false
                        }
                    }
                }
            }

            // Sticky Cart Creation Buttons
            VStack {
                Divider()
                CartCreationButtons(
                    customCart: cart,
                    selectedVariants: selectedVariants,
                    isCreatingCart: isCreatingCart,
                    isLoadingProducts: isLoadingProducts,
                    hasProducts: !allProducts.isEmpty,
                    onCreateCart: createCustomCart,
                    onClearCart: {
                        withAnimation {
                            cart = nil
                            selectedVariants.removeAll()
                        }
                        // Trigger scroll using state change
                        scrollToTop = true
                    }
                )
                .padding(.vertical, 12)
                .background(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: -2)
            }
        }
        .task {
            await onLoad()
        }
    }

    private func createCustomCart() {
        isCreatingCart = true

        Network.shared.createCart(merchandiseQuantities: selectedVariants) { cart in
            withAnimation {
                self.cart = cart
                isCreatingCart = false
                // Clear selections after creating cart
                selectedVariants.removeAll()
            }
            // Trigger scroll to cart after creation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                scrollToCart = true
            }
        }
    }

    func onLoad() async {
        // Prevent multiple simultaneous loads
        guard !isLoadingProducts else {
            print("Already loading products, skipping...")
            return
        }

        print("Starting to load products...")
        isLoadingProducts = true

        // Ensure products load regardless of any configuration issues
        defer {
            isLoadingProducts = false
        }

        await withCheckedContinuation { continuation in
            Network.shared.getProducts { products in
                DispatchQueue.main.async {
                    if let products {
                        print("Loaded \(products.nodes.count) products")
                        withAnimation {
                            allProducts = products.nodes
                        }
                    } else {
                        print("Warning: No products returned from API")
                    }
                    continuation.resume()
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var configuration = ShopifyAcceleratedCheckouts.Configuration(
        storefrontDomain: "my-shop.myshopify.com",
        storefrontAccessToken: "asdb"
    )

    CartBuilderView(configuration: $configuration)
}
