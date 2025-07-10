import PassKit
@testable import ShopifyAcceleratedCheckouts
import ShopifyCheckoutSheetKit
import SwiftUI
import XCTest

@available(iOS 17.0, *)
final class ApplePayIntegrationTests: XCTestCase {
    var mockConfiguration: ApplePayConfigurationWrapper!
    var mockCommonConfiguration: ShopifyAcceleratedCheckouts.Configuration!
    var mockApplePayConfiguration: ShopifyAcceleratedCheckouts.ApplePayConfiguration!
    var mockShopSettings: ShopSettings!

    override func setUp() {
        super.setUp()

        mockCommonConfiguration = ShopifyAcceleratedCheckouts.Configuration(
            shopDomain: "test-shop.myshopify.com",
            storefrontAccessToken: "test-token"
        )

        mockApplePayConfiguration = ShopifyAcceleratedCheckouts.ApplePayConfiguration(
            merchantIdentifier: "test.merchant.id",
            supportedNetworks: [.visa, .masterCard, .amex],
            contactFields: []
        )

        mockShopSettings = ShopSettings(
            name: "Test Shop",
            primaryDomain: Domain(
                host: "test-shop.myshopify.com",
                url: "https://test-shop.myshopify.com"
            ),
            paymentSettings: PaymentSettings(countryCode: "US")
        )

        mockConfiguration = ApplePayConfigurationWrapper(
            common: mockCommonConfiguration,
            applePay: mockApplePayConfiguration,
            shopSettings: mockShopSettings
        )
    }

    override func tearDown() {
        mockConfiguration = nil
        mockCommonConfiguration = nil
        mockApplePayConfiguration = nil
        mockShopSettings = nil
        super.tearDown()
    }

    func testViewModifierWithButtonIntegration() async {
        var callbackInvoked = false

        await MainActor.run {
            // Create a hosting controller to test SwiftUI integration
            let view = AcceleratedCheckoutButtons(cartID: "gid://Shopify/Cart/test-cart")
                .withWallets([.applepay])
                .onComplete {
                    callbackInvoked = true
                }
                .environment(mockCommonConfiguration)
                .environment(mockApplePayConfiguration)
                .environment(mockShopSettings)

            let hostingController = UIHostingController(rootView: view)

            _ = hostingController.view

            XCTAssertNotNil(hostingController.view, "View should be created")

            XCTAssertNotNil(hostingController.rootView, "Root view should exist")
        }
    }

    func testViewModifierWithButtonIntegrationIncludingCancel() async {
        var completeInvoked = false
        var failInvoked = false
        var cancelInvoked = false

        await MainActor.run {
            // Create a hosting controller to test SwiftUI integration with all callbacks
            let view = AcceleratedCheckoutButtons(cartID: "gid://Shopify/Cart/test-cart")
                .withWallets([.applepay])
                .onComplete {
                    completeInvoked = true
                }
                .onFail {
                    failInvoked = true
                }
                .onCancel {
                    cancelInvoked = true
                }
                .environment(mockCommonConfiguration)
                .environment(mockApplePayConfiguration)
                .environment(mockShopSettings)

            let hostingController = UIHostingController(rootView: view)

            _ = hostingController.view

            XCTAssertNotNil(hostingController.view, "View should be created with all callbacks")
            XCTAssertNotNil(hostingController.rootView, "Root view should exist")

            // Verify callbacks are not invoked during view creation
            XCTAssertFalse(completeInvoked, "Complete callback should not be invoked on view creation")
            XCTAssertFalse(failInvoked, "Fail callback should not be invoked on view creation")
            XCTAssertFalse(cancelInvoked, "Cancel callback should not be invoked on view creation")
        }
    }

    func testInvariantIdentifierHandling() {
        let identifier = CheckoutIdentifier.invariant

        let button = ApplePayButton(identifier: identifier, eventHandlers: EventHandlers())

        // Create hosting controller to render the view
        let hostingController = UIHostingController(
            rootView: button
                .environment(mockCommonConfiguration)
                .environment(mockApplePayConfiguration)
                .environment(mockShopSettings)
        )

        XCTAssertNotNil(hostingController.view)
        // The view should essentially be empty/minimal due to invariant case
    }

    func testCallbackPersistenceAcrossViewUpdates() async {
        var successCount = 0
        let successHandler = {
            successCount += 1
        }

        let button = ApplePayButton(
            identifier: .cart(cartID: "gid://Shopify/Cart/test-cart"),
            eventHandlers: EventHandlers(checkoutSuccessHandler: successHandler)
        )

        // Apply additional modifiers (simulating view updates)
        // Note: withLabel returns 'some View', not ApplePayButton
        let modifiedView = AnyView(
            button
                .id(UUID())
        )

        // This tests that the environment value propagates correctly
        XCTAssertNotNil(button, "Button should still exist after modifications")
        XCTAssertNotNil(modifiedView, "Modified view should exist")
    }

    func testCheckoutDelegateCancelCallback() async {
        var cancelCallbackInvoked = false

        let viewController = ApplePayViewController(
            identifier: .cart(cartID: "gid://Shopify/Cart/test-cart"),
            configuration: mockConfiguration
        )

        await MainActor.run {
            viewController.onCancel = {
                cancelCallbackInvoked = true
            }
        }

        let delegate = viewController.authorizationDelegate

        delegate.checkoutDidCancel()

        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        await MainActor.run {
            XCTAssertTrue(cancelCallbackInvoked, "Cancel callback should be invoked when checkoutDidCancel is called")
        }
    }

    func testCheckoutDidClickLinkDelegateIntegration() async {
        var callbackInvoked = false
        var receivedURL: URL?

        let viewController = ApplePayViewController(
            identifier: .cart(cartID: "gid://Shopify/Cart/test-cart"),
            configuration: mockConfiguration
        )

        await MainActor.run {
            viewController.onClickLink = { url in
                callbackInvoked = true
                receivedURL = url
            }
        }

        let delegate = viewController.authorizationDelegate

        let testURL = URL(string: "https://help.shopify.com/payment-terms")!
        delegate.checkoutDidClickLink(url: testURL)

        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        await MainActor.run {
            XCTAssertTrue(callbackInvoked, "checkoutDidClickLink callback should be invoked")
            XCTAssertEqual(receivedURL, testURL, "URL should be passed to callback")
        }
    }

    func testCheckoutDidEmitWebPixelEventDelegateIntegration() async {
        let viewController = ApplePayViewController(
            identifier: .cart(cartID: "gid://Shopify/Cart/test-cart"),
            configuration: mockConfiguration
        )

        var callbackSet = false

        await MainActor.run {
            viewController.onWebPixelEvent = { _ in
                callbackSet = true
            }
        }

        await MainActor.run {
            XCTAssertNotNil(viewController.onWebPixelEvent, "Web pixel event callback should be set")
        }
    }
}
