import UIKit
import WebKit

protocol CheckoutWebViewDelegate: AnyObject {
    func checkoutViewDidStartNavigation()
    func checkoutViewDidFinishNavigation()
    func checkoutViewDidClickLink(url: URL)
    func checkoutViewDidFailWithError(error: CheckoutError)
}

class CheckoutWebView: WKWebView {
    private static var cache: CacheEntry?
    var timer: Date?

    static var preloadingActivatedByClient: Bool = false

    var checkoutBridge: CheckoutBridgeProtocol.Type = CheckoutBridge.self

    weak static var uncacheableViewRef: CheckoutWebView?

    private var navigationObserver: NSKeyValueObservation?

    var isBridgeAttached = false

    var client: (any CheckoutCommunicationProtocol)?

    var isRecovery = false {
        didSet {
            isBridgeAttached = false
        }
    }

    var isPreloadingAvailable: Bool {
        return !isRecovery && ShopifyCheckoutSheetKit.configuration.preloading.enabled
    }

    static func `for`(checkout url: URL, recovery: Bool = false, entryPoint: MetaData.EntryPoint? = nil) -> CheckoutWebView {
        OSLogger.shared.debug("Creating webview for URL: \(url.absoluteString), recovery: \(recovery)")

        if recovery {
            CheckoutWebView.invalidate()
            return CheckoutWebView(recovery: true, entryPoint: entryPoint)
        }

        let cacheKey = "\(url.absoluteString)_\(entryPoint?.rawValue ?? "nil")"

        guard ShopifyCheckoutSheetKit.configuration.preloading.enabled else {
            OSLogger.shared.debug("Preloading not enabled")
            return uncacheableView(entryPoint: entryPoint)
        }

        guard let cache, cacheKey == cache.key, !cache.isStale else {
            let view = CheckoutWebView(entryPoint: entryPoint)
            CheckoutWebView.cache = CacheEntry(key: cacheKey, view: view)
            return view
        }

        OSLogger.shared.debug("Presenting cached entry")
        return cache.view
    }

    static func uncacheableView(entryPoint: MetaData.EntryPoint? = nil) -> CheckoutWebView {
        uncacheableViewRef?.detachBridge()
        let view = CheckoutWebView(entryPoint: entryPoint)
        uncacheableViewRef = view
        return view
    }

    static func invalidate(disconnect: Bool = true) {
        OSLogger.shared.debug("Invalidating cache, disconnect: \(disconnect)")
        preloadingActivatedByClient = false

        if disconnect {
            cache?.view.detachBridge()
        }

        cache = nil
    }

    static func hasCacheEntry() -> Bool {
        return cache != nil
    }

    // MARK: Properties

    weak var viewDelegate: CheckoutWebViewDelegate?
    var presentedEventDidDispatch = false
    var checkoutDidPresent: Bool = false {
        didSet {
            dispatchPresentedMessage(checkoutDidLoad, checkoutDidPresent)
        }
    }

    var checkoutDidLoad: Bool = false {
        didSet {
            dispatchPresentedMessage(checkoutDidLoad, checkoutDidPresent)
        }
    }

    var isPreloadRequest: Bool = false

    private var entryPoint: MetaData.EntryPoint?

    // MARK: Initializers

    init(frame: CGRect = .zero, configuration: WKWebViewConfiguration = WKWebViewConfiguration(), recovery: Bool = false, entryPoint: MetaData.EntryPoint? = nil) {
        OSLogger.shared.debug("Initializing webview, recovery: \(recovery)")
        configuration.allowsInlineMediaPlayback = true
        self.entryPoint = entryPoint

        if recovery {
            configuration.websiteDataStore = WKWebsiteDataStore.nonPersistent()
            configuration.applicationNameForUserAgent = CheckoutBridge.recoveryAgent(entryPoint: entryPoint)
        } else {
            // Sending this user agent makes checkout think we're subscribing to the old protocol
//            configuration.applicationNameForUserAgent = CheckoutBridge.applicationName(entryPoint: entryPoint)
        }

        isRecovery = recovery
        super.init(frame: frame, configuration: configuration)

        #if DEBUG
            if #available(iOS 16.4, *) {
                isInspectable = true
            }
        #endif

        navigationDelegate = self
        translatesAutoresizingMaskIntoConstraints = false
        scrollView.contentInsetAdjustmentBehavior = .never

        setBackgroundColor()

