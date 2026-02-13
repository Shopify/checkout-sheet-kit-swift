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

@testable import ShopifyAcceleratedCheckouts
import ShopifyCheckoutSheetKit
import XCTest

@available(iOS 16.0, *)
class LifecycleObservingClientTests: XCTestCase {
    struct MockClient: CheckoutCommunicationProtocol {
        let handler: @Sendable (String) async -> String?

        func process(_ message: String) async -> String? {
            return await handler(message)
        }
    }

    // MARK: - With base client

    @MainActor
    func test_process_whenEcCompleteReceived_firesOnCompleteAndDelegatesToBase() async {
        let baseProcessed = XCTestExpectation(description: "Base client should process the message")
        let onCompleteFired = XCTestExpectation(description: "onComplete should fire")

        let base = MockClient { _ in
            baseProcessed.fulfill()
            return "{\"result\": \"ok\"}"
        }

        let client = LifecycleObservingClient(base: base, onComplete: {
            onCompleteFired.fulfill()
        })

        let message = "{\"jsonrpc\": \"2.0\", \"method\": \"ec.complete\", \"params\": {}}"
        let result = await client.process(message)

        await fulfillment(of: [onCompleteFired, baseProcessed], timeout: 1.0)
        XCTAssertEqual(result, "{\"result\": \"ok\"}")
    }

    @MainActor
    func test_process_whenNonLifecycleMessage_doesNotFireOnComplete() async {
        let onCompleteFired = XCTestExpectation(description: "onComplete should not fire")
        onCompleteFired.isInverted = true

        let base = MockClient { _ in return nil }

        let client = LifecycleObservingClient(base: base, onComplete: {
            onCompleteFired.fulfill()
        })

        let message = "{\"jsonrpc\": \"2.0\", \"method\": \"ec.other\", \"params\": {}}"
        let result = await client.process(message)

        await fulfillment(of: [onCompleteFired], timeout: 0.5)
        XCTAssertNil(result)
    }

    // MARK: - With nil base client

    @MainActor
    func test_process_whenBaseIsNilAndEcCompleteReceived_firesOnComplete() async {
        let onCompleteFired = XCTestExpectation(description: "onComplete should fire")

        let client = LifecycleObservingClient(base: nil, onComplete: {
            onCompleteFired.fulfill()
        })

        let message = "{\"jsonrpc\": \"2.0\", \"method\": \"ec.complete\", \"params\": {}}"
        let result = await client.process(message)

        await fulfillment(of: [onCompleteFired], timeout: 1.0)
        XCTAssertNil(result)
    }

    @MainActor
    func test_process_whenBaseIsNilAndNonLifecycleMessage_doesNotFireOnComplete() async {
        let onCompleteFired = XCTestExpectation(description: "onComplete should not fire")
        onCompleteFired.isInverted = true

        let client = LifecycleObservingClient(base: nil, onComplete: {
            onCompleteFired.fulfill()
        })

        let message = "{\"jsonrpc\": \"2.0\", \"method\": \"ec.other\", \"params\": {}}"
        let result = await client.process(message)

        await fulfillment(of: [onCompleteFired], timeout: 0.5)
        XCTAssertNil(result)
    }
}
