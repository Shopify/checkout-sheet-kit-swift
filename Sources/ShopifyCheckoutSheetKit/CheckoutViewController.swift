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

	public func updateUIViewController(_ uiViewController: CheckoutViewController, context: Self.Context) {}

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
