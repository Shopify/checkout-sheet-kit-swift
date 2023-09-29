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

protocol CheckoutViewDelegate: AnyObject {
	func checkoutViewDidStartNavigation()

	func checkoutViewDidCompleteCheckout()

	func checkoutViewDidFinishNavigation()

	func checkoutViewDidClickContactLink(url: URL)

	func checkoutViewDidClickLink(url: URL)

	func checkoutViewDidFailWithError(_ error: Error)
}

class CheckoutView: WKWebView {

	private static var cache: CacheEntry?

	static func `for`(checkout url: URL) -> CheckoutView {
		guard ShopifyCheckout.configuration.preloading.enabled else {
			CheckoutView.cache = nil
			return CheckoutView()
		}

		let cacheKey = url.absoluteString

		guard let cache = cache, cacheKey == cache.key, !cache.isStale else {
			let view = CheckoutView()
			CheckoutView.cache = CacheEntry(key: cacheKey, view: view)
			return view
		}

		return cache.view
	}

	static func invalidate() {
		cache = nil
	}

	// MARK: Properties

	weak var delegate: CheckoutViewDelegate?

	// MARK: Initializers

	override init(frame: CGRect, configuration: WKWebViewConfiguration) {
		configuration.applicationNameForUserAgent = CheckoutBridge.applicationName

		super.init(frame: frame, configuration: configuration)

		navigationDelegate = self
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: -

	override func didMoveToSuperview() {
		super.didMoveToSuperview()

		configuration.userContentController
			.removeScriptMessageHandler(forName: CheckoutBridge.messageHandler)

		if superview != nil {
			configuration.userContentController
				.add(self, name: CheckoutBridge.messageHandler)
		}
	}

	func load(checkout url: URL) {
		load(URLRequest(url: url))
	}
}

extension CheckoutView: WKScriptMessageHandler {
	func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
		do {
			if case .checkoutComplete = try CheckoutBridge.decode(message) {
				CheckoutView.cache = nil
				delegate?.checkoutViewDidCompleteCheckout()
			}
		} catch {
			delegate?.checkoutViewDidFailWithError(error)
		}
	}
}

extension CheckoutView: WKNavigationDelegate {
	func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

		guard let url = action.request.url else {
			decisionHandler(.allow)
			return
		}

		if ["mailto", "tel"].contains(url.scheme) {
			delegate?.checkoutViewDidClickContactLink(url: url)
			decisionHandler(.cancel)
			return
		}

		if action.navigationType == .linkActivated && action.targetFrame == nil {
			delegate?.checkoutViewDidClickLink(url: url)
			decisionHandler(.cancel)
			return
		}

		decisionHandler(.allow)
	}

	func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
		delegate?.checkoutViewDidStartNavigation()
	}

	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
		delegate?.checkoutViewDidFinishNavigation()
	}
}

extension CheckoutView {
	fileprivate struct CacheEntry {
		let key: String

		let view: CheckoutView

		private let timestamp = Date()

		private let timeout = TimeInterval(60 * 5)

		var isStale: Bool {
			abs(timestamp.timeIntervalSinceNow) >= timeout
		}
	}
}
