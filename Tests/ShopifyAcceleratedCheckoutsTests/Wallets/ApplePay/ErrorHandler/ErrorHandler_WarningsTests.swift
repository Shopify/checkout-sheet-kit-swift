
@testable import ShopifyAcceleratedCheckouts
import XCTest

class ErrorHandler_WarningsTests: XCTestCase {
    func testMap_outOfStock() {
        let checkoutURL = URL(string: "https://checkout.example.com")!
        let cart = StorefrontAPI.Cart(
            id: GraphQLScalars.ID("test-cart-id"),
            checkoutUrl: GraphQLScalars.URL(checkoutURL),
            totalQuantity: 1,
            buyerIdentity: nil,
            deliveryGroups: StorefrontAPI.CartDeliveryGroupConnection(nodes: []),
            delivery: nil,
            lines: StorefrontAPI.BaseCartLineConnection(nodes: []),
            cost: StorefrontAPI.CartCost(
                totalAmount: StorefrontAPI.MoneyV2(amount: 0, currencyCode: "USD"),
                subtotalAmount: StorefrontAPI.MoneyV2(amount: 0, currencyCode: "USD"),
                totalTaxAmount: nil,
                totalDutyAmount: nil
            ),
            discountCodes: [],
            discountAllocations: []
        )

        let result = ErrorHandler.map(warningType: Api.WarningType.outOfStock, cart: cart)

        switch result {
        case let .interrupt(reason, url):
            XCTAssertEqual(reason, ErrorHandler.InterruptReason.outOfStock)
            XCTAssertEqual(url, checkoutURL)
        default:
            XCTFail("Expected interrupt action with outOfStock reason")
        }
    }

    func testMap_notEnoughStock() {
        let checkoutURL = URL(string: "https://checkout.example.com")!
        let cart = StorefrontAPI.Cart(
            id: GraphQLScalars.ID("test-cart-id"),
            checkoutUrl: GraphQLScalars.URL(checkoutURL),
            totalQuantity: 1,
            buyerIdentity: nil,
            deliveryGroups: StorefrontAPI.CartDeliveryGroupConnection(nodes: []),
            delivery: nil,
            lines: StorefrontAPI.BaseCartLineConnection(nodes: []),
            cost: StorefrontAPI.CartCost(
                totalAmount: StorefrontAPI.MoneyV2(amount: 0, currencyCode: "USD"),
                subtotalAmount: StorefrontAPI.MoneyV2(amount: 0, currencyCode: "USD"),
                totalTaxAmount: nil,
                totalDutyAmount: nil
            ),
            discountCodes: [],
            discountAllocations: []
        )

        let result = ErrorHandler.map(warningType: Api.WarningType.notEnoughStock, cart: cart)

        switch result {
        case let .interrupt(reason, url):
            XCTAssertEqual(reason, ErrorHandler.InterruptReason.notEnoughStock)
            XCTAssertEqual(url, checkoutURL)
        default:
            XCTFail("Expected interrupt action with notEnoughStock reason")
        }
    }
}
