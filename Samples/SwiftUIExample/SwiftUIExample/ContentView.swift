import SwiftUI
import ShopifyCheckoutKit
import Combine

struct CheckoutView: View {
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
							AsyncImage(url: product.featuredImage?.url)
								.aspectRatio(contentMode: .fill)
								.frame(maxWidth: 300, maxHeight: 300)
								.clipped()
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
									CheckoutView(checkoutURL: $checkoutURL, delegate: eventHandler, isShowingCheckout: $isShowingCheckout)
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

class EventHandler: NSObject, CheckoutDelegate {
	var dismissCheckout: (() -> Void)?
	@Published var didCancel = false

	func checkoutDidCancel() {
		didCancel = !didCancel
	}

	func checkoutDidComplete() {
	}
	func checkoutDidFail(error: CheckoutError) {
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
