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

/// GraphQL response structure
struct GraphQLResponse<T: Decodable>: Decodable {
    let data: T?
    let errors: [GraphQLResponseError]?
    let extensions: [String: AnyCodable]?

    /// Check if the response has errors
    var hasErrors: Bool {
        return errors != nil && !errors!.isEmpty
    }
}

/// GraphQL error from response
struct GraphQLResponseError: Decodable, Error {
    let message: String?
    let path: [String]?
    let locations: [Location]?
    let extensions: Extensions?

    struct Location: Decodable {
        let line: Int
        let column: Int
    }

    struct Extensions: Decodable {
        let code: String?
        let field: [String]?
        let cost: Int?
        let maxCost: Int?

        // Custom decoding to handle additional fields
        private struct DynamicCodingKeys: CodingKey {
            var stringValue: String
            var intValue: Int?

            init?(stringValue: String) {
                self.stringValue = stringValue
            }

            init?(intValue _: Int) {
                return nil
            }
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: DynamicCodingKeys.self)

            code = try? container.decode(String.self, forKey: DynamicCodingKeys(stringValue: "code")!)
            field = try? container.decode([String].self, forKey: DynamicCodingKeys(stringValue: "field")!)
            cost = try? container.decode(Int.self, forKey: DynamicCodingKeys(stringValue: "cost")!)
            maxCost = try? container.decode(Int.self, forKey: DynamicCodingKeys(stringValue: "maxCost")!)
        }
    }
}
