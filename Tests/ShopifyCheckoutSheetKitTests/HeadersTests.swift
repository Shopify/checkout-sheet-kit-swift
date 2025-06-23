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

import XCTest
@testable import ShopifyCheckoutSheetKit

class HeadersTests: XCTestCase {
	private var initialConfiguration: Configuration!

	override func setUp() {
		super.setUp()
		initialConfiguration = ShopifyCheckoutSheetKit.configuration
	}

	override func tearDown() {
		ShopifyCheckoutSheetKit.configuration = initialConfiguration
		super.tearDown()
	}

	func testCheckoutKitHeadersIncludesColorSchemeAndBrandingForDarkColorScheme() {
		ShopifyCheckoutSheetKit.configuration.colorScheme = .dark

		let headers = checkoutKitHeaders()

		XCTAssertEqual(headers[Headers.prefersColorScheme], "dark")
		XCTAssertEqual(headers[Headers.branding], Headers.brandingCheckoutKit)
		XCTAssertNil(headers[Headers.purpose])
		XCTAssertEqual(headers.count, 2)
	}

	func testCheckoutKitHeadersIncludesColorSchemeAndBrandingForLightColorScheme() {
		ShopifyCheckoutSheetKit.configuration.colorScheme = .light

		let headers = checkoutKitHeaders()

		XCTAssertEqual(headers[Headers.prefersColorScheme], "light")
		XCTAssertEqual(headers[Headers.branding], Headers.brandingCheckoutKit)
		XCTAssertNil(headers[Headers.purpose])
		XCTAssertEqual(headers.count, 2)
	}

	func testCheckoutKitHeadersOnlyIncludesBrandingForWebColorScheme() {
		ShopifyCheckoutSheetKit.configuration.colorScheme = .web

		let headers = checkoutKitHeaders()

		XCTAssertNil(headers[Headers.prefersColorScheme])
		XCTAssertEqual(headers[Headers.branding], Headers.brandingWeb)
		XCTAssertNil(headers[Headers.purpose])
		XCTAssertEqual(headers.count, 1)
	}

	func testCheckoutKitHeadersOnlyIncludesBrandingForAutomaticColorScheme() {
		ShopifyCheckoutSheetKit.configuration.colorScheme = .automatic

		let headers = checkoutKitHeaders()

		XCTAssertNil(headers[Headers.prefersColorScheme])
		XCTAssertEqual(headers[Headers.branding], Headers.brandingCheckoutKit)
		XCTAssertNil(headers[Headers.purpose])
		XCTAssertEqual(headers.count, 1)
	}

	func testCheckoutKitHeadersIncludesPurposeHeaderWhenIsPreloadIsTrue() {
		ShopifyCheckoutSheetKit.configuration.colorScheme = .dark

		let headers = checkoutKitHeaders(isPreload: true)

		XCTAssertEqual(headers[Headers.purpose], Headers.purposePrefetch)
		XCTAssertEqual(headers[Headers.prefersColorScheme], "dark")
		XCTAssertEqual(headers[Headers.branding], Headers.brandingCheckoutKit)
		XCTAssertEqual(headers.count, 3)
	}

	func testCheckoutKitHeadersWithIsPreloadTrueAndWebColorScheme() {
		ShopifyCheckoutSheetKit.configuration.colorScheme = .web

		let headers = checkoutKitHeaders(isPreload: true)

		XCTAssertEqual(headers[Headers.purpose], Headers.purposePrefetch)
		XCTAssertNil(headers[Headers.prefersColorScheme])
		XCTAssertEqual(headers[Headers.branding], Headers.brandingWeb)
		XCTAssertEqual(headers.count, 2)
	}

	func testCheckoutKitHeadersWithIsPreloadTrueAndAutomaticColorScheme() {
		ShopifyCheckoutSheetKit.configuration.colorScheme = .automatic

		let headers = checkoutKitHeaders(isPreload: true)

		XCTAssertEqual(headers[Headers.purpose], Headers.purposePrefetch)
		XCTAssertNil(headers[Headers.prefersColorScheme])
		XCTAssertEqual(headers[Headers.branding], Headers.brandingCheckoutKit)
		XCTAssertEqual(headers.count, 2)
	}

