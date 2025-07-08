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
import SwiftUI

public class CheckoutViewController: UINavigationController {
	public init(checkout url: URL, delegate: CheckoutDelegate? = nil) {
		let rootViewController = CheckoutWebViewController(checkoutURL: url, delegate: delegate)
		rootViewController.notifyPresented()
		super.init(rootViewController: rootViewController)
		presentationController?.delegate = rootViewController
	}

	@available(*, unavailable)
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

/// Deprecated
extension CheckoutViewController {
	@available(*, deprecated, message: "Use \"CheckoutSheet\" instead.")
	public struct Representable: UIViewControllerRepresentable {
		@Binding var checkoutURL: URL?

		let delegate: CheckoutDelegate?

		public init(checkout url: Binding<URL?>, delegate: CheckoutDelegate? = nil) {
			self._checkoutURL = url
			self.delegate = delegate
		}

		public func makeUIViewController(context: Self.Context) -> CheckoutViewController {
			return CheckoutViewController(checkout: checkoutURL!, delegate: delegate)
		}

		public func updateUIViewController(_ uiViewController: CheckoutViewController, context: Self.Context) {
		}
	}
}

internal class InlineCheckoutWebViewDelegate: CheckoutWebViewDelegate {
	weak var wrapper: InlineCheckoutWebViewWrapper?
	weak var checkoutDelegate: CheckoutDelegate?

	init(wrapper: InlineCheckoutWebViewWrapper, checkoutDelegate: CheckoutDelegate?) {
		self.wrapper = wrapper
		self.checkoutDelegate = checkoutDelegate
	}

	func checkoutViewDidStartNavigation() {}

	func checkoutViewDidCompleteCheckout(event: CheckoutCompletedEvent) {
		checkoutDelegate?.checkoutDidComplete(event: event)
	}

	func checkoutViewDidFinishNavigation() {}

	func checkoutViewDidClickLink(url: URL) {
		checkoutDelegate?.checkoutDidClickLink(url: url)
	}

	func checkoutViewDidFailWithError(error: CheckoutError) {
		checkoutDelegate?.checkoutDidFail(error: error)
	}

	func checkoutViewDidToggleModal(modalVisible: Bool) {}

	func checkoutViewDidEmitWebPixelEvent(event: PixelEvent) {
		checkoutDelegate?.checkoutDidEmitWebPixelEvent(event: event)
	}

}

public class InlineCheckoutWebViewWrapper: UIView {
	internal var webView: CheckoutWebView!
	private var contentHeight: CGFloat = 400
	private var checkoutURL: URL?
	public var delegate: CheckoutDelegate?
	private var autoResizeHeight: Bool = true
	private var webViewHeightConstraint: NSLayoutConstraint?
	private var inlineDelegate: InlineCheckoutWebViewDelegate?
	var onHeightChangeWrapper: ((CGFloat) -> Void)?
	var onLoadingStateChange: ((Bool) -> Void)?
	private var isLoading = true
	private var hasReceivedFirstHeightChange = false

	override public init(frame: CGRect) {
		super.init(frame: frame)
		setupWebView()
		setupNotificationObserver()
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		setupWebView()
		setupNotificationObserver()
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
	}

	private func setupWebView() {
		// WebView will be set via configure method
	}

	private func setupNotificationObserver() {
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(configurationChanged),
			name: Notification.Name("colorSchemeChanged"),
			object: nil
		)
	}

	@objc private func configurationChanged() {
		// Recreate webview with new configuration
		if checkoutURL != nil {
			recreateWebView()
		}
	}

	func configure(with checkoutURL: URL, delegate: CheckoutDelegate?, autoResizeHeight: Bool) {
		// Store parameters for potential recreation
		self.checkoutURL = checkoutURL
		self.delegate = delegate
		self.autoResizeHeight = autoResizeHeight

		createWebView()
	}

