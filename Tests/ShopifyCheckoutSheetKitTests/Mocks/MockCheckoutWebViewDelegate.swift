@testable import ShopifyCheckoutSheetKit
import XCTest

class MockCheckoutWebViewDelegate: CheckoutWebViewDelegate {
    var errorReceived: CheckoutError?

    var didStartNavigationExpectation: XCTestExpectation?
    var didFinishNavigationExpectation: XCTestExpectation?
    var didClickLinkExpectation: XCTestExpectation?
    var didFailWithErrorExpectation: XCTestExpectation?

    func checkoutViewDidStartNavigation() {
        didStartNavigationExpectation?.fulfill()
    }

    func checkoutViewDidFinishNavigation() {
        didFinishNavigationExpectation?.fulfill()
    }

    func checkoutViewDidClickLink(url _: URL) {
        didClickLinkExpectation?.fulfill()
    }

    func checkoutViewDidFailWithError(error: CheckoutError) {
        errorReceived = error
        didFailWithErrorExpectation?.fulfill()
    }
}
