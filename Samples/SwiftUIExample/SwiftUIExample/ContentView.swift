import SwiftUI
import ShopifyCheckoutKit
import Combine

struct ContentView: View {
	@StateObject private var viewModel = ProductViewModel()
	@State private var isShowingCheckout = false
	@State private var checkoutURL: URL?

	var body: some View {
		NavigationView {
			VStack {
				if let product = viewModel.product {
					ScrollView {
						VStack {
							AsyncImage(url: product.featuredImage?.url)
								.aspectRatio(contentMode: .fit)
								.frame(maxWidth: 100)
							Text(product.title)
								.font(.title)
								.multilineTextAlignment(.center)
								.padding()
							if let variant = product.variants.nodes.first {
								Text(variant.title)
									.font(.title3)
									.foregroundColor(.secondary)
									.multilineTextAlignment(.center)
									.padding()
								Button(action: {
									viewModel.beginCheckout { url in
										checkoutURL = url
										isShowingCheckout = true
									}
								}) {
									Text("Buy Now")
										.font(.headline)
										.padding()
										.frame(maxWidth: .infinity)
										.background(Color.blue)
										.foregroundColor(.white)
										.cornerRadius(10)
								}
								.padding()
								.sheet(isPresented: $isShowingCheckout) {
									if let url = checkoutURL {
										CheckoutViewController.Representable(checkout: url)
									}
								}
							}
						}
					}
					.navigationTitle("Product Details")
					.navigationBarItems(trailing: Button(action: {
						viewModel.reloadProduct()
					}) {
						SwiftUI.Image(systemName: "arrow.clockwise")
					})
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
		StorefrontClient.shared.createCart(variant: variant) { [weak self] result in
			if case .success(let cart) =  result {
				DispatchQueue.main.async {
					completion(cart.checkoutUrl)
				}
			}
		}
	}
}
