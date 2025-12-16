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

/// Protocol for requests sent FROM the kit TO checkout (outbound direction)
/// This is the inverse of RPCRequest which handles inbound requests from checkout.
protocol OutboundRPCRequest: Encodable {
	associatedtype Params: Encodable
	associatedtype ResponsePayload: Decodable

	/// The JSON-RPC method name (e.g., "checkout.submit")
	static var method: String { get }

	/// Unique identifier for correlating request/response
	var id: String { get }

	/// Parameters to send with the request
	var params: Params { get }
}

/// JSON-RPC 2.0 request envelope for outbound requests
struct OutboundRPCEnvelope<Params: Encodable>: Encodable {
	let jsonrpc: String = "2.0"
	let id: String
	let method: String
	let params: Params
}

/// JSON-RPC 2.0 response envelope for responses to outbound requests
struct OutboundRPCResponseEnvelope: Codable {
	let jsonrpc: String
	let id: String
	let result: AnyCodable?
	let error: OutboundRPCError?
}

/// JSON-RPC error structure
public struct OutboundRPCError: Codable {
	public let code: Int?
	public let message: String?
	public let data: AnyCodable?
}

/// Errors that can occur with outbound RPC requests
public enum OutboundRPCRequestError: Error {
	case requestCancelled
	case webviewDeallocated
	case encodingFailed(Error)
	case decodingFailed(Error)
	case rpcError(OutboundRPCError)
	case invalidResponse
}

/// Manages pending outbound requests and their async continuations.
/// Uses actor isolation for thread-safe access to the continuations dictionary.
actor PendingRequestManager {
	private var continuations: [String: CheckedContinuation<Data, Error>] = [:]

	/// Register a new pending request with its continuation
	func register(id: String, continuation: CheckedContinuation<Data, Error>) {
		continuations[id] = continuation
	}

	/// Complete a pending request with response data
	/// Returns true if the request was found and completed
	@discardableResult
	func complete(id: String, with data: Data) -> Bool {
		guard let continuation = continuations.removeValue(forKey: id) else {
			return false
		}
		continuation.resume(returning: data)
		return true
	}

	/// Fail a pending request with an error
	/// Returns true if the request was found and failed
	@discardableResult
	func fail(id: String, with error: Error) -> Bool {
		guard let continuation = continuations.removeValue(forKey: id) else {
			return false
		}
		continuation.resume(throwing: error)
		return true
	}

	/// Cancel a specific pending request
	func cancel(id: String) {
		if let continuation = continuations.removeValue(forKey: id) {
			continuation.resume(throwing: OutboundRPCRequestError.requestCancelled)
		}
	}

	/// Cancel all pending requests (called on dealloc/dismiss)
	func cancelAll() {
		for (_, continuation) in continuations {
			continuation.resume(throwing: OutboundRPCRequestError.requestCancelled)
		}
		continuations.removeAll()
	}

	/// Check if there are any pending requests
	var hasPendingRequests: Bool {
		!continuations.isEmpty
	}

	/// Number of pending requests
	var pendingCount: Int {
		continuations.count
	}
}

/// Type-erased container for arbitrary Codable values
/// Used for handling dynamic JSON in RPC responses
public struct AnyCodable: Codable {
	public let value: Any

	public init(_ value: Any) {
		self.value = value
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()

		if container.decodeNil() {
			value = NSNull()
		} else if let bool = try? container.decode(Bool.self) {
			value = bool
		} else if let int = try? container.decode(Int.self) {
			value = int
		} else if let double = try? container.decode(Double.self) {
			value = double
		} else if let string = try? container.decode(String.self) {
			value = string
		} else if let array = try? container.decode([AnyCodable].self) {
			value = array.map(\.value)
		} else if let dict = try? container.decode([String: AnyCodable].self) {
			value = dict.mapValues(\.value)
		} else {
			throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to decode value")
		}
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()

		switch value {
		case is NSNull:
			try container.encodeNil()
		case let bool as Bool:
			try container.encode(bool)
		case let int as Int:
			try container.encode(int)
		case let double as Double:
			try container.encode(double)
		case let string as String:
			try container.encode(string)
		case let array as [Any]:
			try container.encode(array.map { AnyCodable($0) })
		case let dict as [String: Any]:
			try container.encode(dict.mapValues { AnyCodable($0) })
		default:
			throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unable to encode value"))
		}
	}
}
