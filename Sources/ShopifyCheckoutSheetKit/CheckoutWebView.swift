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
    func checkoutViewDidCompleteCheckout(event: CheckoutCompletedEvent)
    func checkoutViewDidFinishNavigation()
    func checkoutViewDidClickLink(url: URL)
    func checkoutViewDidFailWithError(error: CheckoutError)
    func checkoutViewDidToggleModal(modalVisible: Bool)
    func checkoutViewDidEmitWebPixelEvent(event: PixelEvent)
    
    // MARK: - Embedded Checkout Events (Schema 2025-04)
    func checkoutViewDidChangeState(state: CheckoutStatePayload)
    func checkoutViewDidComplete(payload: CheckoutCompletePayload)
    func checkoutViewDidFail(errors: [ErrorPayload])
    func checkoutViewDidEmitWebPixelEvent(payload: WebPixelsPayload)
}

class CheckoutWebView: WKWebView {
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

    private var entryPoint: MetaData.EntryPoint?
    
    var checkoutOptions: CheckoutOptions?

    // MARK: Initializers

    init(frame: CGRect = .zero, configuration: WKWebViewConfiguration = WKWebViewConfiguration(), recovery: Bool = false, entryPoint: MetaData.EntryPoint? = nil) {
        OSLogger.shared.debug("Initializing webview, recovery: \(recovery)")
        /// Some external payment providers require ID verification which trigger the camera
        /// This configuration option prevents the camera from opening as a "Live Broadcast".
        configuration.allowsInlineMediaPlayback = true
        self.entryPoint = entryPoint

        if recovery {
            /// Uses a non-persistent, private cookie store to avoid cross-instance pollution
            configuration.websiteDataStore = WKWebsiteDataStore.nonPersistent()
            configuration.applicationNameForUserAgent = CheckoutBridge.recoveryAgent(entryPoint: entryPoint)
        } else {
            /// Set the User-Agent in non-recovery view
            configuration.applicationNameForUserAgent = CheckoutBridge.applicationName(entryPoint: entryPoint)
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
                    self.viewDelegate?.checkoutViewDidCompleteCheckout(event: createEmptyCheckoutCompletedEvent(id: getOrderIdFromQuery(url: url)))
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
        
        // Build URL with embed query parameter if needed
        let finalURL = buildCheckoutURL(from: url, options: checkoutOptions)
        var request = URLRequest(url: finalURL)

        if isPreload, isPreloadingAvailable {
            isPreloadRequest = true
            request.setValue("prefetch", forHTTPHeaderField: "Shopify-Purpose")
        }

        load(request)
    }
    
    private func buildCheckoutURL(from originalURL: URL, options: CheckoutOptions?) -> URL {
        // Get authentication token if provided
        var authToken: String?
        if let appAuth = options?.appAuthentication {
            switch appAuth {
            case .token(let token):
                authToken = token
            }
        }
        
        // Only add embed parameter if we have options (indicating embedded checkout)
        guard options != nil else {
            return originalURL
        }

        // Get embed params string with authentication token
        let embedValue = CheckoutBridge.embedParams(authToken: authToken)

        // Add the embed parameter to the URL
        var components = URLComponents(url: originalURL, resolvingAgainstBaseURL: false)
        var queryItems = components?.queryItems ?? []
        queryItems.append(URLQueryItem(name: "embed", value: embedValue))
        components?.queryItems = queryItems

        return components?.url ?? originalURL
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
            OSLogger.shared.error("Invalid script message body")
            return
        }

        // Try to decode as JSON first for embedded checkout events
        if let eventData = try? JSONSerialization.jsonObject(with: Data(body.utf8), options: []) as? [String: Any],
           let eventName = eventData["name"] as? String {
            
            switch eventName {
            case "stateChange":
                OSLogger.shared.info("Embedded checkout state change event received")
                handleStateChangeEvent(eventData)
                return
            case "completed":
                OSLogger.shared.info("Embedded checkout completed event received")  
                if handleEmbeddedCompletedEvent(eventData) {
                    return
                }
                // Fall through to legacy handling if embedded handling fails
            case "error":
                OSLogger.shared.error("Embedded checkout error event received")
                if handleEmbeddedErrorEvent(eventData) {
                    return
                }
                // Fall through to legacy handling if embedded handling fails
            case "webPixels":
                OSLogger.shared.info("Embedded checkout web pixels event received")
                handleEmbeddedWebPixelEvent(eventData)
                return
            case "checkoutBlockingEvent":
                if let modalVisible = eventData["body"] as? String, let visible = Bool(modalVisible) {
                    viewDelegate?.checkoutViewDidToggleModal(modalVisible: visible)
                }
                return
            default:
                break
            }
        }
        
        // Fall back to legacy CheckoutBridge decoding for existing events
        do {
            switch try CheckoutBridge.decode(message) {
            /// Completed event  
            case let .checkoutComplete(checkoutCompletedEvent):
                OSLogger.shared.info("Legacy checkout completed event received")
                viewDelegate?.checkoutViewDidCompleteCheckout(event: checkoutCompletedEvent)
            /// Error: Checkout unavailable
            case let .checkoutUnavailable(message, code):
                OSLogger.shared.error("Checkout unavailable error received: \(message ?? "No message"), code: \(code)")
                viewDelegate?.checkoutViewDidFailWithError(
                    error: .checkoutUnavailable(
                        message: message ?? "Checkout unavailable.",
                        code: CheckoutUnavailable.clientError(code: code),
                        recoverable: true
                    )
                )
            /// Error: Storefront not configured properly
            case let .configurationError(message, code):
                OSLogger.shared.error("Configuration error received: \(message ?? "No message"), code: \(code)")
                viewDelegate?.checkoutViewDidFailWithError(error: .checkoutUnavailable(
                    message: message ?? "Storefront configuration error.",
                    code: CheckoutUnavailable.clientError(code: code),
                    recoverable: false
                ))
            /// Error: Checkout expired
            case let .checkoutExpired(message, code):
                OSLogger.shared.info("Checkout expired error received: \(message ?? "No message"), code: \(code)")
                viewDelegate?.checkoutViewDidFailWithError(error: .checkoutExpired(message: message ?? "Checkout has expired.", code: code))
            /// Checkout modal toggled
            case let .checkoutModalToggled(modalVisible):
                viewDelegate?.checkoutViewDidToggleModal(modalVisible: modalVisible)
            /// Checkout web pixel event
            case let .webPixels(event):
                if let nonOptionalEvent = event {
                    viewDelegate?.checkoutViewDidEmitWebPixelEvent(event: nonOptionalEvent)
                }
            default:
                OSLogger.shared.debug("Unsupported legacy event")
            }
        } catch {
            OSLogger.shared.error("Error decoding bridge script message: \(error.localizedDescription)")
            viewDelegate?.checkoutViewDidFailWithError(error: .sdkError(underlying: error))
        }
    }
    
