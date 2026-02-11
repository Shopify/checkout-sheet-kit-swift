@testable import ShopifyCheckoutSheetKit
import XCTest

struct MockBridgeHandler: CheckoutBridgeHandler {
    var readyMessage: String
    var responseMessage: String?
    var receivedMessages: [String] = []

    func handleMessage(_ message: String) async -> String? {
        return responseMessage
    }
}
