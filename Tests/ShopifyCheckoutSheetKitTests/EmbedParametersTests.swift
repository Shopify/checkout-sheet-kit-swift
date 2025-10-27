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
            "protocol=\(MetaData.schemaVersion),branding=app,library=CheckoutKit/\(trimmedMetaDataVersion()),platform=swift,entry=sheet"
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
        let options = CheckoutOptions(entryPoint: .acceleratedCheckouts)

        let result = EmbedParamBuilder.build(entryPoint: options.entryPoint, options: options)

        XCTAssertTrue(result.contains("platform=react-native-swift"))
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
        let options = CheckoutOptions(entryPoint: .acceleratedCheckouts)
        let result = url.withEmbedParam(isRecovery: false, entryPoint: options.entryPoint, options: options)

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
        let options = CheckoutOptions(entryPoint: .acceleratedCheckouts)

        let result = EmbedParamBuilder.build(
            entryPoint: options.entryPoint,
            sourceComponents: components,
            options: options
        )

        XCTAssertTrue(result.contains("entry=\(EmbedFieldValue.entryShopPay)"))
    }

    func test_withEmbedParam_preservesShopPayEntry() {
        let baseURL = URL(string: "https://example.com/checkout?payment=shop_pay")!
        let options = CheckoutOptions(entryPoint: .acceleratedCheckouts)
        let result = baseURL.withEmbedParam(isRecovery: false, entryPoint: options.entryPoint, options: options)

        let updatedComponents = URLComponents(url: result, resolvingAgainstBaseURL: false)
        let embedValue = updatedComponents?.queryItems?.first(where: { $0.name == EmbedQueryParamKey.embed })?.value

        XCTAssertNotNil(embedValue)
        XCTAssertTrue(embedValue?.contains("entry=\(EmbedFieldValue.entryShopPay)") ?? false)
    }

    // MARK: Authentication Tests

    func test_build_withAuthenticationToken_includesAuthenticationInEmbed() {
        let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test"
        let options = CheckoutOptions(authentication: .token(token))

        let result = EmbedParamBuilder.build(entryPoint: nil, options: options)

        XCTAssertTrue(result.contains("authentication=\(token)"))
    }

    func test_build_withoutAuthentication_omitsAuthenticationField() {
        let result = EmbedParamBuilder.build(entryPoint: nil, options: nil)

        XCTAssertFalse(result.contains("authentication="))
    }

    func test_withEmbedParam_includesAuthenticationToken() {
        let url = URL(string: "https://example.com/checkout")!
        let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test"
        let options = CheckoutOptions(authentication: .token(token))

        let result = url.withEmbedParam(isRecovery: false, entryPoint: nil, options: options)

        let components = URLComponents(url: result, resolvingAgainstBaseURL: false)
        let embedValue = components?.queryItems?.first(where: { $0.name == EmbedQueryParamKey.embed })?.value

        XCTAssertNotNil(embedValue)
        XCTAssertTrue(embedValue?.contains("authentication=\(token)") ?? false)
    }

    func test_withEmbedParam_updatesEmbedValueWhenAuthenticationChanges() {
        let url = URL(string: "https://example.com/checkout")!
        let oldToken = "old_token"
        let newToken = "new_token"

        // First add with old token
        let urlWithOldToken = url.withEmbedParam(
            isRecovery: false,
            entryPoint: nil,
            options: CheckoutOptions(authentication: .token(oldToken))
        )

        // Then update with new token
        let result = urlWithOldToken.withEmbedParam(
            isRecovery: false,
            entryPoint: nil,
            options: CheckoutOptions(authentication: .token(newToken))
        )

        let components = URLComponents(url: result, resolvingAgainstBaseURL: false)
        let embedValue = components?.queryItems?.first(where: { $0.name == EmbedQueryParamKey.embed })?.value

        XCTAssertNotNil(embedValue)
        XCTAssertTrue(embedValue?.contains("authentication=\(newToken)") ?? false)
        XCTAssertFalse(embedValue?.contains("authentication=\(oldToken)") ?? true)
    }

    func test_needsEmbedUpdate_returnsFalseWhenAuthenticationChanges() {
        // Authentication changes should NOT trigger an update
        // (tokens are excluded from comparison for security reasons)
        let url = URL(string: "https://example.com/checkout")!
        let oldToken = "old_token"
        let newToken = "new_token"

        let urlWithOldToken = url.withEmbedParam(
            isRecovery: false,
            entryPoint: nil,
            options: CheckoutOptions(authentication: .token(oldToken))
        )

        let needsUpdate = urlWithOldToken.needsEmbedUpdate(
            isRecovery: false,
            entryPoint: nil,
            options: CheckoutOptions(authentication: .token(newToken))
        )

        XCTAssertFalse(needsUpdate)
    }

    func test_embedParamMatches_ignoresAuthenticationDifferences() {
        // Authentication tokens should be ignored when comparing embed params
        let url = URL(string: "https://example.com/checkout")!
        let token = "some_token"
        let options = CheckoutOptions(authentication: .token(token))

        let urlWithToken = url.withEmbedParam(
            isRecovery: false,
            entryPoint: nil,
            options: options
        )

        // Should match even with different auth token
        let matches = urlWithToken.embedParamMatches(
            isRecovery: false,
            entryPoint: nil,
            options: CheckoutOptions(authentication: .token("different_token"))
        )

        XCTAssertTrue(matches)
    }

    // MARK: Helpers

    private func trimmedMetaDataVersion() -> String {
        MetaData.version.split(separator: "-").first.map(String.init) ?? MetaData.version
    }
}
