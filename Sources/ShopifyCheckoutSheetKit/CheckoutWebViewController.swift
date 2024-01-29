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

class CheckoutWebViewController: UIViewController, UIAdaptivePresentationControllerDelegate {

	// MARK: Properties

	weak var delegate: CheckoutDelegate?

	internal let checkoutView: CheckoutWebView

	internal lazy var spinner: SpinnerView = {
		let spinner = SpinnerView(frame: .zero)
		spinner.translatesAutoresizingMaskIntoConstraints = false
		return spinner
	}()

	internal lazy var progress: IndeterminateProgressBarView = {
		let progress = IndeterminateProgressBarView(frame: .zero)
		progress.translatesAutoresizingMaskIntoConstraints = false
		return progress
	}()

	internal var initialNavigation: Bool = true

	private let checkoutURL: URL

	private lazy var closeBarButtonItem: UIBarButtonItem = {
		return UIBarButtonItem(
			barButtonSystemItem: .close, target: self, action: #selector(close)
		)
	}()

	// MARK: Initializers

	public init(checkoutURL url: URL, delegate: CheckoutDelegate? = nil) {
		self.checkoutURL = url
		self.delegate = delegate

		let checkoutView = CheckoutWebView.for(checkout: url)
		checkoutView.translatesAutoresizingMaskIntoConstraints = false
		checkoutView.scrollView.contentInsetAdjustmentBehavior = .never
		self.checkoutView = checkoutView

		super.init(nibName: nil, bundle: nil)

		title = "Checkout"

		navigationItem.rightBarButtonItem = closeBarButtonItem

		checkoutView.viewDelegate = self

		view.backgroundColor = ShopifyCheckoutSheetKit.configuration.backgroundColor
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		if progressBarEnabled() {
			checkoutView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
		}
	}

	// MARK: UIViewController Lifecycle

	override public func viewWillAppear(_ animated: Bool) {
		view.backgroundColor = ShopifyCheckoutSheetKit.configuration.backgroundColor
	}

	override public func viewDidLoad() {
		super.viewDidLoad()

		view.addSubview(checkoutView)
		NSLayoutConstraint.activate([
			checkoutView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
			checkoutView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			checkoutView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			checkoutView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
		])

		if progressBarEnabled() {
			view.addSubview(progress)
			NSLayoutConstraint.activate([
				progress.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
				progress.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
				progress.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
				progress.heightAnchor.constraint(equalToConstant: 6)
			])
			view.bringSubviewToFront(progress)
			checkoutView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
		} else {
			view.addSubview(spinner)
			NSLayoutConstraint.activate([
				spinner.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
				spinner.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
			])
			view.bringSubviewToFront(spinner)
		}

		if checkoutView.isLoading == false {
			self.displayNativePayButton()
		}

		loadCheckout()
	}

	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		if keyPath == #keyPath(WKWebView.estimatedProgress) {
			let estimatedProgress = Float(checkoutView.estimatedProgress)
			progress.setProgress(estimatedProgress, animated: true)
			if estimatedProgress < 1.0 {
				progress.startAnimating()
			} else {
				progress.stopAnimating()
			}
		}
	}

	func notifyPresented() {
		checkoutView.checkoutDidPresent = true
	}

	private func displayNativePayButton() {
		guard ShopifyCheckoutSheetKit.configuration.payButton.enabled else {
			if let payButtonView = self.view.viewWithTag(1337) {
				payButtonView.removeFromSuperview()
			}
			return
		}
		let payButtonView = PayButtonView()
		payButtonView.tag = 1337
		payButtonView.translatesAutoresizingMaskIntoConstraints = false

		view.addSubview(payButtonView)

		NSLayoutConstraint.activate([
			payButtonView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			payButtonView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			payButtonView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
		])

		self.checkoutView.evaluateJavaScript("""
			let style = document.createElement('style');
			document.head.appendChild(style);
			style.appendChild(document.createTextNode('#pay-button-container { display: none !important; }'));
			style.appendChild(document.createTextNode('#sticky-pay-button-container, .XlHGh, #checkout-sdk-pay-button-container { display: none !important; } footer {padding-bottom: 6em !important; padding-block-end: 9em !important}'));

			let shopPayButton = document.querySelector('button[aria-label="Pay now"]')
			if (shopPayButton) shopPayButton.style.display = "none";
		""")

		payButtonView.buttonPressedAction = {
			self.checkoutView.evaluateJavaScript("document.querySelector('#pay-button-container button')?.click()")
			self.checkoutView.evaluateJavaScript("document.querySelector('button[aria-label=\"Pay now\"]')?.click()")
			self.checkoutView.evaluateJavaScript("window.MobileCheckoutSdk.dispatchMessage('submitPayment');")
		}
	}

	public func removeNativePayButton() {
		if ShopifyCheckoutSheetKit.configuration.payButton.enabled {
			if let payButtonView = self.view.viewWithTag(1337) {
				payButtonView.removeFromSuperview()
			}
		}
	}

	private func progressBarEnabled() -> Bool {
		return ShopifyCheckoutSheetKit.configuration.progressBarEnabled
	}

	private func loadCheckout() {
		if checkoutView.url == nil {
			if !progressBarEnabled() {
				checkoutView.alpha = 0
			}
			initialNavigation = true
			checkoutView.load(checkout: checkoutURL)

			if progressBarEnabled() {
				progress.startAnimating()
			}
		} else if checkoutView.isLoading && initialNavigation {
			if progressBarEnabled() {
				progress.startAnimating()
			} else {
				checkoutView.alpha = 0
				spinner.startAnimating()
			}
		}
	}

	@IBAction internal func close() {
		didCancel()
	}

	public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
		didCancel()
	}

	private func didCancel() {
		if !CheckoutWebView.preloadingActivatedByClient {
			CheckoutWebView.invalidate()
		}
		delegate?.checkoutDidCancel()
	}
}

extension CheckoutWebViewController: CheckoutWebViewDelegate {
	func checkoutViewDidStartNavigation() {
		if initialNavigation && !checkoutView.checkoutDidLoad {
			if !progressBarEnabled() {
				spinner.startAnimating()
			}
		}
	}

	func checkoutViewDidFinishNavigation() {
		initialNavigation = false

		if !progressBarEnabled() {
			spinner.stopAnimating()
			UIView.animate(withDuration: UINavigationController.hideShowBarDuration) { [weak checkoutView] in
				checkoutView?.alpha = 1
				if ShopifyCheckoutSheetKit.configuration.payButton.enabled {
					self.displayNativePayButton()
				}
			}
		}
	}

	func checkoutViewDidCompleteCheckout() {
		ConfettiCannon.fire(in: view)
		CheckoutWebView.invalidate()

		self.removeNativePayButton()

		delegate?.checkoutDidComplete()
	}

	func checkoutViewDidFailWithError(error: CheckoutError) {
		CheckoutWebView.invalidate()
		delegate?.checkoutDidFail(error: error)
	}

	func checkoutViewDidClickLink(url: URL) {
		delegate?.checkoutDidClickLink(url: url)
	}

	func checkoutViewDidToggleModal(modalVisible: Bool) {
		guard let navigationController = self.navigationController else { return }
		navigationController.setNavigationBarHidden(modalVisible, animated: true)
	}

	func checkoutViewDidEmitWebPixelEvent(event: PixelEvent) {
		delegate?.checkoutDidEmitWebPixelEvent(event: event)
	}
}
