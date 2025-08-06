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
import PassKit
import SwiftUI

import ShopifyAcceleratedCheckouts
import ShopifyCheckoutSheetKit

// swiftlint:disable opening_brace

// Extracted cart attributes view to reduce complexity
struct CartAttributesSection: View {
    @Binding var showAttributes: Bool
    let cart: Storefront.Cart?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Toggle button
            Button(action: { showAttributes.toggle() }) {
                HStack {
                    Text("Cart Attributes")
                        .font(.headline)
                    Spacer()
                    Image(systemName: showAttributes ? "chevron.up" : "chevron.down")
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            
            if showAttributes {
                cartAttributesContent
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    var cartAttributesContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Cart note
            if let note = cart?.note {
                VStack(alignment: .leading) {
                    Text("Note:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(note)
                        .font(.footnote)
                        .padding(8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }
                .padding(.horizontal)
            }
            
            // Cart attributes
            attributesView
        }
    }
    
    @ViewBuilder
    var attributesView: some View {
        let attributes = cart?.attributes ?? []
        if !attributes.isEmpty {
            VStack(alignment: .leading) {
                Text("Attributes:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                ForEach(attributes, id: \.key) { attribute in
                    HStack {
                        Text(attribute.key)
                            .font(.footnote)
                            .fontWeight(.semibold)
                        Text(":")
                        Text(attribute.value ?? "")
                            .font(.footnote)
                        Spacer()
                    }
                    .padding(8)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(4)
                }
            }
            .padding(.horizontal)
        } else {
            Text("No cart attributes present")
                .font(.footnote)
                .foregroundColor(.orange)
                .padding(.horizontal)
        }
    }
}

struct CartView: View {
    @State var cartCompleted: Bool = false
    @State var isBusy: Bool = false
    @State var showCheckoutSheet: Bool = false
    @State var showAttributes: Bool = false

    @ObservedObject var cartManager: CartManager = .shared
    @ObservedObject var config: AppConfiguration = appConfiguration

    var body: some View {
        if let lines = cartManager.cart?.lines.nodes {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack {
                        CartLines(lines: lines, isBusy: $isBusy)
                        
                        // Cart Attributes Section (extracted to separate view)
                        CartAttributesSection(
                            showAttributes: $showAttributes,
                            cart: cartManager.cart
                        )
                    }
                    .padding(.bottom, 200)
                }

                VStack(spacing: DesignSystem.buttonSpacing) {
                    if let cartId = cartManager.cart?.id.rawValue {
                        AcceleratedCheckoutButtons(cartID: cartId)
                            .wallets([.shopPay, .applePay])
                            .cornerRadius(DesignSystem.cornerRadius)
                            .onComplete { _ in
                                // Reset cart on successful checkout
                                CartManager.shared.resetCart()
                            }
                            .onFail { error in
                                print("Accelerated checkout failed: \(error)")
                            }
                            .onCancel {
                                print("Accelerated checkout cancelled")
                            }
                            .environment(appConfiguration.acceleratedCheckoutsStorefrontConfig)
                            .environment(appConfiguration.acceleratedCheckoutsApplePayConfig)
                    }

                    Button(
                        action: { 
                            print("🛒 [CartView] Checkout button pressed")
                            if let cart = cartManager.cart {
                                print("🛒 [CartView] Cart ID: \(cart.id.rawValue)")
                                let attributes = cart.attributes
                                if !attributes.isEmpty {
                                    print("🛒 [CartView] Cart has \(attributes.count) attributes:")
                                    for attribute in attributes {
                                        print("🛒 [CartView]   - \(attribute.key): \(attribute.value)")
                                    }
                                } else {
                                    print("🛒 [CartView] ⚠️ No cart attributes present!")
                                }
                                if let note = cart.note {
                                    print("🛒 [CartView] Cart note: \(note)")
                                }
                            }
                            showCheckoutSheet = true 
                        },
                        label: {
                            HStack {
                                Text("Check out")
                                    .fontWeight(.bold)
                                Spacer()
                                if let amount = cartManager.cart?.cost.totalAmount,
                                   let total = amount.formattedString()
                                {
                                    Text(total)
                                        .fontWeight(.bold)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(isBusy ? Color.gray : Color(ColorPalette.primaryColor))
                            .cornerRadius(DesignSystem.cornerRadius)
                        }
                    )
                    .disabled(isBusy)
                    .foregroundColor(.white)
                    .accessibilityIdentifier("checkoutSheetButton")
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .onAppear {
                preloadCheckout()
            }
            .sheet(isPresented: $showCheckoutSheet) {
                if let url = cartManager.cart?.checkoutUrl {
                    CheckoutSheet(checkout: url)
                        .colorScheme(.automatic)
                        .onCancel {
                            showCheckoutSheet = false
                        }
                        .onComplete { event in
                            showCheckoutSheet = false
                            // Handle checkout completion
                            print("Checkout completed with order ID: \(event.orderDetails.id)")
                        }
                        .onFail { error in
                            showCheckoutSheet = false
                            // Handle checkout failure
                            print("Checkout failed: \(error)")
                        }
                }
            }
        } else {
            EmptyState()
        }
    }

    private func preloadCheckout() {
        CheckoutController.shared?.preload()
    }

    private func presentCheckout() {
        guard let url = CartManager.shared.cart?.checkoutUrl else {
            return
        }

        CheckoutController.shared?.present(checkout: url)
    }
}

// swiftlint:enable opening_brace

struct EmptyState: View {
    var body: some View {
        VStack(alignment: .center) {
            SwiftUI.Image(systemName: "cart")
                .resizable()
                .frame(width: 30, height: 30)
                .foregroundColor(.gray)
                .padding(.bottom, 6)
            Text("Your cart is empty.")
                .font(.caption)
        }
    }
}

struct CartLines: View {
    var lines: [BaseCartLine]
    @State var updating: GraphQL.ID? {
        didSet {
            isBusy = updating != nil
        }
    }

    @Binding var isBusy: Bool

    var body: some View {
        ForEach(lines, id: \.id) { node in
            let variant = node.merchandise as? Storefront.ProductVariant

            HStack {
                if let imageUrl = variant?.product.featuredImage?.url {
                    AsyncImage(url: imageUrl) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 80, height: 140)
                        case let .success(image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .transition(.opacity.animation(.easeIn))
                        case .failure:
                            Image(systemName: "photo")
                                .frame(width: 80, height: 140)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(width: 80, height: 140)
                    .padding(.trailing, 5)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(variant?.product.title ?? "")
                        .font(.body)
                        .bold()
                        .lineLimit(2)
                        .truncationMode(.tail)

                    Text(variant?.product.vendor ?? "")
                        .font(.body)
                        .foregroundColor(Color(ColorPalette.primaryColor))

                    if let price = variant?.price.formattedString() {
                        HStack {
                            Text("\(price)")
                                .foregroundColor(.gray)

                            Spacer()

                            HStack(spacing: 20) {
                                Button(action: {
                                    /// Prevent multiple simulataneous calls
                                    guard node.quantity > 1, updating != node.id else {
                                        return
                                    }

                                    updating = node.id

                                    /// Invalidate the cart cache to ensure the correct item quantity is reflected on checkout
                                    ShopifyCheckoutSheetKit.invalidate()

                                    _Concurrency.Task {
                                        let cart = try await CartManager.shared.performCartLinesUpdate(id: node.id, quantity: node.quantity - 1)
                                        CartManager.shared.cart = cart
                                        updating = nil

                                        CartManager.shared.preloadCheckout()
                                    }
                                }, label: {
                                    Image(systemName: "minus")
                                        .font(.system(size: 12))
                                        .frame(width: 32, height: 32)
                                        .background(Color.gray.opacity(0.1))
                                        .clipShape(Circle())
                                })

                                VStack {
                                    if updating == node.id {
                                        ProgressView().progressViewStyle(CircularProgressViewStyle())
                                            .scaleEffect(0.8)
                                    } else {
                                        Text("\(node.quantity)")
                                            .frame(width: 20)
                                    }
                                }.frame(width: 20)

                                Button(
                                    action: {
                                        /// Prevent multiple simulataneous calls
                                        guard updating != node.id else {
                                            return
                                        }

                                        updating = node.id

                                        /// Invalidate the cart cache to ensure the correct item quantity is reflected on checkout
                                        ShopifyCheckoutSheetKit.invalidate()

                                        _Concurrency.Task {
                                            let cart = try await CartManager.shared.performCartLinesUpdate(
                                                id: node.id,
                                                quantity: node.quantity + 1
                                            )
                                            CartManager.shared.cart = cart
                                            updating = nil

                                            ShopifyCheckoutSheetKit.preload(checkout: cart.checkoutUrl)
                                        }
                                    },
                                    label: {
                                        Image(systemName: "plus")
                                            .font(.system(size: 12))
                                            .frame(width: 32, height: 32)
                                            .background(Color.gray.opacity(0.1))
                                            .clipShape(Circle())
                                    }
                                )
                            }
                            .padding(.trailing, 10)
                        }
                    }
                }.padding(.leading, 5)
            }
            .padding([.leading, .trailing], 20)
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()
                .background(Color.gray.opacity(0.3))
                .padding(.vertical, 2)
        }
    }
}