	private func createWebView() {
		guard let checkoutURL = checkoutURL else {
			OSLogger.shared.debug("No checkout URL provided")
			return
		}

		OSLogger.shared.debug("Creating webview for URL: \(checkoutURL.absoluteString), autoResizeHeight: \(autoResizeHeight)")

		webView = CheckoutWebView.for(checkout: checkoutURL)
		webView.autoResizeHeight = autoResizeHeight
		webView.onHeightChange = { [weak self] height in
			OSLogger.shared.debug("Height change callback received: \(height)")
			self?.updateHeight(height)
		}

		inlineDelegate = InlineCheckoutWebViewDelegate(wrapper: self, checkoutDelegate: delegate)
		webView.viewDelegate = inlineDelegate

		webView.load(checkout: checkoutURL)

		addSubview(webView)
		webView.translatesAutoresizingMaskIntoConstraints = false

		if autoResizeHeight {
			// Create a height constraint that we can update when content height changes
			webViewHeightConstraint = webView.heightAnchor.constraint(equalToConstant: contentHeight)

			NSLayoutConstraint.activate([
				webView.topAnchor.constraint(equalTo: topAnchor),
				webView.leadingAnchor.constraint(equalTo: leadingAnchor),
				webView.trailingAnchor.constraint(equalTo: trailingAnchor),
				webViewHeightConstraint!
			])

			// Disable scrolling so content sizes naturally
			webView.scrollView.isScrollEnabled = false
			webView.scrollView.bounces = false

			// Set frame AFTER constraints to avoid content adapting to container
			webView.frame = CGRect(x: 0, y: 0, width: bounds.width > 0 ? bounds.width : 375, height: contentHeight)

			OSLogger.shared.debug("Auto-resize mode enabled, initial height: \(contentHeight), frame: \(webView.frame)")
		} else {
			// Standard full-height constraint for non-auto-resize
			NSLayoutConstraint.activate([
				webView.topAnchor.constraint(equalTo: topAnchor),
				webView.leadingAnchor.constraint(equalTo: leadingAnchor),
				webView.trailingAnchor.constraint(equalTo: trailingAnchor),
				webView.bottomAnchor.constraint(equalTo: bottomAnchor)
			])

			// Set frame for non-auto-resize mode
			webView.frame = CGRect(x: 0, y: 0, width: bounds.width > 0 ? bounds.width : 375, height: 400)

			OSLogger.shared.debug("Standard mode with bottom constraint")
		}

		// Force initial layout
		setNeedsLayout()
		layoutIfNeeded()
	}

	private func recreateWebView() {
		// Remove existing webview
		webView?.removeFromSuperview()

		// Invalidate cache to pick up new configuration
		CheckoutWebView.invalidate()

		// Create new webview with updated configuration
		createWebView()

		// Update layout
		invalidateIntrinsicContentSize()
	}


		internal func updateHeight(_ height: CGFloat) {
		guard height != contentHeight else { return }

		OSLogger.shared.debug("Updating wrapper height from \(contentHeight) to \(height)")
		let previousHeight = contentHeight
		contentHeight = height

		// Check if this is the first meaningful height change (indicates content is loaded)
		// Use a higher threshold to ensure content is actually loaded
		if !hasReceivedFirstHeightChange && height > 300 {
			hasReceivedFirstHeightChange = true
			isLoading = false
			onLoadingStateChange?(false)
		}

		// Update the webview height constraint to match the measured content height
		if autoResizeHeight, let heightConstraint = webViewHeightConstraint {
			heightConstraint.constant = height
			OSLogger.shared.debug("Updated webview height constraint to \(height)")
		}

		// Animate the height change with smooth animation
		// Use different timing based on height change magnitude for better UX
		let heightDiff = abs(height - previousHeight)
		let animationDuration: TimeInterval = min(1.2, max(0.8, heightDiff / 400.0))

		// First update the intrinsic content size to let SwiftUI know about the change
		invalidateIntrinsicContentSize()

		// Then animate the layout changes
		UIView.animate(
			withDuration: animationDuration,
			delay: 0,
			usingSpringWithDamping: 0.85,
			initialSpringVelocity: 0.3,
			options: [.curveEaseInOut, .allowUserInteraction],
			animations: {
				// Force layout updates on the view hierarchy
				self.setNeedsLayout()
				self.layoutIfNeeded()

				// Update parent views to propagate the animation
				var currentView: UIView? = self.superview
				while currentView != nil {
					currentView?.setNeedsLayout()
					currentView?.layoutIfNeeded()
					currentView = currentView?.superview
				}
			},
			completion: { _ in
				// Notify SwiftUI after the animation completes
				self.onHeightChangeWrapper?(height)
			}
		)
	}

	override public var intrinsicContentSize: CGSize {
		if webView?.autoResizeHeight == true {
			return CGSize(width: UIView.noIntrinsicMetric, height: contentHeight)
		}
		return CGSize(width: UIView.noIntrinsicMetric, height: 400)
	}
}

