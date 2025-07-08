# Custom GraphQL Client for Storefront API

A lightweight, dependency-free GraphQL client for the Shopify Storefront API.

## Features

- **No external dependencies** - Built using only Foundation APIs
- **Custom scalar support** - Handles Money, DateTime, URL, ID, and other Storefront API scalars
- **Type-safe** - Fully typed models for requests and responses
- **Context support** - Built-in support for @inContext directive for localization
- **Error handling** - Comprehensive error handling for GraphQL and HTTP errors
- **Async/await** - Modern Swift concurrency support

## Architecture

### Core Components

1. **GraphQLClient** - The low-level client that handles HTTP requests and responses
2. **StorefrontAPI** - High-level API wrapper with convenience methods
3. **GraphQLScalars** - Custom scalar types (ID, Money, DateTime, URL, etc.)
4. **StorefrontModels** - Codable models for all Storefront API types
5. **GraphQLDocumentLoader** - Loads and combines GraphQL documents with fragments

### File Structure

```
HTTPClient/
├── GraphQLClient.swift       # Core GraphQL client
├── GraphQLTypes.swift        # Request/response types
├── GraphQLScalars.swift      # Custom scalar implementations
├── StorefrontModels.swift    # API data models
├── StorefrontAPI.swift       # High-level API wrapper
├── GraphQLDocumentLoader.swift # Document management
├── Example.swift             # Usage examples
└── GraphQL/                  # GraphQL documents
    ├── Fragments.graphql
    ├── Queries.graphql
    └── Mutations.graphql
```

## Usage

### Basic Setup

```swift
// Initialize the API
let api = StorefrontAPI(
    shopDomain: "example.myshopify.com",
    storefrontAccessToken: "your-access-token",
    countryCode: "US",        // Optional: for localization
    languageCode: "EN"        // Optional: for localization
)
```

### Creating a Cart

```swift
// Create an empty cart
let cart = try await api.cartCreate()

// Create a cart with items
let variantId = GraphQLScalars.ID("gid://shopify/ProductVariant/123")
let cart = try await api.cartCreate(with: [variantId])
```

### Querying Products

```swift
let products = try await api.products(first: 10)
for product in products {
    print("Product: \(product.title)")
}
```

### Error Handling

```swift
do {
    let cart = try await api.cartCreate()
} catch let error as CartUserError {
    // Handle cart-specific errors
    print("Cart error: \(error.message)")
} catch let error as GraphQLError {
    // Handle GraphQL errors
    switch error {
    case .networkError(let message):
        print("Network error: \(message)")
    case .graphQLErrors(let errors):
        for error in errors {
            print("GraphQL error: \(error.message)")
        }
    default:
        print("Error: \(error.localizedDescription)")
    }
}
```

## Custom Scalars

The client handles all Storefront API custom scalars:

- **ID**: Global identifiers (e.g., `gid://shopify/Product/123`)
- **Money**: Decimal amounts with currency
- **DateTime**: ISO 8601 date-time strings
- **URL**: Absolute URLs
- **HTML**: HTML content
- **CountryCode**: ISO country codes
- **CurrencyCode**: ISO currency codes

## Adding New Operations

1. Add the GraphQL operation to the appropriate `.graphql` file
2. Add corresponding models to `StorefrontModels.swift`
3. Add a convenience method to `StorefrontAPI.swift`
4. Update `GraphQLDocumentLoader` if needed

## Migration from Buy SDK

This client is designed to replace the Buy SDK dependency. Key differences:

- No external dependencies
- Simpler API surface
- Direct GraphQL document management
- Custom scalar handling built-in
- Modern Swift concurrency

To migrate:
1. Replace `Storefront.*` types with the new models
2. Replace `Graph.Client` with `GraphQLClient`
3. Update mutation/query calls to use the new API methods 