	func testWithColorSchemeAddsColorSchemeHeaderForDarkColorScheme() {
		ShopifyCheckoutSheetKit.configuration.colorScheme = .dark

		let headers = ["existing": "value"]
		let result = headers.withColorScheme()

		XCTAssertEqual(result["existing"], "value")
		XCTAssertEqual(result[Headers.prefersColorScheme], "dark")
		XCTAssertEqual(result.count, 2)
	}

	func testWithColorSchemeAddsColorSchemeHeaderForLightColorScheme() {
		ShopifyCheckoutSheetKit.configuration.colorScheme = .light

		let headers: [String: String] = [:]
		let result = headers.withColorScheme()

		XCTAssertEqual(result[Headers.prefersColorScheme], "light")
	}

	func testWithColorSchemeDoesNotAddColorSchemeHeaderForWebColorScheme() {
		ShopifyCheckoutSheetKit.configuration.colorScheme = .web

		let headers = ["existing": "value"]
		let result = headers.withColorScheme()

		XCTAssertEqual(result["existing"], "value")
		XCTAssertNil(result[Headers.prefersColorScheme])
		XCTAssertEqual(result.count, 1)
	}

	func testWithColorSchemeDoesNotAddColorSchemeHeaderForAutomaticColorScheme() {
		ShopifyCheckoutSheetKit.configuration.colorScheme = .automatic

		let headers = ["existing": "value"]
		let result = headers.withColorScheme()

		XCTAssertEqual(result["existing"], "value")
		XCTAssertNil(result[Headers.prefersColorScheme])
		XCTAssertEqual(result.count, 1)
	}

	func testWithBrandingAddsCheckoutKitBrandingForNonWebColorSchemes() {
		ShopifyCheckoutSheetKit.configuration.colorScheme = .dark

		let headers = ["existing": "value"]
		let result = headers.withBranding()

		XCTAssertEqual(result["existing"], "value")
		XCTAssertEqual(result[Headers.branding], Headers.brandingCheckoutKit)
		XCTAssertEqual(result.count, 2)
	}

	func testWithBrandingAddsWebBrandingForWebColorScheme() {
		ShopifyCheckoutSheetKit.configuration.colorScheme = .web

		let headers = ["existing": "value"]
		let result = headers.withBranding()

		XCTAssertEqual(result["existing"], "value")
		XCTAssertEqual(result[Headers.branding], Headers.brandingWeb)
		XCTAssertEqual(result.count, 2)
	}

	func testHasColorSchemeHeaderReturnsTrueWhenColorSchemeHeaderExists() {
		let headers = [Headers.prefersColorScheme: "dark"]

		XCTAssertTrue(headers.hasColorSchemeHeader())
	}

	func testHasColorSchemeHeaderReturnsFalseWhenColorSchemeHeaderDoesNotExist() {
		let headers = ["other": "value"]

		XCTAssertFalse(headers.hasColorSchemeHeader())
	}

	func testHasColorSchemeHeaderIsCaseInsensitive() {
		let headers = [Headers.prefersColorScheme.lowercased(): "dark"]

		XCTAssertTrue(headers.hasColorSchemeHeader())
	}

	func testHasBrandingHeaderReturnsTrueWhenBrandingHeaderExists() {
		let headers = [Headers.branding: Headers.brandingCheckoutKit]

		XCTAssertTrue(headers.hasBrandingHeader())
	}

	func testHasBrandingHeaderReturnsFalseWhenBrandingHeaderDoesNotExist() {
		let headers = ["other": "value"]

		XCTAssertFalse(headers.hasBrandingHeader())
	}

	func testHasBrandingHeaderIsCaseInsensitive() {
		let headers = [Headers.branding.lowercased(): Headers.brandingCheckoutKit]

		XCTAssertTrue(headers.hasBrandingHeader())
	}
}