public struct InlineCheckout: UIViewRepresentable, CheckoutConfigurable {
	public typealias UIViewType = InlineCheckoutWebViewWrapper

	public var checkoutURL: URL
	public var autoResizeHeight: Bool = true

	// SwiftUI-friendly event handlers
	public var onCheckoutComplete: ((CheckoutCompletedEvent) -> Void)?
	public var onCheckoutCancel: (() -> Void)?
	public var onCheckoutFail: ((CheckoutError) -> Void)?
	public var onHeightChange: ((CGFloat) -> Void)?
	public var onPixelEvent: ((PixelEvent) -> Void)?
	public var onLinkClick: ((URL) -> Void)?
	public var onLoadingStateChange: ((Bool) -> Void)?

	public init(
		checkout url: URL,
		autoResizeHeight: Bool = true,
		onCheckoutComplete: ((CheckoutCompletedEvent) -> Void)? = nil,
		onCheckoutCancel: (() -> Void)? = nil,
		onCheckoutFail: ((CheckoutError) -> Void)? = nil,
		onHeightChange: ((CGFloat) -> Void)? = nil,
		onPixelEvent: ((PixelEvent) -> Void)? = nil,
		onLinkClick: ((URL) -> Void)? = nil,
		onLoadingStateChange: ((Bool) -> Void)? = nil
	) {
		self.checkoutURL = url
		self.autoResizeHeight = autoResizeHeight
		self.onCheckoutComplete = onCheckoutComplete
		self.onCheckoutCancel = onCheckoutCancel
		self.onCheckoutFail = onCheckoutFail
		self.onHeightChange = onHeightChange
		self.onPixelEvent = onPixelEvent
		self.onLinkClick = onLinkClick
		self.onLoadingStateChange = onLoadingStateChange

		/// We handle configuration changes manually via notifications
		/// to ensure proper cache invalidation timing
		ShopifyCheckoutSheetKit.invalidateOnConfigurationChange = false
	}

	public func makeUIView(context: Self.Context) -> InlineCheckoutWebViewWrapper {
		let wrapper = InlineCheckoutWebViewWrapper()

		// Create a delegate wrapper that uses our closure properties
		let delegate = InlineCheckoutDelegateWrapper()
		delegate.onComplete = onCheckoutComplete
		delegate.onCancel = onCheckoutCancel
		delegate.onFail = onCheckoutFail
		delegate.onPixelEvent = onPixelEvent
		delegate.onLinkClick = onLinkClick

		wrapper.configure(with: checkoutURL, delegate: delegate, autoResizeHeight: autoResizeHeight)
		wrapper.onHeightChangeWrapper = onHeightChange
		wrapper.onLoadingStateChange = onLoadingStateChange

		return wrapper
	}

	public func updateUIView(_ uiView: InlineCheckoutWebViewWrapper, context: Self.Context) {
		// Update delegate with current closure properties
		if let delegate = uiView.delegate as? InlineCheckoutDelegateWrapper {
			delegate.onComplete = onCheckoutComplete
			delegate.onCancel = onCheckoutCancel
			delegate.onFail = onCheckoutFail
			delegate.onPixelEvent = onPixelEvent
			delegate.onLinkClick = onLinkClick
		}
		uiView.onHeightChangeWrapper = onHeightChange
		uiView.onLoadingStateChange = onLoadingStateChange
	}
}

public struct CheckoutSheet: UIViewControllerRepresentable, CheckoutConfigurable {
	public typealias UIViewControllerType = CheckoutViewController

	var checkoutURL: URL
	var delegate = CheckoutDelegateWrapper()

	public init(checkout url: URL) {
		self.checkoutURL = url

		/// Programatic usage of the library will invalidate the cache each time the configuration changes.
		/// This should not happen in the case of SwiftUI, where the config can change each time a modifier function runs.
		ShopifyCheckoutSheetKit.invalidateOnConfigurationChange = false
	}

	public func makeUIViewController(context: Self.Context) -> CheckoutViewController {
		return CheckoutViewController(checkout: checkoutURL, delegate: delegate)
	}

