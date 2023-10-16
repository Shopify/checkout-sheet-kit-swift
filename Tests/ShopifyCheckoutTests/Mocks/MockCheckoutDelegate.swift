import XCTest
@testable import ShopifyCheckout

class ExampleDelegate: CheckoutDelegate {
    func checkoutDidComplete() {
    }

    func checkoutDidCancel() {
    }

    func checkoutDidFail(errors: [ShopifyCheckout.CheckoutError]) {
    }

    func checkoutDidFail(error: ShopifyCheckout.CheckoutError) {
    }

    func checkoutDidClickContactLink(url: URL) {
    }
}
