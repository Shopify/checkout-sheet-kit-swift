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
import ApolloAPI
@preconcurrency import ShopifyAcceleratedCheckouts
@preconcurrency import ShopifyCheckoutSheetKit
import SwiftUI
import UIKit

typealias Product = Storefront.GetProductsQuery.Data.Products.Node

struct ProductView: View {
    // MARK: Properties

    @State private var product: Product
    @State private var loading = false
    @State private var imageLoaded: Bool = false
    @State private var showingCart = false
    @State private var descriptionExpanded: Bool = false
    @State private var addedToCart: Bool = false

    init(product: Product) {
        _product = State(initialValue: product)
    }

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let imageURL = product.featuredImage?.url, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: UIScreen.main.bounds.width, height: 400)
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(1.2)
                                        .tint(.gray)
                                )
                        case let .success(image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: UIScreen.main.bounds.width, height: 400)
                                .clipped()
                                .opacity(imageLoaded ? 1 : 0)
                                .onAppear {
                                    withAnimation(.easeIn(duration: 0.3)) {
                                        imageLoaded = true
                                    }
                                }
                        case .failure:
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: UIScreen.main.bounds.width, height: 400)
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 48))
                                        .foregroundColor(.gray.opacity(0.6))
                                )
                        @unknown default:
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: UIScreen.main.bounds.width, height: 400)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(product.vendor)
                        .font(.body)
                        .fontWeight(.semibold)
                        .padding(.vertical)
                        .foregroundColor(Color(ColorPalette.primaryColor))

                    Text(product.title)
                        .font(.title)

                    Text(product.description)
                        .font(.body)
                        .foregroundColor(.gray)
                        .lineLimit(descriptionExpanded ? 10 : 3)
                        .onTapGesture {
                            descriptionExpanded.toggle()
                        }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                if let variant = product.variants.nodes.first {
                    VStack(spacing: DesignSystem.buttonSpacing) {
                        Button(action: addToCart) {
                            HStack {
                                Text(loading ? "Adding..." : (addedToCart ? "Added" : "Add to Cart"))
                                    .font(.headline)

                                if loading {
                                    ProgressView()
                                        .colorInvert()
                                }
                                Spacer()

                                Text(formattedVariantPrice(variant))
                            }.padding()
                        }
                        .background(addedToCart ? Color(ColorPalette.successColor) : Color(ColorPalette.primaryColor))
                        .foregroundStyle(.white)
                        .cornerRadius(DesignSystem.cornerRadius)
                        .disabled(!variant.availableForSale || loading)

                        if variant.availableForSale {
                            AcceleratedCheckoutButtons(variantID: variant.id, quantity: 1)
                                .wallets([.applePay])
                                .cornerRadius(DesignSystem.cornerRadius)
                                .onFail { error in
                                    print("Accelerated checkout failed: \(error)")
                                }
                                .onCancel {
                                    print("Accelerated checkout cancelled")
                                }
                                .environmentObject(appConfiguration.acceleratedCheckoutsStorefrontConfig)
                                .environmentObject(appConfiguration.acceleratedCheckoutsApplePayConfig)
                        }
                    }.padding([.leading, .trailing], 15)
                }
            }
        }
        .navigationTitle(product.collections.nodes.first?.title ?? product.title)
        .frame(idealWidth: 200)
    }

    // MARK: Methods

    private func formattedVariantPrice(_ variant: Product.Variants.Node) -> String {
        if !variant.availableForSale {
            return "Out of stock"
        }
        if addedToCart {
            return "✓"
        }
        return MoneyV2(amount: variant.price.amount, currencyCode: variant.price.currencyCode).formattedString() ?? ""
    }

    private func addToCart() {
        _Concurrency.Task {
            guard let variant = product.variants.nodes.first else { return }

            loading = true
            let start = Date()

            _ = try await CartManager.shared.performCartLinesAdd(variant: variant.id)

            let diff = Date().timeIntervalSince(start)
            let message = "Added item to cart in \(String(format: "%.0f", diff * 1000))ms"
            ShopifyCheckoutSheetKit.configuration.logger.log(message)
            loading = false
            addedToCart = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                addedToCart = false
            }
        }
    }

    private func setProduct(_ product: Product?) {
        if let product {
            self.product = product
        }
    }
}

@MainActor
class ProductCache: ObservableObject {
    static let shared = ProductCache()
    @Published public var cachedProduct: Product?
    @Published public var isFetching: Bool = false
    @Published public var collection: [Product]?

    func getProduct(handle: String?, completion: @escaping (Product?) -> Void) {
        if let product = cachedProduct {
            completion(product)
        } else {
            Task {
                let product = await fetchProduct(by: handle)
                self.cachedProduct = product
                completion(product)
            }
        }
    }

    private func fetchProduct(by _: String?) async -> Product? {
        let network = Network.shared

        let query = Storefront.GetProductsQuery(
            first: .some(1),
            country: network.countryCode,
            language: network.languageCode
        )

        do {
            let response = try await network.apollo.fetch(query: query)
            return response.data?.products.nodes.first
        } catch {
            return nil
        }
    }

    public func fetchCollection(limit: Int = 20) {
        Task {
            let network = Network.shared

            let query = Storefront.GetProductsQuery(
                first: .some(limit),
                country: network.countryCode,
                language: network.languageCode
            )

            do {
                let response = try await network.apollo.fetch(query: query)
                self.collection = response.data?.products.nodes
                self.cachedProduct = response.data?.products.nodes.first
            } catch {
                // Fetch failed silently
            }
        }
    }
}

struct ProductGalleryView: View {
    @StateObject private var productCache = ProductCache.shared

    var body: some View {
        TabView {
            if productCache.collection?.isEmpty ?? true {
                Text("Loading products...").padding()
            } else {
                ForEach(productCache.collection!, id: \.id) { product in
                    ProductView(product: product)
                        .onAppear {
                            ProductCache.shared.cachedProduct = product
                        }
                }
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .onAppear {
            productCache.fetchCollection()
        }
    }
}

struct ProductGalleryView_Previews: PreviewProvider {
    static var previews: some View {
        ProductGalleryView()
    }
}
