/*
 MIT License

 Copyright 2023 - Present, Shopify Inc.

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to do so, subject to the
 following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

@testable import ShopifyCheckoutSheetKit
import XCTest

final class EmbedParametersTests: XCTestCase {
    private var originalConfiguration: ShopifyCheckoutSheetKit.Configuration!

    override func setUp() {
        super.setUp()
        originalConfiguration = ShopifyCheckoutSheetKit.configuration
        ShopifyCheckoutSheetKit.configuration = ShopifyCheckoutSheetKit.Configuration()
    }

    override func tearDown() {
        ShopifyCheckoutSheetKit.configuration = originalConfiguration
        originalConfiguration = nil
        super.tearDown()
    }

    func test_build_withDefaultConfiguration_returnsExpectedFields() {
        let result = EmbedParamBuilder.build(entryPoint: nil)

        XCTAssertEqual(
            result,
            "protocol=\(MetaData.schemaVersion), branding=app, library=CheckoutKit/\(trimmedMetaDataVersion()), platform=swift, entry=sheet"
        )
    }

    func test_build_withDarkColorScheme_includesColorScheme() {
        ShopifyCheckoutSheetKit.configuration.colorScheme = .dark

        let result = EmbedParamBuilder.build(entryPoint: nil)

        XCTAssertTrue(result.contains("colorscheme=dark"))
    }

    func test_build_withWebColorScheme_setsBrandingToShopAndOmitsColorScheme() {
        ShopifyCheckoutSheetKit.configuration.colorScheme = .web

        let result = EmbedParamBuilder.build(entryPoint: nil)

        XCTAssertTrue(result.contains("branding=shop"))
        XCTAssertFalse(result.contains("colorscheme="))
    }

    func test_build_withPlatformAndEntryPoint_includesPlatformAndEntryPoint() {
        ShopifyCheckoutSheetKit.configuration.platform = .reactNative

        let result = EmbedParamBuilder.build(entryPoint: .acceleratedCheckouts)

        XCTAssertTrue(result.contains("platform=\(MetaData.Platform.reactNative.rawValue)"))
        XCTAssertTrue(result.contains("entrypoint=\(MetaData.EntryPoint.acceleratedCheckouts.rawValue)"))
        XCTAssertTrue(result.contains("entry=\(EmbedFieldValue.entryWallet)"))
    }

    func test_build_withRecovery_setsRecoveryFlag() {
        let result = EmbedParamBuilder.build(isRecovery: true, entryPoint: nil)

        XCTAssertTrue(result.contains("recovery=true"))
    }

    func test_withEmbedParam_appendsEmbedQueryWhenMissing() {
        let url = URL(string: "https://example.com/checkout")!
        let result = url.withEmbedParam(isRecovery: false, entryPoint: nil)

        let components = URLComponents(url: result, resolvingAgainstBaseURL: false)
        let embedValue = components?.queryItems?.first(where: { $0.name == EmbedQueryParamKey.embed })?.value

        XCTAssertNotNil(embedValue)
        XCTAssertTrue(embedValue?.contains("protocol=\(MetaData.schemaVersion)") ?? false)
    }

    func test_withEmbedParam_setsWalletEntryForAcceleratedCheckouts() {
        let url = URL(string: "https://example.com/checkout")!
        let result = url.withEmbedParam(isRecovery: false, entryPoint: .acceleratedCheckouts)

        let components = URLComponents(url: result, resolvingAgainstBaseURL: false)
        let embedValue = components?.queryItems?.first(where: { $0.name == EmbedQueryParamKey.embed })?.value

        XCTAssertNotNil(embedValue)
        XCTAssertTrue(embedValue?.contains("entry=\(EmbedFieldValue.entryWallet)") ?? false)
    }

    func test_withEmbedParam_overridesExistingEmbedValue() {
        let url = URL(string: "https://example.com/checkout?embed=foo")!
        let result = url.withEmbedParam(isRecovery: false, entryPoint: nil)

        let components = URLComponents(url: result, resolvingAgainstBaseURL: false)
        let embedValue = components?.queryItems?.first(where: { $0.name == EmbedQueryParamKey.embed })?.value

        XCTAssertNotNil(embedValue)
        XCTAssertTrue(embedValue?.contains("entry=\(EmbedFieldValue.entrySheet)") ?? false)
    }

    func test_withEmbedParam_updatesEmbedValueWhenRecoveryFlagNeeded() {
        let standardEmbed = EmbedParamBuilder.build(isRecovery: false, entryPoint: nil)
        var components = URLComponents(string: "https://example.com/checkout")!
        components.queryItems = [URLQueryItem(name: EmbedQueryParamKey.embed, value: standardEmbed)]

        let baseURL = components.url!
        let result = baseURL.withEmbedParam(isRecovery: true, entryPoint: nil)

        let updatedComponents = URLComponents(url: result, resolvingAgainstBaseURL: false)
        let embedValue = updatedComponents?.queryItems?.first(where: { $0.name == EmbedQueryParamKey.embed })?.value

        XCTAssertNotNil(embedValue)
        XCTAssertTrue(embedValue?.contains("recovery=true") ?? false)
    }

    func test_build_withShopPayPayment_setsEntryToShopPay() {
        var components = URLComponents(string: "https://example.com/checkout")!
        components.queryItems = [URLQueryItem(name: "payment", value: "shop_pay")]

        let result = EmbedParamBuilder.build(
            entryPoint: .acceleratedCheckouts,
            sourceComponents: components
        )

        XCTAssertTrue(result.contains("entry=\(EmbedFieldValue.entryShopPay)"))
    }

    func test_withEmbedParam_preservesShopPayEntry() {
        let baseURL = URL(string: "https://example.com/checkout?payment=shop_pay")!
        let result = baseURL.withEmbedParam(isRecovery: false, entryPoint: .acceleratedCheckouts)

        let updatedComponents = URLComponents(url: result, resolvingAgainstBaseURL: false)
        let embedValue = updatedComponents?.queryItems?.first(where: { $0.name == EmbedQueryParamKey.embed })?.value

        XCTAssertNotNil(embedValue)
        XCTAssertTrue(embedValue?.contains("entry=\(EmbedFieldValue.entryShopPay)") ?? false)
    }

    // MARK: Helpers

    private func trimmedMetaDataVersion() -> String {
        MetaData.version.split(separator: "-").first.map(String.init) ?? MetaData.version
    }
}
