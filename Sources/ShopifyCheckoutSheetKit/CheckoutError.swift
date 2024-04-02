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

/// A type representing Shopify Checkout specific errors.
public enum CheckoutError: Swift.Error {
	/// Issued when an internal error within Shopify Checkout SDK
	/// In event of an sdkError you could use the stacktrace to inform you of how to proceed,
	/// if the issue persists, it is recommended to open a bug report in http://github.com/Shopify/checkout-sheet-kit-swift
	case sdkError(underlying: Swift.Error)

	/// Issued when the provided checkout URL results in an error related to shop being on checkout.liquid.
	/// The SDK only supports stores migrated for extensibility.
	case checkoutLiquidNotMigrated(message: String)

	/// Issued when checkout has encountered a unrecoverable error (for example server side error)
	/// if the issue persists, it is recommended to open a bug report in http://github.com/Shopify/checkout-sheet-kit-swift
	case checkoutUnavailable(message: String)

	/// Issued when checkout is no longer available and will no longer be available with the checkout url supplied.
	/// This may happen when the user has paused on checkout for a long period (hours) and then attempted to proceed again with the same checkout url
	/// In event of checkoutExpired, a new checkout url will need to be generated
	case checkoutExpired(message: String)
}

internal enum CheckoutErrorGroup: String, Codable {
	/// An authentication error
	case authentication
	/// A terminal checkout error which cannot be handled
	case unrecoverable
	/// A checkout-related error, such as failure to receive a receipt or progress through checkout
	case checkout
	/// The checkout session has expired and is no longer available
	case checkoutExpired
	/// The error sent by checkout is not supported
	case unsupported
}

internal struct CheckoutErrorEvent: Codable {
	public let code: String?
	public let flowType: String?
	public let group: CheckoutErrorGroup
	public let reason: String?
	public let type: String?
}

internal class CheckoutErrorEventDecoder {
	func decode(from container: KeyedDecodingContainer<CheckoutBridge.WebEvent.CodingKeys>, using decoder: Decoder) -> CheckoutErrorEvent {
		let unsupportedError = CheckoutErrorEvent(code: nil, flowType: nil, group: .unsupported, reason: nil, type: nil)

		do {
			let messageBody = try container.decode(String.self, forKey: .body)

			guard let data = messageBody.data(using: .utf8) else {
				return unsupportedError
			}

			let events = try JSONDecoder().decode([CheckoutErrorEvent].self, from: data)

			guard let error = events.first else {
				return unsupportedError
			}

			return error
		} catch {
			CheckoutBridge.logger.logError(error, "Error decoding checkout error event")
			return unsupportedError
		}
	}
}
