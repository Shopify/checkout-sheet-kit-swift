import Foundation

import SwiftUI

public struct CheckoutViewControllerRepresentable: UIViewControllerRepresentable {
	public typealias UIViewControllerType = CheckoutViewController

	let url: URL
	let delegate: CheckoutDelegate?

	public func makeUIViewController(context: Context) -> CheckoutViewController {
		return CheckoutViewController(checkoutURL: url, delegate: delegate)
	}

	public func updateUIViewController(_ uiViewController: CheckoutViewController, context: Context) {
		// Here you can update the view controller with new data
	}
}

struct CheckoutViewRepresentable: UIViewRepresentable {
	typealias UIViewType = CheckoutView

	let url: URL

	func makeUIView(context: Context) -> CheckoutView {
		return CheckoutView.for(checkout: url)
	}

	func updateUIView(_ uiView: CheckoutView, context: Context) {
		// Here you can update the view with new data
	}
}
