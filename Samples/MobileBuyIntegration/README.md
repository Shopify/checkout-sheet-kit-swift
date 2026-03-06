# MobileBuyIntegration Sample App

A sample iOS app demonstrating how to integrate [Checkout Sheet Kit](../../README.md) with the Shopify Storefront API using [Apollo iOS](https://github.com/apollographql/apollo-ios).

## Architecture

The app uses **Apollo GraphQL** for all Storefront API communication. GraphQL operations are defined as `.graphql` files, and Apollo's code generation tool produces type-safe Swift code from them.

### Storefront API layer

```
MobileBuyIntegration/
├── GraphQL/                          # Source of truth — you edit these
│   ├── Queries/
│   │   ├── GetProducts.graphql           # Product listing query
│   │   ├── CartQuery.graphql             # Fetch cart by ID
│   │   ├── CartFragment.graphql          # Reusable cart fields
│   │   ├── CartLineFragment.graphql      # Cart line item fields
│   │   ├── CartDeliveryGroupFragment.graphql
│   │   └── CartUserErrorFragment.graphql
│   └── Mutations/
│       ├── CartCreate.graphql            # Create a new cart
│       ├── CartLinesAdd.graphql          # Add items to cart
│       └── CartLinesUpdate.graphql       # Update item quantities
│
├── Generated/                        # Auto-generated — do not edit
│   ├── Storefront.graphql.swift          # Namespace & schema metadata
│   ├── Fragments/                        # Swift types for each fragment
│   ├── Operations/
│   │   ├── Mutations/                    # CartCreateMutation, CartLinesAddMutation, etc.
│   │   └── Queries/                      # GetProductsQuery, GetCartQuery
│   └── Schema/
│       ├── Enums/                        # CountryCode, CurrencyCode, LanguageCode, etc.
│       ├── InputObjects/                 # CartInput, CartLineInput, etc.
│       ├── Objects/                      # Cart, Product, MoneyV2, etc.
│       ├── Interfaces/                   # BaseCartLine, Node
│       └── Unions/                       # Merchandise
│
├── Network.swift                     # Apollo client setup + auth interceptor
├── CartManager.swift                 # Cart state management (uses Apollo mutations)
└── ...
```

**`GraphQL/`** contains the `.graphql` files you write and maintain. These define which fields the app fetches from the Storefront API.

**`Generated/`** contains Swift code produced by Apollo's code generation tool. These files should not be edited by hand — they are regenerated from the `.graphql` files and the schema.

### How it works

1. `Network.swift` creates a shared `ApolloClient` that points at the store's Storefront API endpoint and attaches the access token via an interceptor.
2. `CartManager.swift` and `ProductView.swift` call `Network.shared.apollo.perform(mutation:)` / `.fetch(query:)` using the generated operation types (e.g. `Storefront.CartCreateMutation`, `Storefront.GetProductsQuery`).
3. Responses are automatically decoded into the generated Swift types, giving you compile-time safety on every field access.

## Setup

1. Copy the config template and fill in your store credentials:

   ```bash
   cp Storefront.xcconfig.example Storefront.xcconfig
   ```

   Then edit `Storefront.xcconfig` with your values:

   ```
   STOREFRONT_DOMAIN = your-store.myshopify.com
   STOREFRONT_ACCESS_TOKEN = your-token
   API_VERSION = 2025-07
   ```

2. Open the project in Xcode and let SPM resolve the Apollo dependency.

3. Build and run.

## Updating the Storefront API version

When you want to target a newer Storefront API version (e.g. to access new fields or features), follow these steps:

### 1. Update the API version

Edit your `Storefront.xcconfig` and change the `API_VERSION` value:

```
API_VERSION = 2025-10
```

### 2. Download the new schema

The schema defines what types and fields are available in the API. Run from the **repo root** (`checkout-sheet-kit-swift/`):

```bash
dev apollo download_schema mobile-buy
```

This introspects your store's Storefront API at the configured version and writes a `schema.<version>.graphqls` file into the sample app directory.

> If this is your first time, you may need to install the Apollo CLI first. In Xcode, right-click the project in the navigator and select **Install CLI** from the Apollo menu. Alternatively, download the binary from the [Apollo iOS releases](https://github.com/apollographql/apollo-ios/releases) page and place it at `Samples/MobileBuyIntegration/apollo-ios-cli`.

### 3. Update your GraphQL operations (if needed)

If the new API version introduces fields you want to use, or deprecates fields you currently use, edit the `.graphql` files in `MobileBuyIntegration/GraphQL/`.

For example, to add a new field to products:

```graphql
# MobileBuyIntegration/GraphQL/Queries/GetProducts.graphql
query GetProducts(...) {
  products(first: $first) {
    nodes {
      id
      title
      myNewField    # <-- add new fields here
      ...
    }
  }
}
```

### 4. Run code generation

From the **repo root**:

```bash
dev apollo codegen mobile-buy
```

This reads the schema + your `.graphql` files and regenerates the Swift code in `Generated/`. The command also runs `dev fix` to auto-format the output.

### 5. Build and fix any issues

Build the project in Xcode. If the new schema removed or renamed fields, you'll get compile errors pointing you to the exact lines that need updating.

## Dev commands reference

All commands are run from the **repo root** (`checkout-sheet-kit-swift/`):

| Command | Description |
|---------|-------------|
| `dev apollo download_schema mobile-buy` | Download the Storefront API schema for this sample app |
| `dev apollo codegen mobile-buy` | Regenerate Swift types from `.graphql` files |
| `dev apollo codegen all` | Regenerate for all sample apps |
| `dev style` | Run SwiftLint + SwiftFormat checks |
| `dev fix` | Auto-fix lint/format issues |
| `dev build samples` | Build all sample apps |

## Key files

| File | Purpose |
|------|---------|
| `schema.graphqls` | Storefront API schema (downloaded, not hand-written) |
| `apollo-codegen-config.json` | Apollo codegen configuration |
| `apollo-ios-cli` | Apollo CLI binary (not checked into git) |
| `Storefront.xcconfig` | Store credentials + API version (not checked into git) |
| `Network.swift` | Apollo client setup, auth interceptor |
| `CartManager.swift` | Cart state, create/add/update operations |
