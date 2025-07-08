//
//  GraphQLResponse.swift
//  ShopifyAcceleratedCheckouts
//
//  Created by Kieran Barrie Osgood on 27/06/2025.
//

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
    let message: String
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
