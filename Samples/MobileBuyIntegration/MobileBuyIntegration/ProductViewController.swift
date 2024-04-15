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
import UIKit
import ShopifyCheckoutSheetKit

class ProductViewController: UIViewController, CheckoutDelegate {
	func checkoutDidCancel() {
		// no-op
	}

	func checkoutDidEmitWebPixelEvent(event: ShopifyCheckoutSheetKit.PixelEvent) {
		// no-op
	}

	func checkoutDidFail(error: CheckoutError) {
		print(#function, error)
	}

	// MARK: Properties

	@IBOutlet private var image: UIImageView!

	@IBOutlet private var titleLabel: UILabel!

	@IBOutlet private var variantLabel: UILabel!

	@IBOutlet private var descriptionLabel: UILabel!

	@IBOutlet private var addToCartButton: UIButton!

	private var product: Storefront.Product? {
		didSet {
			DispatchQueue.main.async { [weak self] in
				self?.updateProductDetails()
			}
		}
	}

	// MARK: Initializers

	convenience init() {
		self.init(nibName: nil, bundle: nil)
	}

	// MARK: UIViewController Lifecycle

	override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.rightBarButtonItem = UIBarButtonItem(
			barButtonSystemItem: .refresh,
			target: self, action: #selector(reloadProduct)
		)

		if #available(iOS 15.0, *) {
			addToCartButton.configurationUpdateHandler = {
				$0.configuration?.showsActivityIndicator = !$0.isEnabled
			}
		}

		reloadProduct()
	}

	// MARK: Actions

	@IBAction func addToCart() {
		if let variant = product?.variants.nodes.first {
			addToCartButton.isEnabled = false
			let start = Date()
			CartManager.shared.addItem(variant: variant.id) { [weak self] in
				let diff = Date().timeIntervalSince(start)
				let message = "Added item to cart in \(String(format: "%.0f", diff * 1000))ms"
				ShopifyCheckoutSheetKit.configuration.logger.log(message)
				self?.addToCartButton.isEnabled = true
			}
		}
	}

	@IBAction private func reloadProduct() {
		let query = Storefront.buildQuery(inContext: Storefront.InContextDirective(country: Storefront.CountryCode.inferRegion())) { $0
			.products(first: 250) { $0
				.nodes { $0
					.id()
					.title()
					.description()
					.vendor()
					.featuredImage { $0
						.url()
					}
					.variants(first: 1) { $0
						.nodes { $0
							.id()
							.title()
							.price { $0
								.amount()
								.currencyCode()
							}
						}
					}
				}
			}
		}

		StorefrontClient.shared.execute(query: query) { [weak self] result in
			if case .success(let query) = result {
				self?.product = query.products.nodes.randomElement()
			}
		}
	}

	// MARK: Private

	private func updateProductDetails() {
		guard let product = self.product else { return }

		titleLabel.text = product.title
		variantLabel.text = product.vendor
		descriptionLabel.text = product.description

		if let featuredImageURL = product.featuredImage?.url {
			image.load(url: featuredImageURL)
		}

		if let variant = product.variants.nodes.first {
			if #available(iOS 15.0, *) {
				addToCartButton.configuration?
					.subtitle = variant.price.formattedString()
			}
		}
	}
}
