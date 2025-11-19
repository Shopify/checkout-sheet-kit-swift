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

protocol CheckoutWebViewDelegate: AnyObject {
    func checkoutViewDidStartNavigation()
    func checkoutViewDidStart(event: CheckoutStartEvent)
    func checkoutViewDidCompleteCheckout(event: CheckoutCompletedEvent)
    func checkoutViewDidFinishNavigation()
    func checkoutViewDidClickLink(url: URL)
    func checkoutViewDidFailWithError(error: CheckoutError)
    func checkoutViewDidToggleModal(modalVisible: Bool)
    func checkoutViewDidRequestAddressChange(event: AddressChangeRequested)
    func checkoutViewDidRequestCardChange(event: CheckoutCardChangeRequested)
}

private let deprecatedReasonHeader = "x-shopify-api-deprecated-reason"
private let checkoutLiquidNotSupportedReason = "checkout_liquid_not_supported"

public class CheckoutWebView: WKWebView {
    private static var cache: CacheEntry?
    var timer: Date?

    static var preloadingActivatedByClient: Bool = false

    var checkoutBridge: CheckoutBridgeProtocol.Type = CheckoutBridge.self

    /// A reference to the view is needed when preload is deactivated in order to detach the bridge
    weak static var uncacheableViewRef: CheckoutWebView?

    private var navigationObserver: NSKeyValueObservation?

    var isBridgeAttached = false

    var isRecovery = false {
        didSet {
            isBridgeAttached = false
        }
    }

    var isPreloadingAvailable: Bool {
        return !isRecovery && ShopifyCheckoutSheetKit.configuration.preloading.enabled
    }

    static func `for`(checkout url: URL, recovery: Bool = false, options: CheckoutOptions? = nil) -> CheckoutWebView {
        OSLogger.shared.debug("Creating webview for URL: \(url.sanitizedString), recovery: \(recovery)")

        if recovery {
            CheckoutWebView.invalidate()
            return CheckoutWebView(recovery: true, options: options)
        }

        let cacheKey = "\(url.absoluteString)_\(options?.entryPoint?.rawValue ?? "nil")"

        guard ShopifyCheckoutSheetKit.configuration.preloading.enabled else {
            OSLogger.shared.debug("Preloading not enabled")
            return uncacheableView(options: options)
        }

        guard let cache, cacheKey == cache.key, !cache.isStale else {
            let view = CheckoutWebView(options: options)
            CheckoutWebView.cache = CacheEntry(key: cacheKey, view: view)
            return view
        }

        OSLogger.shared.debug("Presenting cached entry")
        return cache.view
    }

