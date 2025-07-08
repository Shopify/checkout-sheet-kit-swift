//
//  GraphQLDocument+Queries.swift
//  ShopifyAcceleratedCheckouts
//

extension GraphQLDocument {
    enum Queries: String {
        case cart = """
        query GetCart($id: ID!) {
          cart(id: $id) {
            ...CartFragment
          }
        }
        """

        case products = """
        query GetProducts($first: Int = 10) {
          products(first: $first) {
            nodes {
              id
              title
              variants(first: 10) {
                nodes {
                  id
                  title
                  requiresShipping
                  price {
                    amount
                    currencyCode
                  }
                }
              }
            }
          }
        }
        """

        case shop = """
        query GetShop {
          shop {
            name
            description
            primaryDomain {
              host
              sslEnabled
              url
            }
            shipsToCountries
            paymentSettings {
              supportedDigitalWallets
              acceptedCardBrands
              countryCode
            }
            moneyFormat
          }
        }
        """
    }
}
