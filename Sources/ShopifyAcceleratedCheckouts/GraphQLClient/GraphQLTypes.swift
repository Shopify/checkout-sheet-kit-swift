//
//  GraphQLTypes.swift
//  ShopifyAcceleratedCheckouts
//

import Foundation

/// GraphQL client errors
enum GraphQLError: LocalizedError {
    case networkError(String)
    case httpError(statusCode: Int, data: Data)
    case decodingError(Error)
    case graphQLErrors([GraphQLResponseError])
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case let .networkError(message):
            return "Network error: \(message)"
        case let .httpError(statusCode, data):
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            return "HTTP error \(statusCode): \(body)"
        case let .decodingError(error):
            return "Decoding error: \(error.localizedDescription)"
        case let .graphQLErrors(errors):
            return "GraphQL errors: \(errors.map { $0.message }.joined(separator: ", "))"
        case .invalidResponse:
            return "Invalid response from server"
        }
    }
}

/// Helper type for encoding/decoding Any values
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let value = try? container.decode(Bool.self) {
            self.value = value
        } else if let value = try? container.decode(Int.self) {
            self.value = value
        } else if let value = try? container.decode(Double.self) {
            self.value = value
        } else if let value = try? container.decode(String.self) {
            self.value = value
        } else if let value = try? container.decode([String: AnyCodable].self) {
            self.value = value.mapValues { $0.value }
        } else if let value = try? container.decode([AnyCodable].self) {
            self.value = value.map { $0.value }
        } else if container.decodeNil() {
            value = NSNull()
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to decode value")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let value as Bool:
            try container.encode(value)
        case let value as Int:
            try container.encode(value)
        case let value as Double:
            try container.encode(value)
        case let value as String:
            try container.encode(value)
        case let value as [String: Any]:
            try container.encode(value.mapValues { AnyCodable($0) })
        case let value as [Any]:
            try container.encode(value.map { AnyCodable($0) })
        case is NSNull:
            try container.encodeNil()
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: container.codingPath, debugDescription: "Unable to encode value"))
        }
    }
}
