import UIKit
import WebKit

class CheckoutWebViewController: UIViewController, UIAdaptivePresentationControllerDelegate {
    var onCancel: (() -> Void)?
    var onFail: ((CheckoutError) -> Void)?
    var bridgeHandler: (any CheckoutCommunicationProtocol)?

    var checkoutViewDidFailWithErrorCount = 0
    var checkoutView: CheckoutWebView

    lazy var progressBar: ProgressBarView = {
        let progressBar = ProgressBarView(frame: .zero)
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        return progressBar
    }()

    var initialNavigation: Bool = true

    private let checkoutURL: URL

    private lazy var closeBarButtonItem: UIBarButtonItem = {
        if let closeButtonTintColor = ShopifyCheckoutSheetKit.configuration.closeButtonTintColor {
            var item: UIBarButtonItem

            if #available(iOS 26.0, *) {
                item = UIBarButtonItem(
                    image: UIImage(systemName: "xmark"),
                    style: .plain,
                    target: self,
                    action: #selector(close)
                )
            } else {
                item = UIBarButtonItem(
                    image: UIImage(systemName: "xmark.circle.fill"),
                    style: .plain,
                    target: self,
                    action: #selector(close)
                )
            }

            item.tintColor = closeButtonTintColor
            return item
        }

        return UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(close)
        )
    }()

    var progressObserver: NSKeyValueObservation?

    // MARK: Initializers

    public init(checkoutURL url: URL, bridgeHandler: (any CheckoutCommunicationProtocol)? = nil, entryPoint: MetaData.EntryPoint? = nil) {
        checkoutURL = url
        self.bridgeHandler = bridgeHandler

        let checkoutView = CheckoutWebView.for(checkout: url, entryPoint: entryPoint)
        checkoutView.translatesAutoresizingMaskIntoConstraints = false
        checkoutView.scrollView.contentInsetAdjustmentBehavior = .never
        checkoutView.bridgeHandler = bridgeHandler
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

    func notifyPresented() {
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

        onCancel?()
    }

    package func presentFallbackViewController(url: URL) {
        progressObserver?.invalidate()
        checkoutView.removeFromSuperview()

        checkoutView = CheckoutWebView.for(checkout: url, recovery: true)
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

    func checkoutViewDidFailWithError(error: CheckoutError) {
        checkoutViewDidFailWithErrorCount += 1
        CheckoutWebView.invalidate()
        onFail?(error)

        if shouldAttemptRecovery(for: error) {
            presentFallbackViewController(url: checkoutURL)
        } else {
            dismiss(animated: true)
        }
    }

    func shouldAttemptRecovery(for error: CheckoutError) -> Bool {
        let isWithinRetryLimit = checkoutViewDidFailWithErrorCount < 2
        return isRecoverableError() && isWithinRetryLimit && error.isRecoverable
    }

    func checkoutViewDidClickLink(url: URL) {
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    private func isRecoverableError() -> Bool {
        return !CheckoutURL(from: checkoutURL).isMultipassURL()
    }
}
