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
		let rootViewController = CheckoutWebViewController(
			checkoutURL: url, delegate: delegate, isSwiftUI: true
		)
		rootViewController.notifyPresented()
		super.init(rootViewController: rootViewController)
		presentationController?.delegate = rootViewController
	}

	@available(*, unavailable)
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

extension CheckoutViewController {
	@available(*, deprecated, message: "Replace \"CheckoutViewController.Representable\" with \"CheckoutSheet\"")
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

public class CheckoutSheetPresenter: ObservableObject {
	@Published var isPresented: Bool = false
	var checkoutURL: URL?

	public init() {}

	public func present(checkout url: URL?) {
		self.checkoutURL = url
		self.isPresented = true
	}

	public func dismiss() {
		self.isPresented = false
	}
}

public class CheckoutDelegateWrapper: CheckoutDelegate {
	var onCheckoutDidComplete: ((CheckoutCompletedEvent) -> Void)?
	var onCheckoutDidCancel: (() -> Void)?
	var onCheckoutDidFail: ((CheckoutError) -> Void)?
	var onCheckoutDidEmitWebPixelEvent: ((PixelEvent) -> Void)?

	public func checkoutDidFail(error: CheckoutError) {
		onCheckoutDidFail?(error)
	}

	public func checkoutDidEmitWebPixelEvent(event: PixelEvent) {
		onCheckoutDidEmitWebPixelEvent?(event)
	}

	public func checkoutDidComplete(event: CheckoutCompletedEvent) {
		onCheckoutDidComplete?(event)
	}

	public func checkoutDidCancel() {
		onCheckoutDidCancel?()
	}
}

public struct CheckoutSheetKit: View, CheckoutModifiers {
	@ObservedObject var presenter: CheckoutSheetPresenter
	var delegate = CheckoutDelegateWrapper()

	public init(presenter: CheckoutSheetPresenter) {
		self.presenter = presenter
	}

	private func dismiss() {
		presenter.dismiss()
		delegate.checkoutDidCancel()
	}

	public var body: some View {
		VStack {
			EmptyView()
		}
			.sheet(isPresented: $presenter.isPresented, onDismiss: dismiss) {
				CheckoutSheet(checkout: $presenter.checkoutURL, delegate: delegate)
					.edgesIgnoringSafeArea(.all)
			}
	}

	public func onCheckoutCancel(_ action: @escaping () -> Void) -> CheckoutSheetKit {
		delegate.onCheckoutDidCancel = action
		return self
	}

	public func onCheckoutCompleted(_ action: @escaping (CheckoutCompletedEvent) -> Void) -> CheckoutSheetKit {
		delegate.onCheckoutDidComplete = action
		return self
	}

	public func onCheckoutDidFail(_ action: @escaping (CheckoutError) -> Void) -> CheckoutSheetKit {
		delegate.onCheckoutDidFail = action
		return self
	}

	public func onCheckoutDidEmitWebPixelEvent(_ action: @escaping (PixelEvent) -> Void) -> CheckoutSheetKit {
		delegate.onCheckoutDidEmitWebPixelEvent = action
		return self
	}
}

public struct CheckoutSheet: UIViewControllerRepresentable, CheckoutModifiers {
	@Binding var checkoutURL: URL?
	let delegate: CheckoutDelegate?

	public init(checkout url: Binding<URL?>, delegate: CheckoutDelegate? = nil) {
		self._checkoutURL = url
		self.delegate = delegate
	}

	public func makeUIViewController(context: CheckoutSheet.Context) -> CheckoutViewController {
		return CheckoutViewController(checkout: checkoutURL!, delegate: delegate)
	}

	public func updateUIViewController(_ uiViewController: CheckoutViewController, context: CheckoutSheet.Context) {}
}

public protocol CheckoutModifiers {
	func backgroundColor(_ color: UIColor) -> Self
	func colorScheme(_ colorScheme: ShopifyCheckoutSheetKit.Configuration.ColorScheme) -> Self
	func tintColor(_ color: UIColor) -> Self
	func title(_ title: String) -> Self
}

extension CheckoutModifiers {
	public func backgroundColor(_ color: UIColor) -> Self {
		ShopifyCheckoutSheetKit.configuration.backgroundColor = color
		return self
	}

	public func colorScheme(_ colorScheme: ShopifyCheckoutSheetKit.Configuration.ColorScheme) -> Self {
		ShopifyCheckoutSheetKit.configuration.colorScheme = colorScheme
		return self
	}

	public func tintColor(_ color: UIColor) -> Self {
		ShopifyCheckoutSheetKit.configuration.tintColor = color
		return self
	}

	public func title(_ title: String) -> Self {
		ShopifyCheckoutSheetKit.configuration.title = title
		return self
	}
}
