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

public class CheckoutWebViewController: UIViewController, UIAdaptivePresentationControllerDelegate {
    public weak var delegate: CheckoutDelegate?
    var checkoutViewDidFailWithErrorCount = 0
    var checkoutView: CheckoutWebView

    lazy var progressBar: ProgressBarView = {
        let progressBar = ProgressBarView(frame: .zero)
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        return progressBar
    }()

    var initialNavigation: Bool = true

    private let checkoutURL: URL
    private let options: CheckoutOptions?

    private lazy var closeBarButtonItem: UIBarButtonItem = {
        if let closeButtonTintColor = ShopifyCheckoutSheetKit.configuration.closeButtonTintColor {
            let image = UIImage(systemName: "xmark.circle.fill")
            let item = UIBarButtonItem(
                image: image,
                style: .plain,
                target: self,
                action: #selector(close)
            )
            item.tintColor = closeButtonTintColor
            return item
        } else {
            return UIBarButtonItem(
                barButtonSystemItem: .close, target: self, action: #selector(close)
            )
        }
    }()

    var progressObserver: NSKeyValueObservation?

    // MARK: Initializers

    public init(checkoutURL url: URL, delegate: CheckoutDelegate? = nil, options: CheckoutOptions? = nil) {
        checkoutURL = url
        self.delegate = delegate
        self.options = options

        let checkoutView = CheckoutWebView.for(checkout: url, options: options)
        checkoutView.translatesAutoresizingMaskIntoConstraints = false
        checkoutView.scrollView.contentInsetAdjustmentBehavior = .never
        self.checkoutView = checkoutView

        super.init(nibName: nil, bundle: nil)

        title = ShopifyCheckoutSheetKit.configuration.title

        navigationItem.rightBarButtonItem = closeBarButtonItem

        checkoutView.viewDelegate = self

        view.backgroundColor = ShopifyCheckoutSheetKit.configuration.backgroundColor
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
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

        observeProgressChanges(checkoutView)
        loadCheckout()
    }

    func observeProgressChanges(_ view: WKWebView) {
        progressObserver = view.observe(\.estimatedProgress, options: [.new]) { [weak self] _, change in
            guard let self else { return }
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

    /// Ensures the bridge connects and presented event fires
    /// Must be called after attaching to hierarchy (viewDidLoad)
    public func notifyPresented() {
        checkoutView.checkoutDidPresent = true
    }

    private func loadCheckout() {
        if checkoutView.url == nil {
            initialNavigation = true
            checkoutView.load(checkout: checkoutURL)
            progressBar.startAnimating()
        } else if checkoutView.isLoading, initialNavigation {
            progressBar.startAnimating()
        }
    }

    @IBAction func close() {
        didCancel()
    }

    public func presentationControllerDidDismiss(_: UIPresentationController) {
        didCancel()
    }

    private func didCancel() {
        if !CheckoutWebView.preloadingActivatedByClient {
            CheckoutWebView.invalidate()
        }

        delegate?.checkoutDidCancel()
    }

    package func presentFallbackViewController(url: URL) {
        progressObserver?.invalidate()
        checkoutView.removeFromSuperview()

        checkoutView = CheckoutWebView.for(checkout: url, recovery: true, options: options)
        checkoutView.translatesAutoresizingMaskIntoConstraints = false
        checkoutView.scrollView.contentInsetAdjustmentBehavior = .never
        checkoutView.viewDelegate = self
        checkoutView.alpha = 1

        view.addSubview(checkoutView)
        NSLayoutConstraint.activate([
            checkoutView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            checkoutView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            checkoutView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            checkoutView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        view.addSubview(progressBar)
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            progressBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            progressBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            progressBar.heightAnchor.constraint(equalToConstant: 1)
        ])
        view.bringSubviewToFront(checkoutView)
        view.bringSubviewToFront(progressBar)

        observeProgressChanges(checkoutView)
        checkoutView.load(checkout: url)
        progressBar.startAnimating()
    }
}

extension CheckoutWebViewController: CheckoutWebViewDelegate {
    func checkoutViewDidStartNavigation() {}

    func checkoutViewDidFinishNavigation() {
        initialNavigation = false
        progressBar.stopAnimating()
        UIView.animate(withDuration: UINavigationController.hideShowBarDuration) { [weak checkoutView] in
            checkoutView?.alpha = 1
        }
    }

    func checkoutViewDidCompleteCheckout(event: CheckoutCompletedEvent) {
        ConfettiCannon.fire(in: view)
        CheckoutWebView.invalidate(disconnect: false)
        delegate?.checkoutDidComplete(event: event)
    }

    func checkoutViewDidFailWithError(error: CheckoutError) {
        checkoutViewDidFailWithErrorCount += 1
        CheckoutWebView.invalidate()
        delegate?.checkoutDidFail(error: error)

        if shouldAttemptRecovery(for: error) {
            presentFallbackViewController(url: checkoutURL)
        } else {
            dismiss(animated: true)
        }
    }

    /// When checkout fails to load we attempt to connect via
    /// recovery mode *once* with CheckoutBridge disabled to avoid
    /// excessive load on potentially degraded services.
    func shouldAttemptRecovery(for error: CheckoutError) -> Bool {
        let isWithinRetryLimit = checkoutViewDidFailWithErrorCount < 2
        let delegateWantsRecovery = delegate?.shouldRecoverFromError(error: error) ?? false

        return isRecoverableError() && isWithinRetryLimit && delegateWantsRecovery
    }

    func checkoutViewDidClickLink(url: URL) {
        delegate?.checkoutDidClickLink(url: url)
    }

    func checkoutViewDidToggleModal(modalVisible: Bool) {
        guard let navigationController else { return }

        navigationController.setNavigationBarHidden(modalVisible, animated: true)
    }

    func checkoutViewDidEmitWebPixelEvent(event: PixelEvent) {
        delegate?.checkoutDidEmitWebPixelEvent(event: event)
    }

    func checkoutViewDidRequestAddressChange(event: AddressChangeRequested) {
        delegate?.checkoutDidRequestAddressChange(event: event)
    }

    private func isRecoverableError() -> Bool {
        /// Reuse of multipass tokens will cause 422 errors. A new token must be generated
        return !CheckoutURL(from: checkoutURL).isMultipassURL()
    }
}
