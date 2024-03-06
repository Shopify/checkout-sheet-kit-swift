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

	public init(checkoutURL: Binding<URL?>, isShowingCheckout: Binding<Bool>) {
		self._checkoutURL = checkoutURL
		self._isShowingCheckout = isShowingCheckout

		delegate.dismissCheckout = { [self] in
			self.isShowingCheckout = false
		}
	}

	public var body: some View {
		CheckoutViewController.Representable(checkout: $checkoutURL, delegate: delegate)
			.onReceive(delegate.$didCancel, perform: { didCancel in
				if didCancel {
					delegate.checkoutDidCancel()
					isShowingCheckout = false
				}
			})

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

public struct CartView: View {
	@Binding var checkoutURL: URL?
	@Binding var isShowingCheckout: Bool
	@Binding var cart: Storefront.Cart?

	public var body: some View {
		if let lines = cart?.lines.nodes {
			ScrollView {
				VStack {
					CartLines(lines: lines)
				}

				Spacer()

				VStack {
					Button(action: {
						isShowingCheckout = true
					}, label: {
						Text("Checkout")
							.padding()
							.frame(maxWidth: .infinity)
							.background(Color.blue)
							.foregroundColor(.white)
							.cornerRadius(10)
							.bold()
					})
					.accessibilityIdentifier("checkoutButton")
					.sheet(isPresented: $isShowingCheckout) {
						if checkoutURL != nil {
							CheckoutSheet(checkoutURL: $checkoutURL, isShowingCheckout: $isShowingCheckout)
						}
					}
					.padding(.top, 15)
					.padding(.horizontal, 5)
				}

				Spacer()
			}.padding(10)
		} else {
			EmptyState()
		}
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

	var body: some View {
		ForEach(lines, id: \.id) { node in
			let variant = node.merchandise as? Storefront.ProductVariant

			HStack {
				if let imageUrl = variant?.product.featuredImage?.url {
					AsyncImage(url: imageUrl) { image in
						image.image?.resizable().aspectRatio(contentMode: .fit)
					}
					.frame(width: 60, height: 90)
				}

				VStack(alignment: .leading, spacing: 1) {
					Text(variant?.product.title ?? "")
						.font(.body)
						.bold()
						.lineLimit(2)
						.truncationMode(.tail)

					Text(variant?.product.vendor ?? "")
						.font(.body)
						.foregroundColor(.blue)

					if let price = variant?.price.formattedString() {
						Text("\(price) - Quantity: \(node.quantity)")
							.font(.caption)
							.foregroundColor(.gray)
					}
				}.padding(.leading, 5)
			}
			.padding([.leading, .trailing], 10)
			.frame(maxWidth: .infinity, alignment: .leading)
		}
	}
}