    static func uncacheableView(options: CheckoutOptions? = nil) -> CheckoutWebView {
        uncacheableViewRef?.detachBridge()
        let view = CheckoutWebView(options: options)
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

    /// Used only for testing
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

    private var options: CheckoutOptions?

    // MARK: Initializers

    public init(
        frame: CGRect = .zero, configuration: WKWebViewConfiguration = WKWebViewConfiguration(),
        recovery: Bool = false, options: CheckoutOptions? = nil
    ) {
        OSLogger.shared.debug("Initializing webview, recovery: \(recovery)")
        /// Some external payment providers require ID verification which trigger the camera
        /// This configuration option prevents the camera from opening as a "Live Broadcast".
        configuration.allowsInlineMediaPlayback = true
        configuration.applicationNameForUserAgent = "ShopifyCheckoutPreview:09-12-trigger-addresss-change-request"
        self.options = options

        if recovery {
            /// Uses a non-persistent, private cookie store to avoid cross-instance pollution
            configuration.websiteDataStore = WKWebsiteDataStore.nonPersistent()
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
                    self.viewDelegate?.checkoutViewDidCompleteCheckout(
                        event: createEmptyCheckoutCompletedEvent(id: getOrderIdFromQuery(url: url)))
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
        OSLogger.shared.info("Loading checkout URL: \(url.sanitizedString), isPreload: \(isPreload)")
        var request = URLRequest(
            url: url.withEmbedParam(isRecovery: isRecovery, entryPoint: options?.entryPoint, options: options))

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
    public func userContentController(
        _: WKUserContentController, didReceive message: WKScriptMessage
    ) {
        guard let viewDelegate else { return }

        do {
            let request = try CheckoutBridge.decode(message)
            handleBridgeRequest(request, viewDelegate: viewDelegate)
        } catch {
            OSLogger.shared.error(
                "[CheckoutWebView]: Failed to decode event: \(error.localizedDescription)"
            )
            viewDelegate.checkoutViewDidFailWithError(error: .sdkError(underlying: error))
        }
    }

    private func handleBridgeRequest(_ request: any RPCRequest, viewDelegate: CheckoutWebViewDelegate) {
        switch request {
        case let startRequest as CheckoutStartRequest:
            OSLogger.shared.info("Checkout start event received")
            viewDelegate.checkoutViewDidStart(event: startRequest.params)

        case let completeRequest as CheckoutCompleteRequest:
            OSLogger.shared.info("Checkout completed event received")
            viewDelegate.checkoutViewDidCompleteCheckout(event: completeRequest.params)

        case let modalRequest as CheckoutModalToggledRequest:
            viewDelegate.checkoutViewDidToggleModal(
                modalVisible: modalRequest.params.modalVisible
            )

        case let addressRequest as AddressChangeRequested:
            OSLogger.shared.info(
                "Address change intent event received: \(addressRequest.params.addressType)"
            )
            viewDelegate.checkoutViewDidRequestAddressChange(event: addressRequest)

        case let cardRequest as CheckoutCardChangeRequested:
            OSLogger.shared.info(
                "Card change intent event received"
            )
            viewDelegate.checkoutViewDidRequestCardChange(event: cardRequest)

        case let errorRequest as CheckoutErrorRequest:
            handleCheckoutError(errorRequest)

        // Ignore unsupported requests
        case is UnsupportedRequest:
            OSLogger.shared.debug("Unsupported request: \(String(describing: request.id))")

        default:
            OSLogger.shared.debug(
                "Unknown request type received \(String(describing: request.id))"
            )
        }
    }

    fileprivate func handleCheckoutError(_ errorRequest: CheckoutErrorRequest) {
        guard let viewDelegate else { return }
        guard let error = errorRequest.firstError else { return }
        let code = CheckoutErrorCode.from(error.code)

        switch error.group {
        case .configuration:
            OSLogger.shared.error(
                "Configuration error received: \(error.reason ?? "No message"), code: \(code)"
            )
            viewDelegate.checkoutViewDidFailWithError(
                error: .checkoutUnavailable(
                    message: error.reason ?? "Storefront configuration error.",
                    code: CheckoutUnavailable.clientError(code: code),
                    recoverable: false
                ))
        case .unrecoverable:
            OSLogger.shared.error(
                "Checkout unavailable error received: \(error.reason ?? "No message"), code: \(code)"
            )
            viewDelegate.checkoutViewDidFailWithError(
                error: .checkoutUnavailable(
                    message: error.reason ?? "Checkout unavailable.",
                    code: CheckoutUnavailable.clientError(code: code),
                    recoverable: true
                )
            )
        case .expired:
            OSLogger.shared.info(
                "Checkout expired error received: \(error.reason ?? "No message"), code: \(code)"
            )
            viewDelegate.checkoutViewDidFailWithError(
                error: .checkoutExpired(
                    message: error.reason ?? "Checkout has expired.", code: code
                ))
        default:
            OSLogger.shared.error("Unknown error group received: \(error.group)")
        }
    }
}

extension CheckoutWebView: WKNavigationDelegate {
    public func webView(
        _: WKWebView, decidePolicyFor action: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = action.request.url else {
            decisionHandler(.allow)
            return
        }

        if isExternalLink(action) || CheckoutURL(from: url).isDeepLink() {
            OSLogger.shared.debug(
                "External or deep link clicked: \(url.sanitizedString) - request intercepted")
            viewDelegate?.checkoutViewDidClickLink(url: removeExternalParam(url))
            decisionHandler(.cancel)
            return
        }

        if handleEmbedParamIfNeeded(for: action, url: url) {
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }

    public func webView(
        _: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
    ) {
        if let response = navigationResponse.response as? HTTPURLResponse {
            decisionHandler(handleResponse(response))
            return
        }
        decisionHandler(.allow)
    }

    func handleResponse(_ response: HTTPURLResponse) -> WKNavigationResponsePolicy {
        let allowRecoverable = !isRecovery
        let headers = response.allHeaderFields
        let statusCode = response.statusCode
        let errorMessageForStatusCode = HTTPURLResponse.localizedString(
            forStatusCode: statusCode
        )

        guard isCheckout(url: response.url) else {
            return .allow
        }

        if statusCode >= 400 {
            /// Invalidate cache for any sort of error
            CheckoutWebView.invalidate()

            OSLogger.shared.debug(
                "Handling response for URL: \(response.url?.sanitizedString ?? "unknown URL"), status code: \(statusCode)"
            )

            switch statusCode {
            case 401:
                OSLogger.shared.debug("Unauthorized access (401)")
                viewDelegate?.checkoutViewDidFailWithError(
                    error: .checkoutUnavailable(
                        message: errorMessageForStatusCode,
                        code: CheckoutUnavailable.httpError(statusCode: statusCode),
                        recoverable: false
                    ))
            case 404:
                OSLogger.shared.debug("Not found (404)")
                if let reason = headers[deprecatedReasonHeader] as? String,
                   reason.lowercased() == checkoutLiquidNotSupportedReason
                {
                    viewDelegate?.checkoutViewDidFailWithError(
                        error: .configurationError(
                            message:
                            "Storefronts using checkout.liquid are not supported. Please upgrade to Checkout Extensibility.",
                            code: CheckoutErrorCode.checkoutLiquidNotMigrated, recoverable: false
                        ))
                } else {
                    viewDelegate?.checkoutViewDidFailWithError(
                        error: .checkoutUnavailable(
                            message: errorMessageForStatusCode,
                            code: CheckoutUnavailable.httpError(statusCode: statusCode),
                            recoverable: false
                        ))
                }
            case 410:
                OSLogger.shared.debug("Gone (410)")
                viewDelegate?.checkoutViewDidFailWithError(
                    error: .checkoutExpired(
                        message: "Checkout has expired.", code: CheckoutErrorCode.cartExpired
                    ))
            case 500 ... 599:
                OSLogger.shared.debug("Server error (5xx)")
                viewDelegate?.checkoutViewDidFailWithError(
                    error: .checkoutUnavailable(
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
                    ))
            }

            return .cancel
        }

        return .allow
    }

    public func webView(_ webView: WKWebView, didStartProvisionalNavigation _: WKNavigation!) {
        let url = webView.url?.sanitizedString ?? ""
        OSLogger.shared.info("Started provisional navigation - url:\(url)")
        timer = Date()
        viewDelegate?.checkoutViewDidStartNavigation()
    }

    /// No need to emit checkoutDidFail error here as it has been handled in handleResponse already
    public func webView(
        _ webView: WKWebView, didFailProvisionalNavigation _: WKNavigation!, withError error: Error
    ) {
        let url = webView.url?.sanitizedString ?? ""
        OSLogger.shared.debug(
            "Failed provisional navigation with error: \(error.localizedDescription) url:\(url)")
        timer = nil
    }

    public func webView(_: WKWebView, didFinish _: WKNavigation!) {
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
                    ))
            }
        }
        checkoutDidLoad = true
        timer = nil
    }

