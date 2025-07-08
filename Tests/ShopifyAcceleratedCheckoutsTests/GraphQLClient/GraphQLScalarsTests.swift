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

//
//  GraphQLScalarsTests.swift
//  ShopifyAcceleratedCheckoutsTests
//

@testable import ShopifyAcceleratedCheckouts
import XCTest

final class GraphQLScalarsTests: XCTestCase {
    // MARK: - ID Scalar Tests

    func testIDInitialization() {
        // Test direct initialization
        let id = GraphQLScalars.ID("gid://shopify/Product/123")
        XCTAssertEqual(id.rawValue, "gid://shopify/Product/123")
        XCTAssertEqual(id.description, "gid://shopify/Product/123")
    }

    func testIDCodable() throws {
        // Test encoding
        let id = GraphQLScalars.ID("gid://shopify/Cart/456")
        let encoded = try JSONEncoder().encode(id)
        let encodedString = String(data: encoded, encoding: .utf8)
        // JSON encoder may escape forward slashes, both are valid
        XCTAssertTrue(encodedString == "\"gid://shopify/Cart/456\"" || encodedString == "\"gid:\\/\\/shopify\\/Cart\\/456\"")

        // Test decoding
        let json = "\"gid://shopify/Order/789\""
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(GraphQLScalars.ID.self, from: data)
        XCTAssertEqual(decoded.rawValue, "gid://shopify/Order/789")
    }

    func testIDNumericIdExtraction() {
        // Test valid GID format
        let id1 = GraphQLScalars.ID("gid://shopify/Product/123456")
        XCTAssertEqual(id1.numericId, "123456")

        // Test nested GID format
        let id2 = GraphQLScalars.ID("gid://shopify/Collection/123/Product/456")
        XCTAssertEqual(id2.numericId, "456")

        // Test non-GID format
        let id3 = GraphQLScalars.ID("simple-id")
        XCTAssertEqual(id3.numericId, "simple-id")

        // Test empty segments
        let id4 = GraphQLScalars.ID("gid://shopify/")
        XCTAssertEqual(id4.numericId, "")
    }

    func testIDHashable() {
        let id1 = GraphQLScalars.ID("gid://shopify/Product/123")
        let id2 = GraphQLScalars.ID("gid://shopify/Product/123")
        let id3 = GraphQLScalars.ID("gid://shopify/Product/456")

        XCTAssertEqual(id1, id2)
        XCTAssertNotEqual(id1, id3)

        // Test in Set
        let set: Set<GraphQLScalars.ID> = [id1, id2, id3]
        XCTAssertEqual(set.count, 2)
    }

    // MARK: - Money Scalar Tests

    func testMoneyInitialization() {
        let money = GraphQLScalars.Money(amount: Decimal(19.99), currencyCode: "USD")
        XCTAssertEqual(money.amount, Decimal(19.99))
        XCTAssertEqual(money.currencyCode, "USD")
    }

    func testMoneyCodable() throws {
        // Test encoding
        let money = GraphQLScalars.Money(amount: Decimal(49.95), currencyCode: "CAD")
        let encoded = try JSONEncoder().encode(money)
        let json = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]

        // Check amount - it might be NSDecimalNumber or NSNumber
        if let amount = json?["amount"] as? NSDecimalNumber {
            XCTAssertEqual(amount.decimalValue, Decimal(49.95))
        } else if let amount = json?["amount"] as? NSNumber {
            XCTAssertEqual(Decimal(amount.doubleValue), Decimal(49.95))
        } else {
            XCTFail("Amount not found or wrong type")
        }
        XCTAssertEqual(json?["currencyCode"] as? String, "CAD")

