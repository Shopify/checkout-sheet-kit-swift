@testable import ShopifyCheckoutSheetKit
import XCTest

struct MockBridgeClient: CheckoutCommunicationProtocol {
    var responseMessage: String?
    var receivedMessages: [String] = []

    func process(_: String) async -> String? {
        return responseMessage
    }
}
