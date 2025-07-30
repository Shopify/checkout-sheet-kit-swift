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

@preconcurrency import Buy
import SwiftUI

struct ProductGridView: View {
    @StateObject private var productCache = ProductCache.shared
    @State private var selectedProduct: Storefront.Product?
    @State private var showProductSheet = false

    let columns = [
        GridItem(.fixed(UIScreen.main.bounds.width / 2 - 10)),
        GridItem(.fixed(UIScreen.main.bounds.width / 2 - 10))
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                if let products = productCache.collection, !products.isEmpty {
                    ForEach(products, id: \.id) { product in
                        ProductGridItem(product: product)
                            .onTapGesture {
                                selectProductAndShowSheet(for: product)
                            }
                    }
                } else {
                    Text("Loading products...")
                        .padding()
                }
            }
            .padding(.horizontal, 5)
            .padding(.top, 10)
        }
        .onAppear {
            if productCache.collection == nil {
                productCache.fetchCollection()
            }
        }
        .sheet(isPresented: $showProductSheet) {
            ProductSheetView(product: $selectedProduct, isPresented: $showProductSheet)
        }
    }

    private func selectProductAndShowSheet(for product: Storefront.Product) {
        selectedProduct = product
        if selectedProduct != nil {
            showProductSheet = true
        }
    }
}

struct ProductSheetView: View {
    @Binding var product: Storefront.Product?
    @Binding var isPresented: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let product {
                ProductView(product: product)
            }

            Button(action: {
                isPresented = false
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14))
                    .padding()
                    .foregroundStyle(.white)
            }
            .padding([.top, .trailing], 16)
        }
        .edgesIgnoringSafeArea(.top)
    }
}

struct ProductGridItem: View {
    let product: Storefront.Product
    let maxWidth = UIScreen.main.bounds.width / 2 - 20

    var body: some View {
        VStack {
            ZStack {
                if let imageURL = product.featuredImage?.url {
                    AsyncImage(url: thumbnailURL(from: imageURL)) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.gray)
                                )
                        case let .success(image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 32))
                                        .foregroundColor(.gray.opacity(0.6))
                                )
                        @unknown default:
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                        }
                    }
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .overlay(
                            Image(systemName: "photo.badge.exclamationmark")
                                .font(.system(size: 40))
                                .foregroundStyle(.gray.opacity(0.6))
                        )
                }
            }
            .frame(maxWidth: maxWidth)
            .frame(height: 180)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            .clipped()

            VStack(spacing: 4) {
                Text(product.title)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)

                if let price = product.variants.nodes.first?.price {
                    Text(price.formattedString()!)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .frame(alignment: .leading)
            .padding(.bottom, 16)
        }
    }

    // Generate thumbnail URL for faster loading in grid view
    private func thumbnailURL(from originalURL: URL) -> URL {
        let urlString = originalURL.absoluteString

        // Shopify image transformation: add size parameters for thumbnail
        // Target size: 300x300 (2x the display size for retina screens)
        if urlString.contains("cdn.shopify.com") || urlString.contains("shopify.com") {
            // Insert size parameters before file extension
            if let lastDotIndex = urlString.lastIndex(of: ".") {
                let baseURL = String(urlString[..<lastDotIndex])
                let fileExtension = String(urlString[lastDotIndex...])
                let thumbnailURLString = "\(baseURL)_300x300\(fileExtension)"
                return URL(string: thumbnailURLString) ?? originalURL
            }
        }

        // Fallback to original URL if transformation fails
        return originalURL
    }
}

struct ProductGrid_Previews: PreviewProvider {
    static var previews: some View {
        ProductGridView()
    }
}
