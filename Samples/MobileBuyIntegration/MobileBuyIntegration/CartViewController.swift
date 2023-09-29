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
import Combine
import ShopifyCheckout

class CartViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

	// MARK: Properties

	private var bag = Set<AnyCancellable>()

	@IBOutlet private var emptyView: UIView!

	@IBOutlet private var tableView: UITableView!

	@IBOutlet private var footerView: UIView!

	@IBOutlet private var checkoutButton: UIButton!

	// MARK: Initializers

	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

		title = "Cart"

		navigationItem.rightBarButtonItem = UIBarButtonItem(
			title: "Reset", style: .plain, target: self, action: #selector(resetCart)
		)

		tabBarItem.image = UIImage(systemName: "cart")

		CartManager.shared.$cart
			.receive(on: DispatchQueue.main)
			.sink { [weak self] _ in
				self?.cartDidUpdate()
			}
			.store(in: &bag)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: UIViewController Lifecycle

	override func viewDidLoad() {
		super.viewDidLoad()

		tableView.register(
			UITableViewCell.self, forCellReuseIdentifier: "row"
		)
		tableView.allowsSelection = false

		cartDidUpdate()
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		tableView.reloadData()
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()

		tableView.contentInset.bottom = footerView.frame.size.height
	}

	// MARK: UITableViewDataSource

	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return CartManager.shared.cart?.lines.nodes.count ?? 0
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let variant = variant(at: indexPath)

		let cell = tableView.dequeueReusableCell(withIdentifier: "row", for: indexPath)

		var content = cell.defaultContentConfiguration()
		content.text = variant.product.title
		content.secondaryText = variant.product.vendor
		cell.contentConfiguration = content

		return cell
	}

	// MARK: Private

	private func cartDidUpdate() {
		let cart = CartManager.shared.cart
		let totalQuantity = cart?.totalQuantity ?? 0

		tabBarItem.badgeValue = String(totalQuantity)

		if isViewLoaded {
			emptyView.isHidden = totalQuantity > 0
			tableView.reloadData()
			tableView.isHidden = totalQuantity <= 0
			checkoutButton.isHidden = totalQuantity <= 0
			checkoutButton.configuration?
				.subtitle = cart?.cost.totalAmount.formattedString()
		}
	}

	@IBAction private func presentCheckout() {
		guard let url = CartManager.shared.cart?.checkoutUrl else { return }
		ShopifyCheckout.present(checkout: url, from: self, delegate: self)
	}

	@IBAction private func resetCart() {
		CartManager.shared.resetCart()
	}

	private func variant(at indexPath: IndexPath) -> Storefront.ProductVariant {
		guard
			let lines = CartManager.shared.cart?.lines.nodes,
			let variant = lines[indexPath.item].merchandise as? Storefront.ProductVariant
		else {
			fatalError("invald index path")
		}
		return variant
	}
}

extension CartViewController: CheckoutDelegate {
	func checkoutDidComplete() {
		resetCart()
	}

	func checkoutDidCancel() {
		dismiss(animated: true)
	}

	func checkoutDidFail(errors: [ShopifyCheckout.CheckoutError]) {
		print(#function, errors)
	}
}
