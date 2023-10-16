import XCTest
import WebKit
@testable import ShopifyCheckout

class CheckoutViewDelegateTests: XCTestCase {

    private let checkoutURL = URL(string: "https://checkout-sdk.myshopify.com")!
    private var viewController: CheckoutViewController!

    override func setUp() {
        ShopifyCheckout.configure {
            $0.preloading.enabled = true
        }
        viewController = CheckoutViewController(
            checkoutURL: checkoutURL, delegate: ExampleDelegate())
    }

    func testTitleIsSetToCheckout() {
        XCTAssertEqual(viewController.title, "Checkout")
    }

    func testCheckoutViewDidCompleteCheckoutInvalidatesViewCache() {
        let one = CheckoutView.for(checkout: checkoutURL)
        let two = CheckoutView.for(checkout: checkoutURL)
        XCTAssertEqual(one, two)

        viewController.checkoutViewDidCompleteCheckout()

        let three = CheckoutView.for(checkout: checkoutURL)
        XCTAssertNotEqual(two, three)
    }

    func testCheckoutViewDidFailWithErrorInvalidatesViewCache() {
        let one = CheckoutView.for(checkout: checkoutURL)
        let two = CheckoutView.for(checkout: checkoutURL)
        XCTAssertEqual(one, two)

        viewController.checkoutViewDidFailWithError(error: .checkoutUnavailable(message: "error"))

        let three = CheckoutView.for(checkout: checkoutURL)
        XCTAssertNotEqual(two, three)
    }

    func testCloseInvalidatesViewCache() {
        let one = CheckoutView.for(checkout: checkoutURL)
        let two = CheckoutView.for(checkout: checkoutURL)
        XCTAssertEqual(one, two)

        viewController.close()

        let three = CheckoutView.for(checkout: checkoutURL)
        XCTAssertNotEqual(two, three)
    }

    func testCheckoutViewDidClickLinkDoesNotInvalidateViewCache() {
        let one = CheckoutView.for(checkout: checkoutURL)
        let two = CheckoutView.for(checkout: checkoutURL)
        XCTAssertEqual(one, two)

        viewController.checkoutViewDidClickLink(url: URL(string: "https://shopify.com/anything")!)

        let three = CheckoutView.for(checkout: checkoutURL)
        XCTAssertEqual(two, three)
    }
}
