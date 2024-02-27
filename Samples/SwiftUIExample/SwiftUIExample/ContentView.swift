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

struct ContentView: View {
//	private var eventHandler = EventHandler()
	@StateObject private var presenter = CheckoutSheetPresenter()
	@StateObject private var viewModel = ProductViewModel()
	@State private var isShowingCheckout = false
	@State private var checkoutURL: URL?

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
								.padding(3)

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

									presenter.present(checkout: checkoutURL)
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
		.preferredColorScheme(.dark)

		CheckoutSheetKit(presenter: presenter)
			.title("Checkout with SwiftUI!")
			.colorScheme(.dark)
			.tintColor(UIColor(red: 0.33, green: 0.20, blue: 0.92, alpha: 1.00))
			.onCheckoutCancel {
				print("[EVENT] checkout closed")
				presenter.dismiss()
			}
			.onCheckoutCompleted { event in
				print("[EVENT] checkout completed", event)
			}
			.onCheckoutDidFail { error in
				print("[EVENT] checkout failed", error)
			}
			.onCheckoutDidEmitWebPixelEvent { event in
				print("[EVENT] checkout received event", event)
			}
	}

	func didDismiss() {
		isShowingCheckout = false
	}
}

// class EventHandler: CheckoutDelegate {
//	var didCancel: (() -> Void)?
//
//	func checkoutDidCancel() {
//		print("[debug] checkoutDidCancel")
//		didCancel?()
//	}
//
//	func checkoutDidComplete(event: ShopifyCheckoutSheetKit.CheckoutCompletedEvent) {}
//
//	func checkoutDidFail(error: CheckoutError) {}
//
//	func checkoutDidEmitWebPixelEvent(event: ShopifyCheckoutSheetKit.PixelEvent) {}
// }

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
