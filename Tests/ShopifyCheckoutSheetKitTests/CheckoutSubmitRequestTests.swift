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

@testable import ShopifyCheckoutSheetKit
import XCTest

class CheckoutSubmitRequestTests: XCTestCase {
	// MARK: - Request Encoding Tests

	func testRequestEncodesWithCorrectMethod() throws {
		let request = CheckoutSubmitRequest(cart: nil)

		let data = try JSONEncoder().encode(request)
		let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

		XCTAssertEqual(json?["method"] as? String, "checkout.submit")
		XCTAssertEqual(json?["jsonrpc"] as? String, "2.0")
		XCTAssertNotNil(json?["id"])
	}

	func testRequestEncodesWithUniqueId() throws {
		let request1 = CheckoutSubmitRequest(cart: nil)
		let request2 = CheckoutSubmitRequest(cart: nil)

		XCTAssertNotEqual(request1.id, request2.id)
	}

	func testRequestEncodesCartWhenProvided() throws {
		let cart = createTestCart(id: "test-cart-for-submit")
		let request = CheckoutSubmitRequest(cart: cart)

		let data = try JSONEncoder().encode(request)
		let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

		let params = json?["params"] as? [String: Any]
		let cartJson = params?["cart"] as? [String: Any]
		XCTAssertEqual(cartJson?["id"] as? String, "test-cart-for-submit")
	}

	func testRequestEncodesNullCartWhenNotProvided() throws {
		let request = CheckoutSubmitRequest(cart: nil)

		let data = try JSONEncoder().encode(request)
		let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

		let params = json?["params"] as? [String: Any]
		// Cart should be null, not missing
		XCTAssertTrue(params?.keys.contains("cart") ?? false)
	}

	func testRequestUsesSpecifiedIdForTesting() throws {
		let request = CheckoutSubmitRequest.testInstance(id: "custom-test-id")

		XCTAssertEqual(request.id, "custom-test-id")
	}

	// MARK: - Response Decoding Tests

	func testResponseDecodesWithNoErrors() throws {
		let json = """
		{
			"errors": null
		}
		"""
		let data = json.data(using: .utf8)!
		let response = try JSONDecoder().decode(CheckoutSubmitResponsePayload.self, from: data)

		XCTAssertNil(response.errors)
	}

	func testResponseDecodesWithEmptyErrors() throws {
		let json = """
		{
			"errors": []
		}
		"""
		let data = json.data(using: .utf8)!
		let response = try JSONDecoder().decode(CheckoutSubmitResponsePayload.self, from: data)

		XCTAssertNotNil(response.errors)
		XCTAssertTrue(response.errors?.isEmpty ?? false)
	}

	func testResponseDecodesWithErrors() throws {
		let json = """
		{
			"errors": [
				{
					"code": "INVALID_PAYMENT",
					"message": "Payment credentials are invalid"
				},
				{
					"code": "ADDRESS_REQUIRED",
					"message": "Shipping address is required",
					"fieldTarget": "address"
				}
			]
		}
		"""
		let data = json.data(using: .utf8)!
		let response = try JSONDecoder().decode(CheckoutSubmitResponsePayload.self, from: data)

		XCTAssertEqual(response.errors?.count, 2)
		XCTAssertEqual(response.errors?[0].code, "INVALID_PAYMENT")
		XCTAssertEqual(response.errors?[0].message, "Payment credentials are invalid")
		XCTAssertNil(response.errors?[0].fieldTarget)
		XCTAssertEqual(response.errors?[1].code, "ADDRESS_REQUIRED")
		XCTAssertEqual(response.errors?[1].fieldTarget, "address")
	}

	func testResponseTestInstanceCreation() {
		let errors = [
			ResponseError(code: "TEST_ERROR", message: "Test message", fieldTarget: nil)
		]
		let response = CheckoutSubmitResponsePayload.testInstance(errors: errors)

		XCTAssertEqual(response.errors?.count, 1)
		XCTAssertEqual(response.errors?[0].code, "TEST_ERROR")
	}

	// MARK: - OutboundRPCResponseEnvelope Tests

	func testOutboundRPCResponseEnvelopeDecodes() throws {
		let json = """
		{
			"jsonrpc": "2.0",
			"id": "request-123",
			"result": {
				"errors": null
			}
		}
		"""
		let data = json.data(using: .utf8)!
		let envelope = try JSONDecoder().decode(OutboundRPCResponseEnvelope.self, from: data)

		XCTAssertEqual(envelope.jsonrpc, "2.0")
		XCTAssertEqual(envelope.id, "request-123")
		XCTAssertNotNil(envelope.result)
		XCTAssertNil(envelope.error)
	}

	func testOutboundRPCResponseEnvelopeDecodesError() throws {
		let json = """
		{
			"jsonrpc": "2.0",
			"id": "request-123",
			"error": {
				"code": -32600,
				"message": "Invalid Request"
			}
		}
		"""
		let data = json.data(using: .utf8)!
		let envelope = try JSONDecoder().decode(OutboundRPCResponseEnvelope.self, from: data)

		XCTAssertEqual(envelope.jsonrpc, "2.0")
		XCTAssertEqual(envelope.id, "request-123")
		XCTAssertNil(envelope.result)
		XCTAssertNotNil(envelope.error)
		XCTAssertEqual(envelope.error?.code, -32600)
		XCTAssertEqual(envelope.error?.message, "Invalid Request")
	}

