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

import UIKit
import WebKit

class CheckoutViewController: UIViewController {

	// MARK: Properties

	weak var delegate: CheckoutDelegate?

	private let checkoutView: CheckoutView

	private lazy var spinner: SpinnerView = {
		let spinner = SpinnerView(frame: .zero)
		spinner.translatesAutoresizingMaskIntoConstraints = false
		return spinner
	}()

	private var initialNavigation: Bool = true

	private let checkoutURL: URL

	private lazy var closeBarButtonItem = UIBarButtonItem(
		barButtonSystemItem: .close, target: self, action: #selector(close)
	)

	// MARK: Initializers

	public init(checkoutURL url: URL, delegate: CheckoutDelegate? = nil) {
		self.checkoutURL = url
		self.delegate = delegate

		let checkoutView = CheckoutView.for(checkout: url)
		checkoutView.translatesAutoresizingMaskIntoConstraints = false
		self.checkoutView = checkoutView

		super.init(nibName: nil, bundle: nil)

		title = "Checkout"

		navigationItem.rightBarButtonItem = closeBarButtonItem

		checkoutView.viewDelegate = self
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: UIViewController Lifecycle

	override public func viewDidLoad() {
		super.viewDidLoad()

		view.backgroundColor = .systemBackground

		view.addSubview(checkoutView)
		NSLayoutConstraint.activate([
			checkoutView.topAnchor.constraint(equalTo: view.topAnchor),
			checkoutView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			checkoutView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			checkoutView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
		])

		view.addSubview(spinner)
		NSLayoutConstraint.activate([
			spinner.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
			spinner.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
		])
		view.bringSubviewToFront(spinner)

		loadCheckout()
	}

	private func loadCheckout() {
		if checkoutView.url == nil {
			checkoutView.alpha = 0
			initialNavigation = true
			checkoutView.load(checkout: checkoutURL)
		} else if checkoutView.isLoading && initialNavigation {
			checkoutView.alpha = 0
			spinner.startAnimating()
		}
	}

	@IBAction internal func close() {
		CheckoutView.invalidate()
		delegate?.checkoutDidCancel()
	}
}

extension CheckoutViewController: CheckoutViewDelegate {

	func checkoutViewDidStartNavigation() {
		if initialNavigation {
			spinner.startAnimating()
		}
	}

	func checkoutViewDidFinishNavigation() {
		spinner.stopAnimating()
		initialNavigation = false
		UIView.animate(withDuration: UINavigationController.hideShowBarDuration) { [weak checkoutView] in
			checkoutView?.alpha = 1
		}
	}

	func checkoutViewDidCompleteCheckout() {
		ConfettiCannon.fire(in: view)
		CheckoutView.invalidate()
		delegate?.checkoutDidComplete()
	}

	func checkoutViewDidFailWithError(error: CheckoutError) {
		CheckoutView.invalidate()
		delegate?.checkoutDidFail(error: error)
	}

	func checkoutViewDidClickLink(url: URL) {
		delegate?.checkoutDidClickLink(url: url)
	}
}