        // Test decoding
        let jsonString = """
        {"amount": 99.99, "currencyCode": "EUR"}
        """
        let data = jsonString.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(GraphQLScalars.Money.self, from: data)
        XCTAssertEqual(decoded.amount, Decimal(99.99))
        XCTAssertEqual(decoded.currencyCode, "EUR")
    }

    func testMoneyHashable() {
        let money1 = GraphQLScalars.Money(amount: Decimal(10.00), currencyCode: "USD")
        let money2 = GraphQLScalars.Money(amount: Decimal(10.00), currencyCode: "USD")
        let money3 = GraphQLScalars.Money(amount: Decimal(10.00), currencyCode: "CAD")
        let money4 = GraphQLScalars.Money(amount: Decimal(20.00), currencyCode: "USD")

        XCTAssertEqual(money1, money2)
        XCTAssertNotEqual(money1, money3)
        XCTAssertNotEqual(money1, money4)
    }

    // MARK: - DateTime Scalar Tests

    func testDateTimeInitialization() {
        let date = Date()
        let dateTime = GraphQLScalars.DateTime(date)
        XCTAssertEqual(dateTime.date, date)
    }

    func testDateTimeEncodingDecoding() throws {
        // Test with fractional seconds
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let dateString = "2025-06-25T12:30:45.123Z"
        let date = formatter.date(from: dateString)!

        let dateTime = GraphQLScalars.DateTime(date)
        let encoded = try JSONEncoder().encode(dateTime)
        let encodedString = String(data: encoded, encoding: .utf8)!

        // The encoded string should be a valid ISO8601 date
        XCTAssertTrue(encodedString.contains("2025-06-25"))

        // Test decoding with fractional seconds
        let jsonWithFractional = "\"2025-06-25T12:30:45.123Z\""
        let dataWithFractional = jsonWithFractional.data(using: .utf8)!
        let decodedWithFractional = try JSONDecoder().decode(GraphQLScalars.DateTime.self, from: dataWithFractional)
        XCTAssertNotNil(decodedWithFractional.date)

        // Test decoding without fractional seconds
        let jsonWithoutFractional = "\"2025-06-25T12:30:45Z\""
        let dataWithoutFractional = jsonWithoutFractional.data(using: .utf8)!
        let decodedWithoutFractional = try JSONDecoder().decode(GraphQLScalars.DateTime.self, from: dataWithoutFractional)
        XCTAssertNotNil(decodedWithoutFractional.date)
    }

    func testDateTimeInvalidFormat() {
        let invalidJson = "\"not-a-date\""
        let data = invalidJson.data(using: .utf8)!

        XCTAssertThrowsError(try JSONDecoder().decode(GraphQLScalars.DateTime.self, from: data)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testDateTimeHashable() {
        let date1 = Date()
        let date2 = Date(timeIntervalSince1970: 0)

        let dateTime1 = GraphQLScalars.DateTime(date1)
        let dateTime2 = GraphQLScalars.DateTime(date1)
        let dateTime3 = GraphQLScalars.DateTime(date2)

        XCTAssertEqual(dateTime1, dateTime2)
        XCTAssertNotEqual(dateTime1, dateTime3)
    }

    // MARK: - URL Scalar Tests

    func testURLInitialization() {
        // Test with Foundation.URL
        let foundationURL = Foundation.URL(string: "https://example.com")!
        let url1 = GraphQLScalars.URL(foundationURL)
        XCTAssertEqual(url1.url, foundationURL)

        // Test with string
        let url2 = GraphQLScalars.URL(string: "https://shopify.com")
        XCTAssertNotNil(url2)
        XCTAssertEqual(url2?.url.absoluteString, "https://shopify.com")

        // Test with invalid string - Foundation.URL actually accepts this
        let url3 = GraphQLScalars.URL(string: "not a url")
        XCTAssertNotNil(url3) // Foundation.URL accepts this as a relative URL
    }

    func testURLCodable() throws {
        // Test encoding
        let url = GraphQLScalars.URL(Foundation.URL(string: "https://example.com/path")!)
        let encoded = try JSONEncoder().encode(url)
        let encodedString = String(data: encoded, encoding: .utf8)
        // JSON encoder may escape forward slashes
        XCTAssertTrue(encodedString == "\"https://example.com/path\"" || encodedString == "\"https:\\/\\/example.com\\/path\"")

        // Test decoding valid URL
        let json = "\"https://shopify.com/products\""
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(GraphQLScalars.URL.self, from: data)
        XCTAssertEqual(decoded.url.absoluteString, "https://shopify.com/products")

        // Test decoding invalid URL - use actually invalid URL
        let invalidJson = "\"\"" // Empty string is invalid URL
        let invalidData = invalidJson.data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(GraphQLScalars.URL.self, from: invalidData))
    }

    func testURLHashable() {
        let url1 = GraphQLScalars.URL(Foundation.URL(string: "https://example.com")!)
        let url2 = GraphQLScalars.URL(Foundation.URL(string: "https://example.com")!)
        let url3 = GraphQLScalars.URL(Foundation.URL(string: "https://different.com")!)

        XCTAssertEqual(url1, url2)
        XCTAssertNotEqual(url1, url3)
    }

    // MARK: - HTML Scalar Tests

    func testHTMLInitialization() {
        let htmlContent = "<p>Hello <strong>World</strong></p>"
        let html = GraphQLScalars.HTML(htmlContent)
        XCTAssertEqual(html.rawValue, htmlContent)
    }

    func testHTMLCodable() throws {
        // Test encoding
        let html = GraphQLScalars.HTML("<div class=\"test\">Content</div>")
        let encoded = try JSONEncoder().encode(html)
        let encodedString = String(data: encoded, encoding: .utf8)
        // JSON encoder may escape forward slashes in closing tags
        XCTAssertTrue(encodedString == "\"<div class=\\\"test\\\">Content</div>\"" || encodedString == "\"<div class=\\\"test\\\">Content<\\/div>\"")

        // Test decoding
        let json = "\"<h1>Title</h1><p>Paragraph</p>\""
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(GraphQLScalars.HTML.self, from: data)
        XCTAssertEqual(decoded.rawValue, "<h1>Title</h1><p>Paragraph</p>")
    }

    func testHTMLHashable() {
        let html1 = GraphQLScalars.HTML("<p>Test</p>")
        let html2 = GraphQLScalars.HTML("<p>Test</p>")
        let html3 = GraphQLScalars.HTML("<p>Different</p>")

        XCTAssertEqual(html1, html2)
        XCTAssertNotEqual(html1, html3)
    }

    // MARK: - CountryCode Enum Tests

    func testCountryCodeCodable() throws {
        // Test encoding
        let country = CountryCode.US
        let encoded = try JSONEncoder().encode(country)
        let encodedString = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(encodedString, "\"US\"")

        // Test decoding
        let json = "\"CA\""
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(CountryCode.self, from: data)
        XCTAssertEqual(decoded, .CA)
    }

    func testCountryCodeAllCases() {
        // Test that we have many country codes
        XCTAssertGreaterThan(CountryCode.allCases.count, 200)

        // Test some specific cases
        XCTAssertTrue(CountryCode.allCases.contains(.US))
        XCTAssertTrue(CountryCode.allCases.contains(.CA))
        XCTAssertTrue(CountryCode.allCases.contains(.GB))
        XCTAssertTrue(CountryCode.allCases.contains(.AU))
        XCTAssertTrue(CountryCode.allCases.contains(.JP))
    }

    func testCountryCodeSpecialCases() {
        // Test reserved keywords with backticks
        XCTAssertEqual(CountryCode.DO.rawValue, "DO")
        XCTAssertEqual(CountryCode.IN.rawValue, "IN")
        XCTAssertEqual(CountryCode.IS.rawValue, "IS")
    }

    // MARK: - CurrencyCode Enum Tests

    func testCurrencyCodeCodable() throws {
        // Test encoding
        let currency = CurrencyCode.usd
        let encoded = try JSONEncoder().encode(currency)
        let encodedString = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(encodedString, "\"USD\"")

        // Test decoding
        let json = "\"EUR\""
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(CurrencyCode.self, from: data)
        XCTAssertEqual(decoded, .eur)
    }

    func testCurrencyCodeAllCases() {
        // Test that we have many currency codes
        XCTAssertGreaterThan(CurrencyCode.allCases.count, 150)

        // Test some major currencies
        XCTAssertTrue(CurrencyCode.allCases.contains(.usd))
        XCTAssertTrue(CurrencyCode.allCases.contains(.eur))
        XCTAssertTrue(CurrencyCode.allCases.contains(.gbp))
        XCTAssertTrue(CurrencyCode.allCases.contains(.jpy))
        XCTAssertTrue(CurrencyCode.allCases.contains(.cad))
        XCTAssertTrue(CurrencyCode.allCases.contains(.aud))
    }

    func testCurrencyCodeSpecialCases() {
        // Test reserved keyword with backtick
        XCTAssertEqual(CurrencyCode.try.rawValue, "TRY")
    }

    // MARK: - Integration Tests

    func testScalarsInComplexStructure() throws {
        // Test that scalars work correctly in a complex structure
        struct TestProduct: Codable {
            let id: GraphQLScalars.ID
            let createdAt: GraphQLScalars.DateTime
            let price: GraphQLScalars.Money
            let description: GraphQLScalars.HTML
            let productUrl: GraphQLScalars.URL
            let countryCode: CountryCode
            let currencyCode: CurrencyCode
        }

        let product = TestProduct(
            id: GraphQLScalars.ID("gid://shopify/Product/123"),
            createdAt: GraphQLScalars.DateTime(Date()),
            price: GraphQLScalars.Money(amount: Decimal(29.99), currencyCode: "USD"),
            description: GraphQLScalars.HTML("<p>Great product!</p>"),
            productUrl: GraphQLScalars.URL(Foundation.URL(string: "https://shop.com/product")!),
            countryCode: .US,
            currencyCode: .usd
        )

        // Test round-trip encoding/decoding
        let encoded = try JSONEncoder().encode(product)
        let decoded = try JSONDecoder().decode(TestProduct.self, from: encoded)

        XCTAssertEqual(decoded.id, product.id)
        XCTAssertEqual(decoded.price, product.price)
        XCTAssertEqual(decoded.description, product.description)
        XCTAssertEqual(decoded.productUrl, product.productUrl)
        XCTAssertEqual(decoded.countryCode, product.countryCode)
        XCTAssertEqual(decoded.currencyCode, product.currencyCode)
    }
}
