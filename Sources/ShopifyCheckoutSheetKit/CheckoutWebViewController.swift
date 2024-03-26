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
import SafariServices

class CheckoutWebViewController: UIViewController, UIAdaptivePresentationControllerDelegate {

	var fallback: FallbackViewController? = nil

	private func presentFallbackViewController(url: URL) {
        if fallback == nil {
            fallback = FallbackViewController(checkout: url, delegate: self.delegate)
        }

        guard let view = fallback?.createSafariViewController() else {
            print("Failed to create SFSafariViewController")
            return
        }

        DispatchQueue.main.async {
            self.present(view, animated: false)
        }
    }

	// MARK: Properties

	var delegate: CheckoutDelegate

	internal let checkoutView: CheckoutWebView

	internal lazy var progressBar: ProgressBarView = {
		let progressBar = ProgressBarView(frame: .zero)
		progressBar.translatesAutoresizingMaskIntoConstraints = false
		return progressBar
	}()

	internal var initialNavigation: Bool = true

	private let checkoutURL: URL

	private lazy var closeBarButtonItem: UIBarButtonItem = {
		return UIBarButtonItem(
			barButtonSystemItem: .close, target: self, action: #selector(close)
		)
	}()

	internal var progressObserver: NSKeyValueObservation?

	// MARK: Initializers

	public init(checkoutURL url: URL, delegate: CheckoutDelegate) {
		self.checkoutURL = url
		self.delegate = delegate
		self.fallback = FallbackViewController(checkout: url, delegate: self.delegate)

		let checkoutView = CheckoutWebView.for(checkout: url)
		checkoutView.translatesAutoresizingMaskIntoConstraints = false
		checkoutView.scrollView.contentInsetAdjustmentBehavior = .never
		self.checkoutView = checkoutView

		super.init(nibName: nil, bundle: nil)

		title = ShopifyCheckoutSheetKit.configuration.title

		navigationItem.rightBarButtonItem = closeBarButtonItem

		checkoutView.viewDelegate = self

		view.backgroundColor = ShopifyCheckoutSheetKit.configuration.backgroundColor
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		progressObserver?.invalidate()
	}

	// MARK: UIViewController Lifecycle

	override public func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

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

		view.addSubview(progressBar)
		NSLayoutConstraint.activate([
			progressBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
			progressBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
			progressBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
			progressBar.heightAnchor.constraint(equalToConstant: 1)
		])
		view.bringSubviewToFront(progressBar)

		observeProgressChanges()
		loadCheckout()
	}

	internal func observeProgressChanges() {
		progressObserver = checkoutView.observe(\.estimatedProgress, options: [.new]) { [weak self] (_, change) in
			guard let self = self else { return }
			if let newProgress = change.newValue {
				let estimatedProgress = Float(newProgress)
				self.progressBar.setProgress(estimatedProgress, animated: true)
				if estimatedProgress < 1.0 {
					self.progressBar.startAnimating()
				} else {
					self.progressBar.stopAnimating()
				}
			}
		}
	}

	func notifyPresented() {
		checkoutView.checkoutDidPresent = true
	}

	private func loadCheckout() {
		if checkoutView.url == nil {
			initialNavigation = true
			checkoutView.load(checkout: checkoutURL)
			progressBar.startAnimating()
		} else if checkoutView.isLoading && initialNavigation {
			progressBar.startAnimating()
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

		delegate.checkoutDidCancel()
	}
}

extension CheckoutWebViewController: CheckoutWebViewDelegate {

	func checkoutViewDidStartNavigation() {}

	func checkoutViewDidFinishNavigation() {
		initialNavigation = false
		self.progressBar.stopAnimating()
		UIView.animate(withDuration: UINavigationController.hideShowBarDuration) { [weak checkoutView] in
			checkoutView?.alpha = 1
		}
	}

	func checkoutViewDidCompleteCheckout(event: CheckoutCompletedEvent) {
		ConfettiCannon.fire(in: view)
		CheckoutWebView.invalidate()
		delegate.checkoutDidComplete(event: event)
	}

	func checkoutViewDidFailWithError(error: CheckoutError) {
		CheckoutWebView.invalidate()

		let shouldAttemptRecovery = delegate.shouldRecoverFromError(error: error)
		let url = URL(string: "https://shopify.com")!

		if shouldAttemptRecovery {
			self.presentFallbackViewController(url: url)
		} else {
			delegate.checkoutDidFail(error: error)
		}
	}

	func checkoutViewDidClickLink(url: URL) {
		delegate.checkoutDidClickLink(url: url)
	}

	func checkoutViewDidToggleModal(modalVisible: Bool) {
		guard let navigationController = self.navigationController else {
			return
		}

		navigationController.setNavigationBarHidden(modalVisible, animated: true)
	}

	func checkoutViewDidEmitWebPixelEvent(event: PixelEvent) {
		delegate.checkoutDidEmitWebPixelEvent(event: event)
	}

	private func isErrorRecoverable(error: CheckoutError) -> Bool {
		switch error {
		case .authenticationError(_, _, let recoverable),
			.checkoutExpired(_, _, let recoverable),
			.checkoutUnavailable(_, _, let recoverable),
			.configurationError(_, _, let recoverable),
			.sdkError(_, let recoverable):
			return recoverable
		}
	}
}
