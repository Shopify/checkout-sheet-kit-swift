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

public enum CheckoutErrorCode: String, Codable {
	case storefrontPasswordRequired = "storefront_password_required"
	case checkoutLiquidNotMigrated = "checkout_liquid_not_migrated"
	case cartExpired = "cart_expired"
	case cartCompleted = "cart_completed"
	case invalidCart = "invalid_cart"
	case unknown = "unknown"

	public static func from(_ code: String?) -> CheckoutErrorCode {
		let fallback = CheckoutErrorCode.unknown

		guard let errorCode = code else {
			return fallback
		}

		return CheckoutErrorCode(rawValue: errorCode) ?? fallback
	}
}

public enum CheckoutUnavailable {
	case clientError(code: CheckoutErrorCode)
	case httpError(statusCode: Int)
}

/// A type representing Shopify Checkout specific errors.
/// "recoverable" indicates that though the request has failed, it should be retried in a fallback browser experience.
public enum CheckoutError: Swift.Error {
	/// Issued when an internal error within Shopify Checkout SDK
	/// In event of an sdkError you could use the stacktrace to inform you of how to proceed,
	/// if the issue persists, it is recommended to open a bug report in http://github.com/Shopify/checkout-sheet-kit-swift
	case sdkError(underlying: Swift.Error, recoverable: Bool = true)

	/// Issued when the storefront configuration has caused an error.
	/// Note that the Checkout Sheet Kit only supports stores migrated for extensibility.
	case configurationError(message: String, code: CheckoutErrorCode, recoverable: Bool = false)

	/// Issued when checkout has encountered a unrecoverable error (for example server side error)
	/// if the issue persists, it is recommended to open a bug report in http://github.com/Shopify/checkout-sheet-kit-swift
	case checkoutUnavailable(message: String, code: CheckoutUnavailable, recoverable: Bool)

	/// Issued when checkout is no longer available and will no longer be available with the checkout url supplied.
	/// This may happen when the user has paused on checkout for a long period (hours) and then attempted to proceed again with the same checkout url
	/// In event of checkoutExpired, a new checkout url will need to be generated
	case checkoutExpired(message: String, code: CheckoutErrorCode, recoverable: Bool = false)

	public var isRecoverable: Bool {
        switch self {
		case .checkoutExpired(_, _, let recoverable),
			.checkoutUnavailable(_, _, let recoverable),
			.configurationError(_, _, let recoverable),
			.sdkError(_, let recoverable):
			return recoverable
		}
    }
}

internal enum CheckoutErrorGroup: String, Codable {
	/// An authentication error
	case authentication
	/// A shop configuration error
	case configuration
	/// A terminal checkout error which cannot be handled
	case unrecoverable
	/// A checkout-related error, such as failure to receive a receipt or progress through checkout
	case checkout
	/// The checkout session has expired and is no longer available
	case expired
	/// The error sent by checkout is not supported
	case unsupported
}

internal struct CheckoutErrorEvent: Codable {
	public let group: CheckoutErrorGroup
	public let code: String?
	public let flowType: String?
	public let reason: String?
	public let type: String?

	public init(group: CheckoutErrorGroup, code: String? = nil, flowType: String? = nil, reason: String? = nil, type: String? = nil) {
		self.group = group
		self.code = code
		self.flowType = flowType
		self.reason = reason
		self.type = type
	}
}

internal class CheckoutErrorEventDecoder {
	func decode(from container: KeyedDecodingContainer<CheckoutBridge.WebEvent.CodingKeys>, using decoder: Decoder) -> CheckoutErrorEvent {

		do {
			let messageBody = try container.decode(String.self, forKey: .body)

			/// Failure to decode will trigger the catch block
			let data = messageBody.data(using: .utf8)

			let events = try JSONDecoder().decode([CheckoutErrorEvent].self, from: data!)

			/// Failure to find an event in the payload array will trigger the catch block
			return events.first!
		} catch {
			CheckoutBridge.logger.logError(error, "Error decoding checkout error event")
			return CheckoutErrorEvent(group: .unsupported, reason: "Decoded error could not be parsed.")
		}
	}
}