        if recovery {
            observeNavigationChanges()
        } else {
            connectBridge()
        }
    }

    deinit {
        OSLogger.shared.debug("De-allocating webview")

        if isRecovery {
            navigationObserver?.invalidate()
        } else {
            detachBridge()
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func connectBridge() {
        OSLogger.shared.debug("Bridging communication to checkout")
        configuration.userContentController
            .add(MessageHandler(delegate: self), name: CheckoutBridge.messageHandler)

        isBridgeAttached = true
    }

    public func detachBridge() {
        OSLogger.shared.debug("Detaching bridge")
        configuration.userContentController
            .removeScriptMessageHandler(forName: CheckoutBridge.messageHandler)
        isBridgeAttached = false
    }

    private func setBackgroundColor() {
        isOpaque = false
        backgroundColor = ShopifyCheckoutSheetKit.configuration.backgroundColor

        if #available(iOS 15.0, *) {
            underPageBackgroundColor = ShopifyCheckoutSheetKit.configuration.backgroundColor
        }
    }

    private func observeNavigationChanges() {
        navigationObserver = observe(\.url, options: [.new]) { [weak self] _, change in
            guard let self else { return }

            if let url = change.newValue as? URL {
                if CheckoutURL(from: url).isConfirmationPage() {
                    CheckoutWebView.invalidate(disconnect: false)
                    navigationObserver?.invalidate()
                }
            }
        }
    }

    func instrument(_ payload: InstrumentationPayload) {
        OSLogger.shared.debug("Emitting instrumentation event with payload: \(payload)")
        checkoutBridge.instrument(self, payload)
    }

    // MARK: -

    func load(checkout url: URL, isPreload: Bool = false) {
        OSLogger.shared.info("Loading checkout URL: \(url.absoluteString), isPreload: \(isPreload)")
        var request = URLRequest(url: url)

        if isPreload, isPreloadingAvailable {
            isPreloadRequest = true
            request.setValue("prefetch", forHTTPHeaderField: "Shopify-Purpose")
        }

        load(request)
    }

    private func dispatchPresentedMessage(_ checkoutDidLoad: Bool, _ checkoutDidPresent: Bool) {
        if checkoutDidLoad, checkoutDidPresent, isBridgeAttached {
            OSLogger.shared.info("Emitting presented event to checkout")
            CheckoutBridge.sendMessage(self, messageName: "presented", messageBody: nil)
            presentedEventDidDispatch = true
        }
    }
}

extension CheckoutWebView: WKScriptMessageHandler {
    func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? String else {
            print("[ECP-DEBUG] message body is not a string, type: \(type(of: message.body))")
            return
        }

        print("[ECP-DEBUG] raw message: \(body)")

        if let data = body.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        {
            let method = json["method"] as? String ?? "nil"
            let id = json["id"] as? String ?? "nil"
            print("[ECP-DEBUG] method: \(method), id: \(id)")

            if method == "ec.ready", let reqId = json["id"] as? String {
                print("[ECP-DEBUG] responding to ec.ready with id: \(reqId)")
                let response = "{\"jsonrpc\":\"2.0\",\"id\":\"\(reqId)\",\"result\":{}}"
                CheckoutBridge.sendResponse(self, messageBody: response)
            }
        } else {
            print("[ECP-DEBUG] failed to parse JSON from body")
        }

        guard let client else {
            print("[ECP-DEBUG] no bridge client registered")
            return
        }

        Task {
            if let response = await client.process(body) {
                print("[ECP-DEBUG] client responded: \(response)")
                CheckoutBridge.sendResponse(self, messageBody: response)
            } else {
                print("[ECP-DEBUG] client returned nil for method")
            }
        }
    }
}

