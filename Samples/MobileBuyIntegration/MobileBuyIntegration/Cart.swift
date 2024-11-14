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

import Buy
import SwiftUI
import ShopifyCheckoutSheetKit

struct CartView: View {
	@State var cartCompleted: Bool = false
	@State var isBusy: Bool = false

	@ObservedObject var cartManager: CartManager = CartManager.shared

	var body: some View {
		if let lines = cartManager.cart?.lines.nodes {
			ZStack(alignment: .bottom) {
				ScrollView {
					VStack {
						CartLines(lines: lines, isBusy: $isBusy)
					}
					.padding(.bottom, 80)
				}

				VStack {
					Button(action: presentCheckout, label: {
						HStack {
							Text("Checkout")
								.fontWeight(.bold)
							Spacer()
							if let amount = cartManager.cart?.cost.totalAmount, let total = amount.formattedString() {
								Text(total)
									.fontWeight(.bold)
							}
						}
						.padding()
						.frame(maxWidth: .infinity)
						.background(isBusy ? Color.gray : Color(ColorPalette.primaryColor))
						.cornerRadius(10)
					})
					.disabled(isBusy)
					.foregroundColor(.white)
					.accessibilityIdentifier("checkoutButton")
					.padding(.horizontal, 15)
				}
				.padding(.bottom, 20)
			}
			.onAppear {
				preloadCheckout()
			}
		} else {
			EmptyState()
		}
	}

	private func preloadCheckout() {
        CartManager.shared.preloadCheckout()
    }

    private func presentCheckout() {
        guard let url = CartManager.shared.cart?.checkoutUrl else {
			return
        }

		ShopifyCheckoutSheetKit.present(checkout: url, from: SceneDelegate.cartController, delegate: SceneDelegate.cartController)
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
						case .success(let image):
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

				VStack(alignment: .leading, spacing: 8
) {
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
									guard node.quantity > 1 && updating != node.id else {
										return
									}

									updating = node.id

									/// Invalidate the cart cache to ensure the correct item quantity is reflected on checkout
									ShopifyCheckoutSheetKit.invalidate()

									CartManager.shared.updateQuantity(variant: node.id, quantity: node.quantity - 1, completionHandler: { cart in
										CartManager.shared.cart = cart
										updating = nil

										CartManager.shared.preloadCheckout()
									})
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

								Button(action: {
									/// Prevent multiple simulataneous calls
									guard updating != node.id else {
										return
									}

									updating = node.id

									/// Invalidate the cart cache to ensure the correct item quantity is reflected on checkout
									ShopifyCheckoutSheetKit.invalidate()

									CartManager.shared.updateQuantity(variant: node.id, quantity: node.quantity + 1, completionHandler: { cart in
										CartManager.shared.cart = cart
										updating = nil

										if let url = cart?.checkoutUrl {
											ShopifyCheckoutSheetKit.preload(checkout: url)
										}
									})
								}, label: {
									Image(systemName: "plus")
										.font(.system(size: 12))
										.frame(width: 32, height: 32)
										.background(Color.gray.opacity(0.1))
										.clipShape(Circle())
								})
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