    // MARK: - Embedded Checkout Event Handlers
    
    private func handleStateChangeEvent(_ event: [String: Any]) {
        guard let statePayload = decodeStateChangePayload(from: event) else {
            OSLogger.shared.error("Failed to decode state change payload")
            return
        }
        viewDelegate?.checkoutViewDidChangeState(state: statePayload)
    }
    
    private func handleEmbeddedCompletedEvent(_ event: [String: Any]) -> Bool {
        guard let embeddedPayload = decodeEmbeddedCompletePayload(from: event) else {
            return false
        }
        viewDelegate?.checkoutViewDidComplete(payload: embeddedPayload)
        return true
    }
    
    private func handleEmbeddedErrorEvent(_ event: [String: Any]) -> Bool {
        guard let embeddedErrors = decodeEmbeddedErrorPayload(from: event) else {
            return false
        }
        viewDelegate?.checkoutViewDidFail(errors: embeddedErrors)
        return true
    }
    
    private func handleEmbeddedWebPixelEvent(_ event: [String: Any]) {
        guard let embeddedPayload = decodeEmbeddedWebPixelPayload(from: event) else {
            OSLogger.shared.error("Failed to decode embedded checkout web pixel payload")
            return
        }
        viewDelegate?.checkoutViewDidEmitWebPixelEvent(payload: embeddedPayload)
    }
    
    // MARK: - Embedded Checkout Decoders
    
    private func decodeEmbeddedCompletePayload(from event: [String: Any]) -> CheckoutCompletePayload? {
        guard let messageBody = event["body"] as? String,
              let data = messageBody.data(using: .utf8) else {
            return nil
        }

        do {
            return try JSONDecoder().decode(CheckoutCompletePayload.self, from: data)
        } catch {
            OSLogger.shared.debug("Failed to decode as embedded complete payload: \(error)")
            return nil
        }
    }

    private func decodeEmbeddedWebPixelPayload(from event: [String: Any]) -> WebPixelsPayload? {
        guard let messageBody = event["body"] as? String,
              let data = messageBody.data(using: .utf8) else {
            return nil
        }

        do {
            return try JSONDecoder().decode(WebPixelsPayload.self, from: data)
        } catch {
            OSLogger.shared.debug("Failed to decode as embedded web pixel payload: \(error)")
            return nil
        }
    }

    private func decodeStateChangePayload(from event: [String: Any]) -> CheckoutStatePayload? {
        guard let messageBody = event["body"] as? String,
              let data = messageBody.data(using: .utf8) else {
            return nil
        }

        do {
            return try JSONDecoder().decode(CheckoutStatePayload.self, from: data)
        } catch {
            OSLogger.shared.error("Failed to decode state change payload: \(error)")
            return nil
        }
    }

    private func decodeEmbeddedErrorPayload(from event: [String: Any]) -> [ErrorPayload]? {
        guard let messageBody = event["body"] as? String,
              let data = messageBody.data(using: .utf8) else {
            return nil
        }

        do {
            return try JSONDecoder().decode([ErrorPayload].self, from: data)
        } catch {
            OSLogger.shared.debug("Failed to decode as embedded error payload: \(error)")
            return nil
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
                    ))
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

    /// No need to emit checkoutDidFail error here as it has been handled in handleResponse already
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
                    ))
            }
        }
        checkoutDidLoad = true
        timer = nil
    }

    func webView(_: WKWebView, didFail _: WKNavigation!, withError error: Error) {
        timer = nil

        let nsError = error as NSError

        OSLogger.shared.debug("WebView navigation failed with error: description:\(nsError.localizedDescription) domain:\(nsError.domain) code:\(nsError.code)")

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