	public func updateUIViewController(_ uiViewController: CheckoutViewController, context: Self.Context) {
		guard
			let webViewController = uiViewController
				.viewControllers
				.compactMap({ $0 as? CheckoutWebViewController })
				.first
		else {
			return
		}
            OSLogger.shared.debug(
                "[CheckoutViewController#updateUIViewController]: No ViewControllers matching CheckoutWebViewController \(uiViewController.viewControllers.map {String(describing: $0.self)}.joined(separator: ""))"
            )

		webViewController.delegate = delegate
	}

	/// Lifecycle methods

	@discardableResult public func onCancel(_ action: @escaping () -> Void) -> Self {
		delegate.onCancel = action
		return self
	}

	@discardableResult public func onComplete(_ action: @escaping (CheckoutCompletedEvent) -> Void) -> Self {
		delegate.onComplete = action
		return self
	}

	@discardableResult public func onFail(_ action: @escaping (CheckoutError) -> Void) -> Self {
		delegate.onFail = action
		return self
	}

	@discardableResult public func onPixelEvent(_ action: @escaping (PixelEvent) -> Void) -> Self {
		delegate.onPixelEvent = action
		return self
	}

	@discardableResult public func onLinkClick(_ action: @escaping (URL) -> Void) -> Self {
		delegate.onLinkClick = action
		return self
	}
}

public class CheckoutDelegateWrapper: CheckoutDelegate {
	var onComplete: ((CheckoutCompletedEvent) -> Void)?
	var onCancel: (() -> Void)?
	var onFail: ((CheckoutError) -> Void)?
	var onPixelEvent: ((PixelEvent) -> Void)?
	var onLinkClick: ((URL) -> Void)?

	public func checkoutDidFail(error: CheckoutError) {
		onFail?(error)
	}

	public func checkoutDidEmitWebPixelEvent(event: PixelEvent) {
		onPixelEvent?(event)
	}

	public func checkoutDidComplete(event: CheckoutCompletedEvent) {
		onComplete?(event)
	}

	public func checkoutDidCancel() {
		onCancel?()
	}

	public func checkoutDidClickLink(url: URL) {
		if let onLinkClick = onLinkClick {
			onLinkClick(url)
			return
		}

		/// Use fallback behavior if callback is not provided
		if UIApplication.shared.canOpenURL(url) {
			UIApplication.shared.open(url)
		}
	}
}

public class InlineCheckoutDelegateWrapper: CheckoutDelegate {
	var onComplete: ((CheckoutCompletedEvent) -> Void)?
	var onCancel: (() -> Void)?
	var onFail: ((CheckoutError) -> Void)?
	var onPixelEvent: ((PixelEvent) -> Void)?
	var onLinkClick: ((URL) -> Void)?

	public func checkoutDidFail(error: CheckoutError) {
		onFail?(error)
	}

	public func checkoutDidEmitWebPixelEvent(event: PixelEvent) {
		onPixelEvent?(event)
	}

	public func checkoutDidComplete(event: CheckoutCompletedEvent) {
		onComplete?(event)
	}

	public func checkoutDidCancel() {
		onCancel?()
	}

	public func checkoutDidClickLink(url: URL) {
		if let onLinkClick = onLinkClick {
			onLinkClick(url)
			return
		}

		/// Use fallback behavior if callback is not provided
		if UIApplication.shared.canOpenURL(url) {
			UIApplication.shared.open(url)
		}
	}
}

public protocol CheckoutConfigurable {
	func backgroundColor(_ color: UIColor) -> Self
	func colorScheme(_ colorScheme: ShopifyCheckoutSheetKit.Configuration.ColorScheme) -> Self
	func tintColor(_ color: UIColor) -> Self
	func title(_ title: String) -> Self
}

extension CheckoutConfigurable {
	@discardableResult public func backgroundColor(_ color: UIColor) -> Self {
		ShopifyCheckoutSheetKit.configuration.backgroundColor = color
		return self
	}

	@discardableResult public func colorScheme(_ colorScheme: ShopifyCheckoutSheetKit.Configuration.ColorScheme) -> Self {
		ShopifyCheckoutSheetKit.configuration.colorScheme = colorScheme
		return self
	}

	@discardableResult public func tintColor(_ color: UIColor) -> Self {
		ShopifyCheckoutSheetKit.configuration.tintColor = color
		return self
	}

	@discardableResult public func title(_ title: String) -> Self {
		ShopifyCheckoutSheetKit.configuration.title = title
		return self
	}
}