extension CheckoutWebView: WKNavigationDelegate {
    func webView(_: WKWebView, decidePolicyFor action: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = action.request.url else {
            decisionHandler(.allow)
            return
        }

        if isExternalLink(action) || CheckoutURL(from: url).isDeepLink() {
            OSLogger.shared.debug("External or deep link clicked: \(url.absoluteString) - request intercepted")
            viewDelegate?.checkoutViewDidClickLink(url: removeExternalParam(url))
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }

    func webView(_: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if let response = navigationResponse.response as? HTTPURLResponse {
            decisionHandler(handleResponse(response))
            return
        }
        decisionHandler(.allow)
    }

    func handleResponse(_ response: HTTPURLResponse) -> WKNavigationResponsePolicy {
        let allowRecoverable = !isRecovery
        let statusCode = response.statusCode
        let errorMessageForStatusCode = HTTPURLResponse.localizedString(
            forStatusCode: statusCode
        )

        guard isCheckout(url: response.url) else {
            return .allow
        }

        if statusCode >= 400 {
            CheckoutWebView.invalidate()

            OSLogger.shared.debug("Handling response for URL: \(response.url?.absoluteString ?? "unknown URL"), status code: \(statusCode)")

            switch statusCode {
            case 401:
                OSLogger.shared.debug("Unauthorized access (401)")
                viewDelegate?.checkoutViewDidFailWithError(error: .checkoutUnavailable(message: errorMessageForStatusCode, code: CheckoutUnavailable.httpError(statusCode: statusCode), recoverable: false))
            case 404:
                OSLogger.shared.debug("Not found (404)")
                viewDelegate?.checkoutViewDidFailWithError(error: .checkoutUnavailable(
                    message: errorMessageForStatusCode,
                    code: CheckoutUnavailable.httpError(statusCode: statusCode),
                    recoverable: false
                ))
            case 410:
                OSLogger.shared.debug("Gone (410)")
                viewDelegate?.checkoutViewDidFailWithError(error: .checkoutExpired(message: "Checkout has expired.", code: CheckoutErrorCode.cartExpired))
            case 500 ... 599:
                OSLogger.shared.debug("Server error (5xx)")
                viewDelegate?.checkoutViewDidFailWithError(error: .checkoutUnavailable(
                    message: errorMessageForStatusCode,
                    code: CheckoutUnavailable.httpError(statusCode: statusCode),
                    recoverable: allowRecoverable
                ))
            default:
                OSLogger.shared.debug("\(statusCode) error received")
                viewDelegate?.checkoutViewDidFailWithError(
                    error: .checkoutUnavailable(
                        message: errorMessageForStatusCode,
                        code: CheckoutUnavailable.httpError(statusCode: statusCode),
                        recoverable: false
                    )
                )
            }

            return .cancel
        }

        return .allow
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation _: WKNavigation!) {
        let url = webView.url?.absoluteString ?? ""
        OSLogger.shared.info("Started provisional navigation - url:\(url)")
        timer = Date()
        viewDelegate?.checkoutViewDidStartNavigation()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation _: WKNavigation!, withError error: Error) {
        let url = webView.url?.absoluteString ?? ""
        OSLogger.shared.debug("Failed provisional navigation with error: \(error.localizedDescription) url:\(url)")
        timer = nil
    }

    func webView(_: WKWebView, didFinish _: WKNavigation!) {
        viewDelegate?.checkoutViewDidFinishNavigation()

        if let startTime = timer {
            let endTime = Date()
            let diff = endTime.timeIntervalSince(startTime)
            let message = "Loaded checkout in \(String(format: "%.2f", diff))s"
            let preload = String(isPreloadRequest)

            ShopifyCheckoutSheetKit.configuration.logger.log(message)

            if isBridgeAttached {
                instrument(
                    InstrumentationPayload(
                        name: "checkout_finished_loading",
                        value: Int(diff * 1000),
                        type: .histogram,
                        tags: ["preloading": preload]
                    )
                )
            }
        }
        checkoutDidLoad = true
        timer = nil

        #if DEBUG
            let debugScript = """
            (function() {
                var info = {
                    hasECP: typeof window.EmbeddedCheckoutProtocol !== 'undefined',
                    ecpKeys: typeof window.EmbeddedCheckoutProtocol === 'object' ? Object.keys(window.EmbeddedCheckoutProtocol) : [],
                    hasWebkit: typeof window.webkit !== 'undefined',
                    hasMessageHandlers: typeof window.webkit?.messageHandlers !== 'undefined',
                    hasConsumer: typeof window.webkit?.messageHandlers?.EmbeddedCheckoutProtocolConsumer !== 'undefined',
                    hasMobileSDK: typeof window.MobileCheckoutSdk !== 'undefined',
                    url: window.location.href
                };
                return JSON.stringify(info);
            })();
            """
            evaluateJavaScript(debugScript) { result, error in
                if let error {
                    print("[ECP-DEBUG] JS eval error: \(error.localizedDescription)")
                }
                if let result {
                    print("[ECP-DEBUG] page state: \(result)")
                }
            }
        #endif
    }

    func webView(_: WKWebView, didFail _: WKNavigation!, withError error: Error) {
        timer = nil

        let nsError = error as NSError

        OSLogger.shared.debug("WebView navigation failed with error: description:\(nsError.localizedDescription) domain:\(nsError.domain) code:\(nsError.code)")

        if nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorCancelled {
            OSLogger.shared.debug("Ignoring cancelled URL redirect. code:NSURLErrorCancelled")
            return
        }

        viewDelegate?.checkoutViewDidFailWithError(
            error: .sdkError(underlying: error, recoverable: !isRecovery)
        )
    }

    private func isExternalLink(_ action: WKNavigationAction) -> Bool {
        if action.navigationType == .linkActivated && action.targetFrame == nil {
            return true
        }

        guard let url = action.request.url else { return false }
        guard let url = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return false }

        guard let openExternally = url.queryItems?.first(where: { $0.name == "open_externally" })?.value else { return false }

        return openExternally.lowercased() == "true" || openExternally == "1"
    }

    private func removeExternalParam(_ url: URL) -> URL {
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }
        urlComponents.queryItems = urlComponents.queryItems?.filter { !($0.name == "open_externally") }
        return urlComponents.url ?? url
    }

    private func isCheckout(url: URL?) -> Bool {
        return self.url == url
    }
}

extension CheckoutWebView {
    fileprivate struct CacheEntry {
        let key: String

        let view: CheckoutWebView

        private let timestamp = Date()

        private let timeout = TimeInterval(60 * 5)

        var isStale: Bool {
            abs(timestamp.timeIntervalSinceNow) >= timeout
        }
    }
}
