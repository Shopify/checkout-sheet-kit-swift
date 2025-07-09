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

final class GraphQLTypesTests: XCTestCase {
    // MARK: - GraphQLRequest Encoding Tests

    func testGraphQLRequestEncodingWithVariables() throws {
        let operation = GraphQLRequest(
            query: "query GetUser($id: ID!) { user(id: $id) { name } }",
            responseType: String.self,
            variables: ["id": "123", "active": true]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(operation)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["query"] as? String, operation.query)
        XCTAssertNotNil(json?["variables"])

        let variables = json?["variables"] as? [String: Any]
        XCTAssertEqual(variables?["id"] as? String, "123")
        XCTAssertEqual(variables?["active"] as? Bool, true)
    }

    func testGraphQLRequestEncodingWithoutVariables() throws {
        let operation = GraphQLRequest(
            query: "query { users { name } }",
            responseType: String.self,
            variables: [:]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(operation)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["query"] as? String, operation.query)
        XCTAssertNil(json?["variables"])
    }

    func testGraphQLRequestEncodingWithComplexVariables() throws {
        let operation = GraphQLRequest(
            query: "mutation CreateUser($input: UserInput!) { createUser(input: $input) { id } }",
            responseType: String.self,
            variables: [
                "input": [
                    "name": "John Doe",
                    "age": 30,
                    "tags": ["developer", "swift"],
                    "metadata": [
                        "level": 5,
                        "verified": true
                    ]
                ]
            ]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(operation)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertNotNil(json?["variables"])
        let variables = json?["variables"] as? [String: Any]
        let input = variables?["input"] as? [String: Any]
        XCTAssertEqual(input?["name"] as? String, "John Doe")
        XCTAssertEqual(input?["age"] as? Int, 30)
        XCTAssertEqual(input?["tags"] as? [String], ["developer", "swift"])

        let metadata = input?["metadata"] as? [String: Any]
        XCTAssertEqual(metadata?["level"] as? Int, 5)
        XCTAssertEqual(metadata?["verified"] as? Bool, true)
    }

    // MARK: - GraphQLResponse Tests

    func testGraphQLResponseDecodingWithData() throws {
        struct User: Decodable {
            let id: String
            let name: String
        }

        struct UserResponse: Decodable {
            let user: User
        }

        let json = """
        {
            "data": {
                "user": {
                    "id": "123",
                    "name": "John Doe"
                }
            }
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(GraphQLResponse<UserResponse>.self, from: data)

        XCTAssertNotNil(response.data)
        XCTAssertEqual(response.data?.user.id, "123")
        XCTAssertEqual(response.data?.user.name, "John Doe")
        XCTAssertNil(response.errors)
        XCTAssertFalse(response.hasErrors)
    }

    func testGraphQLResponseDecodingWithErrors() throws {
        struct EmptyResponse: Decodable {}

        let json = """
        {
            "data": null,
            "errors": [
                {
                    "message": "User not found",
                    "path": ["user"],
                    "locations": [{"line": 2, "column": 3}],
                    "extensions": {
                        "code": "USER_NOT_FOUND",
                        "field": ["id"]
                    }
                }
            ]
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(GraphQLResponse<EmptyResponse>.self, from: data)

        XCTAssertNil(response.data)
        XCTAssertNotNil(response.errors)
        XCTAssertTrue(response.hasErrors)
        XCTAssertEqual(response.errors?.count, 1)

        let error = response.errors?.first
        XCTAssertEqual(error?.message, "User not found")
        XCTAssertEqual(error?.path, ["user"])
        XCTAssertEqual(error?.locations?.first?.line, 2)
        XCTAssertEqual(error?.locations?.first?.column, 3)
        XCTAssertEqual(error?.extensions?.code, "USER_NOT_FOUND")
        XCTAssertEqual(error?.extensions?.field, ["id"])
    }

    func testGraphQLResponseDecodingWithExtensions() throws {
        struct EmptyResponse: Decodable {}

        let json = """
        {
            "data": {},
            "extensions": {
                "requestId": "abc123",
                "cost": 42,
                "metadata": {
                    "version": "1.0"
                }
            }
        }
        """

        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(GraphQLResponse<EmptyResponse>.self, from: data)

        XCTAssertNotNil(response.extensions)
        XCTAssertEqual(response.extensions?["requestId"]?.value as? String, "abc123")
        XCTAssertEqual(response.extensions?["cost"]?.value as? Int, 42)

        let metadata = response.extensions?["metadata"]?.value as? [String: Any]
        XCTAssertEqual(metadata?["version"] as? String, "1.0")
    }

    // MARK: - GraphQLError Tests

    func testGraphQLErrorDescriptions() {
        // Test network error
        let networkError = GraphQLError.networkError("Connection timeout")
        XCTAssertEqual(networkError.errorDescription, "Network error: Connection timeout")

        // Test HTTP error
        let httpData = "Bad Request".data(using: .utf8)!
        let httpError = GraphQLError.httpError(statusCode: 400, data: httpData)
        XCTAssertEqual(httpError.errorDescription, "HTTP error 400: Bad Request")

        // Test decoding error
        let decodingError = GraphQLError.decodingError(NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON"]))
        XCTAssertEqual(decodingError.errorDescription, "Decoding error: Invalid JSON")

        // Test GraphQL errors
        let graphQLResponseError = GraphQLResponseError(
            message: "Field not found",
            path: nil,
            locations: nil,
            extensions: nil
        )
        let graphQLErrors = GraphQLError.graphQLErrors([graphQLResponseError])
        XCTAssertEqual(graphQLErrors.errorDescription, "GraphQL errors: Field not found")

        // Test invalid response
        let invalidResponse = GraphQLError.invalidResponse
        XCTAssertEqual(invalidResponse.errorDescription, "Invalid response from server")
    }

    func testGraphQLErrorWithMultipleErrors() {
        let errors = [
            GraphQLResponseError(message: "Error 1", path: nil, locations: nil, extensions: nil),
            GraphQLResponseError(message: "Error 2", path: nil, locations: nil, extensions: nil)
        ]
        let graphQLError = GraphQLError.graphQLErrors(errors)

        XCTAssertEqual(graphQLError.errorDescription, "GraphQL errors: Error 1, Error 2")
    }

    // MARK: - AnyCodable Tests

    func testAnyCodableEncodingPrimitives() throws {
        // Test Bool
        let boolValue = AnyCodable(true)
        let boolData = try JSONEncoder().encode(boolValue)
        XCTAssertEqual(String(data: boolData, encoding: .utf8), "true")

        // Test Int
        let intValue = AnyCodable(42)
        let intData = try JSONEncoder().encode(intValue)
        XCTAssertEqual(String(data: intData, encoding: .utf8), "42")

        // Test Double
        let doubleValue = AnyCodable(3.14)
        let doubleData = try JSONEncoder().encode(doubleValue)
        XCTAssertEqual(String(data: doubleData, encoding: .utf8), "3.14")

        // Test String
        let stringValue = AnyCodable("Hello")
        let stringData = try JSONEncoder().encode(stringValue)
        XCTAssertEqual(String(data: stringData, encoding: .utf8), "\"Hello\"")

        // Test Null
        let nullValue = AnyCodable(NSNull())
        let nullData = try JSONEncoder().encode(nullValue)
        XCTAssertEqual(String(data: nullData, encoding: .utf8), "null")
    }

    func testAnyCodableEncodingCollections() throws {
        // Test Dictionary
        let dictValue = AnyCodable(["key": "value", "number": 123])
        let dictData = try JSONEncoder().encode(dictValue)
        let dictJSON = try JSONSerialization.jsonObject(with: dictData) as? [String: Any]
        XCTAssertEqual(dictJSON?["key"] as? String, "value")
        XCTAssertEqual(dictJSON?["number"] as? Int, 123)

        // Test Array
        let arrayValue = AnyCodable(["a", 1, true])
        let arrayData = try JSONEncoder().encode(arrayValue)
        let arrayJSON = try JSONSerialization.jsonObject(with: arrayData) as? [Any]
        XCTAssertEqual(arrayJSON?.count, 3)
        XCTAssertEqual(arrayJSON?[0] as? String, "a")
        XCTAssertEqual(arrayJSON?[1] as? Int, 1)
        XCTAssertEqual(arrayJSON?[2] as? Bool, true)
    }

    func testAnyCodableDecodingPrimitives() throws {
        // Test Bool
        let boolData = "true".data(using: .utf8)!
        let boolValue = try JSONDecoder().decode(AnyCodable.self, from: boolData)
        XCTAssertEqual(boolValue.value as? Bool, true)

        // Test Int
        let intData = "42".data(using: .utf8)!
        let intValue = try JSONDecoder().decode(AnyCodable.self, from: intData)
        XCTAssertEqual(intValue.value as? Int, 42)

        // Test Double
        let doubleData = "3.14".data(using: .utf8)!
        let doubleValue = try JSONDecoder().decode(AnyCodable.self, from: doubleData)
        XCTAssertEqual(doubleValue.value as? Double, 3.14)

        // Test String
        let stringData = "\"Hello\"".data(using: .utf8)!
        let stringValue = try JSONDecoder().decode(AnyCodable.self, from: stringData)
        XCTAssertEqual(stringValue.value as? String, "Hello")

        // Test Null
        let nullData = "null".data(using: .utf8)!
        let nullValue = try JSONDecoder().decode(AnyCodable.self, from: nullData)
        XCTAssertTrue(nullValue.value is NSNull)
    }

    func testAnyCodableDecodingCollections() throws {
        // Test Dictionary
        let dictData = "{\"key\":\"value\",\"number\":123}".data(using: .utf8)!
        let dictValue = try JSONDecoder().decode(AnyCodable.self, from: dictData)
        let dict = dictValue.value as? [String: Any]
        XCTAssertEqual(dict?["key"] as? String, "value")
        XCTAssertEqual(dict?["number"] as? Int, 123)

        // Test Array
        let arrayData = "[\"a\",1,true]".data(using: .utf8)!
        let arrayValue = try JSONDecoder().decode(AnyCodable.self, from: arrayData)
        let array = arrayValue.value as? [Any]
        XCTAssertEqual(array?.count, 3)
        XCTAssertEqual(array?[0] as? String, "a")
        XCTAssertEqual(array?[1] as? Int, 1)
        XCTAssertEqual(array?[2] as? Bool, true)
    }

    func testAnyCodableWithNestedStructures() throws {
        let nested: [String: Any] = [
            "user": [
                "id": 123,
                "name": "John",
                "active": true,
                "tags": ["swift", "ios"],
                "metadata": [
                    "level": 5
                ]
            ]
        ]

        let encoded = try JSONEncoder().encode(AnyCodable(nested))
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: encoded)

        let result = decoded.value as? [String: Any]
        let user = result?["user"] as? [String: Any]
        XCTAssertEqual(user?["id"] as? Int, 123)
        XCTAssertEqual(user?["name"] as? String, "John")
        XCTAssertEqual(user?["active"] as? Bool, true)
        XCTAssertEqual(user?["tags"] as? [String], ["swift", "ios"])

        let metadata = user?["metadata"] as? [String: Any]
        XCTAssertEqual(metadata?["level"] as? Int, 5)
    }
}
