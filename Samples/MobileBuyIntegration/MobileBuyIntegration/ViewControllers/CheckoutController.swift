import OSLog
import ShopifyCheckoutProtocol
@preconcurrency import ShopifyCheckoutSheetKit
import UIKit

class CheckoutController: UIViewController {
    var window: UIWindow?
    var root: UIViewController?

    private let client = CheckoutProtocol.Client()
        .on(CheckoutProtocol.start) { checkout in
            OSLogger.shared.debug("[UCP] Checkout started: \(checkout.id)")
        }
        .on(CheckoutProtocol.complete) { checkout in
            OSLogger.shared.debug("[UCP] Checkout completed: \(checkout.order?.id ?? "unknown")")
            CartManager.shared.resetCart()
        }

    init(window: UIWindow?) {
        self.window = window
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public static var shared: CheckoutController?

    public func present(checkout url: URL) {
        if let rootViewController = window?.topMostViewController() {
            ShopifyCheckoutSheetKit.present(checkout: url.appendingEcParams(), from: rootViewController, client: client)
            root = rootViewController
        }
    }

    public func preload() {
        CartManager.shared.preloadCheckout()
    }
}
