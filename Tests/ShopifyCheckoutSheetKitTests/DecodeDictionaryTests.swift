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

class DecodeDictionaryTests: XCTestCase {

    private struct TestWrapper: Decodable {
        let data: [String: Any]

        enum CodingKeys: String, CodingKey {
            case data
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            data = try container.decode([String: Any].self, forKey: .data)
        }
    }

    private struct TestArrayWrapper: Decodable {
        let items: [Any]

        enum CodingKeys: String, CodingKey {
            case items
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            items = try container.decode([Any].self, forKey: .items)
        }
    }

    func testDecodesDictionaryWithNullValues() throws {
        let json = """
        {"data": {"name": "test", "value": null, "count": 42}}
        """.data(using: .utf8)!

        let result = try JSONDecoder().decode(TestWrapper.self, from: json)

        XCTAssertEqual(result.data["name"] as? String, "test")
        XCTAssertTrue(result.data["value"] is NSNull)
        XCTAssertEqual(result.data["count"] as? Int, 42)
    }

    func testDecodesArrayWithNullValues() throws {
        let json = """
        {"items": ["hello", null, 123, null, true]}
        """.data(using: .utf8)!

        let result = try JSONDecoder().decode(TestArrayWrapper.self, from: json)

        XCTAssertEqual(result.items.count, 5)
        XCTAssertEqual(result.items[0] as? String, "hello")
        XCTAssertTrue(result.items[1] is NSNull)
        XCTAssertEqual(result.items[2] as? Double, 123)
        XCTAssertTrue(result.items[3] is NSNull)
        XCTAssertEqual(result.items[4] as? Bool, true)
    }

    func testDecodesNestedDictionaryWithNullValues() throws {
        let json = """
        {"data": {"nested": {"key": null}, "list": [null, "value"]}}
        """.data(using: .utf8)!

        let result = try JSONDecoder().decode(TestWrapper.self, from: json)

        let nested = result.data["nested"] as? [String: Any]
        XCTAssertNotNil(nested)
        XCTAssertTrue(nested?["key"] is NSNull)

        let list = result.data["list"] as? [Any]
        XCTAssertNotNil(list)
        XCTAssertEqual(list?.count, 2)
        XCTAssertTrue(list?[0] is NSNull)
        XCTAssertEqual(list?[1] as? String, "value")
    }

    func testDecodesArrayWithOnlyNullValues() throws {
        let json = """
        {"items": [null, null, null]}
        """.data(using: .utf8)!

        let result = try JSONDecoder().decode(TestArrayWrapper.self, from: json)

        XCTAssertEqual(result.items.count, 3)
        XCTAssertTrue(result.items[0] is NSNull)
        XCTAssertTrue(result.items[1] is NSNull)
        XCTAssertTrue(result.items[2] is NSNull)
    }
}
