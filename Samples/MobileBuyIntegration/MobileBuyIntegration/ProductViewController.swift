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

class ProductViewController: UIViewController {

	// MARK: Properties
	private var handle: String?

	@IBOutlet private var image: UIImageView!

	@IBOutlet private var titleLabel: UILabel!

	@IBOutlet private var variantLabel: UILabel!

	@IBOutlet private var descriptionLabel: UILabel!

	@IBOutlet private var addToCartButton: UIButton!

	private var loading = false {
		didSet {
			rerender()
		}
	}

	private var product: Storefront.Product? {
		didSet {
			DispatchQueue.main.async { [weak self] in
				self?.updateProductDetails()
			}
		}
	}

	// MARK: Initializers

	convenience init(handle: String?) {
		self.init(nibName: nil, bundle: nil)

		self.handle = handle
	}

	// MARK: UIViewController Lifecycle

	override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.rightBarButtonItem = UIBarButtonItem(
			barButtonSystemItem: .refresh,
			target: self, action: #selector(reloadProduct)
		)

		navigationItem.leftBarButtonItem = UIBarButtonItem(
			image: UIImage(systemName: "cart"),
			style: .plain,
			target: self, action: #selector(openCart))

		if #available(iOS 15.0, *) {
			addToCartButton.configurationUpdateHandler = {
				$0.configuration?.showsActivityIndicator = self.loading
			}
		}

		if let handle = handle {
			getProductByHandle(handle)
		} else {
			reloadProduct()
		}
	}

	private func rerender() {
		if #available(iOS 15.0, *) {
			addToCartButton.configurationUpdateHandler = {
				$0.configuration?.showsActivityIndicator = self.loading
			}
		}
		updateProductDetails()
	}

	private func setLoading(_ state: Bool) {
		if state {
			addToCartButton.isEnabled = false
			loading = true
		} else {
			addToCartButton.isEnabled = true
			loading = false
		}
	}

	private func setProduct(_ product: Storefront.Product?) {
		if let product = product {
			self.product = product
			self.handle = product.handle
		}
	}

	// MARK: Actions

	@IBAction func addToCart() {
		if let variant = product?.variants.nodes.first {
			self.setLoading(true)
			addToCartButton.isEnabled = false
			let start = Date()
			CartManager.shared.addItem(variant: variant.id) { [weak self] in
				let diff = Date().timeIntervalSince(start)
				let message = "Added item to cart in \(String(format: "%.0f", diff * 1000))ms"
				ShopifyCheckoutSheetKit.configuration.logger.log(message)
				self?.setLoading(false)
			}
		}
	}

	public func getProductByHandle(_ handle: String) {
		let context = Storefront.InContextDirective(country: Storefront.CountryCode.inferRegion())
		let query = Storefront.buildQuery(inContext: context) { $0
			.products(first: 1, query: handle) { $0
				.nodes { $0
					.id()
					.title()
					.handle()
					.description()
					.vendor()
					.featuredImage { $0
						.url()
					}
					.variants(first: 1) { $0
						.nodes { $0
							.id()
							.title()
							.availableForSale()
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
			self?.setLoading(false)
			if case .success(let query) = result {
				self?.setProduct(query.products.nodes.first)
			}
		}
	}

	@IBAction private func reloadProduct() {
		let query = Storefront.buildQuery(inContext: Storefront.InContextDirective(country: Storefront.CountryCode.inferRegion())) { $0
			.products(first: 250) { $0
				.nodes { $0
					.id()
					.title()
					.handle()
					.description()
					.vendor()
					.featuredImage { $0
						.url()
					}
					.variants(first: 1) { $0
						.nodes { $0
							.id()
							.title()
							.availableForSale()
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
			self?.setLoading(false)
			if case .success(let query) = result {
				self?.setProduct(query.products.nodes.randomElement())
			}
		}
	}

	@IBAction private func openCart() {
		let cartViewController = CartViewController()

		if #available(iOS 13.0, *) {
			cartViewController.modalPresentationStyle = .automatic
		} else {
			cartViewController.modalPresentationStyle = .overFullScreen
		}
		present(cartViewController, animated: true, completion: nil)
	}

	// MARK: Private

	private func updateProductDetails() {
		guard let product = self.product else { return }

		titleLabel.text = product.title
		variantLabel.text = product.vendor
		descriptionLabel.text = product.description

		self.navigationItem.title = product.title

		if let featuredImageURL = product.featuredImage?.url {
			image.load(url: featuredImageURL)
		}

		if let variant = product.variants.nodes.first {
			if #available(iOS 15.0, *) {

				if variant.availableForSale {
					addToCartButton.configuration?
						.subtitle = variant.price.formattedString()
				} else {
					addToCartButton.configuration?
						.subtitle = "Out of stock"
					addToCartButton.isEnabled = false
				}
			}
		}
	}
}
