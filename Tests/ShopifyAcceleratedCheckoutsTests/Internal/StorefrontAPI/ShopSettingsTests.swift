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
import XCTest

@available(iOS 17.0, *)
class ShopSettingsTests: XCTestCase {
    func testBasicInitialization() throws {
        let domain = Domain(host: "test-shop.myshopify.com", url: "https://test-shop.myshopify.com")
        let paymentSettings = PaymentSettings(countryCode: "US")

        let shopSettings = ShopSettings(
            name: "Test Shop",
            primaryDomain: domain,
            paymentSettings: paymentSettings
        )

        XCTAssertEqual(shopSettings.name, "Test Shop")
        XCTAssertEqual(shopSettings.primaryDomain.host, "test-shop.myshopify.com")
        XCTAssertEqual(shopSettings.primaryDomain.url, "https://test-shop.myshopify.com")
        XCTAssertEqual(shopSettings.paymentSettings.countryCode, "US")
    }

    func testConvenienceInitFromApiShop() throws {
        let mockShop = try createMockApiShop(
            name: "Mock Shop",
            host: "mock-shop.myshopify.com",
            url: "https://mock-shop.myshopify.com",
            countryCode: "CA"
        )

        let shopSettings = ShopSettings(from: mockShop)

        XCTAssertEqual(shopSettings.name, "Mock Shop")
        XCTAssertEqual(shopSettings.primaryDomain.host, "mock-shop.myshopify.com")
        XCTAssertEqual(shopSettings.primaryDomain.url, "https://mock-shop.myshopify.com")
        XCTAssertEqual(shopSettings.paymentSettings.countryCode, "CA")
    }

    private func createMockApiShop(
        name: String = "Test Shop",
        host: String = "test-shop.myshopify.com",
        url: String = "https://test-shop.myshopify.com",
        countryCode: String = "US"
    ) throws -> StorefrontAPI.Shop {
        // Create mock data with proper structure
        let mockShop = StorefrontAPI.Shop(
            name: name,
            description: "Mock shop description",
            primaryDomain: StorefrontAPI.ShopDomain(
                host: host,
                sslEnabled: true,
                url: GraphQLScalars.URL(Foundation.URL(string: url)!)
            ),
            shipsToCountries: ["US", "CA"],
            paymentSettings: StorefrontAPI.ShopPaymentSettings(
                supportedDigitalWallets: ["APPLE_PAY", "SHOP_PAY"],
                acceptedCardBrands: [.visa, .mastercard],
                countryCode: countryCode
            ),
            moneyFormat: "${{amount}}"
        )

        return mockShop
    }
}
