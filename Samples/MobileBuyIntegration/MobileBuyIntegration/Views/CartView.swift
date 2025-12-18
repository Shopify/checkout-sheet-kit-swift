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
import ShopifyAcceleratedCheckouts
import ShopifyCheckoutSheetKit
import SwiftUI

struct CheckoutData: Identifiable {
    let id = UUID()
    let url: URL
    let token: String?
}

struct CartView: View {
    @State var cartCompleted: Bool = false
    @State var isBusy: Bool = false
    @State var checkoutData: CheckoutData?
    @State var authToken: String? = nil
    @State var isCheckoutLoading: Bool = false

    @ObservedObject var cartManager: CartManager = .shared
    @ObservedObject var config: AppConfiguration = appConfiguration

    @AppStorage(AppStorageKeys.authenticate.rawValue)
    var authenticate: Bool = true

    var body: some View {
        if let lines = cartManager.cart?.lines.nodes {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack {
                        CartLines(lines: lines, isBusy: $isBusy)
                    }
                    .padding(.bottom, 130)
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
                            .environmentObject(
                                appConfiguration.acceleratedCheckoutsStorefrontConfig
                            )
                            .environmentObject(appConfiguration.acceleratedCheckoutsApplePayConfig)
                    }

                    Button(
                        action: {
                            _Concurrency.Task { @MainActor in
                                if authenticate {
                                    await getAccessToken()
                                }

                                if let url = cartManager.cart?.checkoutUrl {
                                    checkoutData = CheckoutData(url: url, token: authToken)
                                }
                            }
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

                _Concurrency.Task {
                    await getAccessToken()
                }
            }
            .sheet(item: $checkoutData) { data in
                ZStack {
                    ShopifyCheckout(checkout: data.url)
                        .auth(token: data.token)
                        .colorScheme(.automatic)
                        .navigationBarHidden(true)
                        .onStart { event in
                            print("Checkout started with cart ID: \(event.cart.id)")
                            isCheckoutLoading = false
                        }
                        .onCancel {
                            checkoutData = nil
                            isCheckoutLoading = false
                        }
                        .onComplete { event in
                            checkoutData = nil
                            isCheckoutLoading = false
                            // Handle checkout completion
                            print("Checkout completed with order ID: \(event.orderConfirmation.order.id)")
                        }
                        .onFail { error in
                            checkoutData = nil
                            isCheckoutLoading = false
                            // Handle checkout failure
                            print("Checkout failed: \(error)")
                        }
                        .onAddressChangeStart { event in
                            print(
                                "🎉 SwiftUI: Address change intent received for addressType: \(event.addressType)"
                            )

                            // Respond with updated cart after 2 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                let hardcodedAddress = CartDeliveryAddress(
                                    firstName: "Jane",
                                    lastName: "Smith",
                                    address1: "456 SwiftUI Avenue",
                                    address2: "Suite 200",
                                    city: "Vancouver",
                                    countryCode: "CA",
                                    phone: "+1-604-555-0456",
                                    provinceCode: "BC",
                                    zip: "V6B 1A1"
                                )

                                let selectableAddress = CartSelectableAddress(
                                    address: .deliveryAddress(hardcodedAddress),
                                    selected: true
                                )
                                let delivery = CartDelivery(addresses: [selectableAddress])

                                let updatedCart = event.cart.copy(
                                    delivery: .override(delivery)
                                )

                                let response = CheckoutAddressChangeStartResponsePayload(cart: updatedCart)

                                print("🎉 SwiftUI: Responding with hardcoded Vancouver address")
                                do {
                                    try event.respondWith(payload: response)
                                } catch {
                                    print(
                                        "Failed to respondwith: Responding with hardcoded Vancouver address"
                                    )
                                }
                            }
                        }
                        .onPaymentMethodChangeStart { event in
                            print("🎉 SwiftUI: Payment method change start received")

                            // Respond with updated cart after 2 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                let instrument = CreditCardPaymentInstrument(
                                    externalReferenceId: "card-visa-1234",
                                    lastDigits: "1234",
                                    brand: CardBrand.visa
                                )

                                let paymentMethod = CartPaymentMethod(instruments: [instrument])
                                let payment = CartPayment(methods: [paymentMethod])

                                let updatedCart = Cart(
                                    id: event.cart.id,
                                    lines: event.cart.lines,
                                    cost: event.cart.cost,
                                    buyerIdentity: event.cart.buyerIdentity,
                                    deliveryGroups: event.cart.deliveryGroups,
                                    discountCodes: event.cart.discountCodes,
                                    appliedGiftCards: event.cart.appliedGiftCards,
                                    discountAllocations: event.cart.discountAllocations,
                                    delivery: event.cart.delivery,
                                    payment: payment
                                )

                                let response = CheckoutPaymentMethodChangeStartResponsePayload(cart: updatedCart)

                                print("🎉 SwiftUI: Responding with hardcoded Visa ending in 1234")
                                do {
                                    try event.respondWith(payload: response)
                                } catch {
                                    print("Failed to respond with payment method change")
                                }
                            }
                        }
                        .onAppear {
                            isCheckoutLoading = true
                        }

                    if isCheckoutLoading {
                        ZStack {
                            Color.black.opacity(0.4)

                            VStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)

                                Text("Loading...")
                                    .foregroundColor(.white)
                                    .padding(.top, 20)
                            }
                        }
                        .edgesIgnoringSafeArea(.all)
                    }
                }
                .presentationDragIndicator(.visible)
                .edgesIgnoringSafeArea(.all)
            }
        } else {
            EmptyState()
        }
    }

    private func preloadCheckout() {
        CheckoutController.shared?.preload()
    }

    @MainActor
    private func getAccessToken() async {
        guard authenticate else {
            authToken = nil
            return
        }

        do {
            authToken = try await AuthenticationService.shared.getAccessToken()
        } catch {
            print("failed to fetch auth token")
            authToken = nil
        }
    }

    private func presentCheckout() {
        guard let url = CartManager.shared.cart?.checkoutUrl else {
            return
        }

        CheckoutController.shared?.present(checkout: url)
    }
}

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
                                Button(
                                    action: {
                                        /// Prevent multiple simulataneous calls
                                        guard node.quantity > 1, updating != node.id else {
                                            return
                                        }

                                        updating = node.id

                                        /// Invalidate the cart cache to ensure the correct item quantity is reflected on checkout
                                        ShopifyCheckoutSheetKit.invalidate()

                                        _Concurrency.Task {
                                            let cart = try await CartManager.shared
                                                .performCartLinesUpdate(
                                                    id: node.id, quantity: node.quantity - 1
                                                )
                                            CartManager.shared.cart = cart
                                            updating = nil

                                            CartManager.shared.preloadCheckout()
                                        }
                                    },
                                    label: {
                                        Image(systemName: "minus")
                                            .font(.system(size: 12))
                                            .frame(width: 32, height: 32)
                                            .background(Color.gray.opacity(0.1))
                                            .clipShape(Circle())
                                    }
                                )

                                VStack {
                                    if updating == node.id {
                                        ProgressView().progressViewStyle(
                                            CircularProgressViewStyle()
                                        )
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
                                            let cart = try await CartManager.shared
                                                .performCartLinesUpdate(
                                                    id: node.id,
                                                    quantity: node.quantity + 1
                                                )
                                            CartManager.shared.cart = cart
                                            updating = nil

                                            ShopifyCheckoutSheetKit.preload(
                                                checkout: cart.checkoutUrl)
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