    public func webView(_: WKWebView, didFail _: WKNavigation!, withError error: Error) {
        timer = nil

        let nsError = error as NSError

        OSLogger.shared.debug(
            "WebView navigation failed with error: description:\(nsError.localizedDescription) domain:\(nsError.domain) code:\(nsError.code)"
        )

        /// Ignore cancelled redirects
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
        guard let url = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return false
        }

        guard
            let openExternally = url.queryItems?.first(where: { $0.name == "open_externally" })?
            .value
        else { return false }

        return openExternally.lowercased() == "true" || openExternally == "1"
    }

    private func removeExternalParam(_ url: URL) -> URL {
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }
        urlComponents.queryItems = urlComponents.queryItems?.filter {
            !($0.name == "open_externally")
        }
        return urlComponents.url ?? url
    }

    private func handleEmbedParamIfNeeded(for action: WKNavigationAction, url: URL) -> Bool {
        guard
            let scheme = url.scheme?.lowercased(),
            scheme == "http" || scheme == "https"
        else {
            return false
        }

        guard action.targetsMainFrame,
              url.needsEmbedUpdate(isRecovery: isRecovery, entryPoint: options?.entryPoint, options: options)
        else {
            return false
        }

        var updatedRequest = action.request
        updatedRequest.url = url.withEmbedParam(
            isRecovery: isRecovery,
            entryPoint: options?.entryPoint,
            options: options
        )
        load(updatedRequest)
        return true
    }

    private func isCheckout(url: URL?) -> Bool {
        return self.url == url
    }

    private func getOrderIdFromQuery(url: URL) -> String? {
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return nil
        }

        let queryItems = urlComponents.queryItems ?? []

        for item in queryItems where item.name == "order_id" {
            return item.value
        }

        return nil
    }
}

extension WKNavigationAction {
    fileprivate var targetsMainFrame: Bool {
        if let targetFrame {
            return targetFrame.isMainFrame
        }

        if let mainDocumentURL = request.mainDocumentURL {
            return mainDocumentURL == request.url
        }

        return true
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

extension URL {
    /// Returns a sanitized URL string safe for logging by redacting sensitive authentication data
    internal var sanitizedString: String {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
            return absoluteString
        }

        // Redact authentication value from embed parameter
        if let embedIndex = components.queryItems?.firstIndex(where: { $0.name == EmbedQueryParamKey.embed }),
           let embedValue = components.queryItems?[embedIndex].value
        {
            let sanitizedEmbed = embedValue
                .split(separator: ",")
                .map { field -> String in
                    if field.starts(with: "\(EmbedFieldKey.authentication)=") {
                        return "\(EmbedFieldKey.authentication)=\(EmbedFieldValue.redacted)"
                    }
                    return String(field)
                }
                .joined(separator: ",")

            components.queryItems?[embedIndex] = URLQueryItem(name: EmbedQueryParamKey.embed, value: sanitizedEmbed)
        }

        return components.url?.absoluteString ?? absoluteString
    }
}
