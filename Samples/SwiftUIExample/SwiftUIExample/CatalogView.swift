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

public struct CheckoutSheet: View {
	@Binding var checkoutURL: URL?
	@Binding var isShowingCheckout: Bool

	let delegate: EventHandler = EventHandler()

	public var body: some View {
		CheckoutViewController.Representable(checkout: $checkoutURL, delegate: delegate)
			.onReceive(delegate.$didCancel, perform: { didCancel in
				if didCancel {
					delegate.checkoutDidCancel()
					isShowingCheckout = false
				}
			})
			.onAppear {
				delegate.dismissCheckout = { [self] in
					self.isShowingCheckout = false
				}
			}
			.edgesIgnoringSafeArea(.all)
	}
}

class EventHandler: NSObject, CheckoutDelegate {
	var dismissCheckout: (() -> Void)?
	@Published var didCancel = false

	func checkoutDidCancel() {
		didCancel.toggle()
	}

	func checkoutDidComplete() {}
	func checkoutDidFail(error: CheckoutError) {}
	func checkoutDidEmitWebPixelEvent(event: ShopifyCheckoutSheetKit.PixelEvent) {}
}

struct CatalogView: View {
	var cartManager: CartManager

	@Binding var checkoutURL: URL?
	@Binding var cart: Storefront.Cart?

	@State private var isAddingToCart = false
	@State private var isShowingCheckout = false
	@State private var isShowingCart = false
	@State private var product: Storefront.Product?

	func onAppear() {
		cartManager.getRandomProduct { [self] result in
			product = result
		}
	}

	var body: some View {
		NavigationView {
			VStack {
				if let product = product {
					ScrollView {
						VStack {
							AsyncImage(url: product.featuredImage?.url) { image in
								image.image?.resizable().aspectRatio(contentMode: .fit)
							}
							.frame(height: 400)

							Text(product.vendor)
								.font(.subheadline)
								.bold()
								.foregroundColor(.blue)
								.multilineTextAlignment(.center)
								.padding(.top, 10)
								.padding()

							Text(product.title)
								.font(.title3)
								.bold()
								.multilineTextAlignment(.center)
								.lineLimit(2)
								.truncationMode(.tail)

							if let price = product.variants.nodes.first?.price.formattedString() {
								Text(price)
									.padding(2)
									.bold()
									.foregroundColor(.gray)
							}

							Button(action: {
								isAddingToCart = true

								if let variantId = product.variants.nodes.first?.id {
									cartManager.addItem(variant: variantId) { cart in
										isAddingToCart = false
										checkoutURL = cart?.checkoutUrl
										isShowingCheckout = true
									}
								}
							}, label: {
								if isAddingToCart {
									ProgressView()
										.progressViewStyle(CircularProgressViewStyle(tint: .white))
										.padding()
										.frame(maxWidth: 400)
										.background(Color.blue)
										.foregroundColor(.white)
										.cornerRadius(10)
								} else {
									Text("Buy now")
										.font(.headline)
										.padding()
										.frame(maxWidth: 400)
										.background(Color.blue)
										.foregroundColor(.white)
										.cornerRadius(10)
								}
							})
							.accessibilityIdentifier("addToCartButton")
							.sheet(isPresented: $isShowingCheckout) {
								CheckoutSheet(checkoutURL: $checkoutURL, isShowingCheckout: $isShowingCheckout)
							}
							.padding()
						}
					}
					.toolbar {
						ToolbarItem(placement: .topBarLeading) {
							Text("SwiftUI")
								.font(.headline)
						}
						ToolbarItemGroup {
							Button(action: {
								onAppear()
							}, label: {
								SwiftUI.Image(systemName: "arrow.clockwise")
							})
						}
					}
				} else {
					ProgressView()
				}
			}
		}
		.padding()
		.onAppear {
			if product != nil {
				return
			}
			onAppear()
		}
		.preferredColorScheme(.light)
		.edgesIgnoringSafeArea(.all)
	}
}

struct BadgeButton: View {
	var badgeCount: Int
	var action: () -> Void

	var body: some View {
		Button(action: action) {
			ZStack {
				SwiftUI.Image(systemName: "cart.fill")

				if badgeCount > 0 {
					Text("\(badgeCount)")
						.foregroundColor(.white)
						.font(.system(size: 12))
						.frame(width: 20, height: 20)
						.background(Color.red)
						.clipShape(Circle())
						.offset(x: 10, y: -10)
				}
			}
		}
	}
}
