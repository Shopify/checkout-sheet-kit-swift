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

import Foundation

internal struct Headers {
	static let purpose = "Sec-Purpose"
	static let purposePrefetch = "prefetch"

	static let prefersColorScheme = "Sec-CH-Prefers-Color-Scheme"

	static let branding = "X-Shopify-Checkout-Kit-Branding"
	static let brandingCheckoutKit = "CHECKOUT_KIT"
	static let brandingWeb = "WEB_DEFAULT"
}

internal func checkoutKitHeaders(isPreload: Bool = false) -> [String: String] {
	var headers = [String: String]()

	if isPreload {
		headers[Headers.purpose] = Headers.purposePrefetch
	}

	return headers
		.withColorScheme()
		.withBranding()
}

internal extension Dictionary where Key == String, Value == String {
	func withColorScheme() -> [String: String] {
		var headers = self

		let colorScheme = ShopifyCheckoutSheetKit.configuration.colorScheme
		switch colorScheme {
		case .light:
			headers[Headers.prefersColorScheme] = "light"
		case .dark:
			headers[Headers.prefersColorScheme] = "dark"
		case .automatic, .web:
			break // Don't add header for automatic or web color schemes
		}

		return headers
	}

	func withBranding() -> [String: String] {
		var headers = self

		let colorScheme = ShopifyCheckoutSheetKit.configuration.colorScheme
		switch colorScheme {
		case .web:
			headers[Headers.branding] = Headers.brandingWeb
		default:
			headers[Headers.branding] = Headers.brandingCheckoutKit
		}

		return headers
	}

	func hasColorSchemeHeader() -> Bool {
		return hasHeader(Headers.prefersColorScheme)
	}

	func hasBrandingHeader() -> Bool {
		return hasHeader(Headers.branding)
	}

	private func hasHeader(_ headerName: String) -> Bool {
		return self.keys.contains { key in
			key.caseInsensitiveCompare(headerName) == .orderedSame
		}
	}
}