	// MARK: - PendingRequestManager Tests

	func testPendingRequestManagerRegistersAndCompletes() async throws {
		let manager = PendingRequestManager()
		let testData = "test response".data(using: .utf8)!

		let expectation = XCTestExpectation(description: "Request completes")

		Task {
			let data: Data = try await withCheckedThrowingContinuation { continuation in
				Task {
					await manager.register(id: "test-1", continuation: continuation)

					// Complete after registration
					Task {
						try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
						await manager.complete(id: "test-1", with: testData)
					}
				}
			}
			XCTAssertEqual(data, testData)
			expectation.fulfill()
		}

		await fulfillment(of: [expectation], timeout: 2.0)
	}

	func testPendingRequestManagerFailsRequest() async throws {
		let manager = PendingRequestManager()

		let expectation = XCTestExpectation(description: "Request fails")

		Task {
			do {
				let _: Data = try await withCheckedThrowingContinuation { continuation in
					Task {
						await manager.register(id: "test-2", continuation: continuation)

						// Fail after registration
						Task {
							try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
							await manager.fail(id: "test-2", with: OutboundRPCRequestError.requestCancelled)
						}
					}
				}
				XCTFail("Should have thrown an error")
			} catch {
				XCTAssertTrue(error is OutboundRPCRequestError)
				expectation.fulfill()
			}
		}

		await fulfillment(of: [expectation], timeout: 2.0)
	}

	func testPendingRequestManagerCancelsAll() async throws {
		let manager = PendingRequestManager()

		let expectation1 = XCTestExpectation(description: "Request 1 cancelled")
		let expectation2 = XCTestExpectation(description: "Request 2 cancelled")

		Task {
			do {
				let _: Data = try await withCheckedThrowingContinuation { continuation in
					Task {
						await manager.register(id: "cancel-1", continuation: continuation)
					}
				}
				XCTFail("Should have been cancelled")
			} catch {
				expectation1.fulfill()
			}
		}

		Task {
			do {
				let _: Data = try await withCheckedThrowingContinuation { continuation in
					Task {
						await manager.register(id: "cancel-2", continuation: continuation)
					}
				}
				XCTFail("Should have been cancelled")
			} catch {
				expectation2.fulfill()
			}
		}

		// Give time for registrations
		try? await Task.sleep(nanoseconds: 100_000_000)

		// Cancel all
		await manager.cancelAll()

		await fulfillment(of: [expectation1, expectation2], timeout: 2.0)
	}

	func testPendingRequestManagerPendingCount() async {
		let manager = PendingRequestManager()

		let initialCount = await manager.pendingCount
		XCTAssertEqual(initialCount, 0)

		// We can't easily test the count while requests are pending without
		// a more complex test setup, but we can verify the initial state
		let hasPending = await manager.hasPendingRequests
		XCTAssertFalse(hasPending)
	}

	// MARK: - AnyCodable Tests

	func testAnyCodableDecodesString() throws {
		let json = "\"hello\""
		let data = json.data(using: .utf8)!
		let anyCodable = try JSONDecoder().decode(AnyCodable.self, from: data)

		XCTAssertEqual(anyCodable.value as? String, "hello")
	}

	func testAnyCodableDecodesNumber() throws {
		let json = "42"
		let data = json.data(using: .utf8)!
		let anyCodable = try JSONDecoder().decode(AnyCodable.self, from: data)

		XCTAssertEqual(anyCodable.value as? Int, 42)
	}

	func testAnyCodableDecodesBool() throws {
		let json = "true"
		let data = json.data(using: .utf8)!
		let anyCodable = try JSONDecoder().decode(AnyCodable.self, from: data)

		XCTAssertEqual(anyCodable.value as? Bool, true)
	}

	func testAnyCodableDecodesArray() throws {
		let json = "[1, 2, 3]"
		let data = json.data(using: .utf8)!
		let anyCodable = try JSONDecoder().decode(AnyCodable.self, from: data)

		let array = anyCodable.value as? [Any]
		XCTAssertEqual(array?.count, 3)
	}

	func testAnyCodableDecodesDict() throws {
		let json = "{\"key\": \"value\"}"
		let data = json.data(using: .utf8)!
		let anyCodable = try JSONDecoder().decode(AnyCodable.self, from: data)

		let dict = anyCodable.value as? [String: Any]
		XCTAssertEqual(dict?["key"] as? String, "value")
	}

	func testAnyCodableEncodesRoundTrip() throws {
		let original = AnyCodable(["key": "value", "number": 42])
		let data = try JSONEncoder().encode(original)
		let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)

		let dict = decoded.value as? [String: Any]
		XCTAssertEqual(dict?["key"] as? String, "value")
		XCTAssertEqual(dict?["number"] as? Int, 42)
	}
}
