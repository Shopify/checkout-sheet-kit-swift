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

import SwiftUI
import ShopifyCheckoutSheetKit

struct CheckoutSheet: View {
	let checkoutURL: Binding<URL?>
	let delegate: EventHandler

	@Binding var isShowingCheckout: Bool

	var body: some View {
		CheckoutViewController.Representable(checkout: checkoutURL, delegate: delegate)
			.onReceive(delegate.$didCancel, perform: { didCancel in
				if didCancel {
					delegate.checkoutDidCancel()
					isShowingCheckout = false
				}
			})

	}
}
struct ContentView: View {
	@StateObject private var viewModel = ProductViewModel()
	@State private var isShowingCheckout = false
	@State private var checkoutURL: URL?
	private var eventHandler = EventHandler()

	init() {
		eventHandler.dismissCheckout = { [self] in
			self.isShowingCheckout = false
		}
	}

	var body: some View {
		NavigationView {
			VStack {
				if let product = viewModel.product {
					ScrollView {
						VStack {
							AsyncImage(url: product.featuredImage?.url) { image in
								image.image?.resizable().aspectRatio(contentMode: .fit)
							}.frame(height: 400)

							Text(product.vendor)
								.font(.subheadline)
								.bold()
								.foregroundColor(.blue)
								.multilineTextAlignment(.center)
								.padding()

							Text(product.title)
								.font(.title)
								.bold()
								.multilineTextAlignment(.center)

							if let price = product.variants.nodes.first?.price.formattedString() {
								Text(price)
									.padding(2)
									.bold()
									.foregroundColor(.gray)
							}

							Button(action: {
								viewModel.beginCheckout { url in
									checkoutURL = url
									isShowingCheckout = true
								}
							}, label: {
								Text("Buy Now")
									.font(.headline)
									.padding()
									.frame(maxWidth: .infinity)
									.background(Color.blue)
									.foregroundColor(.white)
									.cornerRadius(10)
							})
							.padding()
							.sheet(isPresented: $isShowingCheckout) {
								CheckoutSheet(checkoutURL: $checkoutURL, delegate: eventHandler, isShowingCheckout: $isShowingCheckout)
							}
						}
					}
					.navigationBarItems(trailing: Button(action: {
						viewModel.reloadProduct()
					}, label: {
						SwiftUI.Image(systemName: "arrow.clockwise")
					}))
				} else {
					ProgressView()
				}
			}
		}
		.onAppear {
			viewModel.reloadProduct()
		}
	}
}

class EventHandler: NSObject, CheckoutDelegate {
	var dismissCheckout: (() -> Void)?
	@Published var didCancel = false

	func checkoutDidCancel() {
		didCancel.toggle()
	}

	func checkoutDidComplete() {
	}

	func checkoutDidFail(error: CheckoutError) {
	}

	func checkoutDidEmitWebPixelEvent(event: ShopifyCheckoutSheetKit.PixelEvent) {
	}
}

class ProductViewModel: ObservableObject {
	@Published var product: Product?

	func reloadProduct() {
		StorefrontClient.shared.product { [weak self] result in
			if case .success(let product) = result {
				DispatchQueue.main.async {
					self?.product = product
				}
			}
		}
	}

	func beginCheckout(completion: @escaping (URL) -> Void) {
		guard let variant = product?.variants.nodes.first else { return }
		StorefrontClient.shared.createCart(variant: variant) { result in
			if case .success(let cart) =  result {
				DispatchQueue.main.async {
					completion(cart.checkoutUrl)
				}
			}
		}
	}
}
