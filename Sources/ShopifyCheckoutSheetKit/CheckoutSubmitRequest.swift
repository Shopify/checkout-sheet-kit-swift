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

/// Request sent from the kit to checkout to initiate checkout submission.
///
/// This is an outbound request (Embedder → Checkout) that triggers checkout to submit.
/// If the cart contains payment credentials, checkout will proceed to submit.
/// If payment credentials are missing, checkout may respond with a `submitStart` request
/// to collect them.
public struct CheckoutSubmitRequest: OutboundRPCRequest {
	public typealias Params = CheckoutSubmitParams
	public typealias ResponsePayload = CheckoutSubmitResponsePayload

	public static let method = "checkout.submit"

	public let id: String
	public let params: CheckoutSubmitParams

	/// Creates a new checkout submit request
	/// - Parameter cart: Optional cart with payment credentials attached to instruments.
	///                   If nil, checkout may request credentials via submitStart.
	public init(cart: Cart? = nil) {
		self.id = UUID().uuidString
		self.params = CheckoutSubmitParams(cart: cart)
	}

	/// Creates a submit request with a specific ID (for testing)
	internal init(id: String, cart: Cart? = nil) {
		self.id = id
		self.params = CheckoutSubmitParams(cart: cart)
	}
}

/// Parameters for the checkout submit request
public struct CheckoutSubmitParams: Codable {
	/// Optional cart with payment credentials attached.
	/// Pattern: `{ ...cart, payment: { ...cart.payment, methods: [...modified] } }`
	/// where instruments have credentials nested at `cart.payment.methods[*].instruments[*].credentials[*]`
	@NullEncodable public var cart: Cart?

	public init(cart: Cart? = nil) {
		self.cart = cart
	}
}

/// Response payload from checkout after a submit request.
/// Contains any validation or processing errors that occurred.
public struct CheckoutSubmitResponsePayload: Codable {
	/// Application-level validation errors from checkout.
	/// Empty or nil indicates the submit was accepted (though may still be processing).
	public let errors: [ResponseError]?

	public init(errors: [ResponseError]? = nil) {
		self.errors = errors
	}
}

// MARK: - Encodable Conformance

extension CheckoutSubmitRequest {
	public func encode(to encoder: Encoder) throws {
		let envelope = OutboundRPCEnvelope(
			id: id,
			method: Self.method,
			params: params
		)
		try envelope.encode(to: encoder)
	}
}

// MARK: - Testing Support

extension CheckoutSubmitRequest {
	/// Creates a test instance for unit testing purposes.
	/// - Parameters:
	///   - id: The request ID (defaults to a test UUID)
	///   - cart: Optional cart to include in the request
	/// - Returns: A test instance of CheckoutSubmitRequest
	public static func testInstance(
		id: String = "test-submit-request-id",
		cart: Cart? = nil
	) -> CheckoutSubmitRequest {
		CheckoutSubmitRequest(id: id, cart: cart)
	}
}

extension CheckoutSubmitResponsePayload {
	/// Creates a test instance for unit testing purposes.
	/// - Parameter errors: Optional errors to include in the response
	/// - Returns: A test instance of CheckoutSubmitResponsePayload
	public static func testInstance(
		errors: [ResponseError]? = nil
	) -> CheckoutSubmitResponsePayload {
		CheckoutSubmitResponsePayload(errors: errors)
	}
}
