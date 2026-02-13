@preconcurrency import Buy
import ShopifyAcceleratedCheckouts
import ShopifyCheckoutProtocol
import ShopifyCheckoutSheetKit
import SwiftUI

struct CartView: View {
    @State var cartCompleted: Bool = false
    @State var isBusy: Bool = false
    @State var isCompleted: Bool = false
    @State var showCheckoutSheet: Bool = false

    @ObservedObject var cartManager: CartManager = .shared

    private let client = CheckoutProtocol.Client()
        .on(CheckoutProtocol.start) { checkout in
            print("[UCP] Checkout started: \(checkout.id)")
        }
        .on(CheckoutProtocol.complete) { checkout in
            print("[UCP] Checkout completed: \(checkout.order?.id ?? "unknown")")
            CartManager.shared.resetCart()
        }

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
                    if let cartID = cartManager.cart?.id.rawValue {
                        AcceleratedCheckoutButtons(cartID: cartID)
                            .onFail { error in
                                print("[AcceleratedCheckout] Failed: \(error)")
                            }
                            .onCancel {
                                print("[AcceleratedCheckout] Cancelled")
                            }
                            .connect(client)
                            .environmentObject(
                                ShopifyAcceleratedCheckouts.Configuration(
                                    storefrontDomain: InfoDictionary.shared.domain,
                                    storefrontAccessToken: InfoDictionary.shared.accessToken
                                )
                            )
                            .environmentObject(
                                ShopifyAcceleratedCheckouts.ApplePayConfiguration(
                                    merchantIdentifier: InfoDictionary.shared.merchantIdentifier,
                                    contactFields: [.email, .phone]
                                )
                            )
                    }

                    Button(
                        action: { showCheckoutSheet = true },
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
                    CheckoutSheet(checkout: url.appendingEcParams())
                        .connect(client)
                        .colorScheme(.automatic)
                        .onCancel {
                            print("[ShopifyCheckoutKit] CANCEL")
                            showCheckoutSheet = false

                            if isCompleted {
                                CartManager.shared.resetCart()
                                isCompleted = false
                            }
                        }
                        .onFail { error in
                            showCheckoutSheet = false
                            print("[ShopifyCheckoutKit] FAIL - Checkout failed: \(error)")
                        }
                        .edgesIgnoringSafeArea(.all)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        cartManager.resetCart()
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
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
                                    guard node.quantity > 1, updating != node.id else {
                                        return
                                    }

                                    updating = node.id

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
                                        guard updating != node.id else {
                                            return
                                        }

                                        updating = node.id

                                        ShopifyCheckoutSheetKit.invalidate()

                                        _Concurrency.Task {
                                            let cart = try await CartManager.shared.performCartLinesUpdate(
                                                id: node.id,
                                                quantity: node.quantity + 1
                                            )
                                            CartManager.shared.cart = cart
                                            updating = nil

                                            ShopifyCheckoutSheetKit.preload(checkout: cart.checkoutUrl.appendingEcParams())
